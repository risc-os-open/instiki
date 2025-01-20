xml.instruct! :xml, version: '1.0', encoding: "UTF-8"

xml.exception do
  if Rails.env.production?
    xml.class('500')
    xml.message('Sorry, something went wrong. Please contact ROOL if this error persists via webmaster@riscosopen.org')
  else
    xml.class(exception.class.name)
    xml.message(exception.message)
    xml.backtrace do
      exception.backtrace.each { | line | xml.line(line) }
    end
  end
end
