# frozen_string_literal: true
# name: discourse-topic-view-modes
# about: Adds configurable CSS classes to body via ?tvm=MODE query param
# version: 3.0.0
# authors: @denvergeeks
# url: https://github.com/denvergeeks/discourse-topic-view-modes

enabled_site_setting :topic_view_modes_enabled

register_asset "stylesheets/topic-view-modes.scss", :desktop

add_admin_route "topic_view_modes.admin.title", "discourse-topic-view-modes",
                use_new_show_route: true

after_initialize do
  module ::TopicViewModes
    PLUGIN_NAME = "discourse-topic-view-modes"
  end

  require_relative "app/controllers/topic_view_modes/admin_controller"

  Discourse::Application.routes.prepend do
    get "/admin/plugins/discourse-topic-view-modes/modes" => "topic_view_modes/admin#index",
        constraints: StaffConstraint.new
    put "/admin/plugins/discourse-topic-view-modes/modes" => "topic_view_modes/admin#update",
        constraints: StaffConstraint.new
  end
end
