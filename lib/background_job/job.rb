# Job is the parent class of all types of jobs

module BackgroundJob

  class Job < ActiveRecord::Base
    self.set_table_name "background_jobs"
    belongs_to :named_queue

    STATUSES = [QUEUED = 'Queued', INPROCESS = 'In Process', COMPLETED = 'Completed', FAILED='Failed']

    validates_inclusion_of :status, :in => STATUSES

    def self.enqueue(params)
      named_queue = params[:named_queue] || 'Default'
      queue = NamedQueue.find_or_create_by_name(named_queue)
      job = self.create(:handler => params[:method], 
        :data => params[:params], 
        :status => QUEUED, 
        :named_queue_id => queue.id)
      job.id
    end

    def run
      begin  
        cmd = "#{self.handler} #{self.data if self.data.present?}"
        start_job
        eval(cmd)
        end_job
      rescue Exception => e
        fail_job
      end 
    end

    def start_job
	  self.status = INPROCESS
      self.start_time = Time.now
      self.save!
    end

    def end_job
      self.status = COMPLETED
      self.end_time = Time.now
      self.save!
    end

    def fail_job exception
	  self.status = FAILED
      self.end_time = Time.now
      self.error = "#{exception.message}\n#{exception.backtrace}"
      self.save!
    end


  end

end