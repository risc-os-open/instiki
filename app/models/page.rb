class Page < ApplicationRecord
  belongs_to :web

  has_many(
    :revisions,
    -> { order('id ASC') },
    dependent: :destroy
  )

  has_many(
    :wiki_references,
    -> { order('referenced_name ASC') }
  )

  # 2024-12-24 (ADH): Used to be a 'has_one' relationship, "id DESC" ordering.
  #
  # This is implemented as a Ruby iterator so that eager-loading of 'revisions'
  # will work, else we've an enforced DB query on every single current revision
  # reference codebase-wide. Using a local Ruby search over what is usually a
  # quite small array (rarely more than tens of items) was much, much faster.
  #
  def current_revision
    self.revisions.to_a.sort_by(&:id).last
  end

  def name
    read_attribute(:name).as_utf8
  end

  def revise(content, name, time, author, renderer)
    revisions_size = new_record? ? 0 : revisions.size
    if (revisions_size > 0) and content == current_revision.content and name == self.name
      raise InstikiErrors::ValidationError.new(
          "You have tried to save page '#{name}' without changing its content")
    end

    self.name = name
    author = Author.new(author.to_s) unless author.is_a?(Author)

    # 2011-03-12 (ADH): Assumption of Textile processing; patch inter-page
    #                   links expressed as Textile links not Wiki links, so
    #                   that Instiki's references mechanism recognises them
    #                   and pages are less likely to be erroneously declared
    #                   to be orphans.
    #
    content = patch_interpage_textile_links( content )

    # Try to render content to make sure that markup engine can take it,
    renderer.revision = Revision.new(
       :page => self, :content => content, :author => author, :revised_at => time)
    renderer.display_content(update_references = true)

    # A user may change a page, look at it and make some more changes - several times.
    # Not to record every such iteration as a new revision, if the previous revision was done
    # by the same author, not more than 30 minutes ago, then update the last revision instead of
    # creating a new one
    if (revisions_size > 0) && continous_revision?(time, author)
      current_revision.update(content: content, revised_at: time)
    else
      revisions.build(:content => content, :author => author, :revised_at => time)
    end
    save
    self
  end

  def rollback(revision_number, time, author_ip, renderer)
    roll_back_revision = self.revisions[revision_number]
    if roll_back_revision.nil?
      raise InstikiErrors::ValidationError.new("Revision #{revision_number} not found")
    end
    author = Author.new(roll_back_revision.author.name, author_ip)
    revise(roll_back_revision.content, self.name, time, author, renderer)
  end

  def revisions?
    revisions.size > 1
  end

  def previous_revision(revision)
    revision_index = revisions.each_with_index do |rev, index|
      if rev.id == revision.id
        break index
      else
        nil
      end
    end
    if revision_index.nil? or revision_index == 0
      nil
    else
      revisions[revision_index - 1]
    end
  end

  def references
    web.select.pages_that_reference(name)
  end

  # Finding these in Ruby means that an eager-loaded reference set will be used
  # instead of forcing a new DB query.
  #
  def wiki_words
    wiki_references.to_a.select { |ref| ref.wiki_word? }.map { |ref| ref.referenced_name }
  end

  def categories
    wiki_references.to_a.select { |ref| ref.category? }.map { |ref| ref.referenced_name }
  end

  def redirects
    wiki_references.to_a.select { |ref| ref.redirected_page? }.map { |ref| ref.referenced_name }
  end

  def linked_from
    web.select.pages_that_link_to(name)
  end

  def included_from
    web.select.pages_that_include(name)
  end

  # Returns the original wiki-word name as separate words, so "MyPage" becomes "My Page".
  def plain_name
    web.brackets_only? ? name.escapeHTML.html_safe : WikiWords.separate(name).escapeHTML.html_safe
  end

  LOCKING_PERIOD = 30.minutes

  def lock(time, locked_by)
    self.update(locked_at: time, locked_by: locked_by)
  end

  def lock_duration(time)
    ((time - locked_at) / 60).to_i unless locked_at.nil?
  end

  def unlock
    update_attribute(:locked_at, nil)
  end

  def locked?(comparison_time)
    locked_at + LOCKING_PERIOD > comparison_time unless locked_at.nil?
  end

  def to_param
    name.as_utf8
  end

  private

    def continous_revision?(time, author)
      (current_revision.author == author) && (revised_at + 30.minutes > time)
    end

    # Forward method calls to the current revision, so the page responds to all revision calls
    def method_missing(method_id, *args, &block)
      method_name = method_id.to_s
      # Perform a hand-off to AR::Base#method_missing
      if @attributes.include?(method_name) or md = /(=|\?|_before_type_cast)$/.match(method_name)
        super(method_id, *args, &block)
      else
        current_revision.send(method_id)
      end
    end

    # 2011-03-12 (ADH): Patch for Textile based wiki code.
    #
    # Some people use Textile links to refer to pages within the Wiki, perhaps
    # because they're unaware of the "[[Page name|Visible text]]" alias syntax.
    # This means that the Wiki may think a page is an orphan, with no links to
    # it, because there *are* links but they're in Textile format, not in Wiki
    # reference format.
    #
    # This method takes a string and returns a reasonably robustly processed
    # equivalent which has any Textile links which look like inter-page
    # references replaced by Wiki syntax equivalents on the "[[link|alias]]"
    # form. Typically, you pass the body text for entire revision in here.
    #
    # Heavily obfuscated Textile links, e.g. those which might specify an
    # absolute URL path from the document root or even including a host name
    # but still ultimately point to another page within the Wiki, will not be
    # replaced. So if users try hard enough, they can still break things!
    #
    unless defined? TEXTILE_LINK_PATTERN

      # In TEXTILE_ALIAS_PATTERN_START, we want it anchored to the start of a
      # line but a <textarea> uses "\r\n". The regexp fails if we try to use
      # "^" to anchor to start-of-line. Instead, match "\r\n" literally.
      #
      # In TEXTILE_LINK_PATTERN, after the ":" any non-white space character is
      # allowed. Trailing punctuation at the end of the link ('"foo":bar. ') is
      # stripped if necessary later. A '"' is not allowed immediately after the
      # ':' either, since Textile doesn't allow it and one or two sequences in
      # the ROOL Wiki can lead to disaster otherwise, such as '"#",":"'. In a
      # similar vein, a vertical bar is also ignored as this is a Textile table
      # cell separator and can't be used in named link references either.

      TEXTILE_LINK_PATTERN        = /\[?"([^\s].*?)":([^\s\"\|]+)\]?/
      TEXTILE_LINK_TRIM_PATTERN   = /[^\w]+$/
      TEXTILE_ALIAS_PATTERN_START = /\r\n\[/.source
      TEXTILE_ALIAS_PATTERN_END   = /\]([^\s]+)/.source

      ROOL_OLD_WIKI_PATH_PREFIX   = '/wiki/documentation/pages/'
    end
    #
    def patch_interpage_textile_links( str )

      # Changes will be made to "sub_str". The original is used for searches.

      sub_str = str.dup

      # Textile links may have the link inline, or refer to a link later in the
      # text using an alias. We record aliases and strip them out after the main
      # substitutions are done. We can't strip them out as we do the main
      # substitutions because several different Textile links may refer to the
      # same alias, even if other parts of that link are different.

      alias_matches = []

      # Scan the string for Textile links. In each match, we get the visible text
      # in the first parameter, link or alias in the second parameter and the
      # whole matched string set in "$&".

      str.scan( TEXTILE_LINK_PATTERN ) do | visible_text, link_or_alias |

        whole_link = $&

        # Patch the search: The link or alias has to be allowed to include all
        # kinds of characters, because they do! Stars, hyphens, underscores and
        # various other things. However we find in practice that Textile can
        # understand when a punctuation character occurs at the very end of a
        # link (it's followed by white space) and so this isn't considered part
        # of that link (even for ".", which might otherwise be legitimately
        # present for e.g. filename extensions).
        #
        # Accordingly, trim any non-alphabetic, non-numeric characters off the
        # end of the whole found piece of text and the link or alias text.

           whole_link.gsub!( TEXTILE_LINK_TRIM_PATTERN, '' )
        link_or_alias.gsub!( TEXTILE_LINK_TRIM_PATTERN, '' )

        # Generate a regular expression which matches an alias definition. If
        # we find it, then this link used an alias by definition; else the URL
        # was inline.

        alias_regexp = Regexp.new( "#{ TEXTILE_ALIAS_PATTERN_START }#{ Regexp.escape( link_or_alias ) }#{ TEXTILE_ALIAS_PATTERN_END }" )
        alias_match  = str.match( alias_regexp )

        # If an alias definition is found, index 1 will hold the URI part.

        if ( alias_match.nil? )
          link = link_or_alias
        else
          link = alias_match[ 1 ]
        end

        # Special case: If we have a known absolute URL prefix on the link,
        # strip it off. This is in case someone's daft enough (and it's seen on
        # the ROOL wiki) to encode a Textile format link with a URL path from
        # the root right back down to a Wiki page - for some reason.
        #
        # This is very much ROOL specific since the URL path prefix in question
        # used here is from the old ROOL I2-based Wiki.

        if ( link.index( ROOL_OLD_WIKI_PATH_PREFIX ) == 0 )
          link = link[ ROOL_OLD_WIKI_PATH_PREFIX.length .. -1 ]
        end

        # If there's a "/" in the link, it can't be an in-Wiki reference or
        # alias. Obfuscated in-Wiki references are possible ("/wiki_root/page",
        # that kind of thing) but we don't try to catch everything. If the user
        # tries hard enough they can defeat this code. We'd have to do something
        # complex with URI canonicalisation and the routing table to see if the
        # URI could possibly refer to the Wiki. It's really not worth the effort
        # and the performance impact to try that hard to avoid page references
        # that may lead to pages being declared as orphans, even though there is
        # technically an obscure format of reference elsewhere within the Wiki.
        #
        # A further complication is anchor references. In the ROOL Wiki, Textile
        # is sometimes used to link to anchors within pages but in most cases
        # there's also a higher level link to wider page too. Since that wider
        # link will be Wiki-fied, the page won't be an orphan; so leave the
        # anchor-based links in Textile format (there's no equivalent Wiki
        # syntax for them).

        next if ( link.include?( '/' ) || link.include?( '#' ) )

        # A "+" in a Textile link from I2 translates to a space in reality. After
        # that, hex sequences of the form "%XY" should be unescaped to arrive at
        # something Instiki will recognise as a Wiki page title.
        #
        # There are more esoteric forms such as "(foo). Text" which assigns class
        # "foo" to the <a> element, but we don't support those here.

        link.gsub!( '+', ' ' )
        link = CGI::unescape( link )

        # Substitute any matching Textile links with a Wiki link equivalent.

        sub_str.gsub!( whole_link, "[[#{ link }|#{ visible_text }]]" )

        # Remember alias definitions for removal later.

        alias_matches.push( alias_match[ 0 ] ) unless alias_match.nil?

      end

      # More slowness... Must now remove any referenced links too. Maintain
      # the "\r\n" included by the regular expression so that we don't
      # accidentally end up collapsing non-replaced link references against
      # textile output above, which "modern" Textile doesn't like.

      alias_matches.each do | alias_match |
        sub_str.gsub!( alias_match, "\r\n" )
      end

      return sub_str
    end
end
