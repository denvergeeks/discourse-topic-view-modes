import Component from "@glimmer/component";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { inject as service } from "@ember/service";
import DToggleSwitch from "discourse/components/d-toggle-switch";
import { eq } from "@ember/object/computed";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";

export default class AdminPluginDiscourseTopicViewModes extends Component {
  @service siteSettings;

  @tracked loading = true;
  @tracked saving = false;
  @tracked modes = [];
  @tracked expandedMode = null;

  DToggleSwitch = DToggleSwitch;
  eq = eq;
  on = on;
  fn = fn;

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
  togglePlugin() {
    this.siteSettings.set(
      "topic_view_modes_enabled",
      !this.pluginEnabled
    );
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
  toggleModeEnabled(mode) {
    mode.enabled = !mode.enabled;
  }

  @action
  async saveAll() {
    this.saving = true;
    try {
      await ajax("/admin/plugins/discourse-topic-view-modes/modes", {
        type: "PUT",
        data: { modes: this.modes },
      });
    } finally {
      this.saving = false;
    }
  }
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
          @onClick={{this.togglePlugin}}
        />
      </div>

      <div class="tvm-modes-list">
        {{#each this.modes as |mode|}}
          <div
            class="tvm-mode-card
                   {{if mode.preset "is-preset"}}
                   {{unless mode.enabled "is-disabled"}}
                   {{if (this.eq mode.value this.expandedMode) "is-expanded"}}"
          >
            <div
              class="tvm-mode-header"
              {{this.on "click" (this.fn this.toggleExpand mode)}}
            >
              <span class="tvm-mode-value">{{mode.value}}</span>
              <span class="tvm-mode-label">{{mode.label}}</span>

              <this.DToggleSwitch
                @state={{mode.enabled}}
                @onClick={{this.fn this.toggleModeEnabled mode}}
              />

              <button
                type="button"
                {{this.on "click" (this.fn this.removeMode mode)}}
              >
                {{d-icon "trash-can"}}
              </button>
            </div>

            {{#if (this.eq mode.value this.expandedMode)}}
              <div class="tvm-mode-details">
                <label>
                  Value
                  <input
                    type="text"
                    value={{mode.value}}
                    {{this.on "input" (this.fn this.updateField mode "value")}}
                  >
                </label>

                <label>
                  Label
                  <input
                    type="text"
                    value={{mode.label}}
                    {{this.on "input" (this.fn this.updateField mode "label")}}
                  >
                </label>

                <label>
                  CSS Classes
                  <input
                    type="text"
                    value={{mode.classes}}
                    {{this.on "input" (this.fn this.updateField mode "classes")}}
                  >
                </label>

                <label>
                  Custom CSS
                  <textarea
                    {{this.on "input" (this.fn this.updateCss mode)}}
                  >{{mode.css}}</textarea>
                </label>
              </div>
            {{/if}}
          </div>
        {{/each}}
      </div>

      <div class="tvm-actions">
        <button
          type="button"
          {{this.on "click" this.addMode}}
        >
          Add Mode
        </button>
        <button
          type="button"
          {{this.on "click" this.saveAll}}
          disabled={{this.saving}}
        >
          {{if this.saving "Saving…" "Save All"}}
        </button>
      </div>
    {{/if}}
  </div>
</template>;
