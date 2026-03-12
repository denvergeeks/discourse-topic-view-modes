# frozen_string_literal: true

# name: discourse-topic-content-view
# about: Adds configurable CSS classes to body via ?tcv=MODE query param, enabling mode-specific topic presentation (hide chrome, show only cooked content, etc.)
# version: 2.0.0
# authors: @denvergeeks
# url: https://github.com/denvergeeks/discourse-topic-content-view

enabled_site_setting :topic_content_view_enabled

register_asset "stylesheets/topic-content-view.scss", :desktop

add_admin_route "topic_content_view.admin.title", "topic-content-view"

after_initialize do
  module ::TopicContentView
    PLUGIN_NAME = "discourse-topic-content-view"
  end

  require_relative "app/controllers/topic_content_view/admin_controller"

  Discourse::Application.routes.prepend do
    get "/admin/plugins/topic-content-view" => "topic_content_view/admin#index",
        constraints: StaffConstraint.new
    put "/admin/plugins/topic-content-view" => "topic_content_view/admin#update",
        constraints: StaffConstraint.new
  end
end
