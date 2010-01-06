require 'rubygems'
require 'test/unit'
require 'shoulda'

require 'active_support'
require 'action_controller'
require 'action_view/test_case'

Dir[File.join(File.dirname(__FILE__), %w[.. app helpers *])].each { |f| require f }
