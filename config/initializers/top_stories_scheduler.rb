require 'rufus-scheduler'

Rails.application.configure do
  config.after_initialize do
    if defined?(Rails::Server) || (Rails.env.production? && defined?(Puma))
      Rails.logger.info "Starting Top Stories Scheduler"

      begin
        scheduler = Rufus::Scheduler.new

        scheduler.every '5m', first: :now do
          Rails.logger.info "Scheduling TopStoriesSchedulerJob"

          TopStoriesSchedulerJob.perform_later
        end

        at_exit do
          Rails.logger.info "Shutting down Top Stories Scheduler"

          scheduler&.shutdown(:wait)
        end

      rescue => e
        Rails.logger.error "Failed to start Top Stories Scheduler: #{e.message}"
      end
    else
      Rails.logger.info "Skipping Top Stories Scheduler initialization (not running as server)"
    end
  end
end
