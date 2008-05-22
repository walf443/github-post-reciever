#!/usr/bin/ruby

require 'drb/drb'
require 'yaml'
require 'thread'
require 'pathname'

config_file = File.join(File.dirname(__FILE__), '../', 'config.yaml')
config = YAML.load_file(config_file)

raise 'config was wrong' unless config['workers']

( Pathname.new(__FILE__).parent.parent + 'lib' + 'github_post_reciever/worker').children.grep(/\.rb$/).each do |file|
  require file.expand_path
end

config['workers'].each do |worker|
  Process.fork do
    DRb.start_service(worker['uri'], GitHubPostReciever::Worker.const_get(worker['type']).new(worker['config']))
    sleep
  end
end

sleep
