import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DToggleSwitch from "discourse/components/d-toggle-switch";
import { i18n } from "discourse-i18n";
import dIcon from "discourse/helpers/d-icon";

const eq = (a, b) => a === b;

function modeCardClass(mode, expandedValue) {
  const classes = ["tvm-mode-card"];
  if (mode.preset) { classes.push("is-preset"); }
  if (!mode.enabled) { classes.push("is-disabled"); }
  if (mode.value === expandedValue) { classes.push("is-expanded"); }
  return classes.join(" ");
}

export default class AdminPluginDiscourseTopicViewModes extends Component {
  @service siteSettings;

  @tracked modes = [];
  @tracked saving = false;
  @tracked expandedMode = null;
  @tracked loading = true;

  constructor(owner, args) {
    super(owner, args);
    this.loadModes();
  }

  get pluginEnabled() {
    return this.siteSettings.topic_view_modes_enabled;
  }

  async loadModes() {
    this.loading = true;
    try {
      const result = await ajax("/admin/plugins/discourse-topic-view-modes");
      this.modes = result.modes || [];
    } catch (e) {
      try {
        this.modes = JSON.parse(this.siteSettings.topic_view_modes || "[]");
      } catch (_) {
        this.modes = [];
      }
    } finally {
      this.loading = false;
    }
  }

  @action
  togglePlugin() {
    const newValue = !this.pluginEnabled;
    this.saving = true;
    ajax("/admin/site_settings/topic_view_modes_enabled", {
      type: "PUT",
      data: { value: newValue },
    })
      .then(() => { this.siteSettings.topic_view_modes_enabled = newValue; })
      .catch(popupAjaxError)
      .finally(() => { this.saving = false; });
  }

  @action
  toggleExpand(mode) {
    this.expandedMode = this.expandedMode === mode.value ? null : mode.value;
  }

  @action
  updateField(mode, field, event) {
    mode[field] = event.target.value;
    this.modes = [...this.modes];
  }

  @action
  updateCss(mode, event) {
    mode.css = event.target.value;
    this.modes = [...this.modes];
  }

  @action
  toggleModeEnabled(mode) {
    mode.enabled = !mode.enabled;
    this.modes = [...this.modes];
  }

  @action
  addMode() {
    this.modes = [
      ...this.modes,
      { value: "", label: "", classes: "", css: "", preset: false, enabled: true },
    ];
  }

  @action
  removeMode(mode) {
    this.modes = this.modes.filter((m) => m !== mode);
    this.saveAll();
  }

  @action
  async saveAll() {
    this.saving = true;
    try {
      await ajax("/admin/plugins/discourse-topic-view-modes", {
        type: "PUT",
        contentType: "application/json",
        data: JSON.stringify({ modes: this.modes }),
      });
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.saving = false;
    }
  }

  <template>
    <div class="topic-view-modes-admin">
      <div class="admin-plugin-controls">
        <span class="admin-plugin-label">{{i18n "topic_view_modes.admin.plugin_enabled"}}</span>
        <DToggleSwitch
          @state={{this.pluginEnabled}}
          @disabled={{this.saving}}
          {{on "click" this.togglePlugin}}
        />
      </div>

      {{#if this.loading}}
        <div class="loading-spinner small"></div>
      {{else}}
        <div class="tvm-modes-list">
          {{#each this.modes as |mode|}}
            <div class={{modeCardClass mode this.expandedMode}}>
              <div class="tvm-mode-header" role="button" {{on "click" (fn this.toggleExpand mode)}}>
                <span class="tvm-mode-label">{{if mode.label mode.label mode.value}}</span>
                <span class="tvm-mode-value tvm-tag">{{mode.value}}</span>
                {{#if mode.preset}}
                  <span class="tvm-badge">{{i18n "topic_view_modes.admin.preset"}}</span>
                {{/if}}
                <DToggleSwitch
                  @state={{mode.enabled}}
                  @disabled={{this.saving}}
                  {{on "click" (fn this.toggleModeEnabled mode)}}
                />
                {{#unless mode.preset}}
                  <button class="btn btn-danger btn-small" {{on "click" (fn this.removeMode mode)}}>
                    {{dIcon "trash-can"}}
                  </button>
                {{/unless}}
              </div>
              {{#if (eq mode.value this.expandedMode)}}
                <div class="tvm-mode-fields">
                  <label>{{i18n "topic_view_modes.admin.field_value"}}
                    <input type="text" value={{mode.value}} disabled={{mode.preset}}
                      {{on "input" (fn this.updateField mode "value")}} />
                  </label>
                  <label>{{i18n "topic_view_modes.admin.field_label"}}
                    <input type="text" value={{mode.label}}
                      {{on "input" (fn this.updateField mode "label")}} />
                  </label>
                  <label>{{i18n "topic_view_modes.admin.field_classes"}}
                    <input type="text" value={{mode.classes}}
                      {{on "input" (fn this.updateField mode "classes")}} />
                  </label>
                  <label>{{i18n "topic_view_modes.admin.field_css"}}
                    <textarea {{on "input" (fn this.updateCss mode)}}>{{mode.css}}</textarea>
                  </label>
                  <button class="btn btn-primary" {{on "click" this.saveAll}} disabled={{this.saving}}>
                    {{dIcon "floppy-disk"}} {{i18n "topic_view_modes.admin.save_all"}}
                  </button>
                </div>
              {{/if}}
            </div>
          {{/each}}
        </div>
        <div class="tvm-actions">
          <button class="btn btn-default" {{on "click" this.addMode}} disabled={{this.saving}}>
            {{dIcon "plus"}} {{i18n "topic_view_modes.admin.add_mode"}}
          </button>
        </div>
      {{/if}}
    </div>
  </template>
}
