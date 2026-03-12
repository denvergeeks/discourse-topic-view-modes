import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/components/d-button";
import DToggleSwitch from "discourse/components/d-toggle-switch";
import { i18n } from "discourse-i18n";

// Tiny unique-id helper so each new mode gets a stable JS key
let _uid = 0;
function uid() { return ++_uid; }

class ModeItem {
  @tracked label;
  @tracked value;
  @tracked classes;
  @tracked css;
  @tracked preset;
  @tracked enabled;
  @tracked expanded = false;
  _key; // stable identity for {{each}}

  constructor({ value, label, classes, css, preset, enabled }) {
    this.value   = value   ?? "";
    this.label   = label   ?? "";
    this.classes = classes ?? "";
    this.css     = css     ?? "";
    this.preset  = preset  ?? false;
    this.enabled = enabled !== false; // default on
    this._key    = uid();
  }
}

export default class AdminPluginsTopicContentView extends Component {
  @service router;

  @tracked modes = [];
  @tracked _globalSaving = false;
  @tracked _globalSaved  = false;

  constructor(owner, args) {
    super(owner, args);
    this._loadModes();
  }

  async _loadModes() {
    try {
      const data = await ajax("/admin/plugins/topic-content-view");
      this.modes = (data.modes || []).map((m) => new ModeItem(m));
    } catch (e) {
      popupAjaxError(e);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  @action
  addMode() {
    const newMode = new ModeItem({ value: "", label: "", classes: "tcv-mode", css: "", preset: false, enabled: true });
    newMode.expanded = true;
    this.modes = [newMode, ...this.modes];
  }

  @action
  toggleExpanded(mode) {
    mode.expanded = !mode.expanded;
  }

  @action
  toggleEnabled(mode) {
    mode.enabled = !mode.enabled;
  }

  @action
  removeMode(mode) {
    if (mode.preset) return;
    this.modes = this.modes.filter((m) => m._key !== mode._key);
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
  async saveAll() {
    this._globalSaving = true;
    this._globalSaved  = false;

    const invalid = this.modes.find((m) => !m.value.trim());
    if (invalid) {
      invalid.expanded = true;
      this._globalSaving = false;
      return;
    }

    try {
      await ajax("/admin/plugins/topic-content-view", {
        type: "PUT",
        data: {
          modes: this.modes.map((m) => ({
            value:   m.value.trim(),
            label:   m.label.trim(),
            classes: m.classes.trim(),
            css:     m.css,
            preset:  m.preset,
            enabled: m.enabled,
          })),
        },
      });
      this._globalSaved = true;
      setTimeout(() => (this._globalSaved = false), 2500);
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this._globalSaving = false;
    }
  }

  // ── Template ──────────────────────────────────────────────────────────────

  <template>
    <div class="tcv-admin">
      <div class="tcv-admin-header">
        <div class="tcv-admin-header-text">
          <h2>{{i18n "topic_content_view.admin.title"}}</h2>
          <p class="tcv-admin-description">{{i18n "topic_content_view.admin.description"}}</p>
        </div>
        <div class="tcv-admin-header-actions">
          <DButton
            @action={{this.addMode}}
            @label="topic_content_view.admin.add_mode"
            @icon="plus"
            class="btn-default tcv-add-btn"
          />
          <DButton
            @action={{this.saveAll}}
            @label={{if this._globalSaving "saving" "topic_content_view.admin.save_all"}}
            @disabled={{this._globalSaving}}
            class="btn-primary tcv-save-all-btn"
          />
          {{#if this._globalSaved}}
            <span class="tcv-saved-indicator">{{i18n "saved"}}</span>
          {{/if}}
        </div>
      </div>

      <div class="tcv-mode-list">
        {{#each this.modes key="_key" as |mode|}}
          <div class="tcv-mode-card {{if mode.expanded 'is-expanded'}} {{if mode.preset 'is-preset'}} {{unless mode.enabled 'is-disabled'}}">

            {{! ── Card header ── }}
            <div class="tcv-mode-card-header">
              <span
                class="tcv-mode-card-toggle-area"
                role="button"
                {{on "click" (fn this.toggleExpanded mode)}}
              >
                <span class="tcv-mode-card-arrow">
                  {{#if mode.expanded}}&#9660;{{else}}&#9654;{{/if}}
                </span>
                <span class="tcv-mode-card-title">
                  {{#if mode.label}}
                    {{mode.label}}
                  {{else}}
                    <em class="tcv-untitled">{{i18n "topic_content_view.admin.untitled"}}</em>
                  {{/if}}
                </span>
                <span class="tcv-mode-card-slug">
                  {{#if mode.value}}?tcv={{mode.value}}{{/if}}
                </span>
                {{#if mode.preset}}
                  <span class="tcv-preset-badge">{{i18n "topic_content_view.admin.preset"}}</span>
                {{/if}}
              </span>

              <span class="tcv-mode-card-controls">
                <DToggleSwitch
                  @state={{mode.enabled}}
                  @label={{if mode.enabled "topic_content_view.admin.enabled" "topic_content_view.admin.disabled"}}
                  {{on "click" (fn this.toggleEnabled mode)}}
                />
                {{#unless mode.preset}}
                  <DButton
                    @action={{fn this.removeMode mode}}
                    @icon="trash-can"
                    @title="topic_content_view.admin.delete_mode"
                    class="btn-flat tcv-delete-btn"
                  />
                {{/unless}}
              </span>
            </div>

            {{! ── Card body (expanded) ── }}
            {{#if mode.expanded}}
              <div class="tcv-mode-card-body">

                <div class="tcv-field-row">
                  <label>{{i18n "topic_content_view.admin.field_label"}}</label>
                  <input
                    type="text"
                    value={{mode.label}}
                    placeholder="e.g. Clean Read"
                    {{on "input" (fn this.updateField mode "label")}}
                  />
                </div>

                <div class="tcv-field-row">
                  <label>
                    {{i18n "topic_content_view.admin.field_value"}}
                    {{#if mode.preset}}
                      <span class="tcv-field-readonly-note">({{i18n "topic_content_view.admin.preset_readonly"}})</span>
                    {{/if}}
                  </label>
                  <input
                    type="text"
                    value={{mode.value}}
                    placeholder="e.g. clean"
                    disabled={{mode.preset}}
                    {{on "input" (fn this.updateField mode "value")}}
                  />
                  <p class="tcv-field-hint">{{i18n "topic_content_view.admin.field_value_hint"}}</p>
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
                    placeholder="/* CSS injected when ?tcv={{mode.value}} is active */"
                    {{on "input" (fn this.updateCss mode)}}
                  >{{mode.css}}</textarea>
                  <p class="tcv-field-hint">{{i18n "topic_content_view.admin.field_css_hint"}}</p>
                </div>

              </div>
            {{/if}}

          </div>
        {{/each}}
      </div>

    </div>
  </template>
}
