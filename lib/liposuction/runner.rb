require 'eventmachine'

module Liposuction
  
  class ApplicationProxy < EventMachine::Connection
    
    attr_accessor :application, :proxy
    
    def receive_data(data)
      if @body
        puts "appending to body #{@body.inspect}" 
        @body << data
      else
        puts "setting body #{@body.inspect}" 
        @body = data
      end
      puts "body is now #{@body.inspect}" 
      
      command_response = proxy.process(@body)
      puts "state is #{command_response.state}"
      
      response = case command_response.state
      when :incomplete
        nil
      when :complete
        application.call(command_response.command)
      when :abort, :uncognized
        proxy.response_for_state(command_response.state)
      end
      send_data(response.last) if response
      
    end
    
  end
    
  
  class Runner
    
    attr_reader :proxy, :application
    
    def initialize(proxy, application)
      @proxy = proxy
      @application = application
    end
    
    def run(port, address = '0.0.0.0')
      puts "Starting the proxy! #{proxy.class.name.to_s} #{address} #{port}"
      pid = EM.fork_reactor do
        trap("INT") { EM.stop; puts "\nmoooooooo ya later"; exit(0)}
        EM.run do
          EM.start_server(address, port, ApplicationProxy) do |c|
            c.application = application
            c.proxy = proxy
          end
        end
      end

      #if @options[:daemonize]
      #  File.open(options[:pid], 'w') {|f| f << pid}
      #  Process.detach(pid)
      #else
        trap("INT") { }
        Process.wait(pid)
      #end

      #pid
    end
    
  end
  
end