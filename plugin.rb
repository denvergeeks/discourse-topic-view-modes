# name: discourse-topic-content-view
# about: Display topic cooked content at /topic-content/:id with full theme JS
# version: 0.5.0
# authors: @denvergeeks
# url: https://github.com/denvergeeks/discourse-topic-content-view

enabled_site_setting :topic_content_view_enabled

after_initialize do
  class ::TopicContentViewController < ::ApplicationController
    requires_plugin 'discourse-topic-content-view'
    skip_before_action :check_xhr, :preload_json, :verify_authenticity_token
    layout false

    def show
      topic = find_topic(params[:id])
      raise Discourse::NotFound unless topic
      guardian.ensure_can_see!(topic)

      post = topic.first_post
      raise Discourse::NotFound unless post

      title      = ERB::Util.html_escape(topic.title)
      site_title = ERB::Util.html_escape(SiteSetting.title)
      cooked     = post.cooked
      nonce      = SecureRandom.hex(16)

      # Resolve the hashed publish asset path the same way Discourse does
      publish_js_path = begin
        ActionController::Base.helpers.asset_path('publish.js')
      rescue
        # Fallback: scan the assets directory for the hashed filename
        publish_file = Dir.glob(Rails.root.join('public', 'assets', 'publish-*.js')).first
        publish_file ? "/assets/#{File.basename(publish_file)}" : nil
      end

      # Collect theme CSS stylesheet URLs
      theme_ids = []
      if current_user
        theme_ids = current_user.user_option&.theme_ids || []
      end
      theme_ids = [SiteSetting.default_theme_id] if theme_ids.empty?
      theme_id = theme_ids.first

      css_links = []
      if theme_id && theme_id > 0
        theme = Theme.find_by(id: theme_id)
        if theme
          target = :desktop
          [
            Stylesheet::Manager.new(theme_ids: [theme_id]).stylesheet_data(:desktop_theme),
            Stylesheet::Manager.new(theme_ids: [theme_id]).stylesheet_data(:common_theme),
            Stylesheet::Manager.new(theme_ids: []).stylesheet_data(:desktop),
          ].flatten.each do |s|
            css_links << s[:new_href] if s[:new_href].present?
          end
        end
      end

      # Also include the base Discourse desktop stylesheet
      base_css = begin
        ActionController::Base.helpers.asset_path('desktop.css')
      rescue
        nil
      end
      css_links.unshift(base_css) if base_css

      topic_id = topic.id
      slug     = topic.slug

      html_content = <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <title>#{title} - #{site_title}</title>
          #{css_links.map { |href| "<link rel=\"stylesheet\" href=\"#{ERB::Util.html_escape(href)}\" />" }.join("\n  ")}
        </head>
        <body class="published-page">
          <div id="main" class="published-page-content">
            <div id="ember-main-application" data-topic-id="#{topic_id}" data-slug="#{ERB::Util.html_escape(slug)}">
              <div class="published-page-content">
                <h1 class="published-page-title">#{title}</h1>
                <div class="cooked">#{cooked}</div>
              </div>
            </div>
          </div>
          #{publish_js_path ? "<script nonce=\"#{nonce}\" src=\"#{publish_js_path}\"></script>" : ''}
        </body>
        </html>
      HTML

      render html: html_content.html_safe
    end

    private

    def find_topic(id_or_slug)
      if id_or_slug =~ /\A\d+\z/
        Topic.find_by(id: id_or_slug.to_i)
      else
        Topic.find_by(slug: id_or_slug)
      end
    end
  end

  Discourse::Application.routes.prepend do
    get '/topic-content/:id' => 'topic_content_view#show', constraints: { id: /[^.]+/ }
  end
end
