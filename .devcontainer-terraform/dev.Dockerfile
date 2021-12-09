FROM ubuntu:bionic

ARG USERNAME=user
ARG USER_UID=1001
ARG USER_GID=1001

USER root

COPY pki /build/pki
COPY shell/.zshrc /build/shell/.zshrc
COPY shell/.bashrc /build/shell/.bashrc
COPY shell/.profile.sh /build/shell/.profile.sh
COPY shell/.welcome.sh /build/shell/.welcome.sh
COPY shell/.config/starship.toml /build/shell/.config/starship.toml

#Install software dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends sudo git npm make apt-transport-https gnupg2 curl lsb-release zsh ca-certificates\
    && apt-get purge -y --auto-remove \
    && rm -rf /var/lib/apt/lists/*

# Setup non root user with sudo access
WORKDIR /home/${USERNAME}
RUN sudo useradd -m $USERNAME && \
    chmod -R 777 /home/$USERNAME && \
    mkdir -p /etc/sudoers.d && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

# Setup shell for root and ${USERNAME}
#ENTRYPOINT [ "/bin/zsh" ]
RUN usermod --shell /bin/zsh root && \
    usermod --shell /bin/zsh ${USERNAME}
COPY --chown=${USER_UID}:${USER_GID} shell/.zshrc shell/.bashrc shell/.profile.sh shell/.welcome.sh shell/.setProxy.sh /home/${USERNAME}/
RUN mkdir -p /home/${USERNAME}/.config
COPY --chown=${USER_UID}:${USER_GID} shell/.config/starship.toml /home/${USERNAME}/.config

# Install the Root CA's
RUN cp /build/pki/* /usr/local/share/ca-certificates/
RUN update-ca-certificates

## Set timezone
#timedatectl set-timezone Australia/Melbourne

# Install starship
RUN sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes

#Install McFly
RUN curl -LSfs https://raw.githubusercontent.com/cantino/mcfly/master/ci/install.sh | sh -s -- --git cantino/mcfly
RUN touch /home/$USERNAME/.bash_history
RUN touch /home/$USERNAME/.zsh_history

#Install Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
RUN echo "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee -a /etc/apt/sources.list.d/hashicorp.list
RUN apt-get update && apt-get install terraform

ENV HOME /home/${USERNAME}
USER ${USERNAME}
CMD [ "/bin/zsh" ]