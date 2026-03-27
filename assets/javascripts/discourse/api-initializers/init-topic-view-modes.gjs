import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("0.8.57", (api) => {
  api.addAdminPluginConfigurationNav("discourse-topic-view-modes", () => {
    return {
      name: "discourse-topic-view-modes",
      label: "topic_view_modes.admin.title",
      links: [
        {
          name: "modes",
          label: "topic_view_modes.admin.modes_tab_label",
          route: "adminPlugins.show.discourse-topic-view-modes",
          description: "topic_view_modes.admin.modes_tab_description",
        },
      ],
    };
  });
});
