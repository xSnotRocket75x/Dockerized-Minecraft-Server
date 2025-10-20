# Dockerized Multi-Loader Minecraft Server

A fully configurable Minecraft server setup using Docker and Docker Compose. Supports multiple server types including **Vanilla, Fabric, Forge, and Quilt**, with automatic version detection and installation.

## Features

- Supports **Vanilla, Fabric, Forge, and Quilt** servers
- Automatically installs and updates the correct Minecraft version
- Configurable via a `.env` file for:
  - Memory settings (`MEMORY_MIN`, `MEMORY_MAX`)
  - World name, gamemode, difficulty, and more
- Persistent world and mods folders (`./data`, `./mods`)
- Easy to switch between different mod loaders
- Runs in a reproducible Docker container environment

## Getting Started

### Prerequisites

- [Docker](https://www.docker.com/) and [Docker Compose](https://docs.docker.com/compose/)
- `.env` file configured (see example below)

### Example `.env` file

```env
CONTAINER_NAME=Minecraft_Server
SERVER_TYPE=fabric
MC_VERSION=1.21.9
MEMORY_MIN=2G
MEMORY_MAX=6G
EULA=true
WORLD_NAME=world
DIFFICULTY=normal
GAMEMODE=survival
MAX_PLAYERS=10
VIEW_DISTANCE=10
ENABLE_COMMAND_BLOCKS=false
ALLOW_FLIGHT=false
MOTD=My Minecraft Server
ONLINE_MODE=true
WHITE_LIST=false
FABRIC_INSTALLER_VERSION=1.1.0
FORGE_INSTALLER_VERSION=1.21.1-45.1.0
QUILT_INSTALLER_VERSION=0.22.2
