class LongSlowJob
  def self.perform
    #do the heavy lifting
    puts "This was tough!"
  end
end

class MiniResque
  def self.reserve
    LongSlowJob
  end

  def self.work_one_job(strategy)
    case strategy
    when :inproc
      job = reserve
      job.perform
    when :forking
      pid = fork do
        job = reserve
        job.perform
        #exit
      end
      Process.wait pid
    end
  end
end

MiniResque.work_one_job :inproc

