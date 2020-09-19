FROM jenkins/jenkins:lts

# Derived from https://github.com/getintodevops/jenkins-withdocker (miiro@getintodevops.com)

## ref: https://github.com/jenkinsci/docker/blob/master/Dockerfile
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG http_port=8080
ARG agent_port=50000
ARG JENKINS_HOME=/var/jenkins_home

## ref: https://stackoverflow.com/questions/59025426/docker-container-how-to-set-gid-of-socket-file-to-groupid-130
# Used to set the docker group ID
# Set to 497 by default, which is the groupID used by AWS Linux ECS instance
#ARG DOCKER_GID=497
ARG DOCKER_GID=991

USER root

# Create Docker Group with GID
# Set default value of 497 if DOCKER_GID set to blank string by Docker compose
#RUN groupadd -g ${DOCKER_GID:-497} docker
RUN groupadd -g ${DOCKER_GID:-991} docker

# Install the latest Docker CE binaries and add user `jenkins` to the docker group
RUN apt-get update && \
    apt-get -y --no-install-recommends install apt-transport-https \
      ca-certificates \
      curl \
      gnupg2 \
      software-properties-common && \
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg > /tmp/dkey; apt-key add /tmp/dkey && \
    add-apt-repository \
      "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
      $(lsb_release -cs) \
      stable" && \
    apt-get update && \
    apt-get -y --no-install-recommends install docker-ce && \
    apt-get clean && \
    usermod -aG docker jenkins

#==========
# PYTHON3.8
#==========
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y python3.8 && \
    apt-get install -y python3-distutils python3-setuptools && \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python3.8 get-pip.py

#==========
# PIP, DOCKER COMPOSE, ANSIBLE
# refs:
#    https://github.com/tiangolo/docker-with-compose/blob/master/Dockerfile
#    https://stackoverflow.com/questions/34819221/why-is-python-setup-py-saying-invalid-command-bdist-wheel-on-travis-ci
#==========
RUN pip3 install --upgrade pip wheel setuptools && \
    pip3 install -U docker-compose ansible

#==========
# VMWARE GOVC CLI
# refs:
#    https://github.com/matt-l-welch/docker-govc/blob/master/Dockerfile
#    https://www.msystechnologies.com/blog/learn-how-to-install-configure-and-test-govc/
#==========
RUN curl -L $(curl -s https://api.github.com/repos/vmware/govmomi/releases/latest | \
    grep browser_download_url | grep govc_linux_amd64 | cut -d '"' -f 4) | \
    gunzip > /usr/local/bin/govc && \
    chmod +x /usr/local/bin/govc

# drop back to the regular jenkins user - good practice
#USER jenkins
USER ${user}

## Add jenkins plugin
#COPY plugins.txt /usr/share/jenkins/plugins.txt
#RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/plugins.txt

