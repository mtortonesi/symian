require 'test_helper'

require 'symian/work_shift'


describe Symian::WorkShift do

  # it "should require a work shift type" do
  #   lambda { Symian::WorkShift.new }.should raise_error(ArgumentError)
  # end

  # it "should require a valid work shift type" do
  #   lambda { Symian::WorkShift.new(:unknown_type) }.should raise_error(ArgumentError)
  # end

  describe 'a 24-hours workshift' do

    let(:ws) { Symian::WorkShift.new(:all_day_long) }

    it 'should be always active' do
      # a = Symian::WorkShift.new(:all_day_long)
      ws.active_at?(Time.now).must_equal true
      # lambda { a.secs_to_begin_of_shift(Time.now) }.should raise_error(RuntimeError)
    end

    it 'should never finish' do
      ws.secs_to_end_of_shift(Time.now).must_equal Symian::WorkShift::Infinity
    end

    it 'should have an infinite duration' do
      ws.duration().must_equal Symian::WorkShift::Infinity
    end

  end

  describe 'predefined workshifts' do
  # it "should support predefined workshifts" do
  #   a = nil
  #   lambda { a = Symian::WorkShift.new(:predefined, :id => 1) }.should_not raise_error
  # end
  end

  describe 'custom workshifts' do

    describe 'an 8-hour custom workshift started 1 hour ago' do

      let(:ws) do
        now = Time.now
        workshift_start = now.advance(:hours => -1)
        workshift_end   = now.advance(:hours =>  7)
        Symian::WorkShift.new(:custom,
                              :start_time => workshift_start,
                              :end_time   => workshift_end)
      end

      it 'should be active' do
        ws.active_at?(Time.now).must_equal true
      end

      it 'should end in 7 hours' do
        ws.secs_to_end_of_shift(Time.now).must_equal 7.hours
      end

    end

  end

end
