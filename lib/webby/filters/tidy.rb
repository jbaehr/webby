require 'fileutils'
require 'tempfile'

module Webby
module Filters

# The Tidy filter is used to process HTML (or XHTML) through the _tidy_
# program and outpu nicely formatted and correct HTML (or XHTML).
#
# Options can be passed to the _tidy_ program via the
# <code>Webby.site</code> struct. Setting the +filter_options['tidy]+ to a hash
# with desired options will do the trick.
#
# From a project's Rakefile, include the following line (or one that's more
# to your liking):
#
#    SITE.filter_options['tidy'] = {:indent => true, :wrap => 80, :utf8 => true}
#
# You can also give the options directly when setting the filter in the layout:
#  filter:
#    - tidy: no_wrap, utf8
class Tidy

  # call-seq:
  #    Tidy.new( html, options = {} )
  #
  # Create a new filter that will process the given _html_ through the tidy
  # program. execute 'tidy -?' for a list of options
  #
  def initialize( str, options = {} )
    @log = ::Logging::Logger[self]
    @str = str
    @parameter = stringify options

    # create a temporary file for holding any error messages
    # from the tidy program
    @err = Tempfile.new('tidy_err')
    @err.close
  end

  # transforms a hash of options to a string of tidy parameters
  def stringify(options)
    s = String.new
    options.each_pair do |key, value|
      next unless value
      s << " -#{key}"
      s << " #{value}" unless value == true
    end
    s
  end

  # call-seq:
  #    process    => formatted html
  #
  # Process the original HTML text string passed to the filter when it was
  # created and output Tidy formatted HTML or XHTML.
  #
  def process
    cmd = "tidy #{@parameter} -q -f #{@err.path}"
    out = IO.popen(cmd, 'r+') do |tidy|
      tidy.write @str
      tidy.close_write
      tidy.read
    end

    if File.size(@err.path) != 0
      @log.warn File.read(@err.path).strip
    end

    return out
  end

end  # class Tidy

# Render html into html/xhtml via the Tidy program
if cmd_available? %w[tidy -v]
  handel_options = {
      :need_layout => true,
      :defaults => {:indent => true, :wrap => 80}
      }
  register :tidy, handel_options do |input, cursor|
    if ::Webby.site.tidy_options
      Webby.deprecated "tidy_options", "please use filter_options['tidy']"
      opts = {::Webby.site.tidy_options => true}
    else
      opts = cursor.current_options
    end
    Filters::Tidy.new(input, opts).process
  end

# Otherwise raise an error if the user tries to use tidy
else
  register :tidy do |input|
    raise Webby::Error, "'tidy' must be installed to use the tidy filter"
  end
end

end  # module Filters
end  # module Webby

# EOF
