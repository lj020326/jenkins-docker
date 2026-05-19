# Stage 1: Extraction
ARG JENKINS_VERSION=lts-jdk21
FROM jenkins/jenkins:${JENKINS_VERSION} AS builder

# The jenkins/jenkins:lts base image switches to a non-root user (jenkins) by default.
# Switch to root to perform system-level installations
USER root

#RUN apt-get update && apt-get install -y unzip tar
RUN apt-get update -qqy && \
    apt-get -qqy --no-install-recommends install \
      tar zip unzip

ENV YQ_VERSION=v4.53.2
ENV YQ_BINARY=yq_linux_amd64
ARG GOVC_VERSION=v0.53.1
ARG PACKER_VERSION=1.15.3

# Copy all local files into the builder
COPY files/${YQ_BINARY}_${YQ_VERSION}.tar.gz /tmp/
COPY files/govc_${GOVC_VERSION}_linux_x86_64.tar.gz /tmp/
COPY files/packer_${PACKER_VERSION}_linux_amd64.zip /tmp/

# Extract YQ
RUN mkdir -p /out/usr/local/bin && \
    tar -xzf /tmp/${YQ_BINARY}_${YQ_VERSION}.tar.gz -C /out/usr/local/bin/ --wildcards "*${YQ_BINARY}*" && \
    mv /out/usr/local/bin/${YQ_BINARY} /out/usr/local/bin/yq

# Extract GOVC
RUN tar -xzf /tmp/govc_${GOVC_VERSION}_linux_x86_64.tar.gz -C /out/usr/local/bin/ --wildcards "*govc*"

# Extract Packer
RUN unzip /tmp/packer_${PACKER_VERSION}_linux_amd64.zip packer -d /out/usr/local/bin/

# Ensure everything is executable
RUN chmod +x /out/usr/local/bin/*

## ref: https://hub.docker.com/r/jenkins/jenkins
ARG JENKINS_VERSION=lts-jdk21
FROM jenkins/jenkins:${JENKINS_VERSION}
#FROM jenkins/jenkins:lts
#FROM jenkins/jenkins:2.414-jdk21
#FROM jenkins/jenkins:2.414-jdk17

LABEL maintainer="Lee Johnson <ljohnson@dettonville.org>"

ARG BUILD_DATE
ARG BUILD_ID=devel
LABEL build=$BUILD_ID

# Derived from
## ref: https://github.com/jenkinsci/docker-agent/blob/master/17/bullseye/Dockerfile
## ref: https://github.com/jenkinsci/docker/blob/master/Dockerfile
## ref: https://github.com/cyrille-leclerc/java-build-tools-dockerfile
## ref: https://github.com/dettonville/java-build-tools-dockerfile
## ref: https://github.com/getintodevops/jenkins-withdocker (miiro@getintodevops.com)
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
#ARG gid=1000
ARG gid=${uid}
ARG http_port=8080
ARG agent_port=50000
ARG JENKINS_HOME=/var/jenkins_home
#ARG JENKINS_HOME=/home/jenkins

## ref: https://stackoverflow.com/questions/59025426/docker-container-how-to-set-gid-of-socket-file-to-groupid-130
# Used to set the docker group ID
# Set to 497 by default, which is the groupID used by AWS Linux ECS instance
#ARG DOCKER_GID=497
#ARG DOCKER_GID=991
ARG DOCKER_GID=1102

## ref: https://serverfault.com/questions/618994/when-building-from-dockerfile-debian-ubuntu-package-install-debconf-noninteract
ENV container=docker
ENV DEBIAN_FRONTEND=noninteractive

USER root

# Update package lists and install necessary build tools and common dependencies.
# These are essential for compiling some Python packages and for general test execution.
# Add any other system-level dependencies your specific Ansible collections might require.
# For example, if your collections interact with AWS, Azure, databases, etc., you might need:
# apt-get install -y --no-install-recommends libssl-dev libffi-dev openssh-client

## 1. Core System Utilities & Locales
# These rarely change and provide the base for everything else
RUN apt-get update -qqy && \
    apt-get -qqy --no-install-recommends install \
      apt-transport-https apt-utils ca-certificates \
      bash tar zip unzip xorriso \
      curl wget git git-lfs \
      locales tzdata netbase \
      tree less nano jq rsync && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

## 2. Networking & Debugging Tools
RUN apt-get update -qqy && \
    apt-get -qqy --no-install-recommends install \
      dnsutils iproute2 iputils-ping inetutils-telnet \
      openssh-client ssh-askpass sshpass \
      gpg gpg-agent gnupg2 \
      shellcheck groff && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

## 3. Runtimes: Python
# These are the heaviest layers; separating them ensures changes to one don't invalidate the other
RUN apt-get update -qqy && \
    apt-get -qqy --no-install-recommends install \
      python3 python3-pip python3-virtualenv python3-venv && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

## 4. Build Tools & Development Libraries
# Essential for compiling Python C-extensions or local builds
RUN apt-get update -qqy && \
    apt-get -qqy --no-install-recommends install \
      build-essential patch genisoimage dirmngr openssl \
      zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev \
      libpq-dev libmariadb-dev libsasl2-dev libldap2-dev \
      libssl-dev libsqlite3-dev libreadline-dev libffi-dev \
      libbz2-dev uuid-dev default-mysql-client && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Generate and set the locale
RUN sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen

## Ensure the following are set after running `locale-gen`
ENV LANGUAGE=en_US:en
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Create Docker Group with GID
#RUN groupadd -g ${DOCKER_GID} docker
RUN groupadd -g ${DOCKER_GID} docker && \
    usermod -aG docker ${user}

## ref: https://octopus.com/blog/using-ubuntu-docker-image
RUN echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/00-docker
RUN echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/00-docker

## 5. Docker CLI (DinD Support)
# Kept separate so the Docker version can be updated independently
# --- Start Docker-in-Docker (DinD) support installation ---
# Install Docker CLI to enable running docker commands inside this container.
# This is crucial for scenarios like 'ansible-test units --docker' which
# require interacting with a Docker daemon.
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo \
        "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
        $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      docker-ce-cli \
      docker-compose-plugin \
      docker-buildx-plugin && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
# --- End Docker-in-Docker (DinD) support installation ---

# 5. External Tools: Copy in from builder stage ---
# Copy the already-extracted binaries from the builder stage
COPY --from=builder /out/usr/local/bin/ /usr/local/bin/

############################
## Using entrypoint.sh to source/set any secrets passed into the container
##
## ref: https://stackoverflow.com/questions/52492359/docker-secrets-passing-as-environment-variable
## ref: https://github.com/DevilaN/docker-entrypoint-example/
COPY ./entrypoint /
RUN chmod +x /docker-entrypoint.sh
RUN chmod +x /env_secrets_expand.sh

# drop back to the regular jenkins user - good practice
#USER jenkins
USER ${user}

## Second argument is original entrypoint in image
## original image definition: https://github.com/jenkinsci/docker/blob/master/17/debian/bullseye/hotspot/Dockerfile
#ENTRYPOINT ["/docker-entrypoint.sh", "/usr/bin/tini", "--", "/usr/local/bin/jenkins.sh"]
ENTRYPOINT ["/docker-entrypoint.sh", "/usr/local/bin/jenkins.sh"]
#ENTRYPOINT ["/docker-entrypoint.sh"]
#ENTRYPOINT [ "/entrypoint.sh" ]
