require '/Users/joshua/Development/usher/lib/usher'

module Liposuction
  class Proxy
    
    autoload :Builder, File.join(File.dirname(__FILE__), 'proxy', 'builder')

    class Command
      attr_accessor :command_type, :payload, :significant_keys, :raw_command, :data, :proxy
      
      def self.name_and_path(name, path)
        const_set(:Name, name)
        const_set(:Path, path)
      end
      
      def self.name
        const_get(:Name)
      end

      def self.path
        const_get(:Path)
      end
      
      def to_hash
        Hash[significant_keys.collect{|k| self.send(k) ? [k, self.send(k)] : nil}.compact]
      end

      def init
      end

      def complete?
        true
      end

      def finalize!
        data.slice!(0, raw_command.size + proxy.delimiter.size)
      end
      
    end
    
    def self.inherited(subclass)
      subclass.class_eval("
        @@usher = Usher.new(:delimiters => [' '], :generator => Usher::Util::Generators::Generic.new, :collapse_multiple_delimiters => true)
        
        def self.router
          @@usher
        end
        
        def router
          self.class.router
        end
      ")
    end
    
    def self.command(*klasses)
      klasses.each do |klass_sym|
        klass = const_get(klass_sym)
        route = router.add_named_route(klass.name, klass.path).to(klass)
        
        route.grapher.significant_keys.each do |k|
          unless klass.method_defined?(k)
            klass.class_eval "
            attr_accessor :#{k}
            ", __FILE__, __LINE__
          end
        end
      end
    end

    attr_accessor :delimiter
    
    def initialize(command_delimiter)
      self.delimiter = command_delimiter
    end
    
    def build(&block)
      Builder.new(self, &block)
    end
    
    ProcessResponse = Struct.new(:state, :command, :exception)
    
    def build_from_command(command)
      response = router.generator.generate(command.command_type, command.to_hash)
      (command.payload ? [response, command.payload] : [response]).inject("") { |m, c|
        m << c << delimiter
      }
    end
    
    def process(data)
      response = ProcessResponse.new(:unrecognized, nil, nil)

      raw_command = data[/([^#{Regexp.escape(delimiter)}]*)#{Regexp.escape(delimiter)}/, 1]
      recognition_response = router.recognize_path(raw_command.gsub(/ +/, ' ').strip)
      
      if recognition_response
        response.state = :complete
        params = Hash[recognition_response.params]
        name = recognition_response.path.route.named
        destination = recognition_response.path.route.destination

        response.command = recognition_response.path.route.destination.new
        response.command.command_type = name
        response.command.proxy = self
        response.command.significant_keys = recognition_response.path.route.grapher.significant_keys
        response.command.raw_command = raw_command
        response.command.data = data
        params.each {|name, value| response.command.send(:"#{name}=", value)}

        begin
          response.command.init
          response.state = :incomplete unless response.command.complete?
        rescue Exception => e
          puts e
          puts e.backtrace.join("\n")
          response.exception = e

          response.state = :abort
        end
      end

      case response.state
      when :complete
        response.command.finalize!
      when :incomplete
        # do nothing
      when :abort, :unrecognized
        data.slice!(0, raw_command.size + delimiter.size)
      end
      
      response
      
    end
  end
end