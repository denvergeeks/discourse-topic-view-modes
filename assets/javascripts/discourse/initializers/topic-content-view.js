import { withPluginApi } from "discourse/lib/plugin-api";

// Parse the pipe-separated mode definitions from site settings.
// Each entry is "mode_value|class1 class2 class3"
function parseModes(rawSetting) {
  if (!rawSetting) return [];
  return rawSetting
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => {
      const idx = line.indexOf("|");
      if (idx === -1) return null;
      return {
        value: line.slice(0, idx).trim(),
        classes: line.slice(idx + 1).trim().split(/\s+/).filter(Boolean),
      };
    })
    .filter(Boolean);
}

// Remove any previously applied tcv body classes
function clearTcvClasses() {
  const toRemove = [...document.body.classList].filter((c) =>
    c.startsWith("tcv-")
  );
  document.body.classList.remove(...toRemove);
}

export default {
  name: "topic-content-view",

  initialize(container) {
    withPluginApi("1.0.0", (api) => {
      const siteSettings = container.lookup("service:site-settings");

      api.onPageChange(() => {
        clearTcvClasses();

        if (!siteSettings.topic_content_view_enabled) return;

        const modeParam = new URLSearchParams(window.location.search).get("tcv");
        if (!modeParam) return;

        // Merge built-in modes + admin-defined custom modes
        const allModes = [
          ...parseModes(siteSettings.topic_content_view_modes),
          ...parseModes(siteSettings.topic_content_view_custom_modes),
        ];

        const match = allModes.find((m) => m.value === modeParam);
        if (match) {
          document.body.classList.add(...match.classes);
        }
      });
    });
  },
};
