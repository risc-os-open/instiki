$: << File.dirname(__FILE__) + "../../lib"

require_dependency 'chunks/chunk'

require 'redcloth'
require 'commonmarker'
require 'github/markup'

# The markup engines are Chunks that call the one of text converters.
# This markup occurs when the chunk is required to mask itself.
#
module Engines
  class AbstractEngine < Chunk::Abstract

    # Create a new chunk for the whole content and replace it with its mask.
    def self.apply_to(content)
      new_chunk = self.new(content)
      content.replace(new_chunk.mask)
    end

    private

    # Never create engines by constructor - use apply_to instead
    def initialize(content)
      @content = content
    end

  end

  class Textile < AbstractEngine
    def mask
      redcloth = RedCloth.new(@content, [:hard_breaks] + @content.options[:engine_opts])
      redcloth.filter_html = false
      redcloth.no_span_caps = false
      html = redcloth.to_html(:textile)
    end
  end

  class Markdown < AbstractEngine
    def mask
      GitHub::Markup.render_s(
        GitHub::Markups::MARKUP_MARKDOWN,
        @content
      )
    end
  end

  class Mixed < AbstractEngine
    def mask
      redcloth = RedCloth.new(@content, @content.options[:engine_opts])
      redcloth.filter_html = false
      redcloth.no_span_caps = false
      html = redcloth.to_html
    end
  end

  MAP = { :textile => Textile, :markdown => Markdown, :mixed => Mixed }
  MAP.default = Markdown
end
