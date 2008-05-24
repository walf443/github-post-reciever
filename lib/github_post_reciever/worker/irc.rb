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

      has :host, :is => :ro, :kind_of => String, :required => true
      has :port, :is => :ro, :kind_of => Integer, :default => 6667
      has :nick, :is => :ro, :kind_of => String, :required => true
      has :user, :is => :ro, :kind_of => String, :lazy => true, :default => proc {|mine| mine.nick }
      has :real, :is => :ro, :kind_of => String, :lazy => true, :default => proc {|mine| mine.nick }
      has :template, :is => :ro, :kind_of => String, :required => true

      def run method, json
        json['commits'].reverse.each do |sha, commit|
          CommitPingBot.new(@host, @port, {
            'nick' => @nick,
            'user' => @user,
            'real' => @real,
          }).run("##{method}", View.new(@template, commit).result)
        end
      end
    end
  end
end
