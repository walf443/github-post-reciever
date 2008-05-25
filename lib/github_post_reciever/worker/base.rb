require 'drb/drb'
require 'classx'

class GitHubPostReciever
  module Worker
    class Base < ClassX
      def run method, json
        raise NoImprementedError
      end
    end
  end
end
