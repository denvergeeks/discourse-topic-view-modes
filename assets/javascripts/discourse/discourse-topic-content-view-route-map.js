export default {
  resource: "admin.adminPlugins.show",
  path: "/plugins",
  map() {
    this.route("discourse-topic-content-view", { path: "topic-content-view" });
  },
};
