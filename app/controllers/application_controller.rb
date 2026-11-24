class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  def dashboard
    @date = selected_date
    @companies = Company.joins(contacts: :emails)
                        .where(emails: { sent_at: @date.all_day })
                        .distinct
                        .order(:name)
  end

  private

  def selected_date
    Date.iso8601(params[:date])
  rescue ArgumentError, TypeError
    Date.current
  end
end
