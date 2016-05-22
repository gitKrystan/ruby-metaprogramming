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
    it 'returns a hash of method attributes if COUNT_CALLS_TO is valid' do
      valid_method = 'String#size'
      ENV['COUNT_CALLS_TO'] = valid_method
      expected_result = {
        klass: Object.const_get('String'),
        method_symbol: :size,
        method_type: 'instance'
      }
      expect(CallCounter.target_method).to eq expected_result
    end

    it 'returns an error if COUNT_CALLS_TO is not valid'
  end

  describe '#wrap_method_with_counter' do
    let(:counter) { CallCounter.new }

    it 'wraps an instance method with a counter, no effect on method result' do
      ENV['COUNT_CALLS_TO'] = 'String#size'
      counter.wrap_method_with_counter
      9.times { 'test'.size }
      expect('test'.size).to equal 4 # rubocop:disable Performance/FixedSize
      expect(counter.count).to equal 10
    end

    it 'wraps an instance method that takes arguments' do
      ENV['COUNT_CALLS_TO'] = 'Array#join'
      counter.wrap_method_with_counter
      # rubocop:disable Style/WordArray
      expect(['first', 'second'].join(',')).to eq('first,second')
      expect(['third', 'fourth'].join('.')).to eq('third.fourth')
      # rubocop:enable Style/WordArray
      expect(counter.count).to equal 2
    end

    it 'wraps an instance method that takes a block argument' do
      ENV['COUNT_CALLS_TO'] = 'Array#map!'
      counter.wrap_method_with_counter
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
