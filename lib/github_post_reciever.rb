require 'rack'
require 'drb/drb'
require 'json'
require 'classx'
require 'classx/validate'

class GitHubPostReciever
  include ClassX::Validate

  def initialize config
    validate config do
      has :workers, :kind_of => Array
    end
    config['workers'].each do |worker|
      validate worker do
        has :uri
      end
    end
    @workers = config['workers'].map do |worker|
      DRbObject.new_with_uri(worker['uri'])
    end
  end

  def call env
    @req = Rack::Request.new(env)
    @res = Rack::Response.new()

    if @req.path_info == '/post'
      if @req.post? 
        begin
          validate @req.params do
            has :payload
            has :method
          end
        rescue ClassX::AttrRequiredError => e
          return forbidden
        end
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

  def forbidden
    @res.status = 403
    @res.finish
  end

  def method_not_allowed
    @res.status = 405
    @res.finish
  end
end
