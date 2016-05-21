# rubocop:disable Style/BeginBlock
BEGIN { puts 'krystan begin' }

class KHMSolution
  def self.hi
    puts 'Hello world!'
  end

  def self.target_method
    ENV['COUNT_CALLS_TO']
  end
end

at_exit { puts 'krystan end' }
