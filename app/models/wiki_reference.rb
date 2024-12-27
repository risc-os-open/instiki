class WikiReference < ApplicationRecord

  LINKED_PAGE = 'L'
  WANTED_PAGE = 'W'
  REDIRECTED_PAGE = 'R'
  INCLUDED_PAGE = 'I'
  CATEGORY = 'C'
  AUTHOR = 'A'
  FILE = 'F'
  WANTED_FILE = 'E'

  belongs_to :page
  validates_inclusion_of :link_type, :in => [LINKED_PAGE, WANTED_PAGE, REDIRECTED_PAGE, INCLUDED_PAGE, CATEGORY, AUTHOR, FILE, WANTED_FILE]

  def referenced_name
    read_attribute(:referenced_name).as_utf8
  end

  def self.link_type(web, page_name)
    if web.has_page?(page_name) || self.page_that_redirects_for(web, page_name)
      LINKED_PAGE
    else
      WANTED_PAGE
    end
  end

  # Return a relation of Pages for anything that's a linked-to page, a wanted
  # page or a directly included page in the given Web. That is to say, a set of
  # pages that are referenced by some other page. Redirections are accounted
  # for, so a page that's linked via some old name which was subsequently
  # changed *is* included.
  #
  # In a Wiki, a page with no reference from anywhere (other than Home) is an
  # orphan, since there's no way through conventional navigation to ever reach
  # the 'show' view for that page. Only a old known URL to it would work. That
  # said, in Instiki things like the Home page itself is of course not a
  # *referenced* page but also by definition not an orphan, and author-based
  # pages are also not considered orphans since the "created" or "edited by"
  # parts of the UI will link to those. See PageSet#orphaned_pages for details.
  #
  def self.all_referenced_pages_in(web)

    # This is a list of referenced page *names* that are in use in the Wiki and
    # are accessible to users one way or another via normal navigation. The set
    # of names includes both current page names, and old names of pages that
    # were renamed - in which case, a redirection reference should exist. The
    # #referenced_name is the name of the page being linked *to* (and the
    # #page_id is the page which includes that link).
    #
    in_use_references = WikiReference.where(link_type: [LINKED_PAGE, WANTED_PAGE, INCLUDED_PAGE])

    # This is a set of redirection references. The #referenced_name is the old
    # name of the page, which has since changed and the #page_id is the target
    # page which now has a new name (and many such references can exist for any
    # given page, if it gets renamed more than once).
    #
    all_redirections = WikiReference.where(link_type: REDIRECTED_PAGE)

    # If a redirection reference is in the in-use-references set, then this is
    # one of interest; we care about the page ID.
    #
    in_use_redirections = all_redirections.where(referenced_name: in_use_references.select(:referenced_name))

    # Now look at things in terms of pages. These are page IDs where the page
    # *is currently named* per an active reference. No redirection is needed.
    #
    directly_referenced_pages = Page.where(web: web, name: in_use_references.select(:referenced_name))

    # Likewise, pages that are referenced through a redirection can be found.
    #
    redirected_pages = Page.where(web: web, id: in_use_redirections.select(:page_id))

    # So, the total collection of in-use pages is...
    #
    return directly_referenced_pages.or(redirected_pages)
  end

  # This is related to ::all_referenced_pages_in, but returns the *old* names
  # which are still referenced in the Wiki and make use of redirections, as an
  # Array of Strings.
  #
  def self.all_referenced_redirection_names_in(web)
    in_use_references   = WikiReference.where(link_type: [LINKED_PAGE, WANTED_PAGE, INCLUDED_PAGE])
    all_redirections    = WikiReference.where(link_type: REDIRECTED_PAGE)
    in_use_redirections = all_redirections.where(referenced_name: in_use_references.select(:referenced_name))

    return in_use_redirections.pluck(:referenced_name)
  end

  def self.pages_that_reference(web, page_name)
    query = 'SELECT name FROM pages JOIN wiki_references ' +
      'ON pages.id = wiki_references.page_id ' +
      'WHERE wiki_references.referenced_name = ? ' +
      "AND wiki_references.link_type in ('#{LINKED_PAGE}', '#{WANTED_PAGE}', '#{INCLUDED_PAGE}') " +
      "AND pages.web_id = '#{web.id}'"
    names = connection.select_all(sanitize_sql([query, page_name])).map { |row| row['name'] }
  end

  def self.pages_that_link_to(web, page_name)
    query = 'SELECT name FROM pages JOIN wiki_references ' +
      'ON pages.id = wiki_references.page_id ' +
      'WHERE wiki_references.referenced_name = ? ' +
      "AND wiki_references.link_type in ('#{LINKED_PAGE}','#{WANTED_PAGE}') " +
      "AND pages.web_id = '#{web.id}'"
    names = connection.select_all(sanitize_sql([query, page_name])).map { |row| row['name'] }
  end

  def self.pages_that_link_to_file(web, file_name)
    query = 'SELECT name FROM pages JOIN wiki_references ' +
      'ON pages.id = wiki_references.page_id ' +
      'WHERE wiki_references.referenced_name = ? ' +
      "AND wiki_references.link_type in ('#{FILE}') " +
      "AND pages.web_id = '#{web.id}'"
    names = connection.select_all(sanitize_sql([query, file_name])).map { |row| row['name'] }
  end

  def self.pages_that_include(web, page_name)
    query = 'SELECT name FROM pages JOIN wiki_references ' +
      'ON pages.id = wiki_references.page_id ' +
      'WHERE wiki_references.referenced_name = ? ' +
      "AND wiki_references.link_type = '#{INCLUDED_PAGE}' " +
      "AND pages.web_id = '#{web.id}'"
    names = connection.select_all(sanitize_sql([query, page_name])).map { |row| row['name'] }
  end

  # Returns an array of Strings of old page names that (A) redirect to the
  # given and assumed 'current' "page_name", and (B) are also referenced in
  # the Wiki somewhere - according to ::pages_that_reference - so the
  # redirection is not just present, but still in use.
  #
  def self.pages_redirected_to(web, page_name)
    names                     = []
    page                      = web.page(page_name)
    redirected_old_page_names = page.redirects # An Array of WikiReference#referenced_name values

    if Thread.current[:page_redirects] && Thread.current[:page_redirects][page]
      redirected_old_page_names.concat(Thread.current[:page_redirects][page])
    end

    # We know all the old page names for the page currently named "page_name"
    # now, but just because there's a redirection doesn't mean that the old
    # name is actually in use anywhere. A page which has a new name that is no
    # longer in e.g. any WikiWord uses, but also has old names which are also
    # no longer used anywhere, is not usefully referenced and is thus not
    # returned by this method.
    #
    redirected_old_page_names.uniq.each do |redirected_old_page_name|
      names.concat(self.pages_that_reference(web, redirected_old_page_name))
    end

    names.uniq
  end

  def self.page_that_redirects_for(web, page_name)
    query = 'SELECT name FROM pages JOIN wiki_references ' +
      'ON pages.id = wiki_references.page_id ' +
      'WHERE wiki_references.referenced_name = ? ' +
      "AND wiki_references.link_type = '#{REDIRECTED_PAGE}' " +
      "AND pages.web_id = '#{web.id}'"

    row = connection.select_one(sanitize_sql([query, page_name]))
    row&.dig('name')
  end

  def self.pages_in_category(web, category)
    return (
      Page
        .joins(:wiki_references)
        .where(wiki_references: { link_type: CATEGORY, referenced_name: category })
        .where(pages:           { web_id: web.id })
        .order(name: :asc)
    )
  end

  def self.list_categories(web)
    return (
      WikiReference
        .select(:referenced_name).distinct
        .left_outer_joins(:page)
        .where(wiki_references: { link_type: CATEGORY })
        .where(pages:           { web_id: web.id })
        .order(referenced_name: :asc)
        .pluck(:referenced_name)
    )
  end

  def wiki_word?
    linked_page? or wanted_page?
  end

  def wiki_link?
    linked_page? or wanted_page? or file? or wanted_file?
  end

  def linked_page?
    link_type == LINKED_PAGE
  end

  def redirected_page?
    link_type == REDIRECTED_PAGE
  end

  def wanted_page?
    link_type == WANTED_PAGE
  end

  def included_page?
    link_type == INCLUDED_PAGE
  end

  def file?
    link_type == FILE
  end

  def wanted_file?
    link_type == WANTED_FILE
  end

  def category?
    link_type == CATEGORY
  end

end
