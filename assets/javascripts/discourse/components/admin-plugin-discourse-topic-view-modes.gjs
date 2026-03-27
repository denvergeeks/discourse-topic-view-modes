import Component from "@glimmer/component";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { inject as service } from "@ember/service";
import DToggleSwitch from "discourse/components/d-toggle-switch";
import DIcon from "discourse/components/d-icon";

export default class AdminPluginDiscourseTopicViewModes extends Component {
  @service siteSettings;
  @tracked loading = true;
  @tracked saving = false;
  @tracked modes = [];
  @tracked expandedMode = null;

  get pluginEnabled() {
    return this.siteSettings.topic_view_modes_enabled;
  }

  constructor(owner, args) {
    super(owner, args);
    this.loadModes();
  }

  async loadModes() {
    this.loading = true;
    try {
      const data = await ajax("/admin/plugins/discourse-topic-view-modes/modes");
      this.modes = data.modes || [];
    } finally {
      this.loading = false;
    }
  }

  @action
  async togglePlugin() {
    this.siteSettings.set("topic_view_modes_enabled", !this.pluginEnabled);
  }

  @action
  toggleExpand(mode) {
    this.expandedMode =
      this.expandedMode === mode.value ? null : mode.value;
  }

  @action
  addMode() {
    this.modes = [
      ...this.modes,
      {
        value: "",
        label: "",
        classes: "",
        css: "",
        enabled: true,
        preset: false,
      },
    ];
    this.expandedMode = "";
  }

  @action
  removeMode(mode) {
    this.modes = this.modes.filter((m) => m !== mode);
    if (this.expandedMode === mode.value) {
      this.expandedMode = null;
    }
  }

  @action
  updateField(mode, field, event) {
    mode[field] = event.target.value;
  }

  @action
  updateCss(mode, event) {
    mode.css = event.target.value;
  }

  @action
  async toggleModeEnabled(mode) {
    mode.enabled = !mode.enabled;
  }

  @action
  async saveAll() {
    this.saving = true;
    try {
      await ajax(
        "/admin/plugins/discourse-topic-view-modes/modes",
        {
          type: "PUT",
          data: { modes: this.modes },
        }
      );
    } finally {
      this.saving = false;
    }
  }

  // expose imported components to the strict-mode template
  DToggleSwitch = DToggleSwitch;
  DIcon = DIcon;
}

export const template = <template>
  <div class="tvm-admin-wrapper">
    {{#if this.loading}}
      <p>Loading modes…</p>
    {{else}}
      <div class="tvm-plugin-toggle">
        <this.DToggleSwitch
          @state={{this.pluginEnabled}}
          @label="topic_view_modes.admin.plugin_enabled"
          @onClick={{action "togglePlugin"}}
        />
      </div>

      <div class="tvm-modes-list">
        {{#each this.modes as |mode|}}
          <div
            class="tvm-mode-card
                   {{if mode.preset "is-preset"}}
                   {{unless mode.enabled "is-disabled"}}
                   {{if (eq mode.value this.expandedMode) "is-expanded"}}"
          >
            <div
              class="tvm-mode-header"
              {{action "toggleExpand" mode on="click"}}
            >
              <span class="tvm-mode-value">{{mode.value}}</span>
              <span class="tvm-mode-label">{{mode.label}}</span>

              <this.DToggleSwitch
                @state={{mode.enabled}}
                @onClick={{action "toggleModeEnabled" mode}}
              />

              <button {{action "removeMode" mode}}>
                <this.DIcon @icon="trash-can" />
              </button>
            </div>

            {{#if (eq mode.value this.expandedMode)}}
              <div class="tvm-mode-details">
                <label>
                  Value
                  <input
                    type="text"
                    value={{mode.value}}
                    oninput={{action "updateField" mode "value"}}
                  >
                </label>

                <label>
                  Label
                  <input
                    type="text"
                    value={{mode.label}}
                    oninput={{action "updateField" mode "label"}}
                  >
                </label>

                <label>
                  CSS Classes
                  <input
                    type="text"
                    value={{mode.classes}}
                    oninput={{action "updateField" mode "classes"}}
                  >
                </label>

                <label>
                  Custom CSS
                  <textarea
                    oninput={{action "updateCss" mode}}
                  >{{mode.css}}</textarea>
                </label>
              </div>
            {{/if}}
          </div>
        {{/each}}
      </div>

      <div class="tvm-actions">
        <button {{action "addMode"}}>Add Mode</button>
        <button
          {{action "saveAll"}}
          disabled={{this.saving}}
        >
          {{if this.saving "Saving…" "Save All"}}
        </button>
      </div>
    {{/if}}
  </div>
</template>;
