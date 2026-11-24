class PagesController < ApplicationController
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
