# Despite being at (at the time of writing) a very recent v5 release, the
# GitHub Markdown gem is not compatible with the CommonMarker v1 gem that
# has been around a while before it. This works around the problem.
#
class CommonMarker
  def self.render_html(content, commonmarker_opts, commonmarker_exts)
    commonmarker_exts += [
      :strikethrough,
      :table,
      :tasklist,
      :autolink,
      :footnotes,
      :description_lists,
      :math_code,
      :math_dollars,
    ]

    commonmarker_opts = commonmarker_opts.uniq.map { |opt| [opt, true] }.to_h
    commonmarker_exts = commonmarker_exts.uniq.map { |opt| [opt, true] }.to_h.with_indifferent_access

    commonmarker_exts[:header_ids] = 'wiki-content-'

    Commonmarker.to_html(
      content,
      options: {
        render:    commonmarker_opts,
        extension: commonmarker_exts
      }
    )
  end
end
