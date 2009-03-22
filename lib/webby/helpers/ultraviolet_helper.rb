# This code was provided by Guillaume Carbonneau -- http://radr.ca/
# Many thanks for his support of Webby!

if try_require 'uv'

module Webby::Helpers
module UltraVioletHelper

  # The +uv+ method applies syntax highlighting to source code embedded
  # in a webpage. The UltraViolet highlighting engine is used for the HTML
  # markup of the source code. The page sections to be highlighted are given
  # as blocks of text to the +uv+ method.
  #
  # Options can be passed to the UltraViolet engine via attributes in the
  # +uv+ method.
  #
  #    <% uv( :lang => "ruby", :line_numbers => true ) do -%>
  #    # Initializer for the class.
  #    def initialize( string )
  #      @str = string
  #    end
  #    <% end -%>
  #    
  # The supported UltraViolet options are the following:
  #
  #    :lang           : the language to highlight (ruby, c, html, ...)
  #                      [defaults to 'ruby']
  #    :line_numbers   : true or false [defaults to false]
  #    :theme          : see list of available themes in ultraviolet
  #                      [defaults to 'mac_classic']
  #
  # Site wide options can be given in the Sitefile. They will override the
  # helper's defaults and can be overridden by the actual helper parameters.
  #
  #    SITE.helper_options[:uv] = {
  #      :line_numbers => true
  #    } 
  #
  def uv( *args, &block )
    opts = args.last.instance_of?(Hash) ? args.pop : {}

    text = capture_erb(&block)
    return if text.empty?
    
    unless ::Webby.site.uv.empty?
      Webby.deprecated "site.uv", "please use site.helper_options[:uv]"
      defaults = ::Webby.site.uv
      lang = opts.getopt(:lang, defaults[:lang])
      line_numbers = opts.getopt(:line_numbers, defaults[:line_numbers])
      theme = opts.getopt(:theme, defaults[:theme])
    else
      opts = ::Webby::Helpers.options_for :uv, opts
      lang = opts[:lang]
      line_numbers = opts[:line_numbers]
      theme = opts[:theme]
    end
    
    out = %Q{<div class="UltraViolet">\n}
    out << Uv.parse(text, "xhtml", lang, line_numbers, theme)
    out << %Q{\n</div>}

    # put some guards around the output (specifically for textile)
    out = _guard(out)

    concat_erb(out, block.binding)
    return
  end
end  # module UltraVioletHelper

default_options = {
  :lang => 'ruby',
  :line_numbers => false,
  :theme => 'mac_classic'
  }
register(UltraVioletHelper, :uv => default_options)

end  # module Webby::Helpers
else
  Webby::Helpers.register_dummy(:uv, "You need to install the ultraviolet gem to use the uv helper")
end  # try_require

# EOF
