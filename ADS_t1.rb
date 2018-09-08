require 'yaml'



class LinearCongruential
  attr_reader :seed

  def initialize(seed)
    @seed = @r = seed
  end

  def rand
    @r = (25173 * @r + 13849) % 32768
    @r / 32768.to_f
  end

  def rand_between(range)
    first = range.first
    last = range.last
    (last - first) * rand + first
  end
end



class Queue

  attr_reader :id, :servers, :capacity, :client_count, :input, :output, :statistics

  def initialize(config)
    @id = config[:id]
    @servers = config[:servers]
    @capacity = config[:capacity]
    @input = config[:min_arrival]..config[:max_arrival]
    @output = config[:min_service]..config[:max_service]
    @client_count = 0
    @statistics = Hash.new
    capacity.times { |i| @statistics[i] = 0 }
    @statistics[capacity] = 0
  end

  def increment
    @client_count = client_count + 1 if @client_count < @capacity
  end

  def decrement
    @client_count = client_count - 1 if @client_count > 0
  end

  def to_s
    "Queue #{@id}\n" +
    "server_count: #{@server_count}\n" +
    "capacity: #{@capacity}\n" +
    "client_count: #{@client_count}\n" +
    "Input tax #{@input}\n" +
    "Output tax #{@output}\n" +
    "Statistics #{@statistics.to_s}"
  end

end



class Simulation

  Event = Struct.new(:type, :queue_id, :time)

  def initialize(config_file_path)
    @queues = Hash.new
    @topology = Hash.new
    @events = Array.new
    @statistics = Hash.new
    @random = nil
    @duracao = 0
    @previous_event_time = 0
    setup(config_file_path)
  end

  def run
    while true
      evento = proximo_evento
      break if evento.time > @duracao
      puts "#{evento.type} #{evento.time}"
      case evento.type
      when :arrival
        arrival(evento.queue_id, evento.time)
      when :departure
        departure(evento.queue_id, evento.time)
      end
      @previous_event_time = evento.time
    end
  end

  def insere_evento(tipo, id_fila, tempo)
    event = Event.new(tipo, id_fila, tempo)
    @events << event
  end

  def proximo_evento
    pos_proximo_evento = 0
    menor_tempo = Float::MAX
    @events.each_with_index do |evento, index|
      if menor_tempo > evento.time
        menor_tempo = evento.time
        pos_proximo_evento = index
      end
    end
    @events.slice!(pos_proximo_evento)
  end


  def to_s
    @queues.each { |q| q.to_s }.to_s + "\n" +
    @topology.to_s + "\n" +
    @events.to_s
  end

  def setup(config_file_path)
    config = YAML.load_file(config_file_path)
    @duracao = config[:duration]
    config[:queues].each { |q| @queues[q[:id]] = Queue.new(q) }
    config[:topology].each { |e| @topology[e[:from]] = @queues[e[:to]] } unless config[:topology].nil?
    config[:arrivals].each do |e|
      type = :arrival
      queue_id = e[:queue_id]
      time = e[:time]
      event = Event.new(type, queue_id, time)
      @events << event
    end
    @random = LinearCongruential.new(config[:seed])
  end

  def arrival(id_fila, tempo)
    contabiliza_tempo(tempo)
    fila = @queues[id_fila]
    if fila.client_count < fila.capacity
      fila.increment
      if fila.client_count <= fila.servers
       agenda(:departure, fila, tempo)
      end
    end
   agenda(:arrival, fila, tempo)
  end

  def passagem(id_fila, tempo)

  end


  def departure(id_fila, tempo)
    contabiliza_tempo(tempo)
    fila = @queues[id_fila]
    fila.decrement
    agenda(:departure, fila, tempo) if fila.client_count >= fila.servers
  end


  def contabiliza_tempo(tempo)
    @queues.each do |fila_id, fila|
      current_time = fila.statistics[fila.client_count]
      interval = tempo - @previous_event_time
      new_time = current_time + interval
      fila.statistics[fila.client_count] = new_time
    end
  end

  def agenda(tipo, fila, tempo)
    if tipo == :departure
      tipo = :passagem unless @topology[fila.id].nil?
      taxa = fila.output
    else
      taxa = fila.input
    end
    tempo = tempo + ((taxa.last - taxa.first) * @random.rand_between(taxa) + taxa.first)
    insere_evento(tipo, fila.id, tempo)
  end



  private :arrival, :departure, :setup

end



if __FILE__ == $0
  sim = Simulation.new(ARGV[0])
  sim.run
  puts sim.to_s
end

