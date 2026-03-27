import AdminPluginDiscourseTopicViewModes from "discourse/plugins/discourse-topic-view-modes/discourse/components/admin-plugin-discourse-topic-view-modes";
import { i18n } from "discourse-i18n";

export default <template>
  <section class="tvm-admin-page">
    <h1>{{i18n "topic_view_modes.admin.title"}}</h1>

    <p>DEBUG: new show-route template is rendering.</p>

    <AdminPluginDiscourseTopicViewModes />
  </section>
</template>;
