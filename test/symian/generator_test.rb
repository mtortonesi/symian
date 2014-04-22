require 'test_helper'

require 'symian/generator'
require 'symian/event'


describe Symian::IncidentGenerator do

  let(:simulation) { MiniTest::Mock.new }


  it 'should generate incidents with random arrival times' do
    gen = Symian::IncidentGenerator.new(simulation,
                                        :type => :sequential_random_variable,
                                        :source => { :first_value => Time.now,
                                                     :seed => (Process.pid / rand).to_i,
                                                     :distribution => :discrete_uniform,
                                                     :max_value => 100 })
    simulation.expect(:new_event, nil, [ Symian::Event::ET_INCIDENT_ARRIVAL, Symian::Incident, Time, nil ])
    gen.generate
  end


  it 'should generate incidents with arrival times from traces'


end
