require 'socket'
require 'rack'
require 'rack/builder'
require 'http_tools'

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
    load_app
    NUM_WORKERS.times do |num|
      fork {
        $PROGRAM_NAME = "MiniUnicorn Worker #{num}"
        worker_loop
      }
    end
    sleep
  end

  $PROGRAM_NAME = "MiniUnicorn Master"


  def load_app
    rackup_file = 'config.ru'
    @app, options = Rack::Builder.parse_file(rackup_file)
  end

  def worker_loop
    loop do
      connection, _ = @listener.accept

      # read = lazy read
      # it blocks until it gets EOF
      #
      # readpartial = greedy read

      raw_request = connection.readpartial(4096)

      parser = HTTPTools::Parser.new
      parser.on(:finish) do
        env = parser.env.merge!("rack.multiprocess" => true)
        status, header, body = @app.call(env)

        header["Connection"] = "close"
        connection.write HTTPTools::Builder.response(status, header)
        body.each {|chunk| connection.write chunk }
        body.close if body.respond_to?(:close)
      end

      parser << raw_request
      connection.close
    end
  end
end


# $:> ruby mini-unicorn.rb
# $:> echo foo | nc localhost 8080

server = MiniUnicorn.new
server.start
