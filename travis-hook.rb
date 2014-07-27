require 'json'
require 'logger'
require './workers/hook'
require 'sinatra'
require 'yaml'

repos    = YAML.load_file("config/repos.yml")
logger   = Logger.new("log/production.log")

def fetch_data(request)
  request.body.rewind
  JSON.parse request.body.read
end

get '/' do
  JSON.dump("hello" => "world")
end

post '/_github' do
  data = fetch_data(request)
  logger.info data.to_s
  repos.map do |clone_url, rel_output_dir|
    output_dir = File.join("repos", rel_output_dir)
    commit_url = data.fetch('head_commit').fetch('url')
    logger.info "Launching a sidekiq job for #{commit_url}..."
    HookWorker.perform_async clone_url, output_dir, commit_url
  end
  JSON.dump("building" => data.fetch('head_commit'))
end
