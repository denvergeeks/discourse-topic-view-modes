export default {
  resource: "admin.adminPlugins.show",
  map() {
    this.route("discourse-topic-view-modes", {
      path: "discourse-topic-view-modes",
    });
  },
};
