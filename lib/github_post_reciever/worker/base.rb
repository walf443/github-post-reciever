require 'drb/drb'
require 'classx'
require 'classx/validate'

class GitHubPostReciever
  module Worker
    class Base < ClassX
      include Validate

      def run method, json
        raise NoImprementedError
      end
    end
  end
end
