export default {
  resource: "admin.adminPlugins",
  path: "/plugins",
  map() {
    this.route("topic-content-view", { path: "/topic-content-view" });
  },
};
