require File.expand_path(File.join(File.dirname(__FILE__), 'base'))
require 'erb'
require 'uri'
require 'open-uri'
require 'json'
require 'classx/role/logger'

class GitHubPostReciever
  module Worker
    class Json2irc < Base
      class View
        include ClassX::Validate

        def initialize template, data
          # You can user this params in your template.
          @commit = ClassX::Validate.validate data do
            has :message
            has :author, :kind_of => Hash
            has :url
            has :timestamp
          end
          ClassX::Validate.validate @commit.author do
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
      include ClassX::Role::Logger
      has :template, :kind_of => String
      has :url,      :kind_of => URI::HTTP,
        :coerce  => {
          String  => proc {|val| URI(val) },
        }

      has :channels, :kind_of => Array

      def run method, json
        return unless self.channels.include? "##{method}"

        validated_json = ClassX::Validate.validate json do
          has :before
          has :repository, :kind_of => Hash
          has :commits, :kind_of => Array
          has :after
          has :ref
        end
        validated_json.commits.sort_by {|c| c['timestamp'] }.each do |commit|
            json = {
              "method"  => "notice",
              "channel" => method,
              "message" => View.new(self.template, commit).result,
            }.to_json
            url_base = self.url.dup
            url_base.query = "json=#{URI.encode(json)}"
            url_base.open
          sleep(3)
        end
      rescue ClassX::InstanceException => e
        self.logger.error(e)
      end
    end
  end
end
