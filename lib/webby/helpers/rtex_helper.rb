if try_require 'rtex'


module Webby::Helpers

module RTeXHelper
  # escape latex special characters
  def latex_escape(s)
    RTeX::Document.escape(s)
  end
  alias :l :latex_escape
end  # module RTeXHelper

register(RTeXHelper)

end  # module Webby::Helpers
else
  Webby::Helpers.register_dummy(:l, :latex_escape, "You need to install the rtex gem to use the latex_escape helper")
end # try_require

# EOF
