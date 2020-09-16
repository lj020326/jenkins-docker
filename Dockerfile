FROM jenkins/jenkins:lts
MAINTAINER 4oh4

# Derived from https://github.com/getintodevops/jenkins-withdocker (miiro@getintodevops.com)

USER root

## ref: https://stackoverflow.com/questions/59025426/docker-container-how-to-set-gid-of-socket-file-to-groupid-130

# Used to set the docker group ID
# Set to 497 by default, which is the groupID used by AWS Linux ECS instance
#ARG DOCKER_GID=497
ARG DOCKER_GID=991

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
   apt-get -y --no-install-recommends install docker-ce python3-dev python3-venv python3-wheel python3-setuptools python3-pip && \
   apt-get clean && \
   usermod -aG docker jenkins

# Install docker compose
## ref: https://github.com/tiangolo/docker-with-compose/blob/master/Dockerfile
## ref: https://stackoverflow.com/questions/34819221/why-is-python-setup-py-saying-invalid-command-bdist-wheel-on-travis-ci
RUN pip3 install wheel
RUN pip3 install docker-compose ansible

# drop back to the regular jenkins user - good practice
#USER jenkins
USER ${user}

## Add jenkins plugin
#COPY plugins.txt /usr/share/jenkins/plugins.txt
#RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/plugins.txt

