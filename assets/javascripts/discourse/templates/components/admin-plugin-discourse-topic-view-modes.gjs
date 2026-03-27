export default <template>
  <div class="tvm-admin-wrapper">
    {{#if this.loading}}
      <p>Loading modes…</p>
    {{else}}
      <div class="tvm-plugin-toggle">
        {{d-toggle-switch
          state=this.pluginEnabled
          label="topic_view_modes.admin.plugin_enabled"
          onClick=(action "togglePlugin")
        }}
      </div>

      <div class="tvm-modes-list">
        {{#each this.modes as |mode|}}
          <div
            class="tvm-mode-card
                   {{if mode.preset "is-preset"}}
                   {{unless mode.enabled "is-disabled"}}
                   {{if (eq mode.value this.expandedMode) "is-expanded"}}"
          >
            <div
              class="tvm-mode-header"
              {{action "toggleExpand" mode on="click"}}
            >
              <span class="tvm-mode-value">{{mode.value}}</span>
              <span class="tvm-mode-label">{{mode.label}}</span>

              {{d-toggle-switch
                state=mode.enabled
                onClick=(action "toggleModeEnabled" mode)
              }}

              <button {{action "removeMode" mode}}>
                {{d-icon "trash-can"}}
              </button>
            </div>

            {{#if (eq mode.value this.expandedMode)}}
              <div class="tvm-mode-details">
                <label>
                  Value
                  <input
                    type="text"
                    value={{mode.value}}
                    oninput={{action "updateField" mode "value"}}
                  >
                </label>

                <label>
                  Label
                  <input
                    type="text"
                    value={{mode.label}}
                    oninput={{action "updateField" mode "label"}}
                  >
                </label>

                <label>
                  CSS Classes
                  <input
                    type="text"
                    value={{mode.classes}}
                    oninput={{action "updateField" mode "classes"}}
                  >
                </label>

                <label>
                  Custom CSS
                  <textarea
                    oninput={{action "updateCss" mode}}
                  >{{mode.css}}</textarea>
                </label>
              </div>
            {{/if}}
          </div>
        {{/each}}
      </div>

      <div class="tvm-actions">
        <button {{action "addMode"}}>Add Mode</button>
        <button
          {{action "saveAll"}}
          disabled={{this.saving}}
        >
          {{if this.saving "Saving…" "Save All"}}
        </button>
      </div>
    {{/if}}
  </div>
</template>
