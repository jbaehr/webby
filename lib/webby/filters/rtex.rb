# If RTeX is installed, then configure the rtex filter
if try_require('rtex')

  Webby::Filters.register :rtex do |input, cursor|
    # TODO preprocess? set extension to pdf? layout expansion if layout?
    RTeX::Document.new(input).to_pdf(cursor.renderer.get_binding)
  end

# Otherwise raise an error if the user tries to use rtex
else
  Webby::Filters.register :rtex do |input|
    raise Webby::Error, "'RTeX' must be installed to use the rtex filter"
  end
end

# EOF
