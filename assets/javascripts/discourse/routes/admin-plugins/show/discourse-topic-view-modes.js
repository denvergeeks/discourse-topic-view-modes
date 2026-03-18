import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowDiscourseTopicViewModes extends DiscourseRoute {
  model() {
    return this.modelFor("adminPlugins.show");
  }
}
