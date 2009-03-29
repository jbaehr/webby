module Webby
module Filters
   
  class << self

    # This represents a filter handler.
    # +processor+ has to be a block performing the transformation.
    # +options+ are a set of options for this transformation
    Handler = Struct.new :processor, :options
    
    # Register a handler for a filter
    # +filter+ is the name of the filter
    # +options+ is an optional hash of options for the filter. The following keys are recognised:
    #   +need_layout+ says that the filter need the full page, layout already applied
    #   +defaults+ a hash of default options for the filter. These options can be overwritten by the page's meta data
    def register( filter, options = {}, &block )
      _handlers[filter.to_s] = Handler.new(block, options)
    end

    # Register a guard for a filter.
    # +filter+ is the name of the filter.
    # The block has to take one argument, the text to protect against the filter.
    def register_guard( filter, &block )
      _guards[filter.to_s] = block
    end

    # return the guard for a filter
    def guard_for( filter )
      _guards[filter.to_s]
    end
    
    # Process input through filters
    def process( renderer, page, input )
      # Start a new cursor for this page
      Cursor.new(renderer, page).start_for(input)
    end
    
    # Access a filter handler
    def []( name )
      _handlers[name]
    end
      
    # The registered filter handlers
    def _handlers
      @handlers ||= {}
    end

    # The registered filter guards
    def _guards
      @guards ||= {}
    end

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
    # This function transforms the value of a filter option into an option hash
    def parse_options(opt)
      case opt
      when Hash
        # already a hash, yeepee!
        opt.symbolize_keys.sanitize!
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
        h
      else
        Hash.new
      end
    end

    # Instances of this class handle processing a set of filters
    # for a given renderer and page.
    # Note: The instance is passed as the second argument to filters
    #       that require two parameters and can be used to access 
    #       information on the renderer, page, or filters being
    #       processed.
    class Cursor
      
      attr_reader :renderer, :page, :filters
      def initialize(renderer, page)
        @renderer, @page = renderer, page
        @filters = Array(page.filter)
        @log = Logging::Logger[Webby::Renderer]
        @processed = 0
        @prev_cursor = nil
      end
      
      def start_for(input)
        @prev_cursor = @renderer.instance_variable_get(:@_cursor)
        @renderer.instance_variable_set(:@_cursor, self)
        filters.inject(input) do |result, filter|
          handler = Filters[filter]
          raise ::Webby::Error, "unknown filter: #{filter.inspect}" if handler.nil?

          args = [result, self][0, handler.processor.arity]
          _handle(filter, handler, *args)
        end
      ensure
        @renderer.instance_variable_set(:@_cursor, @prev_cursor)
      end
      
      # The list of filters yet to be processed
      def remaining_filters
        filters[@processed..-1]
      end
      
      # The name of the current filter
      def current_filter
        filters[@processed]
      end

      # default options for the current handler merged with site options and options from the page meta data
      def current_options
        (Filters[current_filter].options[:defaults] or Hash.new).
          merge(Filters::parse_options(::Webby.site.filter_options[current_filter])).
          merge((@page.filter_options[current_filter] or Hash.new))
      end

      # Process arguments through a single filter
      def _handle(filter, handler, *args)
        if handler.options[:need_layout] and @page.layout
          # apply the layout already since the current filter need to operate on a complete page.
          @renderer.instance_variable_set(:@content, args[0])
          @renderer._render_layout_for(@page)
          args[0] = @renderer.instance_variable_get(:@content)
          @page.layout = nil # the layout is aleady applied, and we don't want it a second time
        end
        result = handler.processor.call(*args)
        @processed += 1
        result
      rescue StandardError => err
        raise ::Webby::Error, "#{filter} filter error: #{err.message.inspect}"
      end
      
    end  # class Cursor
  end  # class << self
    
end  # module Filters
end  # module Webby

Webby.require_all_libs_relative_to(__FILE__)

# EOF
