export default {
  resource: "admin.adminPlugins",
  path: "/plugins",
  map() {
    this.route("show", { path: "/:plugin_id" }, function () {
      this.route("discourse-topic-view-modes", { path: "/settings" });
    });
  },
};
