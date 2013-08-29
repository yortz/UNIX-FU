require 'socket'

class MiniUnicorn
  NUM_WORKERS = 4
  def initialize(port=8080)
    #socket(2)
    @listener = Socket.new(:INET, :STREAM)

    #bind(2)
    @listener.bind(Socket.sockaddr_in(port, '0.0.0.0'))

    #listen(2)
    @listener.listen(512)
  end

  def start
    NUM_WORKERS.times do
      fork {
        worker_loop
      }
    end
  end

  def worker_loop
    loop do
      connection, _ = @listener.accept
      connection.write(connection.read)
      connection.close
    end
  end
end


# $:> ruby mini-unicorn.rb
# $:> echo foo | nc localhost 8080

server = MiniUnicorn.new
server.start
