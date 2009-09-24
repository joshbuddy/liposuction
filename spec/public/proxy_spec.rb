class ImaginaryProxy < Liposuction::Proxy
  
  class SimpleCommand < Liposuction::Proxy::Command
    name_and_path :simple, 'simple'
  end
  command :SimpleCommand
  
  class MultilineCommand < Liposuction::Proxy::Command
    name_and_path :multiline, 'multi'

    def complete?
      @pos = data.index('+++')
    end
    
    def finalize!
      self.payload = data.slice!(raw_command.size + proxy.delimiter.size, @pos)
      self.payload.slice!(self.payload.size - 3, self.payload.size)
      data.slice!(0, raw_command.size + 3)
    end
    
  end
  command :MultilineCommand
  
  class ParameterCommand < Liposuction::Proxy::Command
    name_and_path :parameters, 'parameters :arg1 :arg2( :arg3)( :arg4( :arg5))'
  end
  command :ParameterCommand
  
end

describe 'A subclassed proxy' do

  before(:each) do
    @proxy = ImaginaryProxy.new("\r\n")
  end
  
  it "should process a simple command" do
    response = @proxy.process("simple\r\n")
    response.state.should == :complete
    response.command.command_type == :simple
  end
  
  it "should process a command with multiline command that ends with +++" do 
    data = "multi\r\nthis is my payload+++"
    response = @proxy.process(data)
    response.state.should == :complete
    response.command.command_type == :simple
    response.command.payload.should == 'this is my payload'
    data.should == ''
  end
  
  it "should generate a simple command" do
    response = @proxy.process("simple\r\n")
    @proxy.build_from_command(response.command).should == "simple\r\n"
  end
  
  it "recognize a command with arguments" do
    response = @proxy.process("parameters param1 param2 param3 param4 param5\r\n")
    response.state.should == :complete
    response.command.command_type == :parameters
    response.command.to_hash.should == {:arg1 => 'param1', :arg2 => 'param2', :arg3 => 'param3', :arg4 => 'param4', :arg5 => 'param5'}
    (response.command.significant_keys & [:arg1, :arg2, :arg3, :arg4, :arg5]).size.should == 5
  end

  it "should generate a command with optional arguments" do
    response = @proxy.process("parameters param1 param2 param3 param4 param5\r\n")
    @proxy.build_from_command(response.command).should == "parameters param1 param2 param3 param4 param5\r\n"
    response.command.arg5 = nil
    @proxy.build_from_command(response.command).should == "parameters param1 param2 param3 param4\r\n"
    response.command.arg3 = nil
    @proxy.build_from_command(response.command).should == "parameters param1 param2 param4\r\n"

    # should ignore extra argument if it cannot be assembled into command
    response.command.arg5 = 'param5'
    response.command.arg4 = nil
    @proxy.build_from_command(response.command).should == "parameters param1 param2\r\n"
  end
end