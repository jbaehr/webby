# If RTeX is installed, then configure the rtex filter
if try_require('rtex')
  Webby::Filters.register :rtex, :need_layout => true do |input, cursor|
    b = cursor.renderer.get_binding
    RTeX::Document.new(input, cursor.current_options).to_pdf(b)
  end

# Otherwise raise an error if the user tries to use rtex
else
  Webby::Filters.register :rtex do |input|
    raise Webby::Error, "'RTeX' must be installed to use the rtex filter"
  end
end

# EOF
