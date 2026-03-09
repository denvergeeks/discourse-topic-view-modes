# name: discourse-topic-content-view
# about: Serves a topic's first-post cooked HTML as a bare page (no Discourse chrome)
# version: 1.0.0
# authors: @denvergeeks
# url: https://github.com/denvergeeks/discourse-topic-content-view

enabled_site_setting :topic_content_view_enabled

after_initialize do
  class ::TopicContentViewController < ::ApplicationController
    requires_plugin 'discourse-topic-content-view'

    # Skip XHR check, CSRF, preload — this is a standalone HTML endpoint
    skip_before_action :check_xhr
    skip_before_action :preload_json
    skip_before_action :verify_authenticity_token
    skip_before_action :redirect_to_login_if_required, raise: false

    def show
      topic_id = params[:id] || params[:slug]

      begin
        topic_view = TopicView.new(topic_id, current_user)
      rescue Discourse::NotFound, Discourse::InvalidAccess
        return render plain: "Not found", status: 404
      end

      topic = topic_view.topic
      return render plain: "Not found", status: 404 unless topic

      begin
        guardian.ensure_can_see!(topic)
      rescue Discourse::InvalidAccess
        return render plain: "Not found", status: 404
      end

      post = topic.ordered_posts.first
      return render plain: "Not found", status: 404 unless post

      @title  = topic.title
      @cooked = post.cooked

      render template: "topic_content_view/show",
             layout: false,
             formats: [:html],
             content_type: "text/html"
    end
  end

  Discourse::Application.routes.prepend do
    get '/tc/:slug/:id' => 'topic_content_view#show',
        constraints: { id: /\d+/, slug: /[^\/]+/ }
    get '/tc/:id' => 'topic_content_view#show',
        constraints: { id: /[^.\/]+/ }
  end
end
