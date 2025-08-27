## ref: https://schneide.blog/2019/10/21/using-parameterized-docker-builds/
ARG IMAGE_REGISTRY=docker.io
ARG BASE_IMAGE_LABEL=lj020326/docker-jenkins:latest
FROM $IMAGE_REGISTRY/$BASE_IMAGE_LABEL

LABEL maintainer="Lee Johnson <ljohnson@dettonville.org>"
ARG BUILD_ID=devel
LABEL build=$BUILD_ID

#################################################
# Inspired by
# https://github.com/lj020326/pipeline-automation-lib/blob/main/docs/jenkins-config-as-code/jenkins-setup-jcac-docker.md
#################################################

## ref: https://github.com/lj020326/pipeline-automation-lib/blob/main/docs/jenkins-config-as-code/Dockerfile

# skip the setup wizard
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
#ENV CASC_JENKINS_CONFIG=/var/jenkins_home/jenkins_casc.yaml

RUN mkdir -p /usr/share/jenkins/ref/plugins

# install plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --clean-download-directory --list --view-security-warnings -f /usr/share/jenkins/ref/plugins.txt
