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

function eq(a, b) {
  return a === b;
}

export default class AdminPluginsTopicContentView extends Component {
  @service siteSettings;

  @tracked modes = [];
  @tracked saving = false;
  @tracked expandedMode = null;

  constructor() {
    super(...arguments);
    this.loadModes();
  }

  get pluginEnabled() {
    return this.siteSettings.topic_content_view_enabled;
  }

  async loadModes() {
    try {
      const raw = this.siteSettings.topic_content_view_modes;
      this.modes = JSON.parse(raw || "[]");
    } catch (e) {
      this.modes = [];
    }
  }

  @action
  togglePlugin() {
    this.saving = true;
    ajax("/admin/site_settings/topic_content_view_enabled", {
      type: "PUT",
      data: { value: !this.pluginEnabled },
    })
      .then(() => {
        this.siteSettings.topic_content_view_enabled = !this.pluginEnabled;
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.saving = false;
      });
  }

  @action
  toggleExpand(mode) {
    this.expandedMode = this.expandedMode === mode.value ? null : mode.value;
  }

  @action
  updateField(mode, field, event) {
    mode[field] = event.target.value;
    this.saveModes();
  }

  @action
  updateCss(mode, event) {
    mode.css = event.target.value;
    this.saveModes();
  }

  @action
  toggleModeEnabled(mode) {
    mode.enabled = !mode.enabled;
    this.saveModes();
  }

  @action
  addMode() {
    this.modes = [
      ...this.modes,
      {
        value: "",
        label: "",
        icon: "",
        classes: "",
        css: "",
        enabled: true,
      },
    ];
  }

  @action
  removeMode(mode) {
    this.modes = this.modes.filter((m) => m !== mode);
    this.saveModes();
  }

  saveModes() {
    ajax("/admin/site_settings/topic_content_view_modes", {
      type: "PUT",
      data: { value: JSON.stringify(this.modes) },
    }).catch(popupAjaxError);
  }

  <template>
    <div class="tcv-admin-panel">
      <div class="tcv-admin-header">
        <h2>{{i18n "topic_content_view.admin.title"}}</h2>
        <DToggleSwitch
          @state={{this.pluginEnabled}}
          @label={{i18n "topic_content_view.admin.enabled_label"}}
          @onChange={{this.togglePlugin}}
        />
      </div>

      <div class="tcv-modes-list">
        {{#each this.modes as |mode|}}
          <div class="tcv-mode-card">
            <div class="tcv-mode-card-header">
              <span class="tcv-mode-label">{{mode.label}}</span>
              <div class="tcv-mode-actions">
                <DToggleSwitch
                  @state={{mode.enabled}}
                  @onChange={{fn this.toggleModeEnabled mode}}
                />
                <button
                  type="button"
                  class="btn btn-flat tcv-expand-btn"
                  {{on "click" (fn this.toggleExpand mode)}}
                >
                  {{if (eq this.expandedMode mode.value) "▲" "▼"}}
                </button>
                <button
                  type="button"
                  class="btn btn-danger btn-small"
                  {{on "click" (fn this.removeMode mode)}}
                >
                  {{i18n "topic_content_view.admin.remove"}}
                </button>
              </div>
            </div>

            {{#if (eq this.expandedMode mode.value)}}
              <div class="tcv-mode-card-body">
                <div class="tcv-field-row">
                  <label>{{i18n "topic_content_view.admin.field_value"}}</label>
                  <input
                    type="text"
                    value={{mode.value}}
                    placeholder="e.g. compact"
                    {{on "input" (fn this.updateField mode "value")}}
                  />
                </div>
                <div class="tcv-field-row">
                  <label>{{i18n "topic_content_view.admin.field_label"}}</label>
                  <input
                    type="text"
                    value={{mode.label}}
                    placeholder="e.g. Compact View"
                    {{on "input" (fn this.updateField mode "label")}}
                  />
                </div>
                <div class="tcv-field-row">
                  <label>{{i18n "topic_content_view.admin.field_icon"}}</label>
                  <input
                    type="text"
                    value={{mode.icon}}
                    placeholder="e.g. list"
                    {{on "input" (fn this.updateField mode "icon")}}
                  />
                </div>
                <div class="tcv-field-row">
                  <label>{{i18n "topic_content_view.admin.field_classes"}}</label>
                  <input
                    type="text"
                    value={{mode.classes}}
                    placeholder="tcv-mode tcv-custom"
                    {{on "input" (fn this.updateField mode "classes")}}
                  />
                  <p class="tcv-field-hint">{{i18n "topic_content_view.admin.field_classes_hint"}}</p>
                </div>
                <div class="tcv-field-row tcv-css-field">
                  <label>{{i18n "topic_content_view.admin.field_css"}}</label>
                  <textarea
                    class="tcv-css-editor"
                    rows="10"
                    placeholder="/* CSS injected when this mode is active */"
                    {{on "input" (fn this.updateCss mode)}}
                  >{{mode.css}}</textarea>
                  <p class="tcv-field-hint">{{i18n "topic_content_view.admin.field_css_hint"}}</p>
                </div>
              </div>
            {{/if}}
          </div>
        {{/each}}
      </div>

      <button
        type="button"
        class="btn btn-primary tcv-add-mode"
        {{on "click" this.addMode}}
      >
        {{i18n "topic_content_view.admin.add_mode"}}
      </button>
    </div>
  </template>
}
