require 'rubygems'

module Liposuction
  
  autoload :VERSION, File.join(File.dirname(__FILE__), 'liposuction', 'version')

  autoload :Proxy, File.join(File.dirname(__FILE__), 'liposuction', 'proxy')
  autoload :MemcacheProxy, File.join(File.dirname(__FILE__), 'liposuction', 'memcache_proxy')

  autoload :Runner, File.join(File.dirname(__FILE__), 'liposuction', 'runner')
  
end
