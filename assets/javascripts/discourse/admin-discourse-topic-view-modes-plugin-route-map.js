export default {
  resource: "admin.adminPlugins.show",
  path: "/plugins",
  map() {
    this.route("discourse-topic-view-modes", {
      path: "discourse-topic-view-modes",
    });
  },
};
