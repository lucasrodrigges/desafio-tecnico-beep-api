require 'rufus-scheduler'

Rails.application.configure do
  config.after_initialize do
    if defined?(Rails::Server) || (Rails.env.production? && defined?(Puma))
      puts.info "Starting Top Stories Scheduler"

      begin
        scheduler = Rufus::Scheduler.new

        scheduler.every '5m', first: :now do
          puts.info "Scheduling TopStoriesSchedulerJob"

          TopStoriesSchedulerJob.perform_later
        end

        at_exit do
          puts.info "Shutting down Top Stories Scheduler"

          scheduler&.shutdown(:wait)
        end

      rescue => e
        puts.error "Failed to start Top Stories Scheduler: #{e.message}"
      end
    else
      puts.info "Skipping Top Stories Scheduler initialization (not running as server)"
    end
  end
end
