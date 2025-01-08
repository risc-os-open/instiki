require 'html_pipeline'
require 'selma'

module WhiteListFormattedContentConcern
  extend ActiveSupport::Concern

  # Just a namespace for a modification of HTML Pipeline's defaults.
  #
  class CustomHtmlSanitizationOptions
    CONFIG = Selma::Sanitizer::Config.freeze_config({
      elements: [
        "a",
        "abbr",
        "b",
        "blockquote",
        "br",
        "caption",
        "cite",
        "code",
        "dd",
        "del",
        "dfn",
        "div",
        "dl",
        "dt",
        "em",
        "figcaption",
        "figure",
        "font",
        "h1",
        "h2",
        "h3",
        "h4",
        "h5",
        "h6",
        "hr",
        "i",
        "img",
        "ins",
        "kbd",
        "li",
        "ol",
        "p",
        "pre",
        "q",
        "s",
        "small",
        "span",
        "strike",
        "strong",
        "sub",
        "summary",
        "sup",
        "table",
        "tbody",
        "td",
        "tfoot",
        "th",
        "thead",
        "tr",
        "tt",
        "ul",
      ],
      attributes: {
        "a"          => ["href"],
        "blockquote" => ["cite"],
        "del"        => ["cite"],
        "div"        => ["id", "name", "class", "itemscope", "itemtype"],
        "img"        => ["src", "longdesc", "loading", "alt"],
        "ins"        => ["cite"],
        "q"          => ["cite"],
        "source"     => ["srcset"],
        "span"       => ["class"],
        "table"      => ["class"],
        all: [
          "abbr",
          "accept-charset",
          "align",
          "alt",
          "aria-describedby",
          "aria-hidden",
          "aria-label",
          "aria-labelledby",
          "background-color",
          "border",
          "charset",
          "clear",
          "color",
          "cols",
          "colspan",
          "compact",
          "dir",
          "disabled",
          "enctype",
          "hspace",
          "id",
          "ismap",
          "itemprop",
          "label",
          "lang",
          "maxlength",
          "media",
          "method",
          "multiple",
          "name",
          "nowrap",
          "open",
          "readonly",
          "rel",
          "rev",
          "role",
          "rows",
          "rowspan",
          "rules",
          "scope",
          "selected",
          "shape",
          "size",
          "span",
          "start",
          "style",
          "summary",
          "tabindex",
          "title",
          "type",
          "usemap",
          "valign",
          "value",
          "width",
        ],
      },
      protocols: {
        "a"          => { "href" => Selma::Sanitizer::Config::VALID_PROTOCOLS }.freeze,
        "blockquote" => { "cite" => ["http", "https", :relative].freeze },
        "del"        => { "cite" => ["http", "https", :relative].freeze },
        "ins"        => { "cite" => ["http", "https", :relative].freeze },
        "q"          => { "cite" => ["http", "https", :relative].freeze },
        "img"        => {
          "src"      => ["http", "https", :relative].freeze,
          "longdesc" => ["http", "https", :relative].freeze,
        },
      },
    })
  end

  # https://github.com/gjtorikian/html-pipeline#convertfilter
  #
  # Runs through RedCloth, then adds a second pass which auto-links anything
  # not already converted to a link through Textile '"foo":link' markup.
  #
  class RedClothAndAutoLinkConvertFilter < HTMLPipeline::ConvertFilter
    include ActionView::Helpers::TextHelper

    def call(text, context: @context)
      html = RedCloth.new(text).to_html()

      # Sanitization is disabled as we use CustomHtmlSanitizationOptions for
      # that via the HTML pipeline; Auto Link's variant is very aggressive..
      #
      html = auto_link(html, sanitize: false) do | link_text |
        truncate(link_text, length: 55, omission: '&hellip;')
      end

      return html
    end
  end

  included do
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::TextHelper

    protected

      def xhtml_sanitize(content)
        content.strip! if content.respond_to?(:strip!)

        if content.blank?
          ''
        else
          pipeline = HTMLPipeline.new(
            # convert_filter:      RedClothAndAutoLinkConvertFilter.new,
            sanitization_config: CustomHtmlSanitizationOptions::CONFIG,
          )

          result = pipeline.call(content)
          (result[:output] || '').html_safe()
        end
      end

  end
end
