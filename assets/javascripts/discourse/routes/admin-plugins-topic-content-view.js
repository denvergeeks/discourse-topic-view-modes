import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class AdminPluginsTopicContentViewRoute extends Route {
  async model() {
    const data = await ajax("/admin/plugins/topic-content-view");
    return data.modes || [];
  }
}
