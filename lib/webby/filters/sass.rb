
# Render text via the Sass library (part of Haml)
if try_require('sass', 'haml')

  Webby::Filters.register :sass do |input, cursor|
    opts = ::Webby.site.sass_options.merge(cursor.page.sass_options || {})
    opts = opts.symbolize_keys
    if opts.empty?
      opts = cursor.current_options
    else
      Webby.deprecated "sass_options", "please use filter_options['sass']"
    end
    opts[:style] = opts[:style].to_sym if opts.include? :style
    Sass::Engine.new(input, opts).render
  end

# Otherwise raise an error if the user tries to use sass
else
  Webby::Filters.register :sass do |input, cursor|
    raise Webby::Error, "'haml' must be installed to use the sass filter"
  end
end

# EOF
