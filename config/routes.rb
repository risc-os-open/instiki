Rails.application.routes.draw do
  ID_REGEXP = /.+/

  def connect_to_web(generic_path, generic_routing_options)
    if defined? DEFAULT_WEB
      explicit_path = generic_path.gsub(/:web\/?/, '')
      explicit_routing_options = generic_routing_options.merge(web: DEFAULT_WEB)

      get(explicit_path, explicit_routing_options)
    end

    generic_routing_options[:constraints] ||= {}
    generic_routing_options[:constraints][:web] = /(?!images).+/

    get(generic_path, **generic_routing_options)
    post(generic_path, **generic_routing_options)
  end

  get  'create_system', controller: 'admin', action: 'create_system'
  post 'create_system', controller: 'admin', action: 'create_system'
  post 'create_web',    controller: 'admin', action: 'create_web'
  post 'delete_web',    controller: 'admin', action: 'delete_web'
  post 'delete_files',  controller: 'admin', action: 'delete_files'
  get  'web_list',      controller: 'wiki',  action: 'web_list'

  connect_to_web ':web/edit_web',                          controller: 'admin', action: 'edit_web'
  connect_to_web ':web/remove_orphaned_pages',             controller: 'admin', action: 'remove_orphaned_pages'
  connect_to_web ':web/remove_orphaned_pages_in_category', controller: 'admin', action: 'remove_orphaned_pages_in_category'
  connect_to_web ':web/file/delete/:id',                   controller: 'file',  action: 'delete',           requirements: { id: /[-._\w]+/}, id:         nil
  connect_to_web ':web/files/:id',                         controller: 'file',  action: 'file',             requirements: { id: /[-._\w]+/}, id:         nil
  connect_to_web ':web/file_list/:sort_order',             controller: 'wiki',  action: 'file_list',                                         sort_order: nil
  connect_to_web ':web/import/:id',                        controller: 'file',  action: 'import'
  connect_to_web ':web/login',                             controller: 'wiki',  action: 'login'
  connect_to_web ':web/web_list',                          controller: 'wiki',  action: 'web_list'
  connect_to_web ':web/show/diff/:id',                     controller: 'wiki',  action: 'show',             requirements: { id: ID_REGEXP             }, mode: 'diff'
  connect_to_web ':web/revision/diff/:id/:rev',            controller: 'wiki',  action: 'revision',         requirements: { id: ID_REGEXP, rev: /\d+/ }, mode: 'diff'
  connect_to_web ':web/revision/:id/:rev',                 controller: 'wiki',  action: 'revision',         requirements: { id: ID_REGEXP, rev: /\d+/ }
  connect_to_web ':web/list/:category',                    controller: 'wiki',  action: 'list',             requirements: { category: /.*/            }, category: nil
  connect_to_web ':web/recently_revised/:category',        controller: 'wiki',  action: 'recently_revised', requirements: { category: /.*/            }, category: nil
  connect_to_web ':web/pages/:id',                         controller: 'i2',    action: 'pages',            requirements: { id: ID_REGEXP             }
  connect_to_web ':web/:action/:id',                       controller: 'wiki',                              requirements: { id: ID_REGEXP             }
  connect_to_web ':web/:action',                           controller: 'wiki'
  connect_to_web ':web',                                   controller: 'wiki',  action: 'index'

  if defined? DEFAULT_WEB
    root controller: 'wiki', action: 'index', web: DEFAULT_WEB
  else
    root controller: 'wiki', action: 'index'
  end
end
