require 'sinatra'
require 'logger'

logger = Logger.new("log/production.log")

get '/' do
  "Hello World!"
end

post '/_github' do
  logger.info params
end
