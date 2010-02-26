$:.unshift(File.dirname(__FILE__))

# This prevents the "require 'some_gem'" error
require 'rubygems'

require 'vuzitruby/base'
require 'vuzitruby/event'
require 'vuzitruby/service'
require 'vuzitruby/document'
require 'vuzitruby/page'
require 'vuzitruby/client_exception'

