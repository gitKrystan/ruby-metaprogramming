require 'rspec'
require './khm_solution'

describe KHMSolutionInputs do
  describe '#target_method' do
    it 'returns the method specified in COUNT_CALLS_TO if valid' do
      valid_method = 'String#size'
      ENV['COUNT_CALLS_TO'] = valid_method
      expect(KHMSolutionInputs.target_method).to eql valid_method
    end

    it 'returns an error if COUNT_CALLS_TO is not valid'
  end
end

describe KHMSolution do
  let(:output_text_file) { 'tmp/test_output.txt' }

  before :each do
    File.delete(output_text_file) if File.exist?(output_text_file)
  end

  describe '#hi' do
    it 'puts Hello World on the command line' do
      system "ruby -r ./khm_solution.rb -e KHMSolution.hi > #{output_text_file}"
      expect(output_to_string).to include "Hello world!\n"
    end
  end
end

def output_to_string
  File.open(output_text_file).read
end
