require 'json'
require 'logger'
require './workers/hook'
require 'sinatra'
require 'yaml'

repos    = YAML.load_file("config/repos.yml")
secrets  = YAML.load_file("config/secrets.yml")
logger   = Logger.new("log/production.log")

def request_body(request)
  request.body.rewind
  request.body.read
end

def fetch_data(request)
  JSON.parse request_body(request)
end

def encoded_signature(token, payload_body)
  'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), token, payload_body)
end

def verify_signature(request, secrets)
  sent_signature = request.env['HTTP_X_HUB_SIGNATURE']
  if sent_signature.nil?
    return halt 400, "Be sure to send the header X-Hub-Signature."
  end
  logger.info "Verifying '#{sent_signature}' is a valid signature..."
  payload_body = request_body(request)
  unless secrets.any? { |sig|
    Rack::Utils.secure_compare(encoded_signature(sig, payload_body), sent_signature)
  }
    return halt 401, "Secret is invalid."
  end
  logger.info "Verified!"
end

get '/' do
  JSON.dump("hello" => "world")
end

post '/_github' do
  data = fetch_data(request)
  logger.info data.to_s
  verify_signature(request, secrets)
  unless data.fetch("ref").eql? "refs/heads/master"
    logger.info "Skipping the build for #{data.fetch('head_commit')}"
    return JSON.dump("skipping" => data)
  end
  repos.map do |clone_url, rel_output_dir|
    output_dir = File.join("repos", rel_output_dir)
    commit_url = data.fetch('head_commit').fetch('url')
    logger.info "Launching a sidekiq job for #{commit_url}..."
    HookWorker.perform_async clone_url, output_dir, commit_url
  end
  JSON.dump("building" => data.fetch('head_commit'))
end
