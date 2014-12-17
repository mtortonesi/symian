require 'symian/work_shift'


module Symian
  class Activity < Struct.new(:iid, :start_time, :end_time)
  end


  class Operator

    extend Forwardable

    REQUIRED_ATTRIBUTES = [
      :oid,
      :support_group_id,
    ]

    OTHER_ATTRIBUTES = [
      :workshift,
      :specialization,
      :work_record,
      :support_group_id,
    ]

    attr_reader *(REQUIRED_ATTRIBUTES + OTHER_ATTRIBUTES)

    def_delegators :@workshift, :active_at?, :secs_to_begin_of_shift, :secs_to_end_of_shift
    def_delegator :@workshift, :duration, :workshift_duration


    def initialize(oid, support_group_id, opts={})
      @oid = oid
      @support_group_id = support_group_id

      # set correspondent instance variables for optional arguments
      opts.each do |k, v|
        # ignore invalid attributes
        instance_variable_set("@#{k}", v) if OTHER_ATTRIBUTES.include?(k)
      end

      # support :workshift => :all_day_long shortcut
      if @workshift == :all_day_long
        @workshift = WorkShift::WORKSHIFT_24x7
      end

      # default workshift is 24x7
      @workshift ||= WorkShift::WORKSHIFT_24x7

      @specialization ||= {}
      @work_record ||= []
    end


    def assign(incident, incident_info, time)

      # initialize incident start work time if needed
      incident.start_work_time ||= time

      # calculate time to end of shift
      tteos = @workshift.secs_to_end_of_shift(time)
      raise "tteos: #{tteos}" if tteos < 0.0

      # specialization
      specialization = @specialization[incident.category] || 1.0

      # calculate time to incident escalation
      ttie = incident_info[:needed_work_time] / specialization.to_f
      raise "ttie: #{ttie}" if ttie < 0.0

      # handle incident
      if tteos < ttie # end of shift first
        work_time = tteos
        reason = :operator_off_duty
      else # escalation first
        work_time = ttie
        reason = :incident_escalation
      end

      # update needed (effective) incident work time
      incident_info[:needed_work_time] -= work_time * specialization

      # update incident tracking
      incident.add_tracking_information(:type => :work,
                                        :at => time,
                                        :duration => work_time,
                                        :sg => @support_group_id,
                                        :operator => @oid)

      # update operator work record
      @work_record << Activity.new(incident.iid, time, time + work_time)

      # return [ reason, time_when_operator_stops_working ]
      [ reason, time + work_time ]
    end

  end
end
