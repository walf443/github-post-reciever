require File.expand_path(File.join(File.dirname(__FILE__), 'base'))
require 'net/irc'
require 'erb'

class GitHubPostReciever
  module Worker
    class IRC < Base
      class CommitPingBot < Net::IRC::Client
        def run channel, message
          @socket = TCPSocket.open(@host, @port)
          if @opts.pass
            post PASS, @opts.pass
          end
          post NICK, @opts.nick
          post USER, @opts.user, '0', '*', @opts.real
          post JOIN, channel
          post NOTICE, channel, message

          sleep(3)
        ensure
          @socket.close
        end
      end

      class View
        def initialize template, data
          @commit = data
          File.open(template, 'r') do |io|
            @erb = ERB.new(io.read)
          end
        end

        def result
          @erb.result(binding)
        end
      end

      def run method, json
        json['commits'].each do |sha, commit|
          CommitPingBot.new(@config['host'], @config['port'], {
            'nick', @config['nick'],
            'user', @config['user'],
            'real', @config['real'],
          }).run("##{method}", View.new(@config['template'], commit).result)
        end
      end
    end
  end
end
