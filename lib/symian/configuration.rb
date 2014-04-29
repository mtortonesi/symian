require 'symian/support/dsl_helper'

module Symian

  module Configurable
    dsl_accessor :start_time,          # simulation start time
                 :duration,            # simulation duration (in seconds)
                 :warmup_duration,     # warmup phase duration (in seconds)
                 :incident_generation, # incident generation
                 :transition_matrix,   # transition matrix
               # :slos,                # service level objectives - not implemented yet
               # :allowed_strategies,  # allowed incident management strategies
               # :objectives,          # optimization objectives ??? - not implemented yet
                 :support_groups       # support group characterization
  end

  class Configuration
    include Configurable

    # attr_accessor :current_strategy    # incident management strategy currently in place
    # attr_accessor :changes

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