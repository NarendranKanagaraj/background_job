# NamedQueue contains the different queues and the processes executing them

module BackgroundJob
  
  class NamedQueue < ActiveRecord::Base
    has_many :jobs

    def self.create_queue(name)
      NamedQueue.create(:name => name)
    end

    def get_next_to_run
      Job.find_by_status_and_named_queue_id([BackgroundJob::Job::QUEUED,self.id])
    end

    def is_pid_active?
      return false if self.pid.blank?
      begin
        Process.getpgid(self.pid)
        true
      rescue Errno::ESRCH
        false
      end
    end

  end
  
end