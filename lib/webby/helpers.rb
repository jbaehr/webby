require Webby.libpath(*%w[webby renderer])

module Webby

# The Helpers module is used to register helper modules that provide extra
# functionality to the Webby renderer. The most notable example is the
# UrlHelpers module that provides methods to link to another page in a
# Webby webiste.
#
# Helpers are registered with the Webby framework by calling:
#
#    Webby::Helpers.register( MyHelper )
#
module Helpers

  # call-seq:
  #    Helpers.register( module )
  #
  # Register the given _module_ as a helper module for the Webby framework.
  #
  def self.register( helper )
    ::Webby::Renderer.__send__( :include, helper )
  end

  # call-seq:
  #   Helpers.register_dummy( :helper_function1, :helper_function2, ..., "error message" )
  #   Helpers.register_dummy( HelperModule, "error message" )
  #
  # Register dummy helpers with a meaningful error message if the functions are not available
  #
  def self.register_dummy( *args )
    message = args.pop
    args = args.first.instance_methods if args.first.class == Module
    args.each do |helper_function|
      ::Webby::Renderer.class_eval <<-EVAL_END
        def #{helper_function}(*dummy_args)
          raise Webby::Error, "#{message}"
        end
      EVAL_END
    end
  end

end  # module Helper
end  # module Webby

Webby.require_all_libs_relative_to(__FILE__)

# EOF
