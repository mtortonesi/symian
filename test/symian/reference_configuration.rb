require 'symian/configuration'

START_TIME      = Time.utc(1978, 'Aug', 12, 14, 30, 0)
DURATION        = 1.minute
WARMUP_DURATION = 10.seconds
SIMULATION_CHARACTERIZATION = <<END
  start_time Time.utc(1978, 'Aug', 12, 14, 30, 0)
  duration 1.minute
  warmup_duration 10.seconds
END

INCIDENT_GENERATION_CHARACTERIZATION = <<END
incident_generation \
  :type   => :sequential_random_variable,
  :source => {
    :first_value => Time.utc(1978, 'Aug', 12, 14, 31, 0),
    :distribution => :exponential,
    :mean => 1/0.0015
  }
END

SUPPORT_GROUPS_CHARACTERIZATION = <<END
support_groups \
  'SG1' => { :work_time => { :distribution => :exponential, :mean => 227370 },
             :operators => { :number => 1, :workshift => :all_day_long } },
  'SG2' => { :work_time => { :distribution => :exponential, :mean => 1980 },
             :operators => { :number => 1, :workshift => :all_day_long } },
  'SG3' => { :work_time => { :distribution => :exponential, :mean => 360 },
             :operators => { :number => 1, :workshift => :all_day_long } }
END

TRANSITION_MATRIX_CHARACTERIZATION = <<END
transition_matrix %q{
  From/To,SG1,SG2,SG3,Out
  In,25,50,25,0
  SG1,0,10,70,20
  SG2,5,0,45,45
  SG3,10,20,0,70
}
END

COST_ANALYSIS_CHARACTERIZATION = <<END
cost_analysis \
  :operations => [
    { :sg_name => 'SG1', :operator_salary => 30_000 },
    { :sg_name => 'SG2', :operator_salary => 40_000 },
    { :sg_name => 'SG3', :operator_salary => 25_000 },
  ],
  :contracting => lambda { |kpis|
    kpis[:mttr] > 9000 ? 1500 : 0.0
  },
  :drift => lambda { |kpis|
    target = 500
    delta = target - kpis[:micd]
    if delta > 0.0
      1500.0 * (2.0 / Math::PI) * Math::atan(10.0 * delta / target)
    else
      0.0
    end
  }
END


# this is the whole reference configuration
# (useful for spec'ing configuration.rb)
REFERENCE_CONFIGURATION =
  SIMULATION_CHARACTERIZATION +
  INCIDENT_GENERATION_CHARACTERIZATION +
  SUPPORT_GROUPS_CHARACTERIZATION +
  TRANSITION_MATRIX_CHARACTERIZATION +
  COST_ANALYSIS_CHARACTERIZATION

evaluator = Object.new
evaluator.extend Symian::Configurable
evaluator.instance_eval(REFERENCE_CONFIGURATION)

# these are preprocessed portions of the reference configuration
# (useful for spec'ing everything else)
INCIDENT_GENERATION = evaluator.incident_generation
SUPPORT_GROUPS      = evaluator.support_groups
TRANSITION_MATRIX   = evaluator.transition_matrix
COST_ANALYSIS       = evaluator.cost_analysis


def with_reference_config(opts={})
  # create temporary file with reference configuration
  tf = Tempfile.open('REFERENCE_CONFIGURATION')
  begin
    tf.write(REFERENCE_CONFIGURATION)
    tf.close

    # create a configuration object from the reference configuration file
    conf = Symian::Configuration.load_from_file(tf.path)

    # apply any change from the opts parameter and validate the modified configuration
    opts.each do |k,v|
      conf.send(k, v)
    end
    conf.validate

    # pass the configuration object to the block
    yield conf
  ensure
    # delete temporary file
    tf.delete
  end
end
