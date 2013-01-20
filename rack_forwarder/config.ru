require 'rubygems'
require 'rack/reverse_proxy'

require 'launch_cakeshow'

class ProcessStarter
  def initialize(app)
    @app = app
  end

  def call(env)
    pid = ensure_process_running()
    p pid
    @app.call(env)
  end
end

use ProcessStarter

use Rack::ReverseProxy do
  reverse_proxy_options :preserve_host => true

  reverse_proxy '/', 'http://127.0.0.1:3000'
end

app = proc do |env|
    [ 200, {'Content-Type' => 'text/plain'}, "cakeshow pid: " + pid.to_s]
end

run app
