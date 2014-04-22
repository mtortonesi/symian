require 'test_helper'

require 'symian/reference_configuration'


describe Symian::Configuration do

  context 'simulation-related parameters' do

    it 'should correctly load simulation start' do
      with_reference_config do |conf|
        conf.start_time.must_equal START_TIME
      end
    end

    it 'should correctly load simulation duration' do
      with_reference_config do |conf|
        conf.duration.must_equal DURATION
      end
    end

    it 'should correctly load simulation end time' do
      with_reference_config do |conf|
        conf.end_time.must_equal START_TIME + DURATION
      end
    end

    it 'should correctly load warmup phase duration' do
      with_reference_config do |conf|
        conf.warmup_duration.must_equal WARMUP_DURATION
      end
    end

    it 'should initialize incident generation' do
      with_reference_config do |conf|
        conf.incident_generation.must_equal INCIDENT_GENERATION
      end
    end

    it 'should initialize support groups' do
      with_reference_config do |conf|
        conf.support_groups.must_equal SUPPORT_GROUPS
      end
    end

    it 'should initialize transition matrix' do
      with_reference_config do |conf|
        conf.transition_matrix.must_equal TRANSITION_MATRIX
      end
    end

  end

end
