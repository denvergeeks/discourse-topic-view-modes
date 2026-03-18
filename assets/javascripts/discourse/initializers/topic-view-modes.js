import { withPluginApi } from "discourse/lib/plugin-api";

function parseModes(rawSetting) {
  if (!rawSetting) return [];
  try {
    const modes = JSON.parse(rawSetting);
    if (!Array.isArray(modes)) return [];
    return modes.filter((m) => m && m.value && m.enabled !== false);
  } catch (_) {
    return [];
  }
}

function clearTcvClasses() {
  const toRemove = [...document.body.classList].filter((c) =>
    c.startsWith("tcv-")
  );
  if (toRemove.length) {
    document.body.classList.remove(...toRemove);
  }
}

function applyModeCss(modeValue, modes) {
  document.getElementById("tcv-mode-custom-css")?.remove();
  if (!modeValue || !modes?.length) return;
  const mode = modes.find((m) => m.value === modeValue);
  if (!mode?.css?.trim()) return;
  const style = document.createElement("style");
  style.id = "tcv-mode-custom-css";
  style.textContent = mode.css;
  document.head.appendChild(style);
}

export default {
  name: "topic-content-view",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");

    withPluginApi("1.3.0", (api) => {
      api.onPageChange(() => {
        clearTcvClasses();
        if (!siteSettings.topic_content_view_enabled) return;

        const modeParam = new URLSearchParams(window.location.search).get(
          "tcv"
        );
        if (!modeParam) return;

        const enabledModes = parseModes(
          siteSettings.topic_content_view_modes
        );
        const match = enabledModes.find((m) => m.value === modeParam);
        if (match?.classes) {
          document.body.classList.add(
            ...match.classes.split(/\s+/).filter(Boolean)
          );
        }
        applyModeCss(modeParam, enabledModes);
      });
    });
  },
};
