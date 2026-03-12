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

// Inject (or remove) the per-mode custom SCSS into a <style> tag
function applyModeScss(modeValue, scssMap) {
  // Remove any previously injected style
  const existing = document.getElementById("tcv-mode-custom-scss");
  if (existing) existing.remove();

  if (!modeValue || !scssMap) return;

  let map = {};
  try {
    map = typeof scssMap === "string" ? JSON.parse(scssMap) : scssMap;
  } catch (_) {
    return;
  }

  const scss = map[modeValue];
  if (!scss || !scss.trim()) return;

  // NOTE: Discourse compiles SCSS server-side; client-side we inject as plain CSS.
  // Admins should write valid CSS (not SCSS-specific syntax like nesting or variables
  // beyond CSS custom properties) for runtime injection to work correctly.
  const style = document.createElement("style");
  style.id = "tcv-mode-custom-scss";
  style.textContent = scss;
  document.head.appendChild(style);
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

        // Inject admin-saved SCSS for this mode
        applyModeScss(modeParam, siteSettings.topic_content_view_mode_scss);
      });
    });
  },
};
