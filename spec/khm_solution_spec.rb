require 'rspec'
require './khm_solution'

describe KHMSolution do
  describe '#hi' do
    it 'puts Hello World on the command line' do
      system 'ruby -r ./khm_solution.rb -e KHMSolution.hi > tmp/output.txt'
      output = File.open('tmp/output.txt').read
      expect(output).to eql "Hello world!\n"
    end
  end
end
