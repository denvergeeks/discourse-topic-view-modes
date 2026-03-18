# frozen_string_literal: true

module TopicViewModes
  class AdminController < ::Admin::AdminController
    def index
      modes = JSON.parse(SiteSetting.topic_view_modes_modes || "[]")
      render json: { modes: modes }
    rescue JSON::ParserError
      render json: { modes: [] }
    end

    def update
      body = JSON.parse(request.body.read)
      modes = body["modes"]

      raise Discourse::InvalidParameters unless modes.is_a?(Array)

      sanitized = modes.map do |m|
        {
          "value"   => m["value"].to_s.strip,
          "label"   => m["label"].to_s.strip,
          "classes" => m["classes"].to_s.strip,
          "css"     => m["css"].to_s.strip,
          "enabled" => m["enabled"] == true,
          "preset"  => m["preset"] == true
        }
      end

      SiteSetting.topic_view_modes = sanitized.to_json
      render json: success_json
    rescue JSON::ParserError
      render json: failed_json, status: 422
    end
  end
end
