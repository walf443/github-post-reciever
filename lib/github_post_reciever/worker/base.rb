require 'drb/drb'

class GitHubPostReciever
  module Worker
    class Base
      def initialize config
        @config = config
      end

      def run method, json
        raise NoImprementedError
      end
    end
  end
end
