# Container for a set of pages with methods for manipulation.

class PageSet
  attr_reader :web, :pages

  # Initialise a page set using:
  #
  # * The Web of interest
  # * An optional ActiveRecord::Relation starting point that selects pages for
  #   the page set, but may have additional query parts chained onto it later.
  # * An optional set of conditions to pass to a single #where that is chained
  #   onto the second parameter.
  #
  # It's more efficient to use the database to produce a page subset for the
  # second parameter than it is to use the third parameter, since that means
  # processing is done in Ruby, using web server CPU and RAM.
  #
  def initialize(web, page_set_query = nil, conditions = nil)
    eager  = [:web, :revisions, :wiki_references]
    @web   = web
    @pages =  if page_set_query.nil?
      # if pages is not specified, make a list of all pages in the web
      web.pages.includes(*eager)
    elsif conditions.nil?
      page_set_query.includes(*eager)
    else
      page_set_query.includes(*eager).where(conditions)
    end
  end

  def each(&block)
    @pages.each(&block)
  end

  # Just returns a date-time of the most recent revision across *all* pages in
  # this page set.
  #
  def most_recent_revision
    most_recent = Revision.where(page: @pages).order(id: :desc).first
    most_recent&.revised_at || Time.at(0)
  end

  def by_name
    PageSet.new(@web, @pages.order(name: :asc))
  end

  alias :sort :by_name

  def by_revision(offset = 0, limit = 50)

    # Build something akin to this, but as an ActiveRecord relation chain so we
    # can later easily apply offsets, limits, count, constrain by web etc.:
    #
    #   SELECT pages.*
    #   FROM pages
    #   JOIN (
    #       SELECT page_id, MAX(revised_at) AS max_revised_at
    #       FROM revisions
    #       GROUP BY page_id
    #   ) revisions ON pages.id = revisions.page_id
    #   ORDER BY revisions.max_revised_at DESC
    #
    join_sql = <<~JOINS
      JOIN (
        SELECT page_id, MAX(revised_at) AS max_revised_at
        FROM revisions
        GROUP BY page_id
      ) max_revisions_join ON pages.id = max_revisions_join.page_id
    JOINS

    ordered_pages = @pages
      .joins(join_sql)
      .reorder('max_revisions_join.max_revised_at DESC')

    return PageSet.new(@web, ordered_pages.where(web: @web))
  end

  def pages_that_reference(page_name)
    all_referring_page_names = WikiReference.pages_that_reference(@web, page_name)
    @pages.where(name: all_referring_page_names)
    # self.select { |page| all_referring_pages.include?(page.name) }
  end

  def pages_that_link_to(page_name)
    all_linking_page_names = WikiReference.pages_that_link_to(@web, page_name)
    @pages.where(name: all_linking_page_names)
    # self.select { |page| all_linking_pages.include?(page.name) }
  end

  def pages_that_include(page_name)
    all_including_pages = WikiReference.pages_that_include(@web, page_name)
    @pages.where(id: all_including_pages.map(&:id))
    # self.select { |page| all_including_pages.include?(page.name) }
  end

  def pages_authored_by(author)
    all_revisions_by_author = Revision.where(author: author)
    authored_page_ids       = revisions_by_author.pluck(:page_id)

    @pages.where(id: authored_page_ids)

    # all_pages_authored_by_the_author =
    #     Page.connection.select_all(sanitize_sql([
    #         "SELECT page_id FROM revision WHERE author = '?'", author]))
    # self.select { |page| page.authors.include?(author) }
  end

  def characters
    chars = 0

    @pages.find_each do | page |
      chars += page.content.size
    end

    return chars
    # @web.pages.inject(0) { |chars,page| chars += page.content.size }
  end

  # Returns all the orphaned pages in this page set. That is,
  # pages in this set for which there is no reference in the web.
  # The HomePage and author pages are always assumed to have
  # references and so cannot be orphans
  # Pages that refer to themselves and have no links from outside are orphans.
  def orphaned_pages
    never_orphans    = @pages.where(name: (web.authors.uniq + ['HomePage']))
    pages_referenced = @pages.where(id: WikiReference.all_referenced_pages_in(@web).select(:id))

    not_orphans = @pages
      .where(id: never_orphans)
      .or(@pages.where(id: pages_referenced))

    return @pages.where.not(id: not_orphans)
  end

  def pages_in_category(category)
    WikiReference.pages_in_category(web, category)
  end

  # Returns all the wiki words in this page set for which
  # there are no pages in this page set's web
  def wanted_pages
    all_current_page_names    = web.pages.pluck(:name)
    old_names_still_used      = WikiReference.all_referenced_redirection_names_in(web)
    all_wiki_words_everywhere = self.wiki_words

    return ((all_wiki_words_everywhere - all_current_page_names) - old_names_still_used)
  end

  def names
    @pages.pluck(:name)
    # self.map { |page| page.name }
  end

  def redirected_names
    self.wiki_words.select {|name| web.has_redirect_for?(name) }
  end

  def wiki_words
    words = []

    @pages.find_each { | page | words += page.wiki_words }

    words.flatten!
    words.uniq!
    words.sort!

    return words
  end

end
