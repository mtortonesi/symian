require 'test_helper'

require 'symian/trace_collector'
require 'symian/incident'
require 'symian/support_group'
require 'symian/operator'
require 'symian/event'

require 'tempfile'


describe Symian::TraceCollector do

  context 'backends' do

    context 'with memory backend' do

      it 'should be creatable' do
        Symian::TraceCollector.new(:memory)
      end

      it 'should not mind attempts to save the trace' do
        Symian::TraceCollector.new(:memory).save_and_close
      end

    end

    context 'with YAML file backend' do

      it 'should require a namefile for creation' do
        lambda { Symian::TraceCollector.new(:yaml) }.must_raise ArgumentError
      end

      it 'should be creatable' do
        tmpfile = Tempfile.new('reserved_for_testing')

        Symian::TraceCollector.new(:yaml, file: tmpfile.path).save_and_close

        tmpfile.close
        tmpfile.unlink
      end

      it 'should allow to save the trace on the YAML file' do
        tmpfile = Tempfile.new('reserved_for_testing')

        Symian::TraceCollector.new(:yaml, file: tmpfile.path).save_and_close
        File.size?(tmpfile.path).must_be :>, 0

        tmpfile.close
        tmpfile.unlink
      end

      it 'should correctly save trace information' do
        # initialize stuff
        now = Time.now
        incs = [ Symian::Incident.new(1, now),
                 Symian::Incident.new(2, now + 1.hour),
                 Symian::Incident.new(3, now + 2.hours) ]
        simulation = MiniTest::Mock.new
        sgs = [ Symian::SupportGroup.new('SG1',
                                 simulation,
                                 { :distribution => :exponential, :mean => 5 },
                                 { :number => 3, :workshift => :all_day_long }),
                Symian::SupportGroup.new('SG2',
                                 simulation,
                                 { :distribution => :exponential, :mean => 10 },
                                 { :number => 5, :workshift => :all_day_long }),
                Symian::SupportGroup.new('SG3',
                                 simulation,
                                 { :distribution => :exponential, :mean => 15 },
                                 { :number => 7, :workshift => :all_day_long }),
                Symian::SupportGroup.new('SG4',
                                 simulation,
                                 { :distribution => :exponential, :mean => 20 },
                                 { :number => 9, :workshift => :all_day_long }) ]

        tmpfile = Tempfile.new('reserved_for_testing')

        # create first trace collector
        tc_1 = Symian::TraceCollector.new(:yaml, file: tmpfile.path)

        # record trace data
        tc_1.record_incidents(incs)
        tc_1.record_support_groups(sgs)

        # save data to file
        tc_1.save_and_close

        # load new trace collector from file
        tc_2 = Symian::TraceCollector.new(:yaml, file: tmpfile.path)

        # check loaded data
        count = 0
        tc_2.incidents.must_equal 3
        tc_2.with_incidents do |i|
          i.must_be_instance_of Symian::Incident
          count += 1
        end

        # check loaded data
        count = 0
        tc_2.support_groups.must_equal 4
        tc_2.with_support_groups do |sg|
          sg.must_be_instance_of Symian::SupportGroup
          count += 1
        end

        # cleanup
        tmpfile.close
        tmpfile.unlink
      end

    end

  end



  context 'operations' do

    let (:now) { Time.now }

    let (:incs) {
      [ Symian::Incident.new(1, now),
        Symian::Incident.new(2, now + 1.hour),
        Symian::Incident.new(3, now + 2.hours) ]
    }

    let (:tc) { Symian::TraceCollector.new(:memory) }

    let (:simulation) { MiniTest::Mock.new }

    let (:sgs) {
      [ Symian::SupportGroup.new('SG1',
                         simulation,
                         { :distribution => :exponential, :mean => 5 },
                         { :number => 3, :workshift => :all_day_long }),
        Symian::SupportGroup.new('SG2',
                         simulation,
                         { :distribution => :exponential, :mean => 10 },
                         { :number => 5, :workshift => :all_day_long }),
        Symian::SupportGroup.new('SG3',
                         simulation,
                         { :distribution => :exponential, :mean => 15 },
                         { :number => 7, :workshift => :all_day_long }) ]
    }

    it 'should store a single incident' do
      tc.incidents.must_equal 0
      tc.record_incidents(incs[0])
      tc.incidents.must_equal 1
    end

    it 'should store an array of incidents' do
      tc.incidents.must_equal 0
      tc.record_incidents(incs)
      tc.incidents.must_equal 3
    end

    it 'should store a single support group' do
      tc.support_groups.must_equal 0
      tc.record_support_groups(sgs[0])
      tc.support_groups.must_equal 1
    end

    it 'should store an array of support groups' do
      tc.support_groups.must_equal 0
      tc.record_support_groups(sgs)
      tc.support_groups.must_equal 3
    end

    it 'should store a single event'

    it 'should store an array of events'

    it 'should allow evaluating a block for each stored incident' do
      tc.record_incidents(incs)
      tc.with_incidents do |i|
        i.closure_time = now
      end
      tc.with_incidents do |i|
        i.closure_time.must_equal now
      end
    end

    it 'should allow considering stored incidents as an enumerable' do
      tc.record_incidents(incs)
      incs_arrived = tc.with_incidents.select{|i| i.arrival_time <= now }
      incs_arrived.size.must_equal 1
      incs_arrived.first.must_equal incs.first
    end

    it 'should allow evaluating a block for each stored support group'

    it 'should allow considering stored support groups as an enumerable'

    it 'should allow evaluating a block for each stored event'

    it 'should allow considering stored events as an enumerable'

  end

end
