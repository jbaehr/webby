class ERB
  module Util
    # generic escape helper. It deligates to "#{@page.format}_escape"
    # :html_escape is provided by ERB::Util per default, :latex_escape
    # comes with RTeX, custom code may provides more...
    def escape(s)
      self.__send__ "#{@page.format}_escape", s
    end
    alias :e :escape
  end
end
