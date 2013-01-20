These files are used on Bluehost to launch the node process and
forward requests made to Rack on to Node.

To use them, follow the instructions on Bluehost for configuring a
Rails 3.x app, but use the config.ru file included here (and make sure
that the launch_cakeshow.rb file is in the same directory). You will
also need to install the rack-reverse-proxy gem.

It works by ensuring that the Node server is always running on each
request (and starting it if it isn't) and then using
rack-reverse-proxy to forward all requests to that node process. Right
now, all the paths are hard-coded into the script, but that could be
fixed, if necessary.
