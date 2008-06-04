require File.expand_path(File.join(File.dirname(__FILE__), 'base'))
require 'net/http'
autoload :URI, 'uri'
autoload :Logger, 'logger'
autoload :Thread, 'thread'
require 'timeout'

class GitHubPostReciever
  module Worker
    # for posting multiple url.
    class ProxyPoster < Base

      has "methods", :kind_of => Hash
      has 'timeout', :kind_of => Fixnum, :default => 60
      has 'logger', :lazy => true, :default => proc { Logger.new($stderr) }

      def run method, json
        if @methods.include? method
          urls = @methods[method]
          raise '@method is wrong' unless urls.kind_of? Array

          urls.each do |url|
            uri = URI(url)
            Thread.new do |th|
              begin
                timeout(@timeout) do
                  Net::HTTP.start(uri.host, uri.port) do |http|
                    res = http.post(uri.path, "payload=#{json.to_json}")
                    case res
                    when Net::HTTPSuccess
                    else
                      @logger.error("#{res}: #{uri}")
                    end
                  end
                end
              rescue TimeoutError => e
                @logger.error("#{e}: #{url}")
              end
            end
          end
        end
      end
    end
  end
end
