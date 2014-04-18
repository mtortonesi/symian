require 'test_helper'

require 'symian/incident'
require 'symian/operator'


describe Symian::Operator do

  # it 'should accept only valid parameters' do
  #   Symian::Operator::ATTRIBUTES.reject{|x| x == :oid or x == :support_group_id }.each do |attribute|
  #     i = Symian::Operator.new(:oid => 1, :support_group_id => 1, attribute => 1)
  #     i.send(attribute).must_equal 1
  #   end
  # end


  # it 'should not accept anything but a hash as a parameter' do
  #   lambda { Symian::Operator.new(:mickey) }.should raise_error(ArgumentError)
  #   lambda { Symian::Operator.new([ :mickey, :goofy ]) }.should raise_error(ArgumentError)
  # end


  it 'should support :workshift => :all_day_long shortcut' do
    o = Symian::Operator.new(1, 1, :workshift => :all_day_long)
    o.workshift.must_equal Symian::WorkShift::WORKSHIFT_24x7
  end


  it 'should work on minor incidents until escalation' do
    assignment_time          = Time.now                  # incident is assigned now
    needed_work_time         = 1.hour                    # incident requires 1 hour of work
    arrival_time             = assignment_time - 1.hour  # incident arrived one hour ago
    expected_escalation_time = assignment_time + 1.hour  # incident should be closed in one hour

    o = Symian::Operator.new(1, 1)
    i = Symian::Incident.new(1, arrival_time)

    o.assign(i, { :needed_work_time => needed_work_time }, assignment_time).must_equal [ :incident_escalation, expected_escalation_time ]
  end


  it 'should work on major incidents until time of shift' do
    assignment_time  = Time.now                   # incident is assigned now
    needed_work_time = 2.hours                    # incident requires 2 hours of work
    arrival_time     = assignment_time - 1.hour   # incident arrived one hour ago
    workshift_start  = assignment_time - 7.hours  # operator workshift started 7 hours ago
    workshift_end    = assignment_time + 1.hour   # operator workshift ends in 1 hour

    o = Symian::Operator.new(1, 1,
                             :workshift => Symian::WorkShift.new(:custom,
                                                                 :start_time => workshift_start,
                                                                 :end_time   => workshift_end))
    i = Symian::Incident.new(1, arrival_time)

    o.assign(i, { :needed_work_time => needed_work_time }, assignment_time).must_equal [ :operator_off_duty, workshift_end ]
  end


  it 'should have specialization factors skewing its productivity' do
    assignment_time          = Time.now                  # incident is assigned now
    needed_work_time         = 2.hours                   # incident requires 2 hours of work
    arrival_time             = assignment_time - 1.hour  # incident arrived one hour ago
    expected_escalation_time = assignment_time + 1.hour  # incident should be closed in one hour

    o = Symian::Operator.new(1, 1,
                             :specialization => { :web => 2.0 })      # 2x specialization on 'web' incidents

    i = Symian::Incident.new(1, arrival_time, :category => :web)

    o.assign(i, { :needed_work_time => needed_work_time }, assignment_time).must_equal [ :incident_escalation, expected_escalation_time ]
  end

end

