require 'symian/support/yaml_io'

module Symian

  class Event

    ET_INCIDENT_ARRIVAL                =  0
    ET_INCIDENT_ASSIGNMENT             =  1
    ET_INCIDENT_RESCHEDULING           =  2
    ET_INCIDENT_ESCALATION             =  3
    ET_OPERATOR_RETURNING              = 10
    ET_OPERATOR_LEAVING                = 11
    ET_OPERATOR_ACTIVITY_STARTS        = 12
    ET_OPERATOR_ACTIVITY_FINISHES      = 13
    ET_SUPPORT_GROUP_QUEUE_SIZE_CHANGE = 20
    ET_END_OF_SIMULATION               = 90


    # let the comparable mixin provide the < and > operators for us
    include Comparable


    # setup readable/accessible attributes
    ATTRIBUTES = [ :type, :data, :time, :destination ]

    attr_reader *ATTRIBUTES # should this be attr_accessor instead?


    # setup attributes saved in traces
    include YAMLSerializable

    TRACED_ATTRIBUTES = ATTRIBUTES


    def initialize(type, data, time, destination)
      @type        = type
      @data        = data
      @time        = time
      @destination = destination
    end

    def <=> (event)
      @time <=> event.time
    end

    def to_s
      "Event type: #{@type}, data: #{@data}, time: #{@time}, #{@destination}"
    end

  end

end

