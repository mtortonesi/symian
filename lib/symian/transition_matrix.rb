require 'csv'
require 'stringio'

require 'erv'


module Symian
  class TransitionMatrix

    # this is mostly for testing purposes
    attr_reader :transition_probabilities

    def initialize(input)
      # allow filename, string, and IO objects as input
      if input.kind_of?(String)
        if File.exists?(input)
          input = File.new(input, 'r')
        else
          input = StringIO.new(input.strip.split("\n").collect{|l| l.strip }.join("\n"))
        end
      else
        raise RuntimeError unless input.respond_to?(:read)
      end

      @transition_probabilities = {}

      # process escalation matrix
      headers = nil
      CSV.parse(input.read, :headers => :first_row) do |row|
        headers ||= row.headers
        @sg_names ||= headers[1..-2]

        # make sure that support groups do not include the "In" virtual support group
        raise RuntimeError if @sg_names.include?("In")

        # make sure that last support group is the "Out" virtual support group
        raise RuntimeError unless headers[-1] == "Out"

        sg_name = row[0]  # the first row element is the support group name

        # make sure support group name is valid
        raise RuntimeError unless sg_name == "In" or @sg_names.include?(sg_name)

        # make sure we are not overwriting existing data
        raise RuntimeError if @transition_probabilities[sg_name]
        @transition_probabilities[sg_name] = []

        # prepare corresponding row in transition matrix
        2.upto(row.length) do |i|
          escalations = Integer(row[i-1]) # raises ArgumentError in case of errors
          if escalations > 0
            @transition_probabilities[sg_name] << { :sg_name => headers[i-1],
                                                    :escalations => escalations }
          end
        end

        # calculate normalized probabilities
        normalize_probabilities(@transition_probabilities[sg_name])
      end

      # check that we have transition probabilities for each support group
      [ "In", *@sg_names].each do |name|
        raise RuntimeError unless @transition_probabilities.has_key?(name)
      end

      # TODO: make seeding of this thing configurable...
      @rng = ERV::RandomVariable.new(:distribution => :uniform, :min_value => 0.0, :max_value => 1.0)
    end


    def escalation(from)
      # raise error if source support group does not exist
      raise ArgumentError unless tps = @transition_probabilities[from]

      # get random value
      x = @rng.next

      # return name of first support group whose (cumulative)
      # transition probability is larger than x
      tps.each do |el|
        return el[:sg_name] if el[:probability] > x
      end

      # the destination support group was not found
      raise RuntimeError
    end


    def merge(sg1_name, sg2_name, new_name=nil)
      # raise error if support groups do not exist
      raise RuntimeError unless sg1_probs = @transition_probabilities.delete(sg1_name) and
                                sg2_probs = @transition_probabilities.delete(sg2_name)

      new_sg_name = new_name || "Merge_of_%s_and_%s" % [ sg1_name, sg2_name ]

      # recalculate escalations to new sg
      @transition_probabilities.each do |k,v|

        # add escalation information for new group
        escalations = 0
        v.each do |el|
          if el[:sg_name] == sg1_name or el[:sg_name] == sg2_name
            escalations += el[:escalations]
          end
        end

        v << { :sg_name => new_sg_name,
               :escalations => escalations }

        # remove old escalation information
        v.delete_if {|el| el[:sg_name] == sg1_name or el[:sg_name] == sg2_name }

        # recalculate normalized probabilities
        normalize_probabilities(v)
      end

      # update @sg_names
      @sg_names[@sg_names.index(sg1_name)] = new_name
      @sg_names.delete(sg2_name)

      # recalculate escalations from new sg
      total_escalation_info = sg1_probs + sg2_probs
      @transition_probabilities[new_sg_name] = []
      [ @sg_names, "Out" ].flatten!.each do |name|
        escalations = total_escalation_info.inject(0) do |sum,el|
          sum + (el[:sg_name] == name ? el[:escalations] : 0)
        end

        if escalations > 0
          @transition_probabilities[new_sg_name] << { :sg_name => name,
                                                      :escalations => escalations }
        end
      end

      # recalculate normalized probabilities
      normalize_probabilities(@transition_probabilities[new_sg_name])
    end


    def to_s
      lines = [ "From/To,#{@sg_names.join(',')},Out" ]
      [ "In", *@sg_names ].each do |input_sg|
        escalations = [ @sg_names, "Out" ].flatten!.map do |output_sg|
          @transition_probabilities[input_sg].map{|x| x[:sg_name] == output_sg ? x[:escalations] : nil }.compact.first || 0
        end
        lines << "#{input_sg},#{escalations.join(',')}"
      end
      lines.join("\n")
    end


    private
      def normalize_probabilities(probability_vector)
        # calculate total escalations
        total_escalations = probability_vector.inject(0) { |sum,el| sum += el[:escalations] }

        # probability values are cumulative
        cumulative_escalations = 0
        probability_vector.each do |el|
          cumulative_escalations += el[:escalations]
          el[:probability] = cumulative_escalations.to_f / total_escalations.to_f
        end

        # just in case...
        probability_vector[-1][:probability] = 1.0
      end
  end
end
