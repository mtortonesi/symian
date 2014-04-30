require 'symian/configuration'

module Symian
  class CostAnalyzer
    def initialize(configuration)
      @configuration = configuration
      unless @configuration.cost_analysis[:operations]
        raise ArgumentError, 'No operations cost configuration provided!'
      end
    end

    def evaluate(kpis)
      # evaluate operation costs
      operations_cost = @configuration.support_groups.inject(0.0) do |sum,(sg_name,sg_conf)|
        sg_costs = @configuration.cost_analysis[:operations].find{|sg| sg[:sg_name] == sg_name }
        unless sg_costs
          raise "Cannot find salaries for support group #{sg_name}!"
        end
        # ugly hack
        sum += sg_conf[:operators][:number] * sg_costs[:operator_salary]
      end
      # need to consider daily costs
      operations_cost /= 30.0

      # evaluate contracting costs (SLO violations)
      contracting_func = @configuration.cost_analysis[:contracting]
      contracting_cost = (contracting_func.nil? ? 0.0 : (contracting_func.call(kpis) or 0.0))

      # evaluate drift costs
      drift_func = @configuration.cost_analysis[:drift]
      drift_cost = (drift_func.nil? ? 0.0 : (drift_func.call(kpis) or 0.0))

      # return result
      { :operations => operations_cost, :contracting => contracting_cost, :drift => drift_cost }
    end
  end
end
