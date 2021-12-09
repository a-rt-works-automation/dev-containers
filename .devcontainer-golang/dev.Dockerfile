ARG ALPINE_VERSION=3.12
ARG DOCKER_VERSION=19.03.13
ARG DOCKER_COMPOSE_VERSION=alpine-1.27.4
ARG GOLANG_VERSION=1.15

FROM golang:${GOLANG_VERSION}-alpine AS go
FROM docker:${DOCKER_VERSION} AS docker-cli
FROM docker/compose:${DOCKER_COMPOSE_VERSION} AS docker-compose

FROM alpine:${ALPINE_VERSION}
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION=local
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

ENV BASE_VERSION="${VERSION}-${BUILD_DATE}-${VCS_REF}"

USER root
COPY --from=go /usr/local/go /usr/local/go
ENV GOPATH=/go
ENV PATH=$GOPATH/bin:/usr/local/go/bin:$PATH \
    CGO_ENABLED=0 \
    GO111MODULE=on

# CA certificates
RUN apk add -q --update --progress --no-cache ca-certificates
# Install the Root CA's into Apline and configure pip to use the resulting bundle
COPY pki/ /usr/local/share/ca-certificates/
RUN update-ca-certificates

# Timezone
RUN apk add -q --update --progress --no-cache tzdata
ENV TZ=

# Setup Git and SSH
RUN apk add -q --update --progress --no-cache git openssh-client

# Setup non root user with sudo access
RUN apk add -q --update --progress --no-cache sudo
WORKDIR /home/${USERNAME}
RUN adduser $USERNAME -s /bin/sh -D -u $USER_UID $USER_GID && \
    mkdir -p /etc/sudoers.d && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

# Setup shell for root and ${USERNAME}
ENTRYPOINT [ "/bin/zsh" ]
RUN apk add -q --update --progress --no-cache zsh nano
ENV EDITOR=nano \
    LANG=en_US.UTF-8 \
    # MacOS compatibility
    TERM=xterm
RUN apk add -q --update --progress --no-cache shadow && \
    usermod --shell /bin/zsh root && \
    usermod --shell /bin/zsh ${USERNAME} && \
    apk del shadow
COPY --chown=${USER_UID}:${USER_GID} shell/.p10k.zsh shell/.zshrc shell/.welcome.sh shell/.setProxy.sh /home/${USERNAME}/
RUN ln -s /home/${USERNAME}/.p10k.zsh /root/.p10k.zsh && \
    cp /home/${USERNAME}/.zshrc /root/.zshrc && \
    cp /home/${USERNAME}/.welcome.sh /root/.welcome.sh && \
    cp /home/${USERNAME}/.setProxy.sh /root/.setProxy.sh && \
    sed -i "s/HOMEPATH/home\/${USERNAME}/" /home/${USERNAME}/.zshrc && \
    sed -i "s/HOMEPATH/root/" /root/.zshrc
ARG POWERLEVEL10K_VERSION=v1.14.3
RUN git clone --single-branch --depth 1 https://github.com/robbyrussell/oh-my-zsh.git /home/${USERNAME}/.oh-my-zsh 2>&1 && \
    git clone --branch ${POWERLEVEL10K_VERSION} --depth 1 https://github.com/romkatv/powerlevel10k.git /home/${USERNAME}/.oh-my-zsh/custom/themes/powerlevel10k 2>&1 && \
    rm -rf /home/${USERNAME}/.oh-my-zsh/custom/themes/powerlevel10k/.git && \
    chown -R ${USERNAME}:${USER_GID} /home/${USERNAME}/.oh-my-zsh && \
    chmod -R 700 /home/${USERNAME}/.oh-my-zsh && \
    cp -r /home/${USERNAME}/.oh-my-zsh /root/.oh-my-zsh && \
    chown -R root:root /root/.oh-my-zsh

# Docker and docker-compose
COPY --from=docker-cli --chown=${USER_UID}:${USER_GID} /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker-compose --chown=${USER_UID}:${USER_GID} /usr/local/bin/docker-compose /usr/local/bin/docker-compose
ENV DOCKER_BUILDKIT=1
# All possible docker host groups
RUN G102=`getent group 102 | cut -d":" -f 1` && \
    G976=`getent group 976 | cut -d":" -f 1` && \
    G1000=`getent group 1000 | cut -d":" -f 1` && \
    if [ -z $G102 ]; then G102=docker102; addgroup --gid 102 $G102; fi && \
    if [ -z $G976 ]; then G976=docker976; addgroup --gid 976 $G976; fi && \
    if [ -z $G1000 ]; then G1000=docker1000; addgroup --gid 1000 $G1000; fi && \
    addgroup ${USERNAME} $G102 && \
    addgroup ${USERNAME} $G976 && \
    addgroup ${USERNAME} $G1000

# Install Go packages
ARG GOLANGCI_LINT_VERSION=v1.33.0
RUN wget -O- -nv https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b /bin -d ${GOLANGCI_LINT_VERSION}
ARG GOPLS_VERSION=v0.6.1
ARG DELVE_VERSION=v1.5.0
ARG GOMODIFYTAGS_VERSION=v1.13.0
ARG GOPLAY_VERSION=v1.0.0
ARG GOTESTS_VERSION=v1.5.3
ARG MOCK_VERSION=v1.4.4
ARG MOCKERY_VERSION=v2.3.0
RUN go get -v \
    # Base Go tools needed for VS code Go extension
    golang.org/x/tools/gopls@${GOPLS_VERSION} \
    #github.com/ramya-rao-a/go-outline \
    #golang.org/x/tools/cmd/guru \
    #golang.org/x/tools/cmd/gorename \
    #github.com/go-delve/delve/cmd/dlv@${DELVE_VERSION} \
    ## Extra tools integrating with VS code
    #github.com/fatih/gomodifytags@${GOMODIFYTAGS_VERSION} \
    #github.com/haya14busa/goplay/cmd/goplay@${GOPLAY_VERSION} \
    #github.com/cweill/gotests/...@${GOTESTS_VERSION} \
    #github.com/davidrjenni/reftools/cmd/fillstruct \
    ## Terminal tools
    #github.com/golang/mock/gomock@${MOCK_VERSION} \
    #github.com/golang/mock/mockgen@${MOCK_VERSION} \
    #github.com/vektra/mockery/v2/...@${MOCKERY_VERSION} \
    2>&1 && \
    rm -rf $GOPATH/pkg/* $GOPATH/src/* /root/.cache/go-build && \
    chown -R ${USER_UID}:${USER_GID} $GOPATH && \
    chmod -R 777 $GOPATH

# VSCode specific (speed up setup)
RUN apk add -q --update --progress --no-cache libstdc++

# Shell setup
COPY --chown=${USER_UID}:${USER_GID} shell/.zshrc-specific shell/.welcome.sh /home/${USERNAME}/
COPY shell/.zshrc-specific shell/.welcome.sh /root/

USER ${USERNAME}

