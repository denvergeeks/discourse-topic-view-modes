export default {
  name: "topic-content-routes",

  initialize() {
    const router = requirejs("discourse/mapping-router").default;

    router.map(function () {
      // /t/some-slug/123/content  →  topic-content-show route, params: { slug, id }
      this.route("topic-content-show", {
        path: "/t/:slug/:id/content",
      });

      // /t/123/content  →  same route, id-only form
      this.route("topic-content-show", {
        path: "/t/:id/content",
      });
    });
  },
};
