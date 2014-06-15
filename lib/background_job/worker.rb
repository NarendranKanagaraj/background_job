####################################################################################################################
# Description: Worker to process named queue jobs                                                
# Author: Narendran Kanagaraj                                                                                 
# Usage : ruby worker.rb <environment> <named_queue>     
# Working: Find all named queue jobs and execute them one by one. This gets invoked via background job engine                                          
#####################################################################################################################

if ARGV.size != 2
	puts "USAGE: ruby worker.rb <environment> <named_queue>"
	exit
end

$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require 'rubygems'

ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV']

require File.dirname(__FILE__) + '/../../config/boot'
require "#{RAILS_ROOT}/config/environment"

def connect(environment)
	conf = YAML::load(File.open(File.dirname(__FILE__) + '/../../config/database.yml'))
	ActiveRecord::Base.establish_connection(conf[environment])
end

# Open ActiveRecord connection
connect(ENV['RAILS_ENV'])

@log1 = Logger.new("#{RAILS_ROOT}/log/#{ARGV[1]}.log", 5, 1048576)

def log_info(str)
	@log1.info "#{Time.now}: #{str}"
end
@named_queue = BackgroundJob::NamedQueue.find_by_name(ARGV[1])
if @named_queue.blank?
	log_info  "No such named queue"
	exit
end

worker_pid_file_path = "#{RAILS_ROOT}/lib/background_job/pids/#{ARGV[1]}.pid"

if !File.exist?(worker_pid_file_path) # Only if another instance of engine is not running
	begin
		worker_pid_file = File.new("#{worker_pid_file_path}","w+")
		worker_pid_file.puts Process.pid
		worker_pid_file.close
		@named_queue.pid = Process.pid
		@named_queue.save!
		log_info  "Background Job processing started"
		while job_to_run = @named_queue.get_next_to_run 
			log_info "Starting Background job: #{job_to_run.id}"
    		runtime =  Benchmark.realtime do
      			job_to_run.run
      		end
      		log_info "Completed Background job: #{job_to_run.id} in %.4f sec" % runtime
    	end
    	log_info "Done"
		@named_queue.pid=nil
		@named_queue.save!
		File.delete(worker_pid_file_path) if File.exists? worker_pid_file_path
	rescue Exception => e
		log_info  "#{e.to_s}"
		File.delete(worker_pid_file_path) if File.exists? worker_pid_file_path
	end
else
	pid_file = File.open(worker_pid_file_path)
	pid = pid_file.read
	pid_file.close
	log_info "Already a worker for the same named queue with pid : #{pid} is running"
end

