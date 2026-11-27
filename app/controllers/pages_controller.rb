# Dashboard : une carte par domaine tiers et par jour d'échange.
class PagesController < ApplicationController
  include ConversationFilters

  def dashboard
    # Un seul domaine tiers sélectionné : on descend dans sa vue
    if selected_domain_ids.one?
      return redirect_to company_view_path(selected_domain_ids.first, **filter_params.except(:view))
    end

    @feed = ActivityFeed.new(conversations: filtered_conversations, before: feed_before)
    @cards = DashboardCards.new(@feed)

    render partial: "pages/feed_page", locals: { feed: @feed, cards: @cards } if turbo_frame_request?
  end
end
