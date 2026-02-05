# Page 1

````
# gldnrmz-elevators

A highly configurable elevator script for QBCore, utilizing `ox_lib` for modern context menus and flexible TextUI support.

## Features

- **Teleport-based Elevators**: Smooth teleportation with fade effects.
- **Access Control**: Restrict floor access based on:
  - **Jobs**: Specific jobs and minimum grades.
  - **Items**: Required items in inventory.
  - **Citizen IDs**: Whitelist specific players.
  - **Job & Item**: Require BOTH a specific job and an item.
- **Modern UI**: Uses `ox_lib` context menus for floor selection.
- **Flexible TextUI**: Supports multiple TextUI resources (`ox_lib`, `qb-core`, `cd_drawtextui`, `arp_ui`).

## Dependencies

- [qb-core](https://github.com/qbcore-framework/qb-core)
- [ox_lib](https://github.com/overextended/ox_lib)

## Installation

1.  Download the script and place it in your `resources` folder.
2.  Ensure `ox_lib` is started before this resource.
3.  Add `ensure gldnrmz-elevators` to your `server.cfg`.

## Configuration

### TextUI Setup
Open `config.lua` and set your preferred TextUI provider:

```lua
Config.TextUI = "ox_lib" -- Options: "qb-core", "ox_lib", "cd_drawtextui", "arp_ui"
```

### Adding Elevators
Elevators are configured in the `Config.Elevators` table in `config.lua`.

**Example Configuration:**

```lua
Config.Elevators = {
    MRPDElevator = {
        {
            coords = vector3(450.0, -980.0, 30.0), -- Coordinates of the elevator interaction point
            heading = 90.0,                        -- Heading player faces after teleporting
            level = "Floor 1",                     -- Subtitle in menu
            label = "Lobby",                       -- Title in menu
            jobs = {                               -- Optional: Job restriction
                ["police"] = 0,                    -- Job name = minimum grade
            },
        },
        {
            coords = vector3(450.0, -980.0, 40.0),
            heading = 90.0,
            level = "Floor 2",
            label = "Roof",
            items = {"elevator_key"},              -- Optional: Item restriction
            jobAndItem = false,                    -- If true, requires BOTH Job AND Item (if both configured)
        },
    },
}
```

### Access Control Options
- **jobs**: Table of `[job_name] = min_grade`.
- **items**: List of item names required.
- **citizenIDs**: List of allowed Citizen IDs.
- **jobAndItem**: Boolean. If `true`, player needs matching Job AND Item. If `false` (default), they need Job OR Item (if both are listed).

## Developer Commands
None

## License
No specific license provided.

````
