require 'yaml'

module Symian
  class TraceCollector
    extend Forwardable

    # attributes to store
    ATTRIBUTES = [ :incidents, :events, :support_groups ]

    def initialize(backend, opts={})
      @backend = case backend
      when :memory
        MemoryBackend.new
      when :yaml
        raise ArgumentError, 'File not specified' unless opts[:file]
        YAMLBackend.new(opts[:file])
      # when :marshal
      #   MarshalBackend.new
      # when :json
      #   JsonBackend.new
      else
        raise ArgumentError, 'Unsupported backend!'
      end
    end

    # methods to dynamically generate
    METHODS = [ :save_and_close, ATTRIBUTES.collect{ |attr| [ "#{attr}", "record_#{attr}", "with_#{attr}" ] } ].flatten!

    # delegate methods to @backend
    def_delegators :@backend, *METHODS

  end


  class MemoryBackend

    def initialize
      TraceCollector::ATTRIBUTES.each do |attr|
        instance_variable_set("@#{attr}_storage", [])
      end
    end

    TraceCollector::ATTRIBUTES.each do |attr|
      class_eval <<-EOS
        def record_#{attr}(elem)
          if Array === elem
            @#{attr}_storage += elem
          else
            @#{attr}_storage << elem
          end
          self
        end

        def #{attr}
          @#{attr}_storage.size
        end

        def with_#{attr}
          if block_given?
            @#{attr}_storage.each do |el|
              yield el
            end
          else
            Enumerator.new(@#{attr}_storage)
          end
        end
      EOS
    end

    def save_and_close
      # raise NotImplementedError, 'A trace with memory backend cannot be saved!'
    end

  end


  class YAMLBackend < MemoryBackend

    def initialize(filename)
      @filename = filename
      # if file exists and is non-empty, try to read its contents
      size = File.size?(@filename)
      if !size.nil? and size > 0
        hash = File.open(@filename) do |file|
          YAML.load(file)
        end
        TraceCollector::ATTRIBUTES.map(&:to_s).each do |attr|
          instance_variable_set("@#{attr}_storage", hash[attr])
        end
      else
        super()
      end
    end

    def save_and_close
      hash = {}
      TraceCollector::ATTRIBUTES.map(&:to_s).each do |attr|
        hash[attr] = instance_variable_get("@#{attr}_storage")
      end
      File.open(@filename, 'w') do |file|
        YAML.dump(hash, file)
      end
    end

  end

end
