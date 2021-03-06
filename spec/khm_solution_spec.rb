require 'rspec'
require './khm_solution'
require 'base64'

class TestClass
  def self.class_method
    'I am a class method'
  end
end

module TestModule
  class TestClassTwo
    def self.class_method
      'I am a class method'
    end

    def instance_method
      'I am an instance method'
    end
  end
end

describe CallCounter do
  before :each do
    CallCounter.reset_count
  end

  describe 'CLI' do
    let(:output_text_file) { 'tmp/test_output.txt' }

    before :each do
      File.delete(output_text_file) if File.exist?(output_text_file)
    end

    it 'puts the number of times a given existing method is called' do
      system "COUNT_CALLS_TO='String#size' ruby -r ./khm_solution.rb"\
        " -e '(1..100).each{|i| i.to_s.size if i.odd? }' > #{output_text_file}"
      expect(output_to_string).to include 'String#size called 50 times'
    end

    it 'puts the number of times a newly defined instance method is called' do
      system "COUNT_CALLS_TO='A#foo' ruby -r ./khm_solution.rb"\
        " -e 'class A; def foo; puts 123; end; end;"\
        " 10.times{A.new.foo}' > #{output_text_file}"
      expect(output_to_string).to include '123'
      expect(output_to_string).to include 'A#foo called 10 times'
    end

    it 'puts the number of times a given instance method is called'\
       ' before the module that defines that method is included' do
      system "COUNT_CALLS_TO='B#foo' ruby -r ./khm_solution.rb"\
        " -e 'module A; def foo; puts 789; end; end; class B; include A; end;"\
        " 3.times{B.new.foo}' > #{output_text_file}"
      expect(output_to_string).to include '789'
      expect(output_to_string).to include 'B#foo called 3 times'
    end

    it 'puts the number of times a given method is called'\
       ' before the module that defines that method is included'\
       'without counting the times another class calls that module method' do
      system "COUNT_CALLS_TO='B#foo' ruby -r ./khm_solution.rb"\
        " -e 'module C; end; module A; def foo; puts 1010; end; end;"\
        ' class B; include(A, C); end; class D; include(A, C); end;'\
        " 2.times{B.new.foo; D.new.foo}' > #{output_text_file}"
      expect(output_to_string).to include '1010'
      expect(output_to_string).to include 'B#foo called 2 times'
    end

    it 'puts the number of times a newly defined class method is called' do
      system "COUNT_CALLS_TO='A.foo' ruby -r ./khm_solution.rb"\
        " -e 'class A; def self.foo; puts 456; end; end;"\
        " 5.times{A.foo}' > #{output_text_file}"
      expect(output_to_string).to include '456'
      expect(output_to_string).to include 'A.foo called 5 times'
    end
  end

  describe '.identify_target_method' do
    it 'returns a hash of method attributes if COUNT_CALLS_TO is valid' do
      ENV['COUNT_CALLS_TO'] = 'String#size'
      CallCounter.identify_target_method
      expect(CallCounter.method_type).to eq 'instance'
      expect(CallCounter.method_class).to eq Object.const_get('String')
      expect(CallCounter.method_symbol).to eq :size
    end
  end

  describe '#wrap_method_with_counter' do
    it 'wraps an instance method with a counter, no effect on method result' do
      ENV['COUNT_CALLS_TO'] = 'String#size'
      CallCounter.wrap_method_with_counter
      9.times { 'test'.size }
      expect('test'.size).to equal 4 # rubocop:disable Performance/FixedSize
      expect(CallCounter.counter).to equal 10
    end

    it 'wraps an instance method that takes arguments' do
      ENV['COUNT_CALLS_TO'] = 'Array#join'
      CallCounter.wrap_method_with_counter
      # rubocop:disable Style/WordArray
      expect(['first', 'second'].join(',')).to eq('first,second')
      expect(['third', 'fourth'].join('.')).to eq('third.fourth')
      # rubocop:enable Style/WordArray
      expect(CallCounter.counter).to equal 2
    end

    it 'wraps an instance method that takes a block argument' do
      ENV['COUNT_CALLS_TO'] = 'Array#map!'
      CallCounter.wrap_method_with_counter
      # rubocop:disable Style/WordArray
      a = ['a', 'b', 'c', 'd']
      a.map! { |x| x + '!' }
      expect(a).to eq(['a!', 'b!', 'c!', 'd!'])
      # rubocop:enable Style/WordArray
      expect(CallCounter.counter).to equal 1
    end

    it 'wraps a class method with no effect on method result' do
      ENV['COUNT_CALLS_TO'] = 'TestClass.class_method'
      CallCounter.wrap_method_with_counter
      expect(TestClass.class_method).to eq 'I am a class method'
      expect(CallCounter.counter).to eq 1
    end

    it 'wraps a class method that takes arguments' do
      ENV['COUNT_CALLS_TO'] = 'Array.try_convert'
      CallCounter.wrap_method_with_counter
      expect(Array.try_convert([1])).to eq [1]
      expect(Array.try_convert('1')).to be_nil
      expect(CallCounter.counter).to eq 2
    end

    it 'wraps a namespaced instance method' do
      ENV['COUNT_CALLS_TO'] = 'TestModule::TestClassTwo#instance_method'
      CallCounter.wrap_method_with_counter
      test_object = TestModule::TestClassTwo.new
      4.times { test_object.instance_method }
      expect(test_object.instance_method).to eq 'I am an instance method'
      expect(CallCounter.counter).to eq 5
    end

    it 'wraps a namespaced class method' do
      ENV['COUNT_CALLS_TO'] = 'TestModule::TestClassTwo.class_method'
      CallCounter.wrap_method_with_counter
      3.times { TestModule::TestClassTwo.class_method }
      expect(TestModule::TestClassTwo.class_method).to eq 'I am a class method'
      expect(CallCounter.counter).to eq 4
    end

    it 'wraps a function from a module' do
      ENV['COUNT_CALLS_TO'] = 'Base64.encode64'
      CallCounter.wrap_method_with_counter
      2.times { Base64.encode64('Test string') }
      expect(Base64.encode64('Test string')).to eq "VGVzdCBzdHJpbmc=\n"
      expect(CallCounter.counter).to eq 3
    end
  end
end

def output_to_string
  File.open(output_text_file).read
end
