require 'rufus-scheduler'

Rails.application.configure do
  config.after_initialize do
    if defined?(Rails::Server) || (Rails.env.production? && defined?(Puma))
      begin
        scheduler = Rufus::Scheduler.new
        scheduler.every '45s', first: :now do
          if TopStoriesChannel.has_active_connections?
            Rails.logger.info "TopStoriesScheduler: Executing job with #{TopStoriesChannel.active_connections_count} active connections"
            TopStoriesSchedulerJob.perform_later
          else
            Rails.logger.debug "TopStoriesScheduler: Skipping job execution - no active WebSocket connections"
          end
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
