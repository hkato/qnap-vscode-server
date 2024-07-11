FROM golang:1.22.5 as builder

RUN go install github.com/boxboat/fixuid@v0.6.0

FROM node:lts

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    less \
    vim-tiny

RUN curl -SsL "https://code.visualstudio.com/sha/download?build=stable&os=cli-linux-armhf" | tar xvfpz - -C /usr/local/bin && \
    chmod +x /usr/local/bin/code

COPY --from=builder /go/bin/fixuid /usr/local/bin

RUN USER=vscode && \
    GROUP=vscode && \
    useradd -m -s /bin/bash $USER && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: $USER\ngroup: $GROUP\n" > /etc/fixuid/config.yml

USER vscode:vscode

EXPOSE 5555
ENTRYPOINT ["fixuid", "code", "serve-web", "--accept-server-license-terms", "--without-connection-token", "--host", "0.0.0.0", "--port", "5555"]
