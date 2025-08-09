if defined?(Rails::Server)
  require 'rufus-scheduler'

  scheduler = Rufus::Scheduler.new

  scheduler.every '1m' do
    TopStoriesSchedulerJob.perform_later
  end
end
