require 'rack'
require 'drb/drb'
require 'json'

class GitHubPostReciever
  def initialize config
    @config = config
    raise 'config was wrong' unless @config['workers'] 
    @workers = @config['workers'].map do |worker|
      DRbObject.new_with_uri(worker['uri'])
    end
  end

  def call env
    @req = Rack::Request.new(env)
    @res = Rack::Response.new()

    if @req.path_info == '/post'
      if @req.post? 
        return bad_request unless ( @req.params['payload'] && @req.params['method'] )
        @res.status = 200
        json = JSON.parse(@req.params['payload'])
        Thread.new do
          @workers.each do |worker|
            begin
              worker.run(@req.params['method'], json)
            rescue Exception => e
              warn e
            end
          end
        end
        @res.write('recieved successfully')
        return @res.finish
      else
        return method_not_allowed
      end
    else
      return not_found
    end
  end

  def not_found
    @res.status = 404
    @res.finish
  end

  def bad_request
    @res.status = 400
    @res.finish
  end

  def method_not_allowed
    @res.status = 405
    @res.finish
  end
end
