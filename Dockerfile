FROM eclipse-temurin:17-jre-jammy

LABEL org.opencontainers.image.authors="Jon LaBelle <https://jonlabelle.com>" \
  org.opencontainers.title="bfg" \
  org.opencontainers.image.description="Docker image for BFG Repo-Cleaner, a tool for removing large files and sensitive data from Git repository history" \
  org.opencontainers.image.source="https://github.com/jonlabelle/docker-bfg" \
  org.opencontainers.image.licenses="MIT"

ARG BFG_VERSION=1.15.0

RUN apt-get update && \
  apt-get install -y --no-install-recommends git && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /work

RUN curl -fsSL -o /usr/local/bin/bfg.jar \
  "https://repo1.maven.org/maven2/com/madgag/bfg/${BFG_VERSION}/bfg-${BFG_VERSION}.jar"

ARG BFG_VERSION=1.15.0

# hadolint ignore=DL3008
RUN apt-get update && \
  apt-get install -y --no-install-recommends git && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /work

RUN curl -fsSL -o /usr/local/bin/bfg.jar \
  "https://repo1.maven.org/maven2/com/madgag/bfg/${BFG_VERSION}/bfg-${BFG_VERSION}.jar"

COPY entrypoint.sh /usr/local/bin/bfg
RUN chmod +x /usr/local/bin/bfg

ENTRYPOINT ["/usr/local/bin/bfg"]
