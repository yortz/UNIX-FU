require 'socket'

class SimpleServer
  def initialize(port=8080)
    #socket(2)
    @listener = Socket.new(:INET, :STREAM)

    #bind(2)
    @listener.bind(Socket.sockaddr_in(port, '0.0.0.0'))

    #listen(2)
    @listener.listen(512)
  end

  def start
    loop do
      connection, _ = @listener.accept
      connection.write(connection.read)
      connection.close
    end
  end
end


# $:> ruby simple-server.rb
# $:> echo foo | nc localhost 8080

server = SimpleServer.new
server.start
