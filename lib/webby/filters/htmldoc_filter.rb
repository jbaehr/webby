# If htmldoc is installed, then configure the htmldoc filter
if try_require('htmldoc')
  handel_options = {
      # this forces the renderer to apply the layout *before* the input is passed to the filter
      :need_layout => true,
      # these are the default options for the filter. they can be overridden by the Sitefile
      # and the individual filter options.
      :defaults => {:bodycolor => :white, :links => true}
      }
  Webby::Filters.register :htmldoc, handel_options do |input, cursor|
    # cursor.current_options method takes the filter's default options, merges
    # the site options, and merges the current page's filter options.
    opts = cursor.current_options
    PDF::HTMLDoc.create do |p|
      opts.each_pair do |key, value|
        p.set_option key, value
      end
      p << input
    end
  end

# Otherwise raise an error if the user tries to use htmldoc
else
  Webby::Filters.register :htmldoc do |input|
    raise Webby::Error, "htmldoc and its ruby wrapper have to be installed in order to use the htmldoc filer"
  end
end

# EOF
