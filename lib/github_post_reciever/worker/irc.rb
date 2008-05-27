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
          @commit = validate data do
            has :message
            has :author, :kind_of => Hash
            has :url
            has :timestamp
          end
          validate @commit.author do
            has :email
            has :name
          end
          File.open(template, 'r') do |io|
            @erb = ERB.new(io.read)
          end
        end

        def result
          @erb.result(binding)
        end
      end

      has :host,     :kind_of => String
      has :port,     :kind_of => Integer, :default => 6667
      has :nick,     :kind_of => String
      has :user,     :kind_of => String, :lazy => true, :default => proc {|mine| mine.nick }
      has :real,     :kind_of => String, :lazy => true, :default => proc {|mine| mine.nick }
      has :template, :kind_of => String

      def run method, json
        validated_json = validate json do
          has :commits, :kind_of => Hash
        end

        validated_json.commits.reverse.each do |sha, commit|
          CommitPingBot.new(@host, @port, {
            'nick' => @nick,
            'user' => @user,
            'real' => @real,
          }).run("##{method}", View.new(@template, commit).result)
        end
      rescue ClassX::InvalidArgumentError => e
        warn e
      rescue ClassX::AttrRequiredError => e
        warn e
      end
    end
  end
end
