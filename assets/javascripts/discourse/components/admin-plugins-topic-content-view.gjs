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
  const classes = ["tcv-mode-card"];
  if (mode.preset) { classes.push("is-preset"); }
  if (!mode.enabled) { classes.push("is-disabled"); }
  if (mode.value === expandedValue) { classes.push("is-expanded"); }
  return classes.join(" ");
}

export default class AdminPluginsTopicContentView extends Component {
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
    return this.siteSettings.topic_content_view_enabled;
  }

  async loadModes() {
    this.loading = true;
    try {
      const result = await ajax("/admin/plugins/topic-content-view");
      this.modes = result.modes || [];
    } catch (e) {
      try {
        this.modes = JSON.parse(
          this.siteSettings.topic_content_view_modes || "[]"
        );
      } catch (_) {
        this.modes = [];
      }
    } finally {
      this.loading = false;
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
      await ajax("/admin/plugins/topic-content-view", {
        type: "PUT",
        data: { modes: this.modes },
      });
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.saving = false;
    }
  }

  <template>
    <div class="tcv-admin">
      <div class="tcv-admin-header">
        <div class="tcv-admin-header-text">
          <h2>{{i18n "topic_content_view.admin.title"}}</h2>
          <p class="tcv-admin-description">{{i18n "topic_content_view.admin.description"}}</p>
        </div>
        <div class="tcv-admin-header-actions">
          <DToggleSwitch
            @state={{this.pluginEnabled}}
            {{on "click" this.togglePlugin}}
          />
          <button
            type="button"
            class="btn btn-primary"
            disabled={{this.saving}}
            {{on "click" this.saveAll}}
          >
            {{i18n "topic_content_view.admin.save_all"}}
          </button>
          <button
            type="button"
            class="btn btn-default"
            {{on "click" this.addMode}}
          >
            {{i18n "topic_content_view.admin.add_mode"}}
          </button>
        </div>
      </div>

      {{#if this.loading}}
        <div class="loading-spinner"></div>
      {{else}}
        <div class="tcv-mode-list">
          {{#each this.modes as |mode|}}
            <div class={{modeCardClass mode this.expandedMode}}>
              <div class="tcv-mode-card-header">
                <button
                  type="button"
                  class="tcv-mode-card-toggle-area"
                  {{on "click" (fn this.toggleExpand mode)}}
                >
                  <span class="tcv-mode-card-arrow">
                    {{#if (eq this.expandedMode mode.value)}}▼{{else}}▶{{/if}}
                  </span>
                  <span class="tcv-mode-card-title">
                    {{#if mode.label}}
                      {{mode.label}}
                    {{else}}
                      <span class="tcv-untitled">{{i18n "topic_content_view.admin.untitled"}}</span>
                    {{/if}}
                  </span>
                  {{#if mode.value}}
                    <span class="tcv-mode-card-slug">?tcv={{mode.value}}</span>
                  {{/if}}
                  {{#if mode.preset}}
                    <span class="tcv-preset-badge">{{i18n "topic_content_view.admin.preset"}}</span>
                  {{/if}}
                </button>
                <div class="tcv-mode-card-controls">
                  <DToggleSwitch
                    @state={{mode.enabled}}
                    {{on "click" (fn this.toggleModeEnabled mode)}}
                  />
                  {{#unless mode.preset}}
                    <button
                      type="button"
                      class="btn-flat tcv-delete-btn"
                      title={{i18n "topic_content_view.admin.delete_mode"}}
                      {{on "click" (fn this.removeMode mode)}}
                    >
                                  <dIcon @name="trash-can" />
                    </button>
                  {{/unless}}
                </div>
              </div>

              {{#if (eq this.expandedMode mode.value)}}
                <div class="tcv-mode-card-body">
                  <div class="tcv-field-row">
                    <label>{{i18n "topic_content_view.admin.field_label"}}</label>
                    <input
                      type="text"
                      value={{mode.label}}
                      {{on "input" (fn this.updateField mode "label")}}
                    />
                  </div>
                  <div class="tcv-field-row">
                    <label>{{i18n "topic_content_view.admin.field_value"}}</label>
                    {{#if mode.preset}}
                      <input type="text" value={{mode.value}} disabled />
                      <p class="tcv-field-readonly-note">{{i18n "topic_content_view.admin.preset_readonly"}}</p>
                    {{else}}
                      <input
                        type="text"
                        value={{mode.value}}
                        {{on "input" (fn this.updateField mode "value")}}
                      />
                    {{/if}}
                    <p class="tcv-field-hint">{{i18n "topic_content_view.admin.field_value_hint"}}</p>
                  </div>
                  <div class="tcv-field-row">
                    <label>{{i18n "topic_content_view.admin.field_classes"}}</label>
                    {{#if mode.preset}}
                      <input type="text" value={{mode.classes}} disabled />
                      <p class="tcv-field-readonly-note">{{i18n "topic_content_view.admin.preset_readonly"}}</p>
                    {{else}}
                      <input
                        type="text"
                        value={{mode.classes}}
                        {{on "input" (fn this.updateField mode "classes")}}
                      />
                    {{/if}}
                    <p class="tcv-field-hint">{{i18n "topic_content_view.admin.field_classes_hint"}}</p>
                  </div>
                  <div class="tcv-field-row tcv-css-field">
                    <label>{{i18n "topic_content_view.admin.field_css"}}</label>
                    <textarea
                      class="tcv-css-editor"
                      {{on "input" (fn this.updateCss mode)}}
                    >{{mode.css}}</textarea>
                    <p class="tcv-field-hint">{{i18n "topic_content_view.admin.field_css_hint"}}</p>
                  </div>
                </div>
              {{/if}}
            </div>
          {{/each}}
        </div>
      {{/if}}
    </div>
  </template>
}
