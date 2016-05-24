require 'pry' # TODO: remove pry

class CallCounter
  @counter = 0
  @method_array = []
  @method_type = nil
  @method_class = nil
  @method_symbol = nil

  class << self
    attr_reader :method_type, :method_class, :method_symbol
  end

  def self.identify_target_method
    add_method_type_to_hash(ENV['COUNT_CALLS_TO'])
    add_method_name_to_hash
    add_class_to_hash
  end

  def self.add_method_type_to_hash(method_string)
    if method_string.include? '#'
      @method_array = method_string.split('#')
      @method_type = 'instance'
    elsif method_string.include? '.'
      @method_array = method_string.split('.')
      @method_type = 'class'
    end
  end

  def self.add_method_name_to_hash
    @method_symbol = @method_array[1].to_sym
  end

  def self.add_class_to_hash
    if Object.const_defined?(@method_array[0])
      @method_class = Object.const_get(@method_array[0])
    else
      @method_class = Object.const_set(@method_array[0], Class.new)
    end
  end

  def self.count
    @counter
  end

  def self.increment_count
    @counter += 1
  end

  def self.reset_count
    @counter = 0
  end

  def self.wrap_method_with_counter
    counter = self
    CallCounter.identify_target_method
    klass = @method_class
    method_symbol = @method_symbol

    if @method_type == 'instance'
      counter.wrap_instance_method_with_counter(klass, method_symbol)
    elsif @method_type == 'class'
      counter.wrap_class_method_with_counter(klass, method_symbol)
    end
  end

  def self.wrap_instance_method_with_counter(klass, method_symbol)
    if klass.send(:instance_methods).include?(method_symbol)
      klass.send(:alias_method, :method_to_count, method_symbol)

      klass.send(:define_method, method_symbol) do |*args, &block|
        CallCounter.increment_count
        method_to_count(*args, &block)
      end
    else
      klass.send(:define_singleton_method, :method_added) do |method_name|
        if method_name == method_symbol
          klass.send(:alias_method, :method_to_count, method_symbol)

          klass.send(:define_singleton_method, :method_added) { |method| }

          klass.send(:define_method, method_symbol) do |*args, &block|
            CallCounter.increment_count
            method_to_count(*args, &block)
          end
        end
      end
    end
  end

  def self.wrap_class_method_with_counter(klass, method_symbol)
    if klass.send(:methods).include?(method_symbol)
      klass.singleton_class.send(:alias_method, :method_to_count, method_symbol)
    else
      klass.send(:define_singleton_method, :method_to_count) do |*args, &block|
      end
    end

    klass.send(:define_singleton_method, method_symbol) do |*args, &block|
      CallCounter.increment_count
      klass.send(:method_to_count, *args, &block)
    end
  end
end

CallCounter.wrap_method_with_counter if ENV['COUNT_CALLS_TO']

at_exit do
  puts "#{ENV['COUNT_CALLS_TO']} called #{CallCounter.count} times"
end
