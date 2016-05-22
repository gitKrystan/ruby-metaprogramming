require 'pry'

# rubocop:disable Style/BeginBlock
BEGIN {
  class CallCounter
    def initialize
      @counter = 0
    end

    def self.target_method
      generate_method_hash(ENV['COUNT_CALLS_TO'])
    end

    def self.generate_method_hash(method_string)
      if method_string.include? '#'
        method_array = method_string.split('#')
        method_hash = { method_type: 'instance' }
      elsif method_string.include? '.'
        method_array = method_string.split('.')
        method_hash = { method_type: 'class' }
      end
      method_hash[:klass] = Object.const_get(method_array[0])
      method_hash[:method_symbol] = method_array[1].to_sym
      method_hash
    end

    def count
      @counter
    end

    def increment_count
      @counter += 1
    end

    def wrap_method_with_counter
      counter = self
      method_hash = CallCounter.target_method
      klass = method_hash[:klass]
      method_symbol = method_hash[:method_symbol]
      klass.send(:alias_method, :method_to_count, method_symbol)
      klass.send(:define_method, method_symbol) do |*args, &block|
        counter.increment_count
        method_to_count(*args, &block)
      end
    end
  end
}

class CallCounter
  def self.hi
    puts 'Hello world!'
  end
end

at_exit { puts 'krystan end' }
