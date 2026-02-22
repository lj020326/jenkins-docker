FROM jenkins/jenkins:lts
LABEL maintainer="Lee Johnson <ljohnson@dettonville.org>"

# Derived from https://github.com/getintodevops/jenkins-withdocker (miiro@getintodevops.com)
## ref: https://github.com/jenkinsci/docker/blob/master/Dockerfile
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=${uid}
ARG http_port=8080
ARG agent_port=50000
ARG JENKINS_HOME=/var/jenkins_home

## ref: https://stackoverflow.com/questions/59025426/docker-container-how-to-set-gid-of-socket-file-to-groupid-130
# Used to set the docker group ID
# Set to 497 by default, which is the groupID used by AWS Linux ECS instance
#ARG DOCKER_GID=497
ARG DOCKER_GID=991

## ref: https://serverfault.com/questions/618994/when-building-from-dockerfile-debian-ubuntu-package-install-debconf-noninteract
ARG DEBIAN_FRONTEND=noninteractive

USER root

#################################################
# Inspired by
# https://github.com/cloudbees/jnlp-slave-with-java-build-tools-dockerfile
# https://github.com/cloudbees/java-build-tools-dockerfile/blob/master/Dockerfile
# https://github.com/SeleniumHQ/docker-selenium/blob/master/Base/Dockerfile
# https://github.com/bibinwilson/jenkins-docker-slave
# https://medium.com/@prashant.vats/jenkins-master-and-slave-with-docker-b993dd031cbd
#################################################

# Create Docker Group with GID
# Set default value of 497 if DOCKER_GID set to blank string by Docker compose
#RUN groupadd -g ${DOCKER_GID:-497} docker
RUN groupadd -g ${DOCKER_GID:-991} docker

## ref: https://stackoverflow.com/questions/32942023/ubuntu-openjdk-8-unable-to-locate-package
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install apt-transport-https apt-utils ca-certificates \
  && apt-get -qqy --no-install-recommends install software-properties-common
#  && apt-get -qqy --no-install-recommends install software-properties-common apt-utils
#  && add-apt-repository -y ppa:git-core/ppa \
#  && add-apt-repository -y ppa:openjdk-r/ppa
#  && add-apt-repository -y ppa:git-core/ppa

#========================
# Miscellaneous packages
# iproute which is surprisingly not available in ubuntu:15.04 but is available in ubuntu:latest
# OpenJDK8
# rlwrap is for azure-cli
# groff is for aws-cli
# tree is convenient for troubleshooting builds
#========================
RUN apt-get update -qqy && \
    apt-get -qqy --no-install-recommends install \
        iproute2 \
        openssh-client \
        ssh-askpass sshpass \
        gpg gpg-agent \
        openjdk-11-jdk \
        tar zip unzip \
        wget curl \
        gnupg2 \
        git \
        build-essential \
        less nano tree \
        jq \
        python3 \
        python3-pip \
        groff \
        rlwrap \
        rsync \
        genisoimage \
        zlib1g-dev \
        libncurses5-dev \
        libgdbm-dev \
        libnss3-dev \
        libssl-dev \
        libsqlite3-dev \
        libreadline-dev \
        libffi-dev \
        libbz2-dev \
		tk-dev \
		uuid-dev \
        default-mysql-client \
	&& rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' ./etc/java-11-openjdk/security/java.security

#====================================
# DOCKER
# Install the latest Docker CE binaries and add user `jenkins` to the docker group
#====================================
RUN curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg > /tmp/docker.dkey; \
    apt-key add /tmp/docker.dkey && \
    add-apt-repository \
      "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
      $(lsb_release -cs) \
      stable" && \
   apt-get update && \
   apt-get -y --no-install-recommends install docker-ce && \
   apt-get clean && \
   usermod -aG docker ${user}

## ref: https://github.com/gdraheim/docker-systemctl-replacement
## ref: https://github.com/gdraheim/docker-systemctl-images/blob/master/centos-elasticsearch.dockerfile
## ref: https://github.com/kamermans/docker-openmanage/tree/master/resources
#COPY files/docker/systemctl.py /usr/bin/systemctl
#RUN test -L /bin/systemctl || ln -sf /usr/bin/systemctl /bin/systemctl

#==========
# PIP
#==========
RUN pip3 install --upgrade pip wheel setuptools

#==========
# DOCKER COMPOSE
# refs:
#    https://github.com/tiangolo/docker-with-compose/blob/master/Dockerfile
#    https://stackoverflow.com/questions/34819221/why-is-python-setup-py-saying-invalid-command-bdist-wheel-on-travis-ci
#==========
RUN pip3 install --upgrade docker-compose yq

#====================================
# ANSIBLE
# ref: https://medium.com/@prashant.vats/jenkins-master-and-slave-with-docker-b993dd031cbd
#====================================
RUN pip3 install --upgrade ansible
RUN mkdir -p /home/jenkins/.ansible \
  && chown -R jenkins:jenkins /home/jenkins/.ansible


#====================================
# ANSIBLE
# Install the terraform binary
#   https://linuxbuz.com/linuxhowto/install-terraform-ubuntu
#   https://blog.gripdev.xyz/2020/07/14/terraform-docker-ubuntu-20-04-go-1-14-and-memlock-down-the-rabbit-hole/
#====================================
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg > /tmp/hashicorp.dkey; \
    apt-key add /tmp/hashicorp.dkey && \
    add-apt-repository \
        "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt-get update && \
    apt-get -y --no-install-recommends install terraform

#====================================
# GOLANG
#  https://linuxize.com/post/how-to-install-go-on-ubuntu-20-04/
#  https://github.com/apparentlymart/terraform-clean-syntax
#====================================
#RUN wget -c https://dl.google.com/go/go1.14.2.linux-amd64.tar.gz -O - | sudo tar -xz -C /usr/local

#==========
# Maven
#==========
ENV MAVEN_VERSION 3.6.3

RUN curl -fsSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven

#==========
# Gradle
#==========
ENV GRADLE_VERSION 6.5.1

RUN wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -P /tmp \
  && unzip -d /opt/gradle /tmp/gradle-${GRADLE_VERSION}-bin.zip \
  && ln -s /opt/gradle/gradle-${GRADLE_VERSION}/bin/gradle /usr/bin/gradle \
  && rm /tmp/gradle-${GRADLE_VERSION}-bin.zip

#==========
# Ant
#==========
ENV ANT_VERSION 1.10.11

RUN curl -fsSL https://www.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/apache-ant-$ANT_VERSION /usr/share/ant \
  && ln -s /usr/share/ant/bin/ant /usr/bin/ant

ENV ANT_HOME /usr/share/ant

#==========
# Dell racadm CLI
# refs:
#   https://linux.dell.com/repo/community/openmanage/
#   https://www.privex.io/articles/install-idrac-tools-racadm-ubuntu-debian/
#   https://www.dell.com/community/Systems-Management-General/SSL-Library-error-and-idracadm7/td-p/4767653
#==========
RUN curl -kfsSL https://archiva.admin.johnson.int/repository/snapshots/org/dettonville/infra/iDRACTools/9.4.0-3733-Debian.15734_amd64/iDRACTools-9.4.0-3733-Debian.15734_amd64.tgz | tar xzf - -C /usr/share \
    && dpkg -i /usr/share/iDRACTools/*.deb \
    && ln -s /opt/dell/srvadmin/bin/idracadm7 /usr/local/bin/racadm
#    && ln -s /usr/lib/x86_64-linux-gnu/libssl.so.1.1 /usr/lib/x86_64-linux-gnu/libssl.so

#==========
# VMWARE govc CLI
# refs:
#    https://github.com/matt-l-welch/docker-govc/blob/master/Dockerfile
#    https://www.msystechnologies.com/blog/learn-how-to-install-configure-and-test-govc/
#    https://stackoverflow.com/questions/61571511/using-the-govc-container-in-jenkins
#==========
RUN curl -fsSL $(curl -s https://api.github.com/repos/vmware/govmomi/releases/latest | \
    grep browser_download_url | grep -i govc_linux_x86_64 | cut -d '"' -f 4) | \
    gunzip > /usr/local/bin/govc && \
    chmod +x /usr/local/bin/govc

#====================================
# Cloud Foundry CLI
# https://github.com/cloudfoundry/cli
#====================================
RUN wget -nv -O - "http://cli.run.pivotal.io/stable?release=linux64-binary&source=github" | tar -C /usr/local/bin -zxf -

#====================================
# AWS CLI
#====================================
RUN pip3 install awscli

# compatibility with CloudBees AWS CLI Plugin which expects pip to be installed as user
RUN mkdir -p /home/jenkins/.local/bin/ \
  && ln -s /usr/local/bin/pip /home/jenkins/.local/bin/pip \
  && chown -R jenkins:jenkins /home/jenkins/.local

#====================================
# Kubernetes CLI
# See https://storage.googleapis.com/kubernetes-release/release/stable.txt
#====================================
RUN curl -fsSL https://storage.googleapis.com/kubernetes-release/release/v1.16.1/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl

#====================================
# OPENSHIFT V3 CLI
# Only install "oc" executable, don't install "openshift", "oadmin"...
# See https://github.com/openshift/origin/releases
#====================================
RUN mkdir /var/tmp/openshift \
        && wget -nv -O - "https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz" \
        | tar -C /var/tmp/openshift --strip-components=1 -zxf - 2> /dev/null \
        && mv /var/tmp/openshift/oc /usr/local/bin \
        && rm -rf /var/tmp/openshift

#==========
# TERRAFORM CLI
# refs:
#   https://linuxbuz.com/linuxhowto/install-terraform-ubuntu
#   https://blog.gripdev.xyz/2020/07/14/terraform-docker-ubuntu-20-04-go-1-14-and-memlock-down-the-rabbit-hole/
#==========
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg > /tmp/hashicorp.dkey; \
    apt-key add /tmp/hashicorp.dkey && \
    add-apt-repository \
        "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt-get update && \
    apt-get -y --no-install-recommends install terraform

#====================================
# JMETER
#====================================
RUN mkdir /opt/jmeter \
      && wget -nv -O - "https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-5.3.tgz" \
      | tar -xz --strip=1 -C /opt/jmeter

# drop back to the regular jenkins user - good practice
#USER jenkins
USER ${user}

## Add jenkins plugin
#COPY plugins.txt /usr/share/jenkins/plugins.txt
#RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/plugins.txt

