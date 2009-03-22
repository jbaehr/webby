if try_require 'coderay'
require 'enumerator'

module Webby::Helpers
module CodeRayHelper

  # The +coderay+ method applies syntax highlighting to source code embedded
  # in a webpage. The CodeRay highlighting engine is used for the HTML
  # markup of the source code. The page sections to be highlighted are given
  # as blocks of text to the +coderay+ method.
  #
  # Options can be passed to the CodeRay engine via attributes in the
  # +coderay+ method.
  #
  #    <% coderay( :lang => :ruby, :line_numbers => :inline ) do -%>
  #    # Initializer for the class.
  #    def initialize( string )
  #      @str = stirng
  #    end
  #    <% end -%>
  #    
  # The supported CodeRay options are the following:
  #
  #    :lang               : the language to highlight (ruby, c, html, ...)
  #    :line_numbers       : include line numbers in :table, :inline,
  #                          or :list
  #    :line_number_start  : where to start with line number counting
  #    :bold_every         : make every n-th number appear bold
  #    :tab_width          : convert tab characters to n spaces
  #
  # Site wide options can be given in the Sitefile. They will override the
  # helper's defaults and can be overridden by the actual helper parameters.
  #
  #    SITE.helper_options[:coderay] = {
  #      :lang => :ruby,
  #      :line_numbers => :inline
  #    }
  #
  def coderay( *args, &block )
    opts = args.last.instance_of?(Hash) ? args.pop : {}

    text = capture_erb(&block)
    return if text.empty?

    unless ::Webby.site.coderay.empty?
      Webby.deprecated "site.coderay", "please use site.helper_options[:coderay]"
      defaults = ::Webby.site.coderay
      lang = opts.getopt(:lang, defaults[:lang]).to_sym

      cr_opts = {}
      %w(line_numbers       to_sym
         line_number_start  to_i
         bold_every         to_i
         tab_width          to_i).each_slice(2) do |key,convert|
        key = key.to_sym
        val = opts.getopt(key, defaults[key])
        next if val.nil?
        cr_opts[key] = val.send(convert)
      end
    else
      cr_opts = ::Webby::Helpers.options_for :coderay, opts
      lang = cr_opts[:lang].to_sym
      cr_opts[:line_numbers] = cr_opts[:line_numbers].to_sym if cr_opts[:line_numbers]
      [:line_number_start, :bold_every, :tab_width].each do |key|
        cr_opts[key] = cr_opts[key].to_i if cr_opts[key]
      end
    end

    #cr.swap(CodeRay.scan(text, lang).html(opts).div)
    out = %Q{<div class="CodeRay">\n<pre>}
    out << ::CodeRay.scan(text, lang).html(cr_opts)
    out << %Q{</pre>\n</div>}

    # put some guards around the output (specifically for textile)
    out = _guard(out)

    concat_erb(out, block.binding)
    return
  end
end  # module CodeRayHelper

default_options = {
  :lang => :ruby,
  :line_numbers => nil,
  :line_number_start => 1,
  :bold_every => 10,
  :tab_width => 8
}
register(CodeRayHelper, :coderay => default_options)

end  # module Webby::Helpers
else
  Webby::Helpers.register_dummy(:coderay, "You need to install the coderay gem to use the coderay helper")
end  # try_require

# EOF
