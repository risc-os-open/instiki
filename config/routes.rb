Rails.application.routes.draw do
  ID_REGEXP  = /.+/
  REV_REGEXP = /\d+/
  WEB_REGEXP = /(?!images)(?!css)(?!assets)[^\/]+/

  def get_or_post(generic_path, generic_routing_options)
    generic_routing_options[:constraints] ||= {}
    generic_routing_options[:constraints][:web] = WEB_REGEXP

     get(generic_path, **generic_routing_options)
    post(generic_path, **generic_routing_options)
  end

  get  'create_system', to: 'admin#create_system'
  post 'create_system', to: 'admin#create_system'
  get  'create_web',    to: 'admin#create_web'
  post 'create_web',    to: 'admin#create_web'
  post 'delete_web',    to: 'admin#delete_web'
  post 'delete_files',  to: 'admin#delete_files'
  get  'web_list',      to: 'wiki#web_list'

  scope '/:web', constraints: { web: WEB_REGEXP } do
    get '', controller: 'wiki', action: 'index'

    get_or_post 'edit_web',                          controller: 'admin'
    post        'remove_orphaned_pages',             controller: 'admin'
    post        'remove_orphaned_pages_in_category', controller: 'admin'

    get_or_post 'file/delete/:id', to: 'file#delete', constraints: { id: /[-._\w]+/ }
    get_or_post 'files/:id',       to: 'file#file',   constraints: { id: /[-._\w]+/ }
    get_or_post 'import/:id',      to: 'file#import'

    post 'authenticate', controller: 'wiki'
    post 'save',         controller: 'wiki'

    # The "defaults" options below are to avoid page names with a "." in them
    # leading to format errors - e.g. "foo.png" shouldn't cause detection of a
    # PNG format and an arising low-down exception due to the lack of matching
    # template for the request.

    get_or_post 'edit/:id', to: 'wiki#edit', constraints: { id: ID_REGEXP }, defaults: {format: 'html'}

    get 'show/diff/:id',          to: 'wiki#show',     constraints: { id: ID_REGEXP                  }, mode: 'diff', defaults: {format: 'html'}
    get 'revision/diff/:id/:rev', to: 'wiki#revision', constraints: { id: ID_REGEXP, rev: REV_REGEXP }, mode: 'diff', defaults: {format: 'html'}
    get 'revision/:id/:rev',      to: 'wiki#revision', constraints: { id: ID_REGEXP, rev: REV_REGEXP },               defaults: {format: 'html'}
    get 'rollback/:id/:rev',      to: 'wiki#rollback', constraints: { id: ID_REGEXP, rev: REV_REGEXP },               defaults: {format: 'html'}
    get 'rollback/:id',           to: 'wiki#rollback', constraints: { id: ID_REGEXP                  },               defaults: {format: 'html'}

    get 'atom_with_content',   controller: 'wiki'
    get 'atom_with_headlines', controller: 'wiki'
    get 'authors',             controller: 'wiki'
    get 'export',              controller: 'wiki'
    get 'export_html',         controller: 'wiki'
    get 'export_markup',       controller: 'wiki'
    get 'feeds',               controller: 'wiki'
    get 'login',               controller: 'wiki'
    get 'published',           controller: 'wiki'
    get 'search',              controller: 'wiki'
    get 'web_list',            controller: 'wiki'

    # Same reason for the "defaults" options as described above.
    #
    get 'cancel_edit/:id',     controller: 'wiki', action: 'cancel_edit', constraints: { id: ID_REGEXP }, defaults: {format: 'html'}
    get 'history/:id',         controller: 'wiki', action: 'history',     constraints: { id: ID_REGEXP }, defaults: {format: 'html'}
    get 'locked/:id',          controller: 'wiki', action: 'locked',      constraints: { id: ID_REGEXP }, defaults: {format: 'html'}
    get 'new/:id',             controller: 'wiki', action: 'new',         constraints: { id: ID_REGEXP }, defaults: {format: 'html'}
    get 'print/:id',           controller: 'wiki', action: 'print',       constraints: { id: ID_REGEXP }, defaults: {format: 'html'}
    get 'show/:id',            controller: 'wiki', action: 'show',        constraints: { id: ID_REGEXP }, defaults: {format: 'html'}
    get 'source/:id',          controller: 'wiki', action: 'source',      constraints: { id: ID_REGEXP }, defaults: {format: 'html'}

    get 'file_list(/:sort_order)',      controller: 'wiki', action: 'file_list'
    get 'list(/:category)',             controller: 'wiki', action: 'list',             constraints: { category: /.*/ }
    get 'recently_revised(/:category)', controller: 'wiki', action: 'recently_revised', constraints: { category: /.*/ }

    # Legacy I2 route
    #
    get 'pages/:id', controller: 'i2', action: 'pages', constraints: { id: ID_REGEXP }, defaults: {format: 'html'}

  end

  # get_or_post ':web/:action/:id', controller: 'wiki', constraints: { id: ID_REGEXP }
  # get_or_post ':web/:action',     controller: 'wiki'
  # get_or_post ':web',             controller: 'wiki', action: 'index'

  root controller: 'wiki', action: 'index'
end
