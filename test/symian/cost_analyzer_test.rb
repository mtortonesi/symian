require 'test_helper'

require 'symian/reference_configuration'
require 'symian/cost_analyzer'


describe Symian::CostAnalyzer do

  context 'operations' do
    it 'should correctly calculate daily operations' do
      EXAMPLE_KPIS = { :mttr => 9000, :micd => 450 }

      with_reference_config do |conf|
        ca = Symian::CostAnalyzer.new(conf)
        res = ca.evaluate(EXAMPLE_KPIS)
        res[:operations].must_equal((25_000 + 30_000 + 40_000) / 30.0)
      end
    end
  end

  context 'contracting' do
    it 'should work if no contracting function is provided' do
      cost_analysis_wo_contracting = COST_ANALYSIS.reject {|x| x == :contracting }
      with_reference_config(cost_analysis: cost_analysis_wo_contracting) do |conf|
        Symian::CostAnalyzer.new(conf)
      end
    end
  end

  context 'drift' do
    it 'should work if no drift function is provided' do
      cost_analysis_wo_drift = COST_ANALYSIS.reject {|x| x == :drift }
      with_reference_config(cost_analysis: cost_analysis_wo_drift) do |conf|
        Symian::CostAnalyzer.new(conf)
      end
    end
  end

    # it 'should work if penalty function returns something' do
    #   evaluator = with_reference_config do |conf|
    #     SISFC::Evaluator.new(conf)
    #   end
    #   evaluator.evaluate_business_impact({ mttr: 0.075 }, nil, EXAMPLE_ALLOCATION)
    # end

    # it 'should work if penalty function returns nil' do
    #   evaluator = with_reference_config do |conf|
    #     SISFC::Evaluator.new(conf)
    #   end
    #   evaluator.evaluate_business_impact({ mttr: 0.025 }, nil, EXAMPLE_ALLOCATION)
    # end
end
