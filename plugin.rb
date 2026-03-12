# name: discourse-topic-content-view
# about: Adds configurable CSS classes to body via ?tcv=MODE query param, enabling mode-specific topic presentation (hide chrome, show only cooked content, etc.)
# version: 2.0.0
# authors: @denvergeeks
# url: https://github.com/denvergeeks/discourse-topic-content-view

enabled_site_setting :topic_content_view_enabled

register_asset "stylesheets/topic-content-view.scss", :desktop

# Register the plugin admin page link in Discourse admin panel
add_admin_route 'topic_content_view.admin.title', 'topic-content-view', use_client_i18n: true

after_initialize do
  module ::TopicContentView
    PLUGIN_NAME = 'discourse-topic-content-view'.freeze

    class Engine < ::Rails::Engine
      engine_name TopicContentView::PLUGIN_NAME
      isolate_namespace TopicContentView
    end
  end

  # Admin controller: serves unified modes JSON and handles full save
  class TopicContentView::AdminController < ::Admin::AdminController
    requires_plugin TopicContentView::PLUGIN_NAME

    # GET /admin/plugins/topic-content-view
    # Returns the parsed modes array
    def index
      render_json_dump(modes: load_modes)
    end

    # PUT /admin/plugins/topic-content-view
    # Saves the entire modes array: params { modes: [...] }
    def update
      modes = params.require(:modes)

      # Sanitise: ensure each mode is a hash with expected keys only
      sanitised = Array(modes).filter_map do |m|
        next unless m.is_a?(ActionController::Parameters) || m.is_a?(Hash)
        m = m.to_unsafe_h.with_indifferent_access
        next if m[:value].blank?
        {
          value:   m[:value].to_s.strip.downcase.gsub(/[^a-z0-9_-]/, ''),
          label:   m[:label].to_s.strip,
          classes: m[:classes].to_s.strip,
          css:     m[:css].to_s,
          preset:  m[:preset].present? ? true : false,
        }
      end

      SiteSetting.set(:topic_content_view_modes, sanitised.to_json)
      render json: success_json
    end

    private

    def load_modes
      raw = SiteSetting.topic_content_view_modes
      return default_modes if raw.blank?
      parsed = JSON.parse(raw)
      parsed.is_a?(Array) ? parsed : default_modes
    rescue JSON::ParserError
      default_modes
    end

    def default_modes
      [
        { 'value' => 'content', 'label' => 'Content Only',  'classes' => 'tcv-mode',            'css' => '', 'preset' => true },
        { 'value' => 'minimal', 'label' => 'Minimal',       'classes' => 'tcv-mode tcv-minimal', 'css' => '', 'preset' => true },
        { 'value' => 'full',    'label' => 'Full',          'classes' => 'tcv-mode tcv-full',    'css' => '', 'preset' => true },
      ]
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
