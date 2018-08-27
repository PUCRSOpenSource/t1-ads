require 'algorithms'
include Containers


class LinearCongruential
  attr_reader :seed

  def initialize(seed)
    @seed = @r = seed
  end

  # range is 0 to 2147483647
  def rand
    @r = (1103515245 * @r + 12345) & 0x7fff_ffff
  end
end

class Queue

  attr_reader :server_count, :size, :client_count

  def initialize(server_count, size)
    @server_count = server_count
    @size = size
    @client_count = 0
  end

  def increment
    @client_count = client_count + 1 if @client_count < @size
  end

  def decrement
    @client_count = client_count - 1 if @client_count > 0
  end

  def to_s
    "Queue\n" +
    "server_count: #{@server_count}\n" +
    "size: #{@size}\n" +
    "client_count: #{@client_count}"
  end

end

class Simulation

  def initialize(server_count, size)
    @queue = Queue.new(server_count, size)
    @statistics = {}
    size.times { | i | @statistics[i] = 0 }
  end

  def to_s
    @queue.to_s +
    "\n" +
    @statistics.to_s
  end

  def run

  end

end


if __FILE__ == $0
  puts Simulation.new(1, 3).to_s
  a = PriorityQueue.new {|x,y| (x <=> y) == -1}
  a.push "Matthias", 2
  a.push "Marina", 1
  puts a.pop
  lcg = LinearCongruential.new(1)
  puts (1..5).map {lcg.rand}
end

