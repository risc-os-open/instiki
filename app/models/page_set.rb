# Container for a set of pages with methods for manipulation.

class PageSet
  attr_reader :web, :pages

  # Initialise a page set using:
  #
  # * The Web of interest
  # * An optional Array of Pages within that web, using any selection metric;
  #   this is internally converted to IDs and transformed into a ".where" query
  #   so that, internally, ActiveRecord query chains can be applied.
  # * An optional Proc which is used to filter the *array* in the second
  #   parameter; i.e., filtering is done on the Ruby side. This narrows down
  #   the page collection that's then converted to IDs as described above.
  #
  # It's more efficient to use the database to produce a page subset for the
  # second parameter than it is to use the third parameter, since that means
  # processing is done in Ruby, using web server CPU and RAM.
  #
  def initialize(web, page_subset_array = nil, condition = nil)
    @web   = web
    @pages =  if page_subset_array.nil?
      # if pages is not specified, make a list of all pages in the web
      web.pages
    elsif condition.nil?
      page_ids = page_subset_array.map(&:id)
      web.pages.where(id: page_ids)
    else
      page_ids = page_subset_array.select { |page| condition[page] }.map(&:id)
      web.pages.where(id: page_ids)
    end
  end

  def each(&block)
    @pages.each(&block)
  end

  def most_recent_revision
    most_recent = Revision.where(page: @pages).order(id: :desc).first
    most_recent&.revised_at || Time.at(0)
    # self.map { |page| page.revised_at }.max || Time.at(0)
  end

  def by_name
    PageSet.new(
      @web,
      @pages.order(name: :asc)
    )

    # PageSet.new(@web, sort_by { |page| page.name })
  end

  alias :sort :by_name

  def by_revision
    ordered_pages = @pages
      .joins('INNER JOIN "revisions" ON "revisions"."page_id" = "pages"."id"')
      .select('"pages".*, MAX("revisions"."revised_at") AS max_revised_at')
      .group('"revisions"."page_id"')
      .order('"max_revised_at" DESC')

    PageSet.new(@web, ordered_pages)

    # PageSet.new(@web, sort_by { |page| page.revised_at }).reverse
  end

  def pages_that_reference(page_name)
    all_referring_pages = WikiReference.pages_that_reference(@web, page_name)
    @pages.where(id: all_referring_pages.map(&:id))
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
    never_orphans = (web.authors + ['HomePage']).uniq
    orphans       = []

    @pages.find_each do | page |
      next if never_orphans.include?(page.name) # NOTE EARLY LOOP RESTART

      references = (WikiReference.pages_that_reference(@web, page.name) +
                    WikiReference.pages_redirected_to(@web, page.name)).uniq

      orphans << page if references.empty? or references == [page.name]
    end

    return orphans

    # self.select { |page|
    #   if never_orphans.include? page.name
    #     false
    #   else
    #     references = (WikiReference.pages_that_reference(@web, page.name) +
    #                   WikiReference.pages_redirected_to(@web, page.name)).uniq
    #     references.empty? or references == [page.name]
    #   end
    # }
  end

  def pages_in_category(category)
    page_ids = WikiReference.pages_in_category(web, category)
    return @pages.where(id: page_ids)

    # self.select { |page|
    #   WikiReference.pages_in_category(web, category).map.include?(page.name)
    # }
  end

  # Returns all the wiki words in this page set for which
  # there are no pages in this page set's web
  def wanted_pages
    known_pages = (web.select.names + self.redirected_names).uniq
    self.wiki_words - known_pages
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
    # self.inject([]) { |wiki_words, page|
    #     wiki_words + page.wiki_words
    # }.flatten.uniq.sort
  end

end
