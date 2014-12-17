require 'test_helper'

require 'symian/incident'
require 'symian/support_group'
require 'symian/work_shift'


describe Symian::SupportGroup do

  before :each do
    @simulation = MiniTest::Mock.new
  end


  it 'should be creatable with one operator group' do
    sg = Symian::SupportGroup.new('SG',
                                  @simulation,
                                  { :distribution => :exponential, :mean => 5 },
                                  { :number => 3, :workshift => Symian::WorkShift.new(:all_day_long) })
    start_time = Time.now
    sg.initialize_at(start_time)
    sg.operators.size.must_equal 3
  end


  it 'should be creatable with several operator groups' do
    sg = Symian::SupportGroup.new('SG',
                                  @simulation,
                                  { :distribution => :exponential, :mean => 5 },
                                  [ { :number => 3, :workshift => Symian::WorkShift.new(:all_day_long) },
                                    { :number => 4, :workshift => Symian::WorkShift.new(:all_day_long) },
                                    { :number => 3, :workshift => Symian::WorkShift.new(:all_day_long) } ])
    start_time = Time.now
    sg.initialize_at(start_time)
    sg.operators.size.must_equal 10
  end


  it 'should allow incident reassignments' do
    ws = Symian::WorkShift.new(:custom,
                               :start_time => Time.utc(2009, 'Jan', 1,  8, 0, 0),
                               :end_time   => Time.utc(2009, 'Jan', 1, 16, 0, 0))
    sg = Symian::SupportGroup.new('SG',
                                  @simulation,
                                  { :distribution => :constant, :value => 10.hours },
                                  [ { :number => 1, :workshift => ws } ])
    start_time = Time.utc(2009, 'Jan', 1, 8, 0, 0)
    incident_arrival = start_time + 2.hours

    @simulation.expect(:new_event,
                       nil,
                       [ Symian::Event::ET_OPERATOR_LEAVING, String, incident_arrival + 6.hours, 'SG'])

    sg.initialize_at(start_time)
    i = Symian::Incident.new(0, incident_arrival,
                             :category     => 'normal',
                             :priority     => 0) # not supported at the moment

    # first increase queue size,...
    @simulation.expect(:new_event, nil, [Symian::Event::ET_SUPPORT_GROUP_QUEUE_SIZE_CHANGE, 1, incident_arrival, 'SG'])
    # ...then decrease it, ...
    @simulation.expect(:new_event, nil, [Symian::Event::ET_SUPPORT_GROUP_QUEUE_SIZE_CHANGE, 0, incident_arrival, 'SG'])
    # ...assign it to an operator, ...
    @simulation.expect(:new_event, nil, [Symian::Event::ET_INCIDENT_ASSIGNMENT, Array, incident_arrival, 'SG'])
    @simulation.expect(:new_event, nil, [Symian::Event::ET_OPERATOR_ACTIVITY_STARTS, Array, incident_arrival, 'SG'])
    # ...and finally escalate the incident.
    @simulation.expect(:new_event, nil, [Symian::Event::ET_OPERATOR_ACTIVITY_FINISHES, Array, incident_arrival + 6.hours, 'SG'])
    @simulation.expect(:new_event, nil, [Symian::Event::ET_INCIDENT_RESCHEDULING, Array, incident_arrival + 6.hours, 'SG'])

    sg.new_incident(i, incident_arrival)

    i.visited_support_groups.must_equal 1
  end


  it 'should accept new incidents' do
    sg = Symian::SupportGroup.new('SG',
                                  @simulation,
                                  { :distribution => :constant, :value => 500 },
                                  [ { :number => 3, :workshift => Symian::WorkShift.new(:all_day_long) } ])
    start_time = Time.now
    sg.initialize_at(start_time)
    incident_arrival = start_time + 3600  # after 1 hour
    i = Symian::Incident.new(0, incident_arrival,
                             :category     => 'normal',
                             :priority     => 0) # not supported at the moment

    # first increase queue size,...
    @simulation.expect(:new_event, nil, [Symian::Event::ET_SUPPORT_GROUP_QUEUE_SIZE_CHANGE, 1, incident_arrival, 'SG'])
    # ...then decrease it, ...
    @simulation.expect(:new_event, nil, [Symian::Event::ET_SUPPORT_GROUP_QUEUE_SIZE_CHANGE, 0, incident_arrival, 'SG'])
    # ...assign it to an operator, ...
    @simulation.expect(:new_event, nil, [Symian::Event::ET_INCIDENT_ASSIGNMENT, Array, incident_arrival, 'SG'])
    @simulation.expect(:new_event, nil, [Symian::Event::ET_OPERATOR_ACTIVITY_STARTS, Array, incident_arrival, 'SG'])
    # ...and finally escalate the incident.
    @simulation.expect(:new_event, nil, [Symian::Event::ET_OPERATOR_ACTIVITY_FINISHES, Array, incident_arrival + 500, 'SG'])
    @simulation.expect(:new_event, nil, [Symian::Event::ET_INCIDENT_ESCALATION, Symian::Incident, incident_arrival + 500, 'SG'])

    sg.new_incident(i, incident_arrival)

    i.visited_support_groups.must_equal 1
  end

  # it 'should handle operators going home'

  # it 'should handle operators coming back'

  # it 'should handle operators finishing their work'

end

