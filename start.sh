#!/bin/bash
set -e

# ------------------------------
# Environment Variables Required
# ------------------------------
: "${SERVER_TYPE:?Environment variable SERVER_TYPE is required (vanilla, fabric, forge, quilt)}"
: "${MC_VERSION:?Environment variable MC_VERSION is required}"
: "${MEMORY_MIN:?Environment variable MEMORY_MIN is required}"
: "${MEMORY_MAX:?Environment variable MEMORY_MAX is required}"

# Optional environment variables with defaults
WORLD_NAME="${WORLD_NAME:-world}"
DIFFICULTY="${DIFFICULTY:-normal}"
GAMEMODE="${GAMEMODE:-survival}"
MAX_PLAYERS="${MAX_PLAYERS:-10}"
VIEW_DISTANCE="${VIEW_DISTANCE:-10}"
ENABLE_COMMAND_BLOCKS="${ENABLE_COMMAND_BLOCKS:-false}"
ALLOW_FLIGHT="${ALLOW_FLIGHT:-false}"
MOTD="${MOTD:-Docker Minecraft Server}"
ONLINE_MODE="${ONLINE_MODE:-true}"
WHITE_LIST="${WHITE_LIST:-false}"

# Optional installer versions for mod loaders
FABRIC_INSTALLER_VERSION="${FABRIC_INSTALLER_VERSION:-1.1.0}"
FORGE_INSTALLER_VERSION="${FORGE_INSTALLER_VERSION:-latest}"
QUILT_INSTALLER_VERSION="${QUILT_INSTALLER_VERSION:-0.22.2}"

# Paths
WORKDIR="/app"
MODS_DIR="$WORKDIR/mods"
mkdir -p "$MODS_DIR"
cd "$WORKDIR"

echo "🧱 Starting container: ${CONTAINER_NAME:-Minecraft_Server}"
echo "✅ Environment validated successfully."

# ------------------------------
# Helper: Generate server.properties
# ------------------------------
generate_server_properties() {
  echo "✅ server.properties generated successfully."
  cat > server.properties <<EOF
level-name=$WORLD_NAME
difficulty=$DIFFICULTY
gamemode=$GAMEMODE
max-players=$MAX_PLAYERS
view-distance=$VIEW_DISTANCE
enable-command-block=$ENABLE_COMMAND_BLOCKS
allow-flight=$ALLOW_FLIGHT
motd=$MOTD
online-mode=$ONLINE_MODE
white-list=$WHITE_LIST
EOF
}

generate_server_properties

# ------------------------------
# Helper: Install Vanilla
# ------------------------------
install_vanilla() {
  if [ -f "server.jar" ]; then
    echo "✅ Vanilla server already installed."
    return
  fi

  echo "🌐 Installing Vanilla server ${MC_VERSION}..."
  
  VERSION_MANIFEST=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json)
  VERSION_URL=$(echo "$VERSION_MANIFEST" | jq -r --arg VER "$MC_VERSION" '.versions[] | select(.id==$VER) | .url')
  if [ -z "$VERSION_URL" ]; then
    echo "❌ ERROR: Minecraft version $MC_VERSION not found!"
    exit 1
  fi

  SERVER_URL=$(curl -s "$VERSION_URL" | jq -r '.downloads.server.url')
  if [ -z "$SERVER_URL" ]; then
    echo "❌ ERROR: Server download URL not found!"
    exit 1
  fi

  curl -L -o server.jar "$SERVER_URL"
  echo "✅ Vanilla server installed."
}

# ------------------------------
# Helper: Install Fabric
# ------------------------------
install_fabric() {
  if [ -f "fabric-server-launch.jar" ]; then
    echo "✅ Fabric server already installed."
    return
  fi

  echo "🌐 Installing Fabric server ${MC_VERSION}..."
  curl -L -o fabric-installer.jar "https://maven.fabricmc.net/net/fabricmc/fabric-installer/${FABRIC_INSTALLER_VERSION}/fabric-installer-${FABRIC_INSTALLER_VERSION}.jar"
  java -jar fabric-installer.jar server -mcversion "$MC_VERSION" -downloadMinecraft
  rm fabric-installer.jar
  echo "✅ Fabric server installed."
}

# ------------------------------
# Helper: Install Forge
# ------------------------------
install_forge() {
  if [ -f "forge-${MC_VERSION}-installer.jar" ]; then
    echo "✅ Forge server already installed."
    return
  fi

  echo "🌐 Installing Forge server ${MC_VERSION}..."
  
  # Determine Forge installer URL
  if [ "$FORGE_INSTALLER_VERSION" = "latest" ]; then
    # Get latest recommended version
    FORGE_JSON=$(curl -s https://maven.minecraftforge.net/net/minecraftforge/forge/maven-metadata.json)
    FORGE_INSTALLER_VERSION=$(echo "$FORGE_JSON" | jq -r '.versioning.release')
  fi

  FORGE_URL="https://maven.minecraftforge.net/net/minecraftforge/forge/${MC_VERSION}-${FORGE_INSTALLER_VERSION}/forge-${MC_VERSION}-${FORGE_INSTALLER_VERSION}-installer.jar"

  curl -L -o forge-installer.jar "$FORGE_URL"
  java -jar forge-installer.jar --installServer
  rm forge-installer.jar
  mv forge-*-universal.jar forge-server.jar
  echo "✅ Forge server installed."
}

# ------------------------------
# Helper: Install Quilt
# ------------------------------
install_quilt() {
  if [ -f "quilt-server-launch.jar" ]; then
    echo "✅ Quilt server already installed."
    return
  fi

  echo "🌐 Installing Quilt server ${MC_VERSION}..."
  curl -L -o quilt-installer.jar "https://maven.quiltmc.org/repository/release/org/quiltmc/quilt-installer/${QUILT_INSTALLER_VERSION}/quilt-installer-${QUILT_INSTALLER_VERSION}.jar"
  java -jar quilt-installer.jar server -mcversion "$MC_VERSION" -downloadMinecraft
  rm quilt-installer.jar
  echo "✅ Quilt server installed."
}

# ------------------------------
# Accept EULA
# ------------------------------
if [ ! -f "eula.txt" ]; then
  echo "eula=true" > eula.txt
fi

# ------------------------------
# Install Server Based on Type
# ------------------------------
case "$SERVER_TYPE" in
  vanilla)
    install_vanilla
    SERVER_JAR="server.jar"
    ;;
  fabric)
    install_fabric
    SERVER_JAR="fabric-server-launch.jar"
    ;;
  forge)
    install_forge
    SERVER_JAR="forge-server.jar"
    ;;
  quilt)
    install_quilt
    SERVER_JAR="quilt-server-launch.jar"
    ;;
  *)
    echo "❌ Unknown SERVER_TYPE: $SERVER_TYPE. Must be one of vanilla, fabric, forge, quilt."
    exit 1
    ;;
esac

# ------------------------------
# Run Server
# ------------------------------
echo "🚀 Starting Minecraft server (${SERVER_TYPE})..."
exec java $JVM_OPTS -jar "$SERVER_JAR" nogui
