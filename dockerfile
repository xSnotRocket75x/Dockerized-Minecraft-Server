FROM eclipse-temurin:21-jdk

WORKDIR /app

# Install curl
RUN apt-get update && apt-get install -y curl unzip jq && rm -rf /var/lib/apt/lists/*

# Copy startup script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 25565
ENV JVM_OPTS="-Xmx6G -Xms6G"

CMD ["/usr/local/bin/start.sh"]
