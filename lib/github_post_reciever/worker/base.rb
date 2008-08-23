require 'drb/drb'
require 'classx'
require 'classx/validate'

class GitHubPostReciever
  module Worker
    class Base 
      include ClassX
      include ClassX::Validate

      def run method, json
        raise NoImprementedError
      end
    end
  end
end
