[![Docker images build](https://github.com/lj020326/jenkins-docker/actions/workflows/build-images.yml/badge.svg)](https://github.com/lj020326/jenkins-docker/actions/workflows/build-images.yml)
[![License](https://img.shields.io/badge/license-GPLv3-brightgreen.svg?style=flat)](LICENSE)

# docker-jenkins

Jenkins in a Docker container, with Docker inside.

The jenkins enabled docker image used in examples here can be found on [dockerhub](https://hub.docker.com/repository/docker/lj020326/docker-jenkins).  

There is a blog post associated with this repository, with more information: [Quickstart CI with Jenkins and Docker-in-Docker](https://github.com/lj020326/pipeline-automation-lib/blob/main/docs/jenkins-docker-in-docker-agent.md)

Running Jenkins in Docker makes a lot of sense: its super quick to get going, and you can just expose the ports needed to access via the web interface. But it also makes sense to run your test cases/builds inside Docker as well: its compartmentalised, with full control of the environment inside.

This Dockerfile just takes the current, official Jenkins long term support (LTS) Docker image, installs Docker CE inside, and adds the `jenkins` user to the `docker` group.

[It is recommended](https://github.com/jenkinsci/docker/blob/master/README.md) to create an explicit volume on the host machine, that will survive the container stop/restart/deletion. Use this argument when you run Docker: `-v jenkins_home:/var/jenkins_home`

## Status

[![GitHub issues](https://img.shields.io/github/issues/lj020326/jenkins-docker.svg?style=flat)](https://github.com/lj020326/jenkins-docker/issues)
[![GitHub stars](https://img.shields.io/github/stars/lj020326/jenkins-docker.svg?style=flat)](https://github.com/lj020326/jenkins-docker/stargazers)
[![Docker Pulls - centos7-systemd-python](https://img.shields.io/docker/pulls/lj020326/docker-jenkins.svg?style=flat)](https://hub.docker.com/repository/docker/lj020326/docker-jenkins/)

### Docker in Docker
It's possible to run into some problems with Docker running inside another Docker container ([more info here](https://github.com/lj020326/pipeline-automation-lib/blob/main/docs/docker-in-docker-the-good-the-bad-and-the-fix.md)). A better approach is that a container does not run its own Docker daemon, but connects to the Docker daemon of the host system. That means, you will have a Docker CLI in the container, as well as on the host system, but they both connect to one and the same Docker daemon. At any time, there is only one Docker daemon running in your machine, the one running on the host system. This [article](https://github.com/lj020326/pipeline-automation-lib/blob/main/docs/docker-inside-a-docker-container.md) really helped me understand this. To do this, you just bind mount to the host system daemon, using this argument when you run Docker: `-v /var/run/docker.sock:/var/run/docker.sock`

### Running the container
The easiest way is to pull from Docker Hub:

    docker run -it -p 8080:8080 -p 50000:50000 \
	    -v jenkins_home:/var/jenkins_home \
	    -v /var/run/docker.sock:/var/run/docker.sock \
	    --restart unless-stopped \
	    lj020326/docker-jenkins

Alternatively, you can clone this repository, build the image from the Dockerfile, and then run the container

    docker build -t docker-jenkins .

    docker run -it -p 8080:8080 -p 50000:50000 \
	    -v jenkins_home:/var/jenkins_home \
	    -v /var/run/docker.sock:/var/run/docker.sock \
	    --restart unless-stopped \
	    docker-jenkins

## Contact

[![Linkedin](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/leejjohnson/)
