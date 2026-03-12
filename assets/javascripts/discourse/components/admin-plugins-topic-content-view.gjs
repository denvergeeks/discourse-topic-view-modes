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

export default class AdminPluginsTopicContentView extends Component {
  @service siteSettings;

  @tracked modes = [];
  @tracked saving = false;
  @tracked expandedMode = null;
  @tracked loading = true;

  constructor() {
    super(...arguments);
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
      // fallback: try parsing from siteSettings
      try {
        const raw = this.siteSettings.topic_content_view_modes;
        this.modes = JSON.parse(raw || "[]");
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
      {
        value: "",
        label: "",
        classes: "",
        css: "",
        preset: false,
        enabled: true,
      },
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
        data: JSON.stringify({ modes: this.modes }),
        contentType: "application/json",
      });
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.saving = false;
    }
  }

  <template>
    <div class="tcv-admin-panel">
      <div class="tcv-admin-header">
        <div class="tcv-admin-title">
          <h2>{{i18n "topic_content_view.admin.title"}}</h2>
          <p class="tcv-admin-description">{{i18n "topic_content_view.admin.description"}}</p>
        </div>
        <div class="tcv-admin-controls">
          <DToggleSwitch
            @state={{this.pluginEnabled}}
            @label={{if this.pluginEnabled (i18n "topic_content_view.admin.enabled") (i18n "topic_content_view.admin.disabled")}}
            {{on "click" this.togglePlugin}}
          />
        </div>
      </div>

      {{#if this.loading}}
        <div class="tcv-loading">Loading...</div>
      {{else}}
        <div class="tcv-modes-list">
          {{#each this.modes as |mode|}}
            <div class="tcv-mode-card {{if mode.preset \"tcv-mode-preset\"}} {{unless mode.enabled \"tcv-mode-disabled\"}}">
              <div class="tcv-mode-card-header">
                <div class="tcv-mode-card-title">
                  <span class="tcv-mode-slug">?tcv={{if mode.value mode.value (i18n "topic_content_view.admin.untitled")}}</span>
                  {{#if mode.label}}
                    <span class="tcv-mode-label">{{mode.label}}</span>
                  {{/if}}
                  {{#if mode.preset}}
                    <span class="tcv-mode-badge">{{i18n "topic_content_view.admin.preset"}}</span>
                  {{/if}}
                </div>
                <div class="tcv-mode-card-actions">
                  <DToggleSwitch
                    @state={{mode.enabled}}
                    @label={{if mode.enabled (i18n "topic_content_view.admin.enabled") (i18n "topic_content_view.admin.disabled")}}
                    {{on "click" (fn this.toggleModeEnabled mode)}}
                    @disabled={{mode.preset}}
                  />
                  <button
                    type="button"
                    class="btn btn-small tcv-expand-btn"
                    {{on "click" (fn this.toggleExpand mode)}}
                  >
                    {{if (eq this.expandedMode mode.value) "▲" "▼"}}
                  </button>
                  {{#unless mode.preset}}
                    <button
                      type="button"
                      class="btn btn-small btn-danger tcv-delete-btn"
                      title={{i18n "topic_content_view.admin.delete_mode"}}
                      {{on "click" (fn this.removeMode mode)}}
                    >
                      {{i18n "topic_content_view.admin.delete_mode"}}
                    </button>
                  {{/unless}}
                </div>
              </div>

              {{#if (eq this.expandedMode mode.value)}}
                <div class="tcv-mode-card-body">
                  <div class="tcv-field">
                    <label class="tcv-field-label">{{i18n "topic_content_view.admin.field_label"}}</label>
                    <input
                      type="text"
                      class="tcv-field-input"
                      value={{mode.label}}
                      {{on "input" (fn this.updateField mode "label")}}
                    />
                  </div>
                  <div class="tcv-field">
                    <label class="tcv-field-label">{{i18n "topic_content_view.admin.field_value"}}</label>
                    <input
                      type="text"
                      class="tcv-field-input"
                      value={{mode.value}}
                      disabled={{mode.preset}}
                      {{on "input" (fn this.updateField mode "value")}}
                    />
                    <span class="tcv-field-hint">{{i18n "topic_content_view.admin.field_value_hint"}}</span>
                  </div>
                  <div class="tcv-field">
                    <label class="tcv-field-label">{{i18n "topic_content_view.admin.field_classes"}}</label>
                    <input
                      type="text"
                      class="tcv-field-input"
                      value={{mode.classes}}
                      disabled={{mode.preset}}
                      {{on "input" (fn this.updateField mode "classes")}}
                    />
                    <span class="tcv-field-hint">{{i18n "topic_content_view.admin.field_classes_hint"}}</span>
                  </div>
                  <div class="tcv-field">
                    <label class="tcv-field-label">{{i18n "topic_content_view.admin.field_css"}}</label>
                    <textarea
                      class="tcv-field-textarea"
                      {{on "input" (fn this.updateCss mode)}}
                    >{{mode.css}}</textarea>
                    <span class="tcv-field-hint">{{i18n "topic_content_view.admin.field_css_hint"}}</span>
                  </div>
                </div>
              {{/if}}
            </div>
          {{/each}}
        </div>

        <div class="tcv-admin-footer">
          <button
            type="button"
            class="btn btn-default tcv-add-btn"
            {{on "click" this.addMode}}
          >
            {{i18n "topic_content_view.admin.add_mode"}}
          </button>
          <button
            type="button"
            class="btn btn-primary tcv-save-btn"
            disabled={{this.saving}}
            {{on "click" this.saveAll}}
          >
            {{i18n "topic_content_view.admin.save_all"}}
          </button>
        </div>
      {{/if}}
    </div>
  </template>
}
