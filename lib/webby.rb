# $Id$

module Webby

  VERSION = '0.4.0'   # :nodoc:

  # Path to the Webby package
  PATH = ::File.expand_path(::File.join(::File.dirname(__FILE__), '..'))

  class Error < StandardError; end  # :nodoc:

  # call-seq:
  #    Webby.require_all_libs_relative_to( filename, directory = nil )
  #
  # Utility method used to rquire all files ending in .rb that lie in the
  # directory below this file that has the same name as the filename passed
  # in. Optionally, a specific _directory_ name can be passed in such that
  # the _filename_ does not have to be equivalent to the directory.
  #
  def self.require_all_libs_relative_to( fname, dir = nil )
    dir ||= File.basename(fname, '.*')
    search_me = File.expand_path(
        File.join(File.dirname(fname), dir, '**', '*.rb'))

    Dir.glob(search_me).sort.each {|rb| require rb}
  end

  # call-seq:
  #    Webby.config    => hash
  #
  # Returns the configuration hash for the Webby application.
  #
  def self.config
    @config ||= {
      'output_dir'    => 'output',
      'content_dir'   => 'content',
      'layout_dir'    => 'layouts',
      'template_dir'  => 'templates',
      'exclude'       => %w(tmp$ bak$ ~$ CVS \.svn)
    }
  end

  # call-seq:
  #    Webby.page_defaults    => hash
  #
  # Returns the page defaults hash used for page resource objects.
  #
  def self.page_defaults
    @page_defaults ||= {
      'extension' => 'html',
      'layout'    => 'default'
    }
  end

end  # module Webby


# call-seq:
#    try_require( library )    => true or false
#
# Try to laod the given _library_ using the built-in require, but do not
# raise a LoadError if unsuccessful. Returns +true+ if the _library_ was
# successfully loaded; returns +false+ otherwise.
#
def try_require( lib )
  require lib
  true
rescue LoadError
  false
end


Webby.require_all_libs_relative_to __FILE__

# EOF
