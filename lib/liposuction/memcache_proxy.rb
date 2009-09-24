module Liposuction
  class MemcacheProxy < Proxy
  
    class AbstractSetCommand < Proxy::Command
      
      #name_and_path :set, '{:command,^set$} :key {:flags,^\d+$} {:exptime,^\d+$} {:bytes,^\d+$}( {:noreply,^noreply$})'
      
      def init
        self.bytes = bytes.to_i
        self.flags = flags.to_i
        self.exptime = exptime.to_i
        
        raise "key size is greater than 250" if respond_to?(:key) && key.size > 250
        raise "bytes is larger than 1,000,000" if respond_to?(:bytes) && bytes > 1_000_000
        raise "payload doesn't end with \\r\\n" if complete? && data[raw_command.size + 2 + bytes, 2] != "\r\n"
      end
    
      def complete?
        raw_command.size + proxy.delimiter.size + bytes <= data.size
      end
      
      def finalize!
        self.payload = data.slice!(raw_command.size + proxy.delimiter.size, bytes + proxy.delimiter.size)
        payload.slice!(payload.size - proxy.delimiter.size, proxy.delimiter.size)
        data.slice!(0, raw_command.size + proxy.delimiter.size)
      end
      
      def noreply?
        !noreply.nil?
      end
      
      def noreply_boolean=(noreply)
        self.noreply = noreply ? 'noreply' : nil
      end
      
    end

    class SetCommand < AbstractSetCommand
      name_and_path :set, 'set :key {:flags,^\d+$} {:exptime,^\d+$} {:bytes,^\d+$}( {:noreply,^noreply$})'
    end
    command :SetCommand

    class AddCommand < AbstractSetCommand
      name_and_path :add, 'add :key {:flags,^\d+$} {:exptime,^\d+$} {:bytes,^\d+$}( {:noreply,^noreply$})'
    end
    command :AddCommand
    
    class ReplaceCommand < AbstractSetCommand
      name_and_path :replace, 'replace :key {:flags,^\d+$} {:exptime,^\d+$} {:bytes,^\d+$}( {:noreply,^noreply$})'
    end
    command :ReplaceCommand
    
    class AppendCommand < AbstractSetCommand
      name_and_path :append, 'append :key {:flags,^\d+$} {:exptime,^\d+$} {:bytes,^\d+$}( {:noreply,^noreply$})'
    end
    command :AppendCommand
    
    class PrependCommand < AbstractSetCommand
      name_and_path :prepend, 'prepend :key {:flags,^\d+$} {:exptime,^\d+$} {:bytes,^\d+$}( {:noreply,^noreply$})'
    end
    command :PrependCommand
    
    class CasCommand < AbstractSetCommand
      name_and_path :cas, 'cas :key {:flags,^\d+$} {:exptime,^\d+$} {:bytes,^\d+$} {:cas_unique,^\d+$}( {:noreply,^noreply$})'

      def init
        super
        self.cas_unique = cas_unique.to_i
      end
    end
    command :CasCommand
    
    class DeleteCommand < Proxy::Command
      name_and_path :delete, 'delete :key( {:time,^\d+$})( {:noreply,^noreply$})'

      def init
        self.time &&= time.to_i
      end

    end
    command :DeleteCommand
    
    class GetCommand < Proxy::Command
      name_and_path :get, '(get|gets) *keys'
      
      def init
        raise "must pass in at least one key" if keys.empty?
        keys.each {|k| raise "key size is greater than 250" if k.size > 250}
      end
    
    end
    command :GetCommand
    
    def initialize
      super("\r\n")
    end
    
  end
end