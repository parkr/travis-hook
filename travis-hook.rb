require 'sinatra'
require 'logger'
require 'json'
require 'yaml'
require 'open3'

logger  = Logger.new("log/production.log")
$stdout = $stderr = File.open("log/production.log", "a")
repos   = YAML.load_file("config/repos.yml")

def fetch_data(request)
  request.body.rewind
  JSON.parse request.body.read
end

def exec(*cmd)
  logger.info "CWD=#{Dir.pwd} : Executing '#{cmd.join(" ")}'..."
  Open3.popen2e(*cmd) do |stdin, stdout_and_stderr, wait_thr|
    exit_status = wait_thr.value.exitstatus
    output = stdout_and_stderr.read
    logger.info output
    [exit_status, output]
  end
end

def clone(clone_url, destination)
  # clone
  exec("git", "clone", clone_url, destination)
  # update
  Dir.chdir(destination) do
    exec("git", "pull", "origin")
  end
end

def make_new_commit(output_dir, commit_url)
  # commit and push
  Dir.chdir(destination) do
    exec(
      "git",
      "commit",
      "--allow-empty",
      "-m",
      "Building commit corresponding to #{commit_url}"
    )
    exec("git", "push")
  end
end

get '/' do
  "Hello World!"
end

post '/_github' do
  data = fetch_data(request)
  logger.info data.to_s
  repos.map do |clone_url, rel_output_dir|
    output_dir = File.join("repos", rel_output_dir)
    clone(clone_url, output_dir)
    commit_url = data.fetch('head_commit').fetch('url')
    make_new_commit(output_dir, commit_url)
  end
end
