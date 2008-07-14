#!/usr/bin/ruby

require 'rubygems'
require 'drb/drb'
require 'yaml'
require 'thread'
require 'pathname'

config_file = File.join(File.dirname(__FILE__), '../', 'config.yaml')
config = YAML.load_file(config_file)

raise 'config was wrong' unless config['workers']

class GitHubPostReciever
  module Worker
    def self.path2class path
      base_path = path.basename.to_s.gsub(path.extname, '')
      base_path.split(/_/).map {|alpha| alpha.capitalize }.join
    end

    ( Pathname.new(__FILE__).parent.parent + 'lib' + 'github_post_reciever/worker').children.grep(/\.rb$/).each do |file|
      autoload path2class(file), file.expand_path.to_s
      p file
    end
  end
end

config['workers'].each do |worker|
  Process.fork do
    DRb.start_service(worker['uri'], GitHubPostReciever::Worker.const_get(worker['type']).new(( worker['config'] || {} )))
    sleep
  end
end

sleep
