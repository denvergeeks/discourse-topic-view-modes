# name: discourse-topic-content-view
# about: Display topic cooked content at /topic-content/:id with full theme JS
# version: 0.6.0
# authors: @denvergeeks
# url: https://github.com/denvergeeks/discourse-topic-content-view

enabled_site_setting :topic_content_view_enabled

after_initialize do
  class ::TopicContentViewController < ::ApplicationController
    requires_plugin 'discourse-topic-content-view'
    skip_before_action :check_xhr, :preload_json, :verify_authenticity_token
    layout false

    INIT_SCRIPT = <<~'JS'
      document.addEventListener('DOMContentLoaded', function() {
        var cooked = document.querySelector('.cooked');
        if (!cooked) return;

        // ── Inline Tooltips (data-tip) ──────────────────────────────────
        cooked.querySelectorAll('[data-tip]').forEach(function(el) {
          var tip = document.createElement('div');
          tip.className = 'discourse-tooltip';
          tip.innerHTML = el.getAttribute('data-tip');
          el.style.position = 'relative';
          el.style.cursor = 'help';
          tip.style.cssText = 'display:none;position:absolute;z-index:9999;background:#333;color:#fff;padding:6px 10px;border-radius:4px;font-size:13px;max-width:300px;white-space:normal;bottom:calc(100% + 6px);left:0;box-shadow:0 2px 8px rgba(0,0,0,.3)';
          el.appendChild(tip);
          el.addEventListener('mouseenter', function() { tip.style.display = 'block'; });
          el.addEventListener('mouseleave', function() { tip.style.display = 'none'; });
        });

        // ── Lightbox images ─────────────────────────────────────────────
        cooked.querySelectorAll('a.lightbox').forEach(function(a) {
          a.addEventListener('click', function(e) {
            e.preventDefault();
            var overlay = document.createElement('div');
            overlay.style.cssText = 'position:fixed;inset:0;background:rgba(0,0,0,.85);z-index:99999;display:flex;align-items:center;justify-content:center;cursor:zoom-out';
            var img = document.createElement('img');
            img.src = a.href;
            img.style.cssText = 'max-width:90vw;max-height:90vh;object-fit:contain;box-shadow:0 4px 32px rgba(0,0,0,.7)';
            overlay.appendChild(img);
            overlay.addEventListener('click', function() { document.body.removeChild(overlay); });
            document.body.appendChild(overlay);
          });
        });

        // ── Lazy YouTube embeds ─────────────────────────────────────────
        cooked.querySelectorAll('.lazy-video-container').forEach(function(c) {
          var id = c.getAttribute('data-video-idx') || c.getAttribute('data-video-id');
          var provider = c.getAttribute('data-provider-name') || 'youtube';
          if (!id) return;
          c.style.cursor = 'pointer';
          c.addEventListener('click', function() {
            var iframe = document.createElement('iframe');
            iframe.width = '560'; iframe.height = '315';
            iframe.allow = 'autoplay; encrypted-media';
            iframe.allowFullscreen = true;
            if (provider === 'youtube') {
              iframe.src = 'https://www.youtube.com/embed/' + id + '?autoplay=1';
            } else if (provider === 'vimeo') {
              iframe.src = 'https://player.vimeo.com/video/' + id + '?autoplay=1';
            }
            iframe.style.cssText = 'width:100%;aspect-ratio:16/9;border:none';
            c.innerHTML = '';
            c.appendChild(iframe);
          });
        });

        // ── Scrollable content (data-theme-scrollable) ──────────────────
        cooked.querySelectorAll('[data-theme-scrollable]').forEach(function(el) {
          el.style.cssText = (el.getAttribute('style') || '') + ';overflow-y:auto;max-height:400px;border:1px solid #ccc;padding:1em;border-radius:4px';
        });

        // ── Masonry gallery (data-masonry-gallery) ──────────────────────
        cooked.querySelectorAll('[data-masonry-gallery]').forEach(function(gallery) {
          gallery.style.cssText = 'columns:3 200px;column-gap:8px';
          gallery.querySelectorAll('p').forEach(function(p) {
            p.style.cssText = 'break-inside:avoid;margin-bottom:8px';
          });
        });

        // ── Footnote popovers ───────────────────────────────────────────
        cooked.querySelectorAll('a.footnote-ref').forEach(function(ref) {
          var targetId = ref.getAttribute('href').replace('#', '');
          ref.addEventListener('mouseenter', function() {
            var fnEl = document.getElementById(targetId);
            if (!fnEl) return;
            var pop = document.createElement('div');
            pop.id = 'fn-pop-' + targetId;
            pop.style.cssText = 'position:absolute;z-index:9999;background:#fff;border:1px solid #ccc;border-radius:4px;padding:8px 12px;max-width:320px;font-size:13px;box-shadow:0 2px 12px rgba(0,0,0,.15)';
            pop.innerHTML = fnEl.innerHTML.replace(/<a[^>]*footnote-backref[^>]*>.*?<\/a>/g, '');
            ref.style.position = 'relative';
            ref.appendChild(pop);
          });
          ref.addEventListener('mouseleave', function() {
            var pop = document.getElementById('fn-pop-' + ref.getAttribute('href').replace('#', ''));
            if (pop) pop.parentNode.removeChild(pop);
          });
        });
      });
    JS

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

      # Resolve publish.js hashed asset path
      publish_js_path = begin
        ActionController::Base.helpers.asset_path('publish.js')
      rescue
        publish_file = Dir.glob(Rails.root.join('public', 'assets', 'publish-*.js')).first
        publish_file ? "/assets/#{File.basename(publish_file)}" : nil
      end

      # Collect theme CSS
      theme_ids = current_user ? (current_user.user_option&.theme_ids || []) : []
      theme_ids = [SiteSetting.default_theme_id] if theme_ids.empty?
      theme_id  = theme_ids.first

      css_links = []
      if theme_id && theme_id > 0
        begin
          [
            Stylesheet::Manager.new(theme_ids: [theme_id]).stylesheet_data(:desktop_theme),
            Stylesheet::Manager.new(theme_ids: [theme_id]).stylesheet_data(:common_theme),
            Stylesheet::Manager.new(theme_ids: []).stylesheet_data(:desktop),
          ].flatten.each { |s| css_links << s[:new_href] if s[:new_href].present? }
        rescue => e
          Rails.logger.warn("TopicContentView: stylesheet error: #{e.message}")
        end
      end

      base_css = begin; ActionController::Base.helpers.asset_path('desktop.css'); rescue; nil; end
      css_links.unshift(base_css) if base_css
      css_links.uniq!

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
          <script nonce="#{nonce}">#{INIT_SCRIPT}</script>
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
