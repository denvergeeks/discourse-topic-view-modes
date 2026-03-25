# discourse-topic-view-modes

A Discourse plugin that lets you apply named view modes to any topic page via a `?tvm=MODE` URL query parameter. Each mode adds CSS body classes and optional inline CSS, giving you full control over how a topic looks without touching themes or reloading the page.

## How It Works

When a visitor (or a link) appends `?tvm=MODE` to any topic URL, the plugin reads the `tvm` parameter on every page change, looks up the matching mode, and:

1. Adds the mode's configured **body classes** to `<body>` (e.g. `tvm-mode tvm-minimal`)
2. Injects the mode's **custom CSS** into `<head>` as an inline `<style>` tag with id `tvm-mode-custom-css`

When the visitor navigates away or the parameter is absent, all `tvm-*` classes are removed and the injected style tag is cleaned up. This happens on every Discourse page transition — no full reload required.

## Three Built-in Preset Modes

The plugin ships with three read-only preset modes that demonstrate the range of what's possible:

| Mode | URL param | Body classes | What it hides |
|------|-----------|--------------|---------------|
| **Minimal** | `?tvm=min` | `tvm-mode tvm-minimal` | Header, sidebar, nav, replies, footer, all posts except the OP |
| **Content Only** | `?tvm=content` | `tvm-mode` | Header, sidebar, all topic chrome — only the post stream remains |
| **Full** | `?tvm=full` | `tvm-mode tvm-full` | Header, sidebar, nav, replies, footer, all posts except the OP |

Presets are locked in the admin UI (read-only) and cannot be deleted. You can add unlimited custom modes alongside them.

## Installation

Follow the standard Discourse plugin install procedure. In your `app.yml`:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/denvergeeks/discourse-topic-view-modes.git
```

Then rebuild:

```bash
./launcher rebuild app
```

## Admin Configuration

Navigate to **Admin → Plugins → Topic View Modes**.

The admin panel lets you:

- **Enable or disable** the plugin with a toggle (site setting `topic_view_modes_enabled`)
- **View preset modes** — the three built-in modes are displayed read-only
- **Add custom modes** — create as many modes as you need with the "Add View Mode" button
- **Configure each mode** by expanding its card:
  - **Name** — human-readable label shown in the admin UI
  - **URL slug** — the value used in `?tvm=VALUE` (e.g. `embed` → `?tvm=embed`)
  - **Body classes** — space-separated CSS classes added to `<body>` when active; always start with `tvm-mode` as the first class
  - **Custom CSS** — plain CSS (not SCSS) injected into `<head>` at runtime when this mode is active
- **Toggle individual modes** on or off without deleting them
- **Delete custom modes** — presets cannot be deleted
- **Save** changes per mode with the Save All button inside the expanded card

All mode data is stored in the site setting `topic_view_modes_modes` as a JSON array.

## Creating a Custom Mode

### Example: Embed / Kiosk mode

Suppose you want a stripped-down view for embedding a topic in an iframe:

1. Go to **Admin → Plugins → Topic View Modes**
2. Click **Add View Mode**
3. Fill in:
   - **Name:** `Embed`
   - **URL slug:** `embed`
   - **Body classes:** `tvm-mode tvm-embed`
   - **Custom CSS:**
     ```css
     body.tvm-embed #main-outlet {
       padding: 0;
       max-width: 100%;
     }
     body.tvm-embed .topic-post:not(:first-child) {
       display: none !important;
     }
     ```
4. Click **Save All**

The mode is now active at any topic URL with `?tvm=embed` appended.

### Targeting mode-specific styles from a theme

Because modes add body classes, you can also target them from any Discourse theme or theme component using standard CSS selectors:

```css
body.tvm-embed .cooked img {
  max-width: 100%;
  height: auto;
}
```

## Using a Mode Link

Append the `?tvm=` parameter to any topic URL:

```
https://your-forum.example.com/t/my-topic/1234?tvm=min
https://your-forum.example.com/t/my-topic/1234?tvm=content
https://your-forum.example.com/t/my-topic/1234?tvm=embed
```

The mode applies instantly on page load and is removed when the user navigates to any URL without the parameter. Sharing the link preserves the mode for the recipient.

## Site Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `topic_view_modes_enabled` | boolean | `true` | Master switch — disables all mode processing when off |
| `topic_view_modes_modes` | string (JSON) | *(preset JSON)* | JSON array of all mode objects, managed via the admin UI |

## Mode Object Schema

Each entry in the `topic_view_modes_modes` JSON array has this shape:

```json
{
  "value": "min",
  "label": "Minimal",
  "classes": "tvm-mode tvm-minimal",
  "css": "",
  "preset": true,
  "enabled": true
}
```

| Field | Type | Description |
|-------|------|-------------|
| `value` | string | The URL slug matched against `?tvm=VALUE` |
| `label` | string | Display name shown in the admin UI |
| `classes` | string | Space-separated body classes applied when active |
| `css` | string | Raw CSS injected into `<head>` when active |
| `preset` | boolean | If `true`, the mode is read-only in the admin UI |
| `enabled` | boolean | If `false`, the mode is ignored even if the URL param matches |

## Base Stylesheet

The plugin includes a desktop-only stylesheet (`topic-view-modes.scss`) that applies structural CSS whenever any `tvm-mode` body class is present. This provides the baseline hiding behaviour for the preset modes — the header, sidebar, topic chrome, navigation, and all posts except the opening post are hidden. Custom CSS from each mode is then layered on top at runtime.

## Compatibility

- **Discourse:** Latest stable and tests-passed builds
- **Glimmer / Ember:** Uses the modern `use_new_show_route` admin plugin pattern
- **Server-side:** Ruby on Rails plugin controller, stores config in site settings — no database migrations required

## Author

[@denvergeeks](https://github.com/denvergeeks)
