# Apex UI Library

Modular re-implementation of the original `ApexL-test.lua` single-file build.

The visual style is preserved 1:1: dark Apex window, compact top bar, macOS
traffic-light dots, collapsible sidebar, breadcrumbs, animated gradient strokes,
rounded section cards and Luna-style controls.

---

## Quick Start

```lua
local Library = require(path.to.ApexLibrary)
local window  = Library.new({ Title = "My Dashboard" })
local page    = window:Page("Home", "lucide:house")
local section = page:Section("General")

section:Label("Welcome to your dashboard!")
section:Toggle("Enable feature", false, function(v) print(v) end)
section:Slider("Volume", 0, 100, 50, function(v) print(v) end)
section:Input("Username", "", function(v) print(v) end)
section:Button("Click me", function() print("hi") end)
section:Keybind("Hotkey", Enum.KeyCode.F, function(k) print(k) end)
section:Dropdown({
    Title = "Theme",
    Values = { "Apex", "Mono", "Solar" },
    Default = "Apex",
    Search = true,
    Callback = function(v) print(v) end,
})
```

---

## Project layout

```
Library/
├── default.project.json          Rojo entry, builds src/ as ApexLibrary
├── place.project.json            Rojo place for Studio/dev usage
├── package.json                  Build scripts for release assets
├── build/                        Lua bundler used for GitHub release assets
├── .github/workflows/release.yml Builds and uploads the fixed Apex release
├── ApexL.lua                     Legacy single-file build (kept for reference)
├── ApexL-test.lua                Legacy single-file build (kept for reference)
├── Example.client.lua            Usage example using the modular API
└── src/
    ├── init.lua                  Public surface: Library.new, SetIconsType, GetIcon
    ├── Theme.lua                 Palette, fonts, sizes, tween presets
    ├── Constants.lua             Hidden-mode defaults
    ├── OptionsRegistry.lua       Shared flagged-control registry
    ├── SaveManager.lua           Config save/load helpers
    ├── Util/
    │   ├── init.lua              Aggregator
    │   ├── Create.lua            Instance.new wrappers (Corner, Stroke, ...)
    │   ├── Foreground.lua        Hover guards / input-blocker helpers
    │   ├── Icons.lua             IconsV2 loader & resolver
    │   ├── Player.lua            Headshot + key-code helpers
    │   └── Callback.lua          SafeCallback wrapper
    ├── Elements/                 Section element builders
    │   ├── init.lua              Registry: Label, Button, Toggle, Slider,
    │   │                         Dropdown, Input, Keybind
    │   └── ...
    ├── UserSettingsElements/     Compact variants for the UserSettings popup
    │   └── ...
    └── Components/
        ├── Section.lua
        ├── UserSettingsSection.lua
        ├── Page.lua
        ├── CameraEffects.lua
        ├── DragBar.lua
        ├── Build.lua             Library.new builder (UI tree + wiring)
        └── Window/
            ├── init.lua          Window class (mixes the modules below)
            ├── Sidebar.lua       Sidebar reflow, breadcrumbs, dividers
            ├── Pages.lua         Window:Page() factory
            ├── Identity.lua      Hidden mode / notifications
            ├── UserSettings.lua  UserSettingsSection factory + popup state
            ├── Lifecycle.lua     Destroy / Minimize / Visibility callbacks
            ├── Dashboard.lua     Built-in dashboard page
            └── Search.lua        Sidebar search/highlight behavior
```

---

## Window API

| Method | Description |
|---|---|
| `Library.new(config)` | Create a new window. Config keys: `Title`, `Logo`, `SideBarLogo`, `TopBarText`, `Keybind`, `IconsType`, `HiddenMode`, `HiddenName`, `HiddenAvatar`, `Size`, `Position`, `GuiName`. |
| `window:Page(name, icon)` / `window:Page({ Name, Icone, IconType, IconColor })` | Create a sidebar page. |
| `window:PageSection({ Name })` / `window:PageSection("MAIN")` | Add a label-only section header in the sidebar (visible when expanded). |
| `window:SideBarDivider()` | Add a divider between sidebar entries. |
| `window:SetSidebarExpanded(state)` | Expand / collapse the sidebar. |
| `window:UpdateContentCanvas()` | Refresh the current page scroll canvas. |
| `window:SetVisible(state)` / `window:Toggle()` / `window:Minimize()` | Visibility helpers. |
| `window:OnDestroy(fn)` / `window:OnMinimize(fn)` | Lifecycle callbacks. |
| `window:SetHiddenMode(state, nick)` / `window:ToggleHiddenMode()` / `window:SetHiddenName(nick)` | Anonymise the user chip / user settings header. |
| `window:SetNotificationsEnabled(state)` / `window:ToggleNotifications()` | Toggle the bell icon. |
| `window:UserSettingsSection({ Name, Description, Icon })` | Add a section to the User Settings popup. |
| `window:GetUserSettingsSection()` | Default "Account" section, lazily created. |
| `window:ClearUserSettings()` | Wipe every UserSettings section. |
| `window:SetUserSettingsVisible(state, instant)` / `window:ToggleUserSettings()` | Show / hide the popup. |
| `window:Destroy()` | Tear down the entire UI and disconnect every connection. |

---

## Page API

| Method | Description |
|---|---|
| `page:Section(name, subtitle)` | Add a card section to the page. |
| `page:UpdateCanvas()` | Re-measure the page scroll. |

---

## Section elements

Every builder returns a control object with `Set` / `Get` (where applicable).

| Method | Signature |
|---|---|
| `section:Label(text, desc)` | read-only text + Apex badge |
| `section:Button(text, callback, desc)` | clickable button |
| `section:Toggle(text, default, callback, desc)` | tracked switch |
| `section:Slider(text, min, max, default, callback, desc)` | numeric slider |
| `section:Input(text, default, callback, desc)` | text box |
| `section:Keybind(text, default, callback, desc)` | keyboard binder |
| `section:Dropdown({ Title, Values, Default, Multi, Search, Callback, Description })` | single / multi select dropdown |

---

## UserSettingsSection elements

Compact equivalents used inside the User Settings popup. Same surface as Section
but visually denser:

`section:Label / Button / Toggle / Keybind / Dropdown / Special`. The `Special`
element accepts a `Render(element, window, section)` callback so you can drop
custom UI inside.

---

## Icons

Icons are resolved through Footagesus/Icons Main-v2 on demand. You can use:

- raw asset ids: `"rbxassetid://12345"`
- icon names with the active pack: `"house"`
- icon names with explicit pack: `"lucide:house"`, `"solar:Home2Bold"`,
  `"geist:accessibility-unread"`, `"sfsymbols:HouseFill"`

Switch the active pack any time with `Library.SetIconsType("lucide" | "solar" | "geist" | "sfsymbols" | "craft" | "gravity")`.

---

## Building & distribution

The project is a Rojo project that builds `src/` as a single `ApexLibrary`
ModuleScript. From the `Library/` folder, install the tools from `rokit.toml`
so `rojo` is available on your `PATH`, then run:

```bash
npm run build
```

This generates:

- `dist/ApexLibrary.rbxm` - Rojo model asset.
- `dist/ApexLibrary.lua` - single-file `loadstring` bundle generated from `src/`.

You can also run the steps independently:

```bash
npm run build:rbxm
npm run build:lua
```

The GitHub Actions release workflow uploads both files to the fixed `Apex`
release tag. The stable runtime URL is:

```lua
local Library = loadstring(game:HttpGet(
    "https://github.com/Null3Hub/Library/releases/download/Apex/ApexLibrary.lua"
))()
```

---

## Migrating from `ApexL-test.lua`

The single-file build is still in this folder under `ApexL.lua` and
`ApexL-test.lua`. The modular version exposes the same public API, so existing
scripts using `Library.new(...)`, `window:Page(...)`, `page:Section(...)`,
`section:Toggle(...)`, etc. work without changes.
