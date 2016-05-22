require 'rspec'
require './khm_solution'

describe CallCounter do
  let(:output_text_file) { 'tmp/test_output.txt' }

  before :each do
    File.delete(output_text_file) if File.exist?(output_text_file)
  end

  describe '.hi' do
    it 'puts Hello World on the command line' do
      system "ruby -r ./khm_solution.rb -e CallCounter.hi > #{output_text_file}"
      expect(output_to_string).to include "Hello world!\n"
    end
  end

  describe '.target_method' do
    it 'returns the method specified in COUNT_CALLS_TO if valid' do
      valid_method = 'String#size'
      ENV['COUNT_CALLS_TO'] = valid_method
      expect(CallCounter.target_method).to eql valid_method
    end

    it 'returns an error if COUNT_CALLS_TO is not valid'
  end

  describe '#wrap_method_with_counter' do
    it 'wraps an instance method with a counter, no effect on method result' do
      counter = CallCounter.new
      counter.wrap_method_with_counter('String#size')
      9.times { 'test'.size }
      expect('test'.size).to equal 4 # rubocop:disable Performance/FixedSize
      expect(counter.count).to equal 10
    end

    it 'wraps an instance method that takes arguments' do
      counter = CallCounter.new
      counter.wrap_method_with_counter('Array#join')
      # rubocop:disable Style/WordArray
      expect(['first', 'second'].join(',')).to eq('first,second')
      expect(['third', 'fourth'].join('.')).to eq('third.fourth')
      # rubocop:enable Style/WordArray
      expect(counter.count).to equal 2
    end

    it 'wraps an instance method that takes a block argument' do
      counter = CallCounter.new
      counter.wrap_method_with_counter('Array#map!')
      # rubocop:disable Style/WordArray
      a = ['a', 'b', 'c', 'd']
      a.map! { |x| x + '!' }
      expect(a).to eq(['a!', 'b!', 'c!', 'd!'])
      # rubocop:enable Style/WordArray
      expect(counter.count).to equal 1
    end
  end
end

def output_to_string
  File.open(output_text_file).read
end
