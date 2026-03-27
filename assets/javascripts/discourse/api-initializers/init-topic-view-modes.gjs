import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("0.8.57", (api) => {
  api.modifyPluginShowNav("discourse-topic-view-modes", (navItems) => {
    navItems.add({
      name: "modes",
      route: "adminPlugins.show.discourse-topic-view-modes", // no sub-route
      label: "topic_view_modes.admin.modes_tab_label",
    });
  });
});
