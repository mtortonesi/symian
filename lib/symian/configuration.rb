require 'symian/support/dsl_helper'

require 'ice_nine'
require 'ice_nine/core_ext/object'


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
        @incident_generation[:source][:path].gsub!('<pwd>', File.expand_path(File.dirname(@filename)))
      end

      # freeze everything!
      @start_time.deep_freeze
      @duration.deep_freeze
      @warmup_duration.deep_freeze
      @incident_generation.deep_freeze
      @transition_matrix.deep_freeze
      @cost_analysis.deep_freeze
      @support_groups.deep_freeze
    end

    def reallocate_ops_and_clone(operators)
      raise 'Wrong allocation' unless operators.size == @support_groups.size

      new_conf = Configuration.new(@filename)
      new_conf.start_time          @start_time
      new_conf.duration            @duration
      new_conf.warmup_duration     @warmup_duration
      new_conf.incident_generation @incident_generation
      new_conf.transition_matrix   @transition_matrix
      new_conf.cost_analysis       @cost_analysis

      new_sgs = {}
      @support_groups.zip(operators) do |(sg_name,sg_conf),num_ops|
        new_sgs[sg_name] = {
          work_time: sg_conf[:work_time], # this is already frozen
          operators: {
            number: num_ops,
            workshift: sg_conf[:operators][:workshift], # this is already frozen
          },
        }
      end
      new_sgs.deep_freeze

      new_conf.support_groups(new_sgs)

      new_conf
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
