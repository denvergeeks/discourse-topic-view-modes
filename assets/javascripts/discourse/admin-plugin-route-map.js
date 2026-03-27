export default {
  resource: "admin.adminPlugins",

  path: "/plugins",

  map() {
    this.route("discourse-topic-view-modes");
  },
};
