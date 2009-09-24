require 'socket'

module Liposuction
  class Proxy
    class Builder
      
      attr_reader :proxy
      
      class Forwarder
        
        attr_reader :host, :port
        
        def initialize(app, host, port)
          @host = host
          @port = port
        end
        
        def call(command)
          begin
            raw_command = command.proxy.build_from_command(command)
            socket = Socket.new(Socket::Constants::AF_INET, Socket::Constants::SOCK_STREAM, 0)
            puts "connecting to port -> #{port.inspect} host -> #{host.inspect}"
            sockaddr = Socket.pack_sockaddr_in(port, host)
            puts "connect"
            socket.connect(sockaddr)
            puts "writing #{raw_command.inspect}"
            socket.write(raw_command)
            socket.flush
            socket.close_write
            data = nil
            while response = socket.read(512)
              data ?
                data << response : data = response
            end
            puts "response: #{data.inspect}"
            [:responded, command, data]
          rescue
            [:not_responded, command, nil]
          end
        end
      end
      
      
      def initialize(proxy, &block)
        @proxy = proxy
        @stack = []
        instance_eval(&block)
      end
      
      def use(class_app, *args)
        @stack << [class_app, *args]
      end
      
      def forward(host, port)
        use Forwarder, host, port
      end
      
      def to_app
        last_app = nil
        @stack.reverse.each do |s|
          last_app = if s.size == 1 && s.first.respond_to?(:call)
            s.first
          else
            s.first.new(last_app, * s[1, s.size - 1])
          end
        end
        last_app
      end
      
    end
  end
end
