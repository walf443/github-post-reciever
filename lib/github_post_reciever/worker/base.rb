require 'drb/drb'
require 'classx'

class GitHubPostReciever
  module Worker
    class Base < ClassX
      def initialize config
        @config = config
      end

      def run method, json
        raise NoImprementedError
      end
    end
  end
end
