# If RTeX is installed, then configure the rtex filter
if try_require('rtex')

  Webby::Filters.register :rtex do |input, cursor|
    # TODO preprocess?
    if cursor.page.layout
      cursor.renderer.instance_variable_set(:@content, input)
      cursor.renderer._render_layout_for(cursor.page)
      input = cursor.renderer.instance_variable_get(:@content)
      cursor.page.layout = nil
    end
    RTeX::Document.new(input).to_pdf(cursor.renderer.get_binding)
  end

# Otherwise raise an error if the user tries to use rtex
else
  Webby::Filters.register :rtex do |input|
    raise Webby::Error, "'RTeX' must be installed to use the rtex filter"
  end
end

# EOF
