require 'test_helper'

require 'symian/incident'

describe Symian::Incident do

  it 'should ignore invalid parameters passed to the constructor' do
    Symian::Incident.new(1, Time.now, :some_invalid_param => "dummy")
  end

  it 'should not be closed unless closure time is provided' do
    inc = Symian::Incident.new(1, Time.now)
    inc.closed?.must_equal false
  end

  it 'should be closed if closure time is provided' do
    inc = Symian::Incident.new(1, Time.now)
    inc.closure_time = Time.now
    inc.closed?.must_equal true
  end

  it 'should have a nil TTR if still open' do
    inc = Symian::Incident.new(1, Time.now)
    inc.ttr.must_be_nil
  end

  it 'should have a valid TTR if closed' do
    arrival_time = Time.now
    closure_time = Time.now + 1.hour
    inc = Symian::Incident.new(1, arrival_time,
                               :closure_time => closure_time)
    inc.ttr.must_equal 1.hour
  end

  it 'should correctly manage tracking information' do
    inc = Symian::Incident.new(1, Time.now)
    tis = [ { :type     => :queue,
              :at       => Time.now,
              :duration => 50.seconds,
              :sg       => 'SG1' },
            { :type     => :work,
              :at       => Time.now + 1.hour,
              :duration => 2.hours,
              :sg       => 'SG2' },
            { :type     => :suspend,
              :at       => Time.now + 20.minutes,
              :duration => 30.minutes,
              :sg       => 'SG3' } ]
    tis.each do |ti|
      inc.add_tracking_information(ti)
    end
    i = 0
    inc.with_tracking_information do |ti|
      ti.must_equal tis[i]
      i += 1
    end
  end

  it 'should correctly calculate time spent at last support group' do
    inc = Symian::Incident.new(1, Time.now)
    now = Time.now

    tis = [ { :type     => :queue,
              :at       => now,
              :duration => 1.hour,
              :sg       => 'SG1' },
            { :type     => :work,
              :at       => now + 1.hour,
              :duration => 2.hours,
              :sg       => 'SG1' },
            { :type     => :queue,
              :at       => now + 3.hours,
              :duration => 1.hour,
              :sg       => 'SG2' },
            { :type     => :work,
              :at       => now + 4.hours,
              :duration => 2.hours,
              :sg       => 'SG2' },
            { :type     => :queue,
              :at       => now + 6.hours,
              :duration => 1.hour,
              :sg       => 'SG3' },
            { :type     => :work,
              :at       => now + 7.hours,
              :duration => 2.hours,
              :sg       => 'SG3' },
            { :type     => :suspend,
              :at       => now + 9.hours,
              :duration => 30.minutes,
              :sg       => 'SG3' },
            { :type     => :work,
              :at       => now + 9.hours + 30.minutes,
              :duration => 30.minutes,
              :sg       => 'SG3' } ]

    tis.each do |ti|
      inc.add_tracking_information(ti)
    end

    inc.total_time_at_last_sg.must_equal 4.hours
    inc.queue_time_at_last_sg.must_equal 1.hour
  end

end
