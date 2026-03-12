# name: discourse-topic-content-view
# about: Adds configurable CSS classes to body via ?tcv=MODE query param, enabling mode-specific topic presentation (hide chrome, show only cooked content, etc.)
# version: 2.0.0
# authors: @denvergeeks
# url: https://github.com/denvergeeks/discourse-topic-content-view

enabled_site_setting :topic_content_view_enabled

register_asset "stylesheets/topic-content-view.scss", :desktop
