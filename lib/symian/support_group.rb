require 'erv'

require 'symian/event'
require 'symian/operator'
require 'symian/work_shift'

require 'symian/support/yaml_io'


module Symian

  class SupportGroup

    # setup readable/accessible attributes
    ATTRIBUTES = [ :sgid, :operators ]

    attr_reader *ATTRIBUTES


    # setup attributes saved in traces
    include YAMLSerializable

    TRACED_ATTRIBUTES = ATTRIBUTES + [ :incident_queue_info ]


    def initialize(support_group_id, simulation, work_time_characterization, operator_characterizations)
      @sgid = support_group_id
      @simulation = simulation

      # initialize needed_work_time_rng
      @needed_work_time_rv = ERV::RandomVariable.new(work_time_characterization)

      # create operators
      @operators = []

      if operator_characterizations.kind_of?(Hash)
        operator_characterizations = [ operator_characterizations ]
      end

      next_op_id = 1
      operator_characterizations.each do |x|
        x[:number].times do |y|
          op = Operator.new("OP#{next_op_id}_#{@sgid}", @sgid, x.reject { |k, v| k == :number })
          @operators << op
          next_op_id = next_op_id + 1
        end
      end

      # initialize incident queue and related tracking information
      @incident_queue = []
      @incident_queue_info = []
    end


    def initialize_at(time)
      # find out which operators are off duty and schedule their comeback
      @operators_off_work = @operators.select do |x|
        !x.workshift.active_at?(time)
      end
      @operators_off_work.each do |op|
        t = op.workshift.secs_to_begin_of_shift(time)
        @simulation.new_event(Event::ET_OPERATOR_RETURNING, op.oid,
                              time + t - 1, @sgid)
      end

      # find out which operators are on duty and schedule their leaving
      @available_operators = @operators - @operators_off_work
      @available_operators.each do |op|
        t = op.workshift.secs_to_end_of_shift(time)
        @simulation.new_event(Event::ET_OPERATOR_LEAVING, op.oid,
                              time + t - 1, @sgid) unless t == WorkShift::Infinity
      end
    end


    def new_incident(incident, time)
      # increase number of visited SGs
      incident.visited_support_groups += 1

      incident_info = {
        # set up incident needed work time
        :needed_work_time => @needed_work_time_rv.next,
        # # reset queue_time_at_last_sg attribute
        # :queue_time => 0
      }

      # put incident at the end of the queue
      @incident_queue << [ incident, incident_info, time ]

      # update queue size tracking information
      @incident_queue_info << { :size => @incident_queue.size, :time => time }
      @simulation.new_event(Event::ET_SUPPORT_GROUP_QUEUE_SIZE_CHANGE, @incident_queue.size,
                            time, @sgid)

      # try to allocate operator
      try_to_allocate_operator(time)
    end


    def schedule_incident_for_reassignment(incident, incident_info, time)
      @incident_queue.unshift [ incident, incident_info, time ]
      # update queue size tracking information
      @incident_queue_info << { :size => @incident_queue.size, :time => time }
      try_to_allocate_operator(time)
    end


    def operator_going_home(operator_id, time)
      op = @operators.find{|x| x.oid == operator_id }
      @available_operators.delete_if{|x| x.oid == operator_id }
      @operators_off_work << op
      @simulation.new_event(Event::ET_OPERATOR_RETURNING, op.oid,
                            time + 86400 - op.workshift.duration, @sgid)
    end


    def operator_arrived_at_work(operator_id, time)
      op = @operators.find{|x| x.oid == operator_id }
      @operators_off_work.delete(op)
      @available_operators << op
      try_to_allocate_operator(time)
      @simulation.new_event(Event::ET_OPERATOR_LEAVING, op.oid,
                            time + op.workshift.duration, @sgid)
    end


    def operator_finished_working(operator_id, time)
      op = @operators.find{|x| x.oid == operator_id }
      if op.workshift.secs_to_end_of_shift(time) > 0
        @available_operators << op
      end
      try_to_allocate_operator(time)
    end


    private

      def try_to_allocate_operator(time)
        if !@available_operators.empty? and !@incident_queue.empty?
          op = @available_operators.shift
          i, inc_info, t = @incident_queue.shift

          # update incident tracking information
          queue_time = time.tv_sec - t.tv_sec
          i.add_tracking_information(:type => :queue,
                                     :at => t,
                                     :duration => queue_time,
                                     :sg => @support_group_id)


          @simulation.new_event(Event::ET_SUPPORT_GROUP_QUEUE_SIZE_CHANGE,
                                @incident_queue.size, time, @sgid)
          @simulation.new_event(Event::ET_INCIDENT_ASSIGNMENT,
                                [ i.iid, op.oid ], time, @sgid)
          @simulation.new_event(Event::ET_OPERATOR_ACTIVITY_STARTS,
                                [ op.oid, i.iid ], time, @sgid)

          report = op.assign(i, inc_info, time)

          @simulation.new_event(Event::ET_OPERATOR_ACTIVITY_FINISHES,
                                [ op.oid, i.iid ], report[1], @sgid)

          finish_time = report[1]
          case report[0]
            when :incident_escalation
              @simulation.new_event(Event::ET_INCIDENT_ESCALATION,
                                    i, finish_time, @sgid)
            when :operator_off_duty
              # TODO: implement configurable rescheduling policy
              @incident_queue << [ i, inc_info, finish_time ]
              @simulation.new_event(Event::ET_INCIDENT_RESCHEDULING,
                                    [ i, op.oid ], finish_time, @sgid)
          end
        end
      end

  end

end

