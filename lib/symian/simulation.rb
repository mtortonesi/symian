require 'symian/event'
require 'symian/generator'
require 'symian/operator'
require 'symian/performance_analyzer'
require 'symian/sorted_array'
require 'symian/support_group'
require 'symian/transition_matrix'
require 'symian/trace_collector'


module Symian
  class Simulation

    ATTRIBUTES = [ :start_time ]

    attr_reader *ATTRIBUTES


    def initialize(configuration, performance_analyzer, trace=TraceCollector.new(:memory))
      @configuration = configuration

      # setup performance analyzer and simulation trace
      @performance_analyzer = performance_analyzer
      @trace = trace

      # setup simulation start and current time
      @current_time = @start_time = @configuration.start_time

      # create support groups
      @support_groups = {}
      @configuration.support_groups.each do |name,conf|
        @support_groups[name] = SupportGroup.new(name, self, conf[:work_time], conf[:operators])
      end

      # create transition matrix
      @transition_matrix = TransitionMatrix.new(@configuration.transition_matrix)

      # create event queue
      @event_queue = SortedArray.new
    end


    def new_event(type, data, time, destination)
      @event_queue << Event.new(type, data, time, destination)
    end


    def now
      @current_time
    end


    def run

      # initialize support groups
      @support_groups.values.each do |sg|
        sg.initialize_at(@configuration.start_time)
      end

      # generate first incident
      ig = IncidentGenerator.new(self, @configuration.incident_generation)
      ig.generate

      # schedule end of simulation
      unless @configuration.end_time.nil?
        # puts "Simulation ends at: #{@configuration.end_time}"
        new_event(Event::ET_END_OF_SIMULATION, nil, @configuration.end_time, nil)
      end

      # calculate warmup threshold
      warmup_threshold = @configuration.start_time + @configuration.warmup_duration

      @incidents_being_worked_on ||= []

      # launch simulation
      until @event_queue.empty?
        e = @event_queue.shift

        # sanity check on simulation time flow
        if @current_time > e.time
          raise 'Error: simulation time inconsistency for event ' +
                "e.type=#{e.type} @current_time=#{@current_time}, e.time=#{e.time}"
        end

        @current_time = e.time

        #Trace.new_event e
        case e.type
          when Event::ET_INCIDENT_ARRIVAL

            sg_name = @transition_matrix.escalation('In')

            sg = @support_groups[sg_name]
            sg.new_incident(e.data, e.time)

            @incidents_being_worked_on << e.data

            # generate next incident
            ig.generate

            # TODO: pinpoint instant for calculation of time spent in enqueued state


          when Event::ET_INCIDENT_ASSIGNMENT

            # TODO: implement calculation of time spent in suspended state


          when Event::ET_OPERATOR_ACTIVITY_STARTS


          when Event::ET_OPERATOR_ACTIVITY_FINISHES

            sg = @support_groups[e.destination]
            sg.operator_finished_working(e.data[0], e.time)


          when Event::ET_INCIDENT_RESCHEDULING

            sg = @support_groups[e.destination]
            sg.schedule_incident_for_reassignment(e.data[0], e.time)

            # TODO: pinpoint instant for calculation of time spent in suspended state


          when Event::ET_INCIDENT_ESCALATION
            inc = e.data

            sg_name = @transition_matrix.escalation(e.destination)
            if sg_name == "Out"
              inc.closure_time = e.time

              # remove incident from list of incidents being worked on and add it to trace
              @incidents_being_worked_on.delete(inc)
              @trace.record_incidents(inc)
            else
              sg = @support_groups[sg_name]
              sg.new_incident(inc, e.time)
            end


          when Event::ET_OPERATOR_LEAVING

            sg = @support_groups[e.destination]
            sg.operator_going_home(e.data, e.time)


          when Event::ET_OPERATOR_RETURNING

            sg = @support_groups[e.destination]
            sg.operator_arrived_at_work(e.data, e.time)


          when Event::ET_SUPPORT_GROUP_QUEUE_SIZE_CHANGE


          when Event::ET_END_OF_SIMULATION
            break

        end
      end

      # save trace file
      @trace.save_and_close
      kpis = @performance_analyzer.calculate_kpis(@trace)
      kpis.merge(incidents_being_worked_on: @incidents_being_worked_on.size)

    end

  end
end
