# name: discourse-topic-content-view
# about: Adds configurable CSS classes to body via ?tcv=MODE query param, enabling mode-specific topic presentation (hide chrome, show only cooked content, etc.)
# version: 2.0.0
# authors: @denvergeeks
# url: https://github.com/denvergeeks/discourse-topic-content-view

enabled_site_setting :topic_content_view_enabled

register_asset "stylesheets/topic-content-view.scss", :desktop

# Register the plugin admin page link in Discourse admin panel
add_admin_route 'topic_content_view.admin.title', 'topic-content-view'

after_initialize do
  module ::TopicContentView
    PLUGIN_NAME = 'discourse-topic-content-view'.freeze

    class Engine < ::Rails::Engine
      engine_name TopicContentView::PLUGIN_NAME
      isolate_namespace TopicContentView
    end
  end

  # Admin controller: serves mode list and handles SCSS save
  class TopicContentView::AdminController < ::Admin::AdminController
    requires_plugin TopicContentView::PLUGIN_NAME

    # GET /admin/plugins/topic-content-view
    # Returns all modes (built-in + custom) and saved SCSS per mode
    def index
      all_modes = parse_modes(SiteSetting.topic_content_view_modes) +
                  parse_modes(SiteSetting.topic_content_view_custom_modes)

      scss_map = begin
        JSON.parse(SiteSetting.topic_content_view_mode_scss || '{}')
      rescue JSON::ParserError
        {}
      end

      render_json_dump(
        modes: all_modes.map do |m|
          m.merge(scss: scss_map[m[:value]] || '')
        end
      )
    end

    # PUT /admin/plugins/topic-content-view
    # Saves SCSS for one mode: params { mode_value, scss }
    def update
      mode_value = params.require(:mode_value)
      scss       = params.fetch(:scss, '')

      scss_map = begin
        JSON.parse(SiteSetting.topic_content_view_mode_scss || '{}')
      rescue JSON::ParserError
        {}
      end

      scss_map[mode_value] = scss
      SiteSetting.set(:topic_content_view_mode_scss, scss_map.to_json)

      render json: success_json
    end

    private

    def parse_modes(raw)
      return [] if raw.blank?
      raw.split("\n").filter_map do |line|
        line = line.strip
        next if line.blank?
        parts = line.split('|', 2)
        next unless parts.length == 2
        { value: parts[0].strip, classes: parts[1].strip }
      end
    end
  end

  TopicContentView::Engine.routes.draw do
    get  '/' => 'admin#index'
    put  '/' => 'admin#update'
  end

  Discourse::Application.routes.prepend do
    mount ::TopicContentView::Engine, at: '/admin/plugins/topic-content-view'
  end
end
