# require 'symian/support/extensions'
require 'symian/support/yaml_io'


module Symian
  class Incident
    include YAMLSerializable

    # priorities are not currently used
    MIN_PRIORITY = 0
    MAX_PRIORITY = 9

    REQUIRED_ATTRIBUTES = [
      :iid,                     # incident ID
      :arrival_time,            # time of incident arrival at the IT support organization
    ]

    OTHER_ATTRIBUTES = [
      :category,                # incident category
    # :severity,                # incident severity - not implemented yet
    # :state,                   # incident state - not implemented yet
      :priority,                # incident priority - not currently used
      :visited_support_groups,  # number of visited SGs
    # :needed_work_time,        # needed work time before incident escalation
    #                           #   - initialized at the arrival in a support group
    #                           #   - decreased as operator works on the incident
    #                           #   - when it reaches 0, the incident is escalated
      :start_work_time,         # time when the first operator starts working on the incident
                                #   - set in Operator#assign
    # :total_work_time,         # total work time on the incident
    #                           #   - initialized to 0 in the constructor
    # :total_queue_time,        # total time spent waiting for an operator
    #                           #   - initialized to 0 in the constructor
    # :total_suspension_time,   # total suspension time
    #                           #   - initialized to 0 in the constructor
      :closure_time,            # time at which the incident was closed
    ]

    attr_accessor *(REQUIRED_ATTRIBUTES + OTHER_ATTRIBUTES)


    # setup attributes saved in traces
    include YAMLSerializable

    TRACED_ATTRIBUTES = REQUIRED_ATTRIBUTES + OTHER_ATTRIBUTES + [ :tracking_information ]


    def initialize(iid, arrival_time, opts={})
      @iid = iid
      @arrival_time = arrival_time

      # set correspondent instance variables for optional arguments
      opts.each do |k, v|
        # ignore invalid attributes
        instance_variable_set("@#{k}", v) if OTHER_ATTRIBUTES.include?(k)
      end

      @tracking_information ||= []
      @visited_support_groups ||= 0
    end


    # the format of track_info is:
    # { :type => one of [ :queue, :work, :suspend ]
    #   :at => begin time
    #   :duration => duration
    #   :sg => support_group_name
    #   :operator => operator_id (if applicable)
    # }
    def add_tracking_information(track_info)
      @tracking_information << track_info
    end

    def with_tracking_information(type=:all)
      selected_ti = if type == :all
        @tracking_information
      else
        @tracking_information.select{|el| el.type == type }
      end

      selected_ti.each do |ti|
        yield ti
      end
    end

    def total_work_time
      calculate_time(:work)
    end

    def total_queue_time
      calculate_time(:queue)
    end

    def total_suspend_time
      calculate_time(:suspend)
    end

    def total_time_at_last_sg
      calculate_time_at_last_support_group(:all)
    end

    def queue_time_at_last_sg
      calculate_time_at_last_support_group(:queue)
    end

    def closed?
      !@closure_time.nil?
    end

    def ttr
      # if incident isn't closed yet, just return nil without raising an exception.
      @closure_time.nil? ? nil : (@closure_time - @arrival_time).to_int
    end


    private

      def calculate_time(type)
        return 0 unless @tracking_information
        @tracking_information.inject(0){|sum,x| sum += ((type == :all || type == x[:type]) ? x[:duration].to_i : 0) }
      end

      def calculate_time_at_last_support_group(*types)
        time = 0
        last_sg = nil
        @tracking_information.reverse_each do |ti|
          last_sg ||= ti[:sg]
          break unless ti[:sg] == last_sg
          time += ti[:duration].to_i if (types.include?(:all) || types.include?(ti[:type]))
        end
        time
      end

  end

end
