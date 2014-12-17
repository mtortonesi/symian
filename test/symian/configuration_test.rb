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

  context 'cloning mechanism' do
    it 'should correctly clone w/ other ops' do
      with_reference_config do |conf|
        new_ops = (1..conf.support_groups.size).to_a
        new_conf = conf.reallocate_ops_and_clone(new_ops)
        new_conf.support_groups.zip(new_ops) do |(k,v),num_ops|
          v[:operators][:number].must_equal num_ops
        end
      end
    end
  end

end
