require 'erv'

require 'symian/configuration'
require 'symian/incident'


module Symian
  class IncidentGenerator

    def initialize(simulation, options={})
      @simulation = simulation

      @arrival_times = Sequence.create(options)
      raise ArgumentError unless @arrival_times

      # NOTE: so far we support only sequential integer iids
      @next_iid = 0
    end


    def generate
      # get next incident arrival time
      next_arrival = @arrival_times.next

      # handle case where arrival times is limited source
      return nil unless next_arrival

      # increase @next_iid
      @next_iid += 1

      # generate and return incident
      i = Incident.new(@next_iid, next_arrival,
                       :category => 'normal', # not supported at the moment
                       :priority => 0)        # not supported at the moment

      @simulation.new_event(Event::ET_INCIDENT_ARRIVAL, i, next_arrival, nil)
    end
  end


  class Sequence
    def self.create(args)
      case args[:type]
      when :file
        FileInputSequence.new(args[:source])
      when :sequential_random_variable
        ERV::SequentialRandomVariable.new(args[:source])
      # TODO: also support CSV files and arrays as input source
      end
    end
  end


  class FileInputSequence
    def initialize(args)
      @file = File.open(args[:path], 'r')
      @curr_val = args[:first_value]
    end

    # returns nil when EOF occurs
    def next
      displacement = @file.gets.try(:chomp).try(:to_f)
      return nil unless displacement

      ret = @curr_val
      @curr_val += displacement
      ret
    end
  end
end
