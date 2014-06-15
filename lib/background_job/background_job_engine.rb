####################################################################################################################
# Description: Script engine to start named queue workers                                                
# Author: Narendran Kanagaraj                                                                                 
# Usage : ruby background_job_engine.rb <environment>     
# Working: Find all named queues and start them if not running. This gets invoked via crontab                                           
#####################################################################################################################

if ARGV.size != 1
	puts "USAGE: ruby background_job_engine.rb <environment>"
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

@log1 = Logger.new("#{RAILS_ROOT}/log/background_job_engine.log", 5, 1048576)

def log_info(str)
	@log1.info "#{Time.now}: #{str}"
end

@background_job_engine_pid_file_path = "#{RAILS_ROOT}/lib/background_job/pids/background_job_engine.pid"

def clean_pid_file filename
	if File.exist?(filename)
		pid_file = File.open(filename)
		pid = pid_file.read
		pid_file.close
		begin
	    	Process.getpgid(pid)
	    rescue Errno::ESRCH
	      	File.delete(filename)
	    end
	end
end

clean_pid_file @background_job_engine_pid_file_path

if !File.exist?(@background_job_engine_pid_file_path) # Only if another instance of engine is not running
	begin
		background_job_engine_pid_file = File.new("#{@background_job_engine_pid_file_path}","w+")
		background_job_engine_pid_file.puts Process.pid
		background_job_engine_pid_file.close
		log_info  "Checking all Named Queues"
		named_queues = BackgroundJob::NamedQueue.all

		named_queues.each do |q| 
			log_info "Checking named queue: #{q.name}"
			unless q.is_pid_active?
				clean_pid_file "#{RAILS_ROOT}/lib/background_job/pids/#{q.name}.pid"
				log_info "Named queue: #{q.name} is inactive"
				log_info "Creating new process for named queue: #{q.name}"
				child_pid = fork{ exec "ruby","#{RAILS_ROOT}/script/background_job/worker.rb", "#{ENV['RAILS_ENV']}", "#{q.name}" }
				log_info "Done creating new process for named queue: #{q.name} with pid: #{child_pid}"
        	else
        		log_info "A process for named queue: #{q.name} is already active. Skipping creation"
        	end
		end
		log_info "Finished checking all named queues"
		File.delete(@background_job_engine_pid_file_path) if File.exists? @background_job_engine_pid_file_path
	rescue Exception => e
		log_info  "#{e.to_s}"
		File.delete(@background_job_engine_pid_file_path) if File.exists? @background_job_engine_pid_file_path
	end
else
	pid_file = File.open(@background_job_engine_pid_file_path)
	pid = pid_file.read
	pid_file.close
	log_info "Already a Background job engine with pid : #{pid} is running"
end

