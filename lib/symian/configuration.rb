require 'symian/support/dsl_helper'

module Symian

  module Configurable
    dsl_accessor :start_time,
                 :duration,
                 :warmup_duration,
                 :incident_generation,
                 :transition_matrix,
                 :cost_analysis,
                 :support_groups
  end

  class Configuration
    include Configurable

    attr_accessor :filename

    def initialize(filename)
      @filename = filename
    end

    def end_time
      @start_time + @duration
    end

    def validate
      # @start_time      = @start_time.to_i
      # @duration        = @duration.to_i
      # @warmup_duration = @warmup_duration.to_i

      if @incident_generation[:type] == :file
        @incident_generation[:source].gsub!('<pwd>', File.expand_path(File.dirname(@filename)))
      end
    end

    def self.load_from_file(filename)
      # allow filename, string, and IO objects as input
      raise ArgumentError, "File #{filename} does not exist!" unless File.exists?(filename)

      # create configuration object
      conf = Configuration.new(filename)

      # take the file content and pass it to instance_eval
      conf.instance_eval(File.new(filename, 'r').read)

      # validate and finalize configuration
      conf.validate

      # return new object
      conf
    end

  end
end
