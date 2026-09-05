FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && \
    apt-get install -y unzip curl libcurl4 libssl3 wget jq && \
    rm -rf /var/lib/apt/lists/*

ARG BDS_Version=latest

ENV VERSION=$BDS_Version

# Construct the download URL and download the server file
RUN if [ "$VERSION" = "latest" ]; then \
        DOWNLOAD_URL=$(curl --silent -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:90.0) Gecko/20100101 Firefox/90.0" https://net-secondary.web.minecraft-services.net/api/v1.0/download/links | \
        jq -r '.result.links[] | select(.downloadType == "serverBedrockLinux") | .downloadUrl'); \
    else \
        DOWNLOAD_URL="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-${VERSION}.zip"; \
    fi; \
    echo "DOWNLOAD_URL=$DOWNLOAD_URL" > /etc/docker_environment

RUN . /etc/docker_environment && \
    wget -q  "$DOWNLOAD_URL" -O bedrock-server.zip && \
    unzip -q bedrock-server.zip -d bedrock-server && \
    rm -f /bedrock-server/bedrock_server_symbols.debug && \
    chmod a+x /bedrock-server/bedrock_server && \
    rm bedrock-server.zip

# Create a separate folder for configurations move the original files there and create links for the files
RUN mkdir -p /bedrock-server/config && \
    mv /bedrock-server/server.properties /bedrock-server/config && \
    mv /bedrock-server/permissions.json /bedrock-server/config && \
    mv /bedrock-server/allowlist.json /bedrock-server/config && \
    ln -s /bedrock-server/config/server.properties /bedrock-server/server.properties && \
    ln -s /bedrock-server/config/permissions.json /bedrock-server/permissions.json && \
    ln -s /bedrock-server/config/allowlist.json /bedrock-server/allowlist.json

EXPOSE 19132/udp

VOLUME /bedrock-server/worlds /bedrock-server/config

WORKDIR /bedrock-server
ENV LD_LIBRARY_PATH=.
CMD ./bedrock_server
