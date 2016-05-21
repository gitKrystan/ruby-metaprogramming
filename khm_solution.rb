# rubocop:disable Style/BeginBlock
BEGIN {
  class KHMSolution
    def self.target_method
      ENV['COUNT_CALLS_TO']
    end
  end
}

class KHMSolution
  def self.hi
    puts 'Hello world!'
  end
end

at_exit { puts 'krystan end' }
