#!/usr/bin/rackup

require 'yaml'
require File.expand_path(File.join(File.dirname(__FILE__), '../lib', 'github_post_reciever'))

config_file = File.join(File.dirname(__FILE__), '../', 'config.yaml')

# It may be better to block except for github post access
# please gem install rack-auth-ip to use this feature.
# github IP may be wrong. 
GITHUB_POST_IP = %w( 65.74.175.0/24 )
require 'rack/auth/ip'
use Rack::Auth::IP, %w( 127.0.0.1 192.168.0.0/24 ).concat(GITHUB_POST_IP)

run GitHubPostReciever.new(YAML.load_file(config_file))

