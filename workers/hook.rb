require 'logger'
require 'open3'
require 'sidekiq'

class HookWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :travis_hook

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
    Dir.chdir(output_dir) do
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

  def perform(clone_url, output_dir, commit_url)
    clone(clone_url, output_dir)
    make_new_commit(output_dir, commit_url)
  end
end
