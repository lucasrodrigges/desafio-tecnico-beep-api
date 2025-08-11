require 'rufus-scheduler'

Rails.application.configure do
  config.after_initialize do
    if defined?(Rails::Server) || (Rails.env.production? && defined?(Puma))
      begin
        scheduler = Rufus::Scheduler.new
        scheduler.every '5m', first: :now do
          TopStoriesSchedulerJob.perform_later
        end

        at_exit do
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
