unless defined? Webby::Resources::Resource

module Webby::Resources

# A Webby::Resource is any file that can be found in the content directory
# or in the layout directory. This class contains information about the
# resources available to Webby.
#
class Resource

  instance_methods.each do |m|
      undef_method(m) unless m =~ %r/\A__|\?$/ ||
                             m == 'class'
  end

  # The full path to the resource file
  attr_reader :path

  # The name of the file excluding the directory and extension
  attr_reader :name

  # The directory of the resource excluding the content directory
  attr_reader :dir

  # Extesion of the resource file
  attr_reader :ext

  # Resource file modification time
  attr_reader :mtime

  attr_reader :_meta_data  #:nodoc:

  # call-seq:
  #    Resource.new( filename )    => resource
  #
  # Creates a new resource object given the _filename_.
  #
  def initialize( fn )
    @path  = fn
    @dir   = ::Webby::Resources.dirname(@path)
    @name  = ::Webby::Resources.basename(@path)
    @ext   = ::Webby::Resources.extname(@path)
    @mtime = ::File.mtime @path

    @_meta_data =  {}
    self._reset
  end

  # call-seq:
  #    equal?( other )    => true or false
  #
  # Returns +true+ if the path of this resource is equivalent to the path of
  # the _other_ resource. Returns +false+ if this is not the case.
  #
  def equal?( other )
    return false unless other.kind_of? ::Webby::Resources::Resource
    (self.destination == other.destination) && (self.path == other.path)
  end
  alias :== :equal?
  alias :eql? :equal?

  # call-seq:
  #    resource <=> other    => -1, 0, +1, or nil
  #
  # Resource comparison operates on the full path of the resource objects
  # and uses the standard String comparison operator. Returns +nil+ if
  # _other_ is not a Resource instance.
  #
  def <=>( other )
    return unless other.kind_of? ::Webby::Resources::Resource
    self.destination <=> other.destination
  end

  # call-seq:
  #    resource[key]    => value or nil
  #
  # Returns the value associated with the given meta-data key. Key is
  # converted into a string.
  #
  def []( key )
    _meta_data[key.to_s]
  end

  # call-seq:
  #    resource[key] = value
  #
  # Sets the given meta-data key to the value. Key is converted into a
  # string.
  #
  def []=( key, value )
    _meta_data[key.to_s] = value
  end

  # call-seq:
  #    method_missing( symbol [, *args, &block] )    => result
  #
  # Invoked by Ruby when a message is sent to the resource that it cannot
  # handle. The default behavior is to convert _symbol_ to a string and
  # search for that string in the resource's meta-data. If found, the
  # meta-data item is returned; otherwise, +nil+ is returned.
  #
  def method_missing( name, *a, &b )
    _meta_data[name.to_s]
  end

  # call-seq:
  #    dirty?    => true or false
  #
  # Returns +true+ if this resource is newer than its corresponding output
  # product. The resource needs to be rendered (if a page or layout) or
  # copied (if a static file) to the output directory.
  #
  def dirty?
    return _meta_data['dirty'] if _meta_data.has_key? 'dirty'

    # if the destination file does not exist, then we are dirty
    return true unless test(?e, destination)

    # if this file's mtime is larger than the destination file's
    # mtime, then we are dirty
    dirty = @mtime > ::File.mtime(destination)
    return dirty if dirty

    # check to see if the layout is dirty, and if it is then we
    # are dirty, too
    if _meta_data.has_key? 'layout'
      lyt = ::Webby::Resources.find_layout(_meta_data['layout'])
      unless lyt.nil?
        return true if lyt.dirty?
      end
    end

    # if we got here, then we are not dirty
    false
  end

  # An array of filters by which this resource is transformed
  # This method strips of the options which may be presend and returns a simple array of strings
  def filter
    Array(_meta_data['filter']).collect do |item|
      case item
      when String
        item
      when Hash
        raise Webby::Error, "invalid filter options for #{item.inspect}" if item.length > 1
        item.keys.first
      else
        raise Webby::Error, "invalid filter options for #{item.inspect}"
      end
    end
  end

  # Returns a hash with an option-hash for each filter.
  # Options for filters may be given in the following forms
  # filter:
  #   - erb
  #   - textile: no_span_caps
  #   - foo: span_caps, no_bar
  #   - rtex:
  #       preprocess: true
  #       preprocessor: latex
  # The resulting filter options will look like this:
  # {
  #   "erb" => {},
  #   "textile" => {:span_caps => false},
  #   "foo" => {:span_caps => true, :bar => false},
  #   "rtex" => {:preprocess => true, :preprocessor => "latex"}
  # }
  def filter_options
    options = Hash.new
    Array(_meta_data['filter']).each do |item|
      case item
      when String
        options[item] = Hash.new
      when Hash
        raise Webby::Error, "invalid filter options for #{item.inspect}" if item.length > 1
        opt = item.values.first
        case opt
        when Hash
          options[item.keys.first] = opt.symbolize_keys.sanitize!
        when String
          h = Hash.new
          opt.split(",").each do |s|
            s.strip!
            if s =~ /^no_(.*)/
              h[$1.to_sym] = false
            else
              h[s.to_sym] = true
            end
          end
          options[item.keys.first] = h
        end
      else
        raise Webby::Error, "invalid filter options for #{item.inspect}"
      end
    end
    options
  end

  # The resource filename excluding path and extension. This will either be
  # the name of the file or the 'filename' attribute from the meta-data if
  # present.
  #
  def filename
    return _meta_data['filename'] if _meta_data.has_key? 'filename'
    name
  end

  # The resource file extension. This will either be the extension of the
  # file or the 'extension' attribute from the meta-data if present.
  #
  def extension
    return _meta_data['extension'] if _meta_data.has_key? 'extension'
    ext
  end

  # The location of this resource in the directory structure. This directory
  # does not include the content folder or the output folder.
  #
  def directory
    return _meta_data['directory'] if _meta_data.has_key? 'directory'
    dir
  end

  # Returns the path in the output directory where the resource will be
  # generated. This path is used to determine if the resource is dirty
  # and in need of generating.
  #
  def destination
    return @destination unless @destination.nil?

    @destination = ::File.join(::Webby.site.output_dir, directory, filename)
    ext = extension
    unless ext.nil? or ext.empty?
      @destination << '.' << ext
    end
    @destination
  end

  # Returns a string suitable for use as a URL linking to this resource.
  #
  def url
    return @url unless @url.nil?
    @url = destination.sub(::Webby.site.output_dir, '')
  end

  # :stopdoc:
  def _read
    MetaFile.read(@path)
  end

  def _reset( meta_data = nil )
    _meta_data.replace(meta_data) if meta_data.instance_of?(Hash)
    @url = nil
    @destination = nil
  end
  # :startdoc:

end  # class Resource
end  # module Webby::Resources

end  # unless defined?

# EOF
