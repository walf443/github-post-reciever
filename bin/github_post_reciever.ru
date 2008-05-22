#!/usr/bin/rackup

require 'yaml'
require File.expand_path(File.join(File.dirname(__FILE__), '../lib', 'github_post_reciever'))

config_file = File.join(File.dirname(__FILE__), '../', 'config.yaml')

run GitHubPostReciever.new(YAML.load_file(config_file))

