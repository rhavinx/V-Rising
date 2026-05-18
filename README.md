# V Rising Dedicated Server (Docker)

## Description

Docker container for hosting a dedicated server for [V Rising](https://store.steampowered.com/app/1604030/V_Rising/). The game server is a Windows binary and runs under Wine.

Server files are downloaded via [DepotDownloader](https://github.com/SteamRE/DepotDownloader) using an anonymous Steam login — no Steam account or credentials required.

## Container Data Life Cycle

Initial container start → settings templates are copied to the "data" volume if not already present.

:Loop  
Container start → `ServerHostSettings.json` in the "data" volume is patched with environment variable values.  
Container shutdown → All persistent data is already in the "data" volume (written directly by the server via `-persistentDataPath`).  
Goto Loop

## Directory Structure

```
.
├── data                              # Volume bind mount
│   ├── .wine                         # Wine prefix (initialized on first run, persistent)
│   ├── Saves
│   │   └── v4
│   │       └── world1                # World save files
│   └── Settings
│       ├── ServerGameSettings.json   # Game settings — edit directly, not managed by container
│       └── ServerHostSettings.json   # Host settings — patched by env vars on every start
└── server                            # Volume bind mount, populated via DepotDownloader
    ├── VRisingServer.exe
    └── VRisingServer_Data
        └── StreamingAssets
            └── Settings              # Default template files — copied to data on first run
```

## Quick Start (Docker)

1. Create a `docker-compose.yml` file from the example below.
2. Start the container: `docker compose up -d` and monitor with `docker compose logs -f`.
3. Forward ports `9876` and `9877` (or your chosen ports) **UDP** on your router.
4. Connect via the Steam server browser or direct IP.

## Game Settings

`ServerGameSettings.json` controls gameplay — difficulty, loot rates, PvP rules, and so on. On first run the container copies the default file from the server install into your data volume. Edit it there directly. The container does not touch it after that.

`ServerHostSettings.json` is patched from environment variables on every container start. Do not edit it in the data volume while the container is running — your changes will be overwritten on the next start. To make a permanent change, update the corresponding environment variable.

> **Critical:** Never change or delete your save files in `Saves/v4/`. The sub-folder name matches your `SAVE_NAME` setting. Changing `SAVE_NAME` after your first run will cause the server to start a new world.

## REMOVE_SERVER_FILES

If DepotDownloader gets into a bad state or you want a clean reinstall:

- Set `REMOVE_SERVER_FILES: "1"` in your `docker-compose.yml` for **one** launch.
- Then set it back to `"0"`. Your saves and settings are preserved in the data volume and will be intact on the next start.

## Docker Compose (docker-compose.yml)

### Environment Variables

| Variable              | Description | Default |
| :-------------------- | :---------- | :-----: |
| TZ                    | Timezone | `"UTC"` |
| PUID                  | Numeric user ID | `"1000"` |
| PGID                  | Numeric group ID | `"1000"` |
| SKIP_UPDATE           | Skip DepotDownloader validation on start (faster startup, no update check) | `"0"` |
| GAME_PORT             | Game port (adjust port mapping if changed) | `"9876"` |
| QUERY_PORT            | Query port (adjust port mapping if changed) | `"9877"` |
| SAVE_NAME             | World save name — must match your existing save folder | `"world1"` |
| SERVER_NAME           | Server display name | *(existing value)* |
| SERVER_DESCRIPTION    | Server description | *(existing value)* |
| SERVER_PASSWORD       | Join password | *(existing value)* |
| MAX_PLAYERS           | Maximum player count | *(existing value)* |
| LIST_ON_STEAM         | List server in Steam server browser (`"true"`/`"false"`) | `"false"` |
| REMOVE_SERVER_FILES   | Wipe server files for a clean reinstall (set to `"1"` for one launch only) | `"0"` |

```yaml
services:
  vrising:
    image: rhavinx/vrising:latest
    container_name: vrising
    stop_grace_period: 30s
    environment:
      TZ: "UTC"
      # PUID: "1000"
      # PGID: "1000"
      SKIP_UPDATE: "0"
      SERVER_NAME: "My V Rising Server"
      # SERVER_DESCRIPTION: ""
      SERVER_PASSWORD: "changeme"
      MAX_PLAYERS: "8"
      GAME_PORT: "9876"
      QUERY_PORT: "9877"
      SAVE_NAME: "world1"
      LIST_ON_STEAM: "false"
      # REMOVE_SERVER_FILES: "0"
    volumes:
      - /path/to/server:/home/steam/vrising/server
      - /path/to/data:/home/steam/vrising/data
    ports:
      - "9876:9876/udp"
      - "9877:9877/udp"
    restart: unless-stopped
```

## Known Issues

- **Slow first connection** — The dedicated server takes time to preload the world on first connection. Subsequent connections are faster once the server is warm.

## Changelog

* 18 May 2026:
  - Initial release
  - debian:trixie-slim + WineHQ stable + DepotDownloader (self-contained, no .NET install required)
  - Two-volume layout: server binaries + persistent data
  - Environment variable patching of ServerHostSettings.json on every start
  - AVX/AVX2 detection with automatic DLL rename for non-AVX hardware
