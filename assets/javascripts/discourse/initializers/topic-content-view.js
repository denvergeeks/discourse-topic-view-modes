import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "topic-content-view",

  initialize() {
    withPluginApi("1.0.0", (api) => {
      // On every page change, check if ?tcv=1 is in the URL.
      // If so, add 'tcv-mode' to <body> so the SCSS hides all chrome.
      api.onPageChange((url) => {
        const hasTcvParam =
          new URLSearchParams(window.location.search).get("tcv") === "1";
        document.body.classList.toggle("tcv-mode", hasTcvParam);
      });
    });
  },
};
