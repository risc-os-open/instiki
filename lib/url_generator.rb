class UrlGenerator < AbstractUrlGenerator

  private

    def file_link(mode, name, text, web_address, known_file, description)
      case mode
      when :export
        if known_file
          %{<a class="existingWikiWord" title="#{description}" href="files/#{CGI.escape(name)}">#{text}</a>}
        else
          %{<span class="newWikiWord">#{text}</span>}
        end
      when :publish
        if known_file
          href = @controller.url_for :controller => 'file', :web => web_address, :action => 'file',
              :id => name, :only_path => true
          %{<a class="existingWikiWord"  title="#{description}" href="#{href}">#{text}</a>}
        else
          %{<span class="newWikiWord">#{text}</span>}
        end
      else
        href = @controller.url_for :controller => 'file', :web => web_address, :action => 'file',
            :id => name, :only_path => true
        if known_file
          %{<a class="existingWikiWord"  title="#{description}" href="#{href}">#{text}</a>}
        else
          %{<span class="newWikiWord">#{text}<a href="#{href}">?</a></span>}
        end
      end
    end

    def page_link(mode, name, text, web_address, known_page)
      case mode
      when :export
        if known_page
          %{<a class="existingWikiWord" href="#{CGI.escape(name)}.html">#{text}</a>}
        else
          %{<span class="newWikiWord">#{text}</span>}
        end
      when :publish
        if known_page
          wikilink_for(mode, name, text, web_address)
        else
          %{<span class="newWikiWord">#{text}</span>}
        end
      else
        if known_page
          wikilink_for(mode, name, text, web_address)
        else
          href = @controller.url_for :controller => 'wiki', :web => web_address, :action => 'new',
              :id => name, :only_path => true
          %{<span class="newWikiWord">#{text}<a href="#{href}">?</a></span>}
        end
      end
    end

    def pic_link(mode, name, text, web_address, known_pic)
      href = @controller.url_for :controller => 'file', :web => web_address, :action => 'file',
        :id => name, :only_path => true
      case mode
      when :export
        if known_pic
          %{<img alt="#{text}" src="files/#{CGI.escape(name)}" />}
        else
          %{<img alt="#{text}" src="no image" />}
        end
      when :publish
        if known_pic
          %{<img alt="#{text}" src="#{href}" />}
        else
          %{<span class="newWikiWord">#{text}</span>}
        end
      else
        if known_pic
          %{<img alt="#{text}" src="#{href}" />}
        else
          %{<span class="newWikiWord">#{text}<a href="#{href}">?</a></span>}
        end
      end
    end

    def media_link(mode, name, text, web_address, known_media, media_type)
      href = @controller.url_for :controller => 'file', :web => web_address, :action => 'file',
        :id => name, :only_path => true
      case mode
      when :export
        if known_media
          %{<#{media_type} src="files/#{CGI.escape(name)}" controls="controls">#{text}</#{media_type}>}
        else
          text
        end
      when :publish
        if known_media
          %{<#{media_type} src="#{href}" controls="controls">#{text}</#{media_type}>}
        else
          %{<span class="newWikiWord">#{text}</span>}
        end
      else
        if known_media
          %{<#{media_type} src="#{href}" controls="controls">#{text}</#{media_type}>}
        else
          %{<span class="newWikiWord">#{text}<a href="#{href}">?</a></span>}
        end
      end
    end

    def delete_link(mode, name, web_address, known_file)
      href = @controller.url_for :controller => 'file', :web => web_address,
          :action => 'delete', :id => name, :only_oath => true
      if mode == :show and known_file
        %{<span class="deleteWikiWord"><a href="#{href}">Delete #{name}</a></span>}
      else
        %{<span class="deleteWikiWord">[[#{name}:delete]]</span>}
      end
    end

    def wikilink_for(mode, name, text, web_address)
      web = Web.find_by_address(web_address)
      action = web.published? && (web != @web || mode == :publish) ? 'published' : 'show'
      href = @controller.url_for :controller => 'wiki', :web => web_address, :action => action,
            :id => name, :only_path => true
      title = web == @web ? '' : %{ title="#{web_address}"}
      %{<a class="existingWikiWord" href="#{href}"#{title}>#{text}</a>}
    end

end
