require File.expand_path(File.join(File.dirname(__FILE__), 'base'))
require 'pit'
require 'classx/role/logger'
require 'erb'
require 'net/http'

class GitHubPostReciever
  module Worker
    class WassrChannel < Base
      include ClassX::Role::Logger

      has :domain_for_pit, :kind_of => String
      has :account, :kind_of => Hash, :lazy => true, :default => proc {|mine| Pit.get(mine.domain_for_pit, :require => { 'username' => '', 'password' => '' }) }
      has :template, :kind_of => String
      has :channels, :kind_of => Array

      def run method, json
        return unless @channels.include? "##{method}"
        validated_json = validate json do
          has :before
          has :repository, :kind_of => Hash
          has :commits, :kind_of => Array
          has :after
          has :ref
        end

        validated_json.commits.sort_by {|c| c['timestamp'] }.each do |commit|
          message = View.new(self.template, commit).result
          Net::HTTP.start('api.wassr.jp') do |http|
            req = Net::HTTP::Post.new('/channel_message/update.json', {
              'User-Agent' => "GithubPostReciever( #{self.account['username'] } )"
            })
            req.basic_auth self.account['username'], self.account['password']
            req.set_form_data({'name_en' => method, 'body' => message})
            res = http.request req
            self.logger.info("#{res.inspect}: #{method}: #{message}")
          end
          sleep(10)
        end
      rescue ClassX::InstanceException => e
        self.logger.error(e)
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
    end
  end
end
