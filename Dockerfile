################################################################################
# BASE IMAGE
################################################################################
FROM ubuntu:20.04
################################################################################
# ENVIRONMENT VARIABLES
################################################################################
ENV USERNAME abops
ENV HOME_DIR /home/abops
ENV TF_MAJOR 0.15
################################################################################
# COPY FILES
################################################################################
COPY files/zshrc ${HOME_DIR}/.zshrc
################################################################################
# INSTALL CORE DEPENDENCIES
################################################################################
RUN apt-get update \
    && ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y \
        build-essential \
        ca-certificates \
        curl \
        fonts-firacode \
        gnupg \
        htop \
        jq \
        locales \
        lsb-release \
        python3-pip \
        man \
        openssl \
        software-properties-common \
        ssh \
        sshuttle \
        sudo \
        telnet \
        unzip \
        vim \
        zsh \
        # Multi-editor support in Coder
        libfontconfig1 \
        libgtk-3-0 \
        libxi6 \
        libxrender1 \
        libxtst6 \
################################################################################
# INSTALL REPOSITORIES
################################################################################
    && apt-add-repository --yes ppa:ansible/ansible \
    && apt-add-repository --yes ppa:git-core/ppa \
################################################################################
# INSTALL 3RD PARTY PACKAGES
################################################################################
    && apt-get update \
    && apt-get install -y \
        ansible-base \
        git \
################################################################################
# PIP3 LIBRARIES
################################################################################
    && /usr/bin/pip3 install \
        bcrypt \
        paramiko \
        pygit2 \
        pyyaml \
        requests \
        validators \
        yq \
################################################################################
# TERRAFORM
################################################################################
    && export TERRAFORM_VERSION=$(curl -s https://releases.hashicorp.com/terraform/ | grep $TF_MAJOR | grep -v "\-[a-zA-Z]" | awk -F '_' {' print $2 '} | awk -F "<" {' print $1 '} | sort -u | tail -n1) \
    && curl -o /tmp/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip -q /tmp/terraform.zip -d /tmp \
    && chmod +x /tmp/terraform \
    && mv /tmp/terraform /usr/local/bin/terraform \
################################################################################
# AWS CLI
################################################################################
    && curl -o /tmp/aws.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
    && unzip -q /tmp/aws.zip -d /tmp \
    && /tmp/aws/install \
################################################################################
# KUBECTL CLIENT
################################################################################
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
################################################################################
# KUBESEAL / SEALED SECRETS
################################################################################
    && export KUBESEAL_VERSION=$(curl --silent "https://api.github.com/repos/bitnami-labs/sealed-secrets/tags" | jq -r '.[0].name') \
    && wget https://github.com/bitnami-labs/sealed-secrets/releases/download/${KUBESEAL_VERSION}/kubeseal-linux-amd64 -O kubeseal \
    && sudo install -m 755 kubeseal /usr/local/bin/kubeseal \
################################################################################
# ARGOCD
################################################################################
    && export ARGOCD_VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/$ARGOCD_VERSION/argocd-linux-amd64 \
    && chmod +x /usr/local/bin/argocd \
################################################################################
# ADD CODER USER
################################################################################
    && adduser --gecos '' --disabled-password --shell /bin/zsh --home ${HOME_DIR} ${USERNAME} \
    && chown ${USERNAME}:${USERNAME} ${HOME_DIR} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd \
################################################################################
# CREATE REQUIRED DIRECTORIES AND FILES
################################################################################
    && ln -s /usr/bin/make /usr/bin/abctl \
    && mkdir ${HOME_DIR}/.ssh \
    && touch ${HOME_DIR}/.ssh/known_hosts \
################################################################################
# FILE PERMISSIONS
################################################################################
    && chmod 0644 ${HOME_DIR}/.zshrc \
    && chown ${USERNAME}:${USERNAME} ${HOME_DIR}/.zshrc \
    && chmod 0700 ${HOME_DIR}/.ssh \
    && chown ${USERNAME}:${USERNAME} ${HOME_DIR}/.ssh \
    && chmod 0644 ${HOME_DIR}/.ssh/known_hosts \
    && chown ${USERNAME}:${USERNAME} ${HOME_DIR}/.ssh/known_hosts \
################################################################################
# CLEANUP
################################################################################
    && rm -rf /tmp/* \
    && rm -rf /var/lib/apt/lists/*
################################################################################
# SET USER TO CODER
################################################################################
USER ${USERNAME}
################################################################################
# INSTALL ANSIBLE MODULES
################################################################################
RUN ansible-galaxy collection install community.kubernetes \
    && ansible-galaxy collection install ansible.posix \
    && ansible-galaxy collection install community.general
################################################################################
# SET WORKDIR TO CODER HOME DIR
################################################################################
WORKDIR ${HOME_DIR}
################################################################################
# LAUNCH ZSH ON STARTUP
################################################################################
CMD [ "/usr/bin/zsh" ]