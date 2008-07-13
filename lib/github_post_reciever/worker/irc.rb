require File.expand_path(File.join(File.dirname(__FILE__), 'base'))
require 'net/irc'
require 'erb'
require 'logger'
require 'monitor'

class GitHubPostReciever
  module Worker
    class IRC < Base
      class CommitPingBot < Net::IRC::Client
        attr_accessor :commit_queue

        def connect channels
          channels.each do |channel|
            init_channel(channel)
          end
          start
        end

        # start session
        def on_rpl_endofmotd message
          @channels.keys.each do |channel|
            post JOIN, channel
          end
        end

        def on_message message
          if @commit_queue.nil?
            @commit_queue = []
            @commit_queue.extend(MonitorMixin)
          elsif @commit_queue.size > 0
            while ( @commit_queue.size > 0 )
              @commit_queue.synchronize do
                post(NOTICE, *@commit_queue.pop)
              end
            end
          end

          false
        end
      end

      class View
        include ClassX::Validate

        def initialize template, data
          # You can user this params in your template.
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

      # You can set this param to config.
      has :host,     :kind_of => String
      has :port,     :kind_of => Integer, :default => 6667
      has :nick,     :kind_of => String
      has :user,     :kind_of => String, :lazy => true, :default => proc {|mine| mine.nick }
      has :real,     :kind_of => String, :lazy => true, :default => proc {|mine| mine.nick }
      has :template, :kind_of => String
      has :channels, :kind_of => Array
      has :log_level, :default => proc { Logger::INFO }
      has :logger, :kind_of => Logger, :default => proc { Logger.new($stderr) }
      has :commit_ping_bot, :lazy => true, :default => proc {|mine|
        CommitPingBot.new(mine.host, mine.port, {
          'nick' => mine.nick,
          'user' => mine.user,
          'real' => mine.nick,
          'logger' => mine.logger,
        })
      }

      def after_init
        @logger.level = @log_level
        Thread.new do
          @commit_ping_bot.connect @channels
        end
      end

      def run method, json
        return unless @channels.include? "##{method}"

        validated_json = validate json do
          has :before
          has :repository, :kind_of => Hash
          has :commits, :kind_of => Hash
          has :after
          has :ref
        end
        validated_json.commits.values.sort_by {|c| c['timestamp'] }.each do |commit|
          if @commit_ping_bot.commit_queue.nil?
            @commit_ping_bot.commit_queue = []
            @commit_ping_bot.commit_queue.extend(MonitorMixin)
          else
            @commit_ping_bot.commit_queue.synchronize do
              @commit_ping_bot.commit_queue.unshift(["##{method}", View.new(@template, commit).result])
            end
          end
        end
      rescue ClassX::InstanceExceptoin => e
        @logger.error(e)
      end
    end
  end
end
