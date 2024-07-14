FROM golang:1.22.5 as builder

# fixuid - https://github.com/boxboat/fixuid
# no 32-bit binaries
RUN go install github.com/boxboat/fixuid@v0.6.0

FROM node:lts

# sudo for Docker
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo

# fixuid
COPY --from=builder /go/bin/fixuid /usr/local/bin

RUN chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: vscode\ngroup: users\n" > /etc/fixuid/config.yml && \
    adduser --gid 100 --shell /bin/bash --disabled-password --gecos "" vscode && \
    echo "vscode ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/vscode

# VS Code
RUN curl -SsL "https://code.visualstudio.com/sha/download?build=stable&os=cli-linux-armhf" | tar xvfpz - -C /usr/local/bin && \
    chmod +x /usr/local/bin/code

# Development tools
#   - Docker outside of Docker
#   - vim, less
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y --no-install-recommends \
    docker-ce-cli \
    docker-compose-plugin \
    vim-tiny \
    less \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER vscode:vscode

EXPOSE 5555
ENTRYPOINT ["fixuid", "code", "serve-web", "--without-connection-token", "--host", "0.0.0.0", "--port", "5555"]
