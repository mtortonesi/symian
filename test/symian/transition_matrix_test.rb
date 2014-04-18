require 'test_helper'

require 'symian/transition_matrix'


describe Symian::TransitionMatrix do

  let(:test_matrix) do
    # <<-END.gsub(/^\s+/, '') # remove leading spaces
    #   From/To,SG01,SG02,SG03,Out
    #   In,1,2,3,4
    #   SG01,0,2,0,2
    #   SG02,10,0,50,40
    #   SG03,0,3,0,3
    # END
    "From/To,SG01,SG02,SG03,Out\n" \
    "In,1,2,3,4\n"                 \
    "SG01,0,2,0,2\n"               \
    "SG02,10,0,50,40\n"            \
    "SG03,0,3,0,3"
  end

  it 'should correctly load and process an escalation matrix' do
    tm = Symian::TransitionMatrix.new(test_matrix)
    tm.transition_probabilities.must_equal({
      'In' => [
        { :sg_name => 'SG01', :escalations =>  1, :probability => 0.1 },
        { :sg_name => 'SG02', :escalations =>  2, :probability => 0.3 },
        { :sg_name => 'SG03', :escalations =>  3, :probability => 0.6 },
        { :sg_name =>  'Out', :escalations =>  4, :probability => 1.0 }
      ],
      'SG01' => [
        { :sg_name => 'SG02', :escalations =>  2, :probability => 0.5 },
        { :sg_name =>  'Out', :escalations =>  2, :probability => 1.0 }
      ],
      'SG02' => [
        { :sg_name => 'SG01', :escalations => 10, :probability => 0.1 },
        { :sg_name => 'SG03', :escalations => 50, :probability => 0.6 },
        { :sg_name =>  'Out', :escalations => 40, :probability => 1.0 }
      ],
      'SG03' => [
        { :sg_name => 'SG02', :escalations =>  3, :probability => 0.5 },
        { :sg_name =>  'Out', :escalations =>  3, :probability => 1.0 }
      ],
    })
  end

  it 'should correctly print the matrix' do
    tm = Symian::TransitionMatrix.new(test_matrix)
    tm.to_s.must_equal test_matrix.chomp
  end

  it 'should correctly escalate incidents between existing and connected groups' do
    tm = Symian::TransitionMatrix.new(test_matrix)
    1.upto(30) do
      [ 'SG01', 'SG03', 'Out' ].must_include tm.escalation('SG02')
    end
  end

  it 'should not escalate incidents from unexisting groups' do
    tm = Symian::TransitionMatrix.new(test_matrix)
    lambda { tm.escalation('UnexistingSG') }.must_raise ArgumentError
  end

  # it 'should not escalate incidents to unconnected groups' do
  # end

  it 'should correctly merge support groups' do
    tm = Symian::TransitionMatrix.new(test_matrix)
    tm.merge('SG01', 'SG03')
    tm.transition_probabilities.must_equal({
      'In' => [
        { :sg_name => 'SG02',                   :escalations => 2, :probability => 0.2 },
        { :sg_name => 'Out',                    :escalations => 4, :probability => 0.6 },
        { :sg_name => 'Merge_of_SG01_and_SG03', :escalations => 4, :probability => 1.0 }
      ],
      'SG02' => [
        { :sg_name => 'Out',                    :escalations => 40, :probability => 0.4 },
        { :sg_name => 'Merge_of_SG01_and_SG03', :escalations => 60, :probability => 1.0 }
      ],
      'Merge_of_SG01_and_SG03' => [
        { :sg_name => 'SG02',                   :escalations => 5,  :probability => 0.5 },
        { :sg_name => 'Out',                    :escalations => 5,  :probability => 1.0 }
      ]
    })
  end

end
