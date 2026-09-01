#=============================================================================
# 1. BUILDER STAGE (Decoupled Binary Ingestion)
# ref: https://hub.docker.com/r/jenkins/jenkins
#=============================================================================
ARG JENKINS_VERSION=lts-jdk21
FROM jenkins/jenkins:${JENKINS_VERSION} AS builder

# The jenkins/jenkins:lts base image switches to a non-root user (jenkins) by default.
# Switch to root to perform system-level installations
USER root

ENV YQ_VERSION=v4.53.2
ENV YQ_BINARY=yq_linux_amd64
ARG GOVC_VERSION=v0.53.1
ARG PACKER_VERSION=1.15.3
ARG INCLUSIVITY_VERSION=0.19.0

RUN apt-get update && apt-get install -y --no-install-recommends unzip tar curl \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /out/usr/local/bin

# ADD auto-extracts local archives, saving extract layers
ADD files/${YQ_BINARY}_${YQ_VERSION}.tar.gz /tmp/
ADD files/govc_${GOVC_VERSION}_linux_x86_64.tar.gz /tmp/
COPY files/packer_${PACKER_VERSION}_linux_amd64.zip /tmp/
ADD files/inclusivity-${INCLUSIVITY_VERSION}-linux-amd64.tar.gz /tmp/

RUN mv /tmp/${YQ_BINARY} /out/usr/local/bin/yq || mv /tmp/*${YQ_BINARY}* /out/usr/local/bin/yq && \
    mv /tmp/govc /out/usr/local/bin/govc || true && \
    unzip /tmp/packer_${PACKER_VERSION}_linux_amd64.zip packer -d /out/usr/local/bin/ && \
    mv /tmp/inclusivity /out/usr/local/bin/inclusivity || true

COPY retry_command.sh /out/usr/local/bin/retry_command.sh
RUN chmod +x /out/usr/local/bin/*

#=============================================================================
# 3. CONSOLIDATED RUNTIME IMAGE
#=============================================================================
FROM jenkins/jenkins:${JENKINS_VERSION}
LABEL maintainer="Lee Johnson <ljohnson@dettonville.org>"
LABEL description="Optimized Jenkins Controller"

ARG BUILD_DATE
ARG BUILD_ID=devel
LABEL build=$BUILD_ID

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    container=docker \
    VIRTUAL_ENV=/opt/venv \
    PIP_NO_CACHE_DIR=1

ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=${uid}
ARG DOCKER_GID=1102

USER root

# Setup Docker Group, Jenkins User, and APT Configuration
RUN groupadd -g ${DOCKER_GID} docker && \
    usermod -aG sudo,docker ${user} && \
    echo 'APT::Install-Suggests "0";\nAPT::Install-Recommends "0";' > /etc/apt/apt.conf.d/00-docker

# Switch default shell to bash so pipefail is recognized
SHELL ["/bin/bash", "-c"]

# Combined APT Installation Layer
RUN set -o pipefail && \
    apt-get update -qqy && \
    apt-get -qqy --no-install-recommends install \
      apt-transport-https apt-utils ca-certificates \
      bash tar zip unzip xorriso \
      curl git git-lfs \
      locales tzdata netbase \
      tree less jq rsync \
      dnsutils iproute2 iputils-ping inetutils-telnet \
      openssh-client ssh-askpass sshpass \
      gpg gpg-agent gnupg2 \
      ldap-utils \
      shellcheck groff rlwrap && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

## 2. Runtimes: Python
# These are the heaviest layers; separating them ensures changes to one don't invalidate the other
RUN apt-get update -qqy && \
    apt-get -qqy --no-install-recommends install \
      python3 python3-pip python3-virtualenv python3-venv && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

## 3. Build Tools & Development Libraries
# Essential for compiling Python C-extensions or local builds
RUN apt-get update -qqy && \
    apt-get -qqy --no-install-recommends install \
      build-essential patch genisoimage dirmngr openssl \
      libxml2-dev libxslt1-dev \
      zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev \
      libpq-dev libmariadb-dev libsasl2-dev libldap2-dev \
      libssl-dev libsqlite3-dev libreadline-dev libffi-dev \
      libbz2-dev uuid-dev default-mysql-client && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && apt-get install -y docker-ce-cli docker-compose-plugin docker-buildx-plugin docker-model-plugin && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

#=============================================================================
# 4. RUNTIME DEPENDENCY INGESTION
#=============================================================================
COPY --from=builder /out/usr/local/bin/ /usr/local/bin/

############################
## Using entrypoint.sh to source/set any secrets passed into the container
##
## ref: https://stackoverflow.com/questions/52492359/docker-secrets-passing-as-environment-variable
## ref: https://github.com/DevilaN/docker-entrypoint-example/
COPY ./entrypoint /
RUN chmod +x /docker-entrypoint.sh
RUN chmod +x /env_secrets_expand.sh

# Configure Multiarch Contexts
RUN for user_home in /root /home/${user}; do \
        mkdir -p ${user_home}/.ssh && \
        mkdir -p ${user_home}/.docker/buildx/instances && \
        echo '{"name":"multiarch-builder","driver":"docker-container","nodes":[{"name":"multiarch-builder0","endpoint":"unix:///var/run/docker.sock","platforms":null,"flags":[],"env":null,"driver-opts":null}]}' \
        > ${user_home}/.docker/buildx/instances/multiarch-builder && \
        mkdir -p ${user_home}/.docker && \
        echo '{"currentContext":"default"}' \
        > ${user_home}/.docker/config.json && \
        mkdir -p ${user_home}/.ansible/collections && \
        chown -R ${user}:${user} ${user_home}/.docker ${user_home}/.ansible || true; \
    done

# Controller runs as the jenkins user (uid 1000) – this is intentional.
# Agent images that are launched by the Docker Pipeline plugin must stay as
# root; see the agent Dockerfile for the full explanation.
ENV HOME=/home/${user}
WORKDIR ${HOME}
USER ${user}

## Second argument is original entrypoint in image
## original image definition: https://github.com/jenkinsci/docker/blob/master/17/debian/bullseye/hotspot/Dockerfile
#ENTRYPOINT ["/docker-entrypoint.sh", "/usr/bin/tini", "--", "/usr/local/bin/jenkins.sh"]
ENTRYPOINT ["/docker-entrypoint.sh", "/usr/local/bin/jenkins.sh"]
#ENTRYPOINT ["/docker-entrypoint.sh"]
#ENTRYPOINT [ "/entrypoint.sh" ]
