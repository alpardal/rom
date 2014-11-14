# encoding: utf-8

# this is needed for guard to work, not sure why :(
require "bundler"
Bundler.setup

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'rom'

require 'rom/adapter/memory'

require 'rom-sql'
require 'rom/sql/spec/support'

root = Pathname(__FILE__).dirname

Dir[root.join('shared/*.rb').to_s].each { |f| require f }

RSpec.configure do |config|
  config.before do
    @constants = Object.constants
  end

  config.after do
    (Object.constants - @constants).each { |name| Object.send(:remove_const, name) }
  end
end
