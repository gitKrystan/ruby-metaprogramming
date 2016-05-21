class KHMSolution
  def self.hi
    puts 'Hello world!'
  end

  def self.target_method
    ENV['COUNT_CALLS_TO']
  end
end
