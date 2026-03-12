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
      const result = await ajax("/admin/plugins/discourse-topic-content-view");
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
    const newValue = !this.pluginEnabled;
    this.saving = true;
    ajax("/admin/site_settings/topic_content_view_enabled", {
      type: "PUT",
      data: { value: newValue },
    })
      .then(() => {
        this.siteSettings.topic_content_view_enabled = newValue;
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
      await ajax("/admin/plugins/discourse-topic-content-view", {
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
}
