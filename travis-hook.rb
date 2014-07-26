require 'sinatra'
require 'logger'
require 'json'

logger = Logger.new("log/production.log")

get '/' do
  "Hello World!"
end

post '/_github' do
  request.body.rewind  # in case someone already read it
  data = JSON.parse request.body.read
  logger.info data.to_s
  "Hello #{data['name']}!"
end
