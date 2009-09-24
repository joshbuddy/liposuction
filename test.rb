require 'lib/liposuction'

class CommandLogger
  
  def initialize(app)
    @app = app
  end
  
  def call(command)
    if command.respond_to?(:bytes)
      puts "command has #{command.bytes} bytes to process..."
    end
    response = @app.call(command)
    if response.first == :responded
      puts "everything went okay!"
    end
    response
  end
  
end

class HelpHandler

  def initialize(app)
    @app = app
  end
  
  def call(command)
    if command.command_type == :help
      [
        :responded,
        command,
        <<-HELP
Memcache Help
=============
set <key> <something> <something> 
your value here

get <key> ...
        
and so forth        
        HELP
        ]
    else
      @app.call(command)
    end
  end

end

class MemcacheProxyWithHelp < Liposuction::MemcacheProxy

  class HelpCommand < Liposuction::Proxy::Command
    name_and_path :help, 'help'
  end
  command :HelpCommand
  
end


proxy = MemcacheProxyWithHelp.new
builder = proxy.build do
  use CommandLogger
  use HelpHandler
  forward '127.0.0.1', 11211
end

runner = Liposuction::Runner.new(proxy, builder.to_app)

runner.run(11210)
