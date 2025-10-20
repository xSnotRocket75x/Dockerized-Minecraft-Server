#!/bin/bash
set -e

echo "🧱 Starting container: ${CONTAINER_NAME:-undefined}"

# --- Required environment variables ---
required_vars=(
  CONTAINER_NAME SERVER_TYPE MC_VERSION MEMORY_MAX MEMORY_MIN
  EULA WORLD_NAME DIFFICULTY GAMEMODE MAX_PLAYERS VIEW_DISTANCE
  ENABLE_COMMAND_BLOCKS ALLOW_FLIGHT MOTD ONLINE_MODE WHITE_LIST
)

for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "❌ ERROR: Environment variable '$var' is not set. Check your .env file."
    exit 1
  fi
done

echo "✅ Environment validated successfully."

# --- Ensure mods folder exists ---
mkdir -p mods

# --- EULA agreement ---
echo "eula=${EULA}" > eula.txt

# --- Generate server.properties dynamically ---
cat > server.properties <<EOF
motd=${MOTD}
level-name=${WORLD_NAME}
difficulty=${DIFFICULTY}
gamemode=${GAMEMODE}
max-players=${MAX_PLAYERS}
view-distance=${VIEW_DISTANCE}
enable-command-block=${ENABLE_COMMAND_BLOCKS}
allow-flight=${ALLOW_FLIGHT}
online-mode=${ONLINE_MODE}
white-list=${WHITE_LIST}
EOF
echo "✅ server.properties generated successfully."

# --- Helper functions ---
get_installed_version_fabric() {
  [ -f fabric-server-launch.jar ] && java -jar fabric-server-launch.jar --version 2>/dev/null | grep -oP 'Minecraft \K[\d\.]+'
}

get_installed_version_vanilla() {
  [ -f server.jar ] && unzip -p server.jar version.json | grep -oP '"id":\s*"\K[\d\.]+'
}

install_fabric() {
  INSTALLED_MC_VERSION=$(get_installed_version_fabric || echo "")
  if [ "$INSTALLED_MC_VERSION" = "$MC_VERSION" ]; then
    echo "✅ Fabric server for MC ${MC_VERSION} already installed."
    return
  elif [ -n "$INSTALLED_MC_VERSION" ]; then
    echo "⚠️ Fabric: old version detected (${INSTALLED_MC_VERSION}), updating to ${MC_VERSION}..."
    rm -f fabric-server-launch.jar
  fi

  echo "🌐 Installing Fabric server for MC ${MC_VERSION}..."
  curl -L -o fabric-installer.jar "https://maven.fabricmc.net/net/fabricmc/fabric-installer/${FABRIC_INSTALLER_VERSION}/fabric-installer-${FABRIC_INSTALLER_VERSION}.jar"
  java -jar fabric-installer.jar server -mcversion "${MC_VERSION}" -downloadMinecraft
  rm fabric-installer.jar
  echo "✅ Fabric server installed."
}

install_forge() {
  # Note: Forge installer overwrites the jar, so we reinstall if version differs
  # This is a simplified version; ideally, you parse the installer metadata for version
  echo "🌐 Installing Forge server for MC ${MC_VERSION}..."
  curl -L -o forge-installer.jar "https://maven.minecraftforge.net/net/minecraftforge/forge/${FORGE_INSTALLER_VERSION}/forge-${FORGE_INSTALLER_VERSION}-installer.jar"
  java -jar forge-installer.jar --installServer
  rm forge-installer.jar
  SERVER_JAR="forge-${FORGE_INSTALLER_VERSION}.jar"
  echo "✅ Forge server installed."
}

install_quilt() {
  echo "🌐 Installing Quilt server for MC ${MC_VERSION}..."
  curl -L -o quilt-installer.jar "https://maven.quiltmc.org/repository/release/org/quiltmc/quilt-installer/${QUILT_INSTALLER_VERSION}/quilt-installer-${QUILT_INSTALLER_VERSION}.jar"
  java -jar quilt-installer.jar install server "${MC_VERSION}" --download-server
  rm quilt-installer.jar
  SERVER_JAR="quilt-server-launch.jar"
  echo "✅ Quilt server installed."
}

install_vanilla() {
  INSTALLED_MC_VERSION=$(get_installed_version_vanilla || echo "")
  if [ "$INSTALLED_MC_VERSION" = "$MC_VERSION" ]; then
    echo "✅ Vanilla server for MC ${MC_VERSION} already installed."
    SERVER_JAR="server.jar"
    return
  fi

  echo "🌐 Installing Vanilla server ${MC_VERSION}..."
  DOWNLOAD_URL=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json \
    | grep -A5 "\"${MC_VERSION}\"" \
    | grep 'url' \
    | head -1 \
    | cut -d '"' -f4)
  SERVER_URL=$(curl -s "$DOWNLOAD_URL" | grep 'server' | grep 'url' | cut -d '"' -f4)
  curl -L -o server.jar "$SERVER_URL"
  SERVER_JAR="server.jar"
  echo "✅ Vanilla server installed."
}

# --- Install / Update server depending on type ---
case "${SERVER_TYPE}" in
  fabric)
    install_fabric
    SERVER_JAR="fabric-server-launch.jar"
    ;;
  forge)
    install_forge
    ;;
  quilt)
    install_quilt
    ;;
  vanilla)
    install_vanilla
    ;;
  *)
    echo "❌ ERROR: Unknown SERVER_TYPE '${SERVER_TYPE}'. Must be one of: fabric, forge, quilt, vanilla"
    exit 1
    ;;
esac

# --- Launch the server ---
echo "🚀 Launching ${SERVER_TYPE^} Minecraft ${MC_VERSION} with ${MEMORY_MAX} RAM..."
exec java -Xmx${MEMORY_MAX} -Xms${MEMORY_MIN} -jar "${SERVER_JAR}" nogui
