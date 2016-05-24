require 'pry' # TODO: remove pry

class CallCounter
  @counter = 0

  class << self
    attr_reader :counter, :method_type, :method_class, :method_symbol
  end

  def self.increment_count
    @counter += 1
  end

  def self.reset_count
    @counter = 0
  end

  # Sets class instance variables based on the
  # environment variable COUNT_CALLS_TO.
  def self.identify_target_method
    identify_method_type(ENV['COUNT_CALLS_TO'])
    identify_method_symbol
    identify_method_class
  end

  def self.identify_method_type(method_string)
    if method_string.include? '#'
      @method_array = method_string.split('#')
      @method_type = 'instance'
    elsif method_string.include? '.'
      @method_array = method_string.split('.')
      @method_type = 'class'
    else
      raise 'COUNT_CALLS_TO environmental variable does not match'\
        ' Class#instance_method or Class.class_method format'
    end
  end

  def self.identify_method_symbol
    @method_symbol = @method_array[1].to_sym
  end

  def self.identify_method_class
    if Object.const_defined?(@method_array[0])
      @method_class = Object.const_get(@method_array[0])
    else
      @method_class = Object.const_set(@method_array[0],
                                       new_class_with_include_hook)
    end
  end

  def self.new_class_with_include_hook
    Class.new do
      def self.include(*modules)
        modules.each do |mod|
          CallCounter.wrap_module_method_with_counter(mod)
        end
        super
      end
    end
  end

  def self.wrap_method_with_counter
    identify_target_method
    if @method_type == 'instance'
      wrap_instance_method_with_counter(@method_class, @method_symbol)
    elsif @method_type == 'class'
      wrap_class_method_with_counter(@method_class, @method_symbol)
    end
  end

  def self.wrap_instance_method_with_counter(klass, method_symbol)
    if klass.send(:instance_methods).include?(method_symbol)
      add_counter_to_instance_method(klass, method_symbol)
    else
      add_counter_to_future_instance_method(klass, method_symbol)
    end
  end

  def self.add_counter_to_instance_method(klass, method_symbol)
    klass.send(:alias_method, :method_to_count, method_symbol)
    klass.send(:define_method, method_symbol) do |*args, &block|
      CallCounter.increment_count if self.class == CallCounter.method_class
      method_to_count(*args, &block)
    end
  end

  def self.add_counter_to_future_instance_method(klass, method_symbol)
    klass.send(:define_singleton_method, :method_added) do |method_name|
      if method_name == method_symbol
        CallCounter.reset_method_added(klass)
        CallCounter.add_counter_to_instance_method(klass, method_symbol)
      end
    end
  end

  def self.reset_method_added(klass)
    klass.send(:define_singleton_method, :method_added) { |method| }
  end

  def self.wrap_class_method_with_counter(klass, method_symbol)
    if klass.send(:methods).include?(method_symbol)
      add_counter_to_class_method(klass, method_symbol)
    else
      add_counter_to_future_class_method(klass, method_symbol)
    end
  end

  def self.add_counter_to_class_method(klass, method_symbol)
    klass.singleton_class.send(:alias_method, :method_to_count, method_symbol)
    klass.send(:define_singleton_method, method_symbol) do |*args, &block|
      CallCounter.increment_count
      klass.send(:method_to_count, *args, &block)
    end
  end

  def self.add_counter_to_future_class_method(klass, target_method)
    klass.send(:define_singleton_method, :singleton_method_added) do |method|
      if method == target_method
        CallCounter.reset_singleton_method_added(klass)
        CallCounter.add_counter_to_class_method(klass, target_method)
      end
    end
  end

  def self.reset_singleton_method_added(klass)
    klass.send(:define_singleton_method, :singleton_method_added) { |method| }
  end

  def self.wrap_module_method_with_counter(mod)
    wrap_instance_method_with_counter(mod, @method_symbol)
  end
end

CallCounter.wrap_method_with_counter if ENV['COUNT_CALLS_TO']

at_exit do
  puts "#{ENV['COUNT_CALLS_TO']} called #{CallCounter.counter} times"
end
