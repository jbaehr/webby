
# If RedCloth is installed, then configure the textile filter
if try_require('redcloth', 'RedCloth')

  Webby::Filters.register :textile do |input, cursor|
    options = Array.new
    # no_span_caps is the default, to stay backward compatible
    options << :no_span_caps unless cursor.current_options[:span_caps]
    options << :lite_mode if cursor.current_options[:lite_mode]
    # if the page has "format: latex" in it's meta data, we render to latex
    target = :latex if cursor.page.format == :latex
    # if we will filter through rtex, use latex as default target
    target = :latex if cursor.remaining_filters.include? "rtex"
    # it's still possible to overwrite this setting by giving an explicit target
    target = :latex if cursor.current_options[:latex]
    target = :html if cursor.current_options[:html]
    if target == :latex
      RedCloth.new(input, options).to_latex
    else
      RedCloth.new(input, options).to_html
    end
  end

# Otherwise raise an error if the user tries to use textile
else
  Webby::Filters.register :textile do |input|
    raise Webby::Error, "'RedCloth' must be installed to use the textile filter"
  end
end

# EOF
