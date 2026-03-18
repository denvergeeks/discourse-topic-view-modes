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

function clearTvmClasses() {
  const toRemove = [...document.body.classList].filter((c) =>
    c.startsWith("tvm-")
  );
  if (toRemove.length) {
    document.body.classList.remove(...toRemove);
  }
}

function applyModeCss(modeValue, modes) {
  document.getElementById("tvm-mode-custom-css")?.remove();
  if (!modeValue || !modes?.length) return;
  const mode = modes.find((m) => m.value === modeValue);
  if (!mode?.css?.trim()) return;
  const style = document.createElement("style");
  style.id = "tvm-mode-custom-css";
  style.textContent = mode.css;
  document.head.appendChild(style);
}

export default {
  name: "topic-view-modes",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");

    withPluginApi("1.3.0", (api) => {
      api.onPageChange(() => {
        clearTvmClasses();
        if (!siteSettings.topic_view_modes_enabled) return;

        const modeParam = new URLSearchParams(window.location.search).get(
          "tvm"
        );
        if (!modeParam) return;

        const enabledModes = parseModes(
          siteSettings.topic_view_modes_modes
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
