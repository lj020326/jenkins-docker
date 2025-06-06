## ref: https://hub.docker.com/r/jenkins/jenkins
FROM jenkins/jenkins:lts-jdk21
#FROM jenkins/jenkins:lts
#FROM jenkins/jenkins:2.414-jdk21
#FROM jenkins/jenkins:2.414-jdk17

LABEL maintainer="Lee Johnson <ljohnson@dettonville.org>"
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

ARG INTERNAL_IMAGE_BUILD=NO
ARG INSTALL_INSPEC=NO

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

#################################################
# Inspired by
# https://github.com/cloudbees/jnlp-slave-with-java-build-tools-dockerfile
# https://github.com/cloudbees/java-build-tools-dockerfile/blob/master/Dockerfile
# https://github.com/SeleniumHQ/docker-selenium/blob/master/Base/Dockerfile
# https://github.com/bibinwilson/jenkins-docker-slave
# https://medium.com/@prashant.vats/jenkins-master-and-slave-with-docker-b993dd031cbd
#################################################

# Create Docker Group with GID
#RUN groupadd -g ${DOCKER_GID} docker
RUN groupadd -g ${DOCKER_GID} docker && \
    usermod -aG docker ${user}

### ref: https://stackoverflow.com/questions/32942023/ubuntu-openjdk-8-unable-to-locate-package
RUN apt-get update -qqy && \
    apt-get -qqy install apt-utils && \
    apt-get -qqy --no-install-recommends install \
      apt-transport-https \
      locales \
      ca-certificates \
      software-properties-common

########################
## Set the locale
## ref: https://stackoverflow.com/questions/28405902/how-to-set-the-locale-inside-a-debian-ubuntu-docker-container#28406007
##
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

#========================
# Miscellaneous packages
# iproute which is surprisingly not available in ubuntu:15.04 but is available in ubuntu:latest
# OpenJDK8
# rlwrap is for azure-cli
# groff is for aws-cli
# tree is convenient for troubleshooting builds
#========================
RUN apt-get -qqy --no-install-recommends install \
    dnsutils \
    iproute2 \
    openssh-client \
    iputils-ping \
    inetutils-telnet \
    ssh-askpass sshpass \
    gpg gpg-agent \
    tar zip unzip \
    wget curl \
    gnupg2 \
    git \
    build-essential \
    less nano tree \
    jq \
    python3 \
    python3-pip \
    rsync \
#        ansible \
#        groff \
#        rlwrap \
#		uuid-dev \
#        default-mysql-client \
	&& rm -rf /var/lib/apt/lists/* \
    && apt-get clean

#========================
# OpenJDK-17
# ref: https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-on-ubuntu-20-04
# ref: https://askubuntu.com/questions/1203898/package-openjdk-11-jdk-has-no-installation-candidate
#========================
#RUN add-apt-repository ppa:openjdk-r/ppa \
RUN apt update && \
    apt-get -qqy --no-install-recommends install \
    default-jdk
#    default-jre
#    openjdk-17-jdk-headless

### ref: https://stackoverflow.com/questions/43316935/change-java-securerandom-in-dockerfile
#RUN sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' /etc/java-${JAVA_VERSION}-openjdk/security/java.security
#
### ref: https://www.howtoforge.com/how-to-install-java-openjdk-and-oracle-jdk-on-ubuntu-22-04/
##ENV JAVA_HOME=/opt/java/openjdk
#ENV JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64

######################################
### Groovy install
###
### ref: https://github.com/groovy/docker-groovy/blob/master/jdk11/Dockerfile
###
######################################
#ENV GROOVY_VERSION=4.0.11
#ENV GROOVY_HOME=/opt/groovy
#RUN set -o errexit -o nounset \
#    && echo "Downloading Groovy" \
#    && curl -fsSL -o groovy.zip "https://archive.apache.org/dist/groovy/${GROOVY_VERSION}/distribution/apache-groovy-binary-${GROOVY_VERSION}.zip" \
#    && echo "Importing keys listed in http://www.apache.org/dist/groovy/KEYS from key server" \
#    && export GNUPGHOME="$(mktemp -d)" \
#    && curl https://downloads.apache.org/groovy/KEYS -o "${GNUPGHOME}/groovy-keys" \
#    && gpg --import "${GNUPGHOME}/groovy-keys" \
#    && echo "Checking download signature" \
#    && curl -fsSL -o groovy.zip.asc "https://archive.apache.org/dist/groovy/${GROOVY_VERSION}/distribution/apache-groovy-binary-${GROOVY_VERSION}.zip.asc" \
#    && gpg --batch --no-tty --verify groovy.zip.asc groovy.zip \
#    && rm --recursive --force "${GNUPGHOME}" \
#    && rm groovy.zip.asc \
#    \
#    && echo "Installing Groovy" \
#    && unzip groovy.zip \
#    && rm groovy.zip \
#    && mv "groovy-${GROOVY_VERSION}" "${GROOVY_HOME}/" \
#    && ln --symbolic "${GROOVY_HOME}/bin/grape" /usr/bin/grape \
#    && ln --symbolic "${GROOVY_HOME}/bin/groovy" /usr/bin/groovy \
#    && ln --symbolic "${GROOVY_HOME}/bin/groovyc" /usr/bin/groovyc \
#    && ln --symbolic "${GROOVY_HOME}/bin/groovyConsole" /usr/bin/groovyConsole \
#    && ln --symbolic "${GROOVY_HOME}/bin/groovydoc" /usr/bin/groovydoc \
#    && ln --symbolic "${GROOVY_HOME}/bin/groovysh" /usr/bin/groovysh \
#    && ln --symbolic "${GROOVY_HOME}/bin/java2groovy" /usr/bin/java2groovy \
#    \
#    && echo "Editing startGroovy to include java.xml.bind module" \
#    && sed --in-place 's|startGroovy ( ) {|startGroovy ( ) {\n    JAVA_OPTS="$JAVA_OPTS --add-modules=ALL-SYSTEM"|' "${GROOVY_HOME}/bin/startGroovy"

## Create Docker Group with GID
## Set default value of 497 if DOCKER_GID set to blank string by Docker compose
##RUN groupadd -g ${DOCKER_GID:-497} docker
#RUN groupadd -g ${DOCKER_GID:-991} docker
#
##====================================
## DOCKER
## Install the latest Docker CE binaries and add user `jenkins` to the docker group
##====================================
#RUN curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg > /tmp/docker.dkey; \
#    apt-key add /tmp/docker.dkey && \
#    add-apt-repository \
#      "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
#      $(lsb_release -cs) \
#      stable" && \
#   apt-get update && \
#   apt-get -y --no-install-recommends install docker-ce && \
#   apt-get clean && \
#   usermod -aG docker ${user}
#
### ref: https://github.com/gdraheim/docker-systemctl-replacement
### ref: https://github.com/gdraheim/docker-systemctl-images/blob/master/centos-elasticsearch.dockerfile
### ref: https://github.com/kamermans/docker-openmanage/tree/master/resources
##COPY files/docker/systemctl.py /usr/bin/systemctl
##RUN test -L /bin/systemctl || ln -sf /usr/bin/systemctl /bin/systemctl
#
##==========
## PIP
##==========
#RUN pip3 install --upgrade pip wheel setuptools
#
##==========
## DOCKER COMPOSE
## refs:
##    https://github.com/tiangolo/docker-with-compose/blob/master/Dockerfile
##    https://stackoverflow.com/questions/34819221/why-is-python-setup-py-saying-invalid-command-bdist-wheel-on-travis-ci
##==========
#RUN pip3 install --upgrade docker-compose yq
#
###====================================
### ANSIBLE
### ref: https://medium.com/@prashant.vats/jenkins-master-and-slave-with-docker-b993dd031cbd
### Now done in the initial apt-get package install
###====================================
#RUN pip3 install --upgrade ansible
#
### Ansible uses the following packages.
### Most of the current versions are not installed by default with the Ansible package
#RUN pip3 install \
#    pyyaml \
#    pywinrm \
#    jinja2 \
#    jmespath \
#    netaddr \
#    passlib \
#    cryptography \
#    pyOpenSSL \
#    git+https://github.com/vmware/vsphere-automation-sdk-python.git \
#    awxkit
#
#RUN mkdir -p ${JENKINS_HOME}/.ansible \
#  && chown -R ${user}:${group} ${JENKINS_HOME}/.ansible
#
##====================================
## GOLANG
##  https://linuxize.com/post/how-to-install-go-on-ubuntu-20-04/
##  https://github.com/apparentlymart/terraform-clean-syntax
##====================================
##RUN wget -c https://dl.google.com/go/go1.14.2.linux-amd64.tar.gz -O - | sudo tar -xz -C /usr/local
#
##==========
## Maven
##==========
##ENV MAVEN_VERSION=3.6.3
#RUN MAVEN_VERSION=$(curl -sX GET http://archive.apache.org/dist/maven/maven-3/ | grep href | sed 's/.*\/">\(.*\)\/<.*/\1/' | uniq | tail -1) \
#  && curl -fsSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
#  && mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven \
#  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn
#
#ENV MAVEN_HOME=/usr/share/maven
#
##==========
## Gradle
##==========
##ENV GRADLE_VERSION=6.5.1
#RUN GRADLE_VERSION=$(curl -sX GET https://services.gradle.org/distributions/ | grep bin.zip | sed 's/.*gradle-\(.*\)-bin.*/\1/' | uniq | head -1) \
#  && wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -P /tmp \
#  && unzip -d /opt/gradle /tmp/gradle-${GRADLE_VERSION}-bin.zip \
#  && ln -s /opt/gradle/gradle-${GRADLE_VERSION}/bin/gradle /usr/bin/gradle \
#  && rm /tmp/gradle-${GRADLE_VERSION}-bin.zip
#
##==========
## Ant
##==========
##ENV ANT_VERSION=1.10.11
#
##RUN ANT_VERSION=$(wget -q -O -  https://downloads.apache.org/ant/binaries/ | grep tar.bz | sed 's/.*apache-ant-\(.*\)-bin.*/\1/' | uniq | head -1) && \
#RUN ANT_VERSION=$(curl -sX GET https://downloads.apache.org/ant/binaries/ | grep tar.bz | sed 's/.*apache-ant-\(.*\)-bin.*/\1/' | uniq | head -1) \
#  && curl -fsSL https://www.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz | tar xzf - -C /usr/share \
#  && mv /usr/share/apache-ant-$ANT_VERSION /usr/share/ant \
#  && ln -s /usr/share/ant/bin/ant /usr/bin/ant
#
#ENV ANT_HOME=/usr/share/ant
#
##==========
## Dell racadm CLI
## refs:
##   https://linux.dell.com/repo/community/openmanage/
##   https://www.privex.io/articles/install-idrac-tools-racadm-ubuntu-debian/
##   https://www.dell.com/community/Systems-Management-General/SSL-Library-error-and-idracadm7/td-p/4767653
##==========
ENV IDRAC_TOOLS_URL="https://archiva.admin.dettonville.int/repository/snapshots/org/dettonville/infra/iDRACTools/9.4.0-3733-Debian.15734_amd64/iDRACTools-9.4.0-3733-Debian.15734_amd64.tgz"
ENV CURL_INSTALL_IDRAC_TOOLS="curl -kfsSL ${IDRAC_TOOLS_URL} | tar xzf - -C /usr/share=\
    && dpkg -i /usr/share/iDRACTools/*.deb \
    && ln -s /opt/dell/srvadmin/bin/idracadm7 /usr/local/bin/racadm"
## ref: https://stackoverflow.com/questions/43654656/dockerfile-if-else-condition-with-external-arguments
RUN if [ "$INTERNAL_IMAGE_BUILD" = "YES" ] ; then \
      eval ${CURL_INSTALL_IDRAC_TOOLS} ; \
    else \
      echo "[INTERNAL_IMAGE_BUILD=${INTERNAL_IMAGE_BUILD}]: Idrac Tools not installed" ; \
    fi

##RUN curl -kfsSL https://archiva.admin.dettonville.int/repository/snapshots/org/dettonville/infra/iDRACTools/9.4.0-3733-Debian.15734_amd64/iDRACTools-9.4.0-3733-Debian.15734_amd64.tgz | tar xzf - -C /usr/share \
##    && dpkg -i /usr/share/iDRACTools/*.deb \
##    && ln -s /opt/dell/srvadmin/bin/idracadm7 /usr/local/bin/racadm
###    && ln -s /usr/lib/x86_64-linux-gnu/libssl.so.1.1 /usr/lib/x86_64-linux-gnu/libssl.so
#
##==========
## VMWARE govc CLI
## refs:
##    https://github.com/matt-l-welch/docker-govc/blob/master/Dockerfile
##    https://www.msystechnologies.com/blog/learn-how-to-install-configure-and-test-govc/
##    https://stackoverflow.com/questions/61571511/using-the-govc-container-in-jenkins
##==========
RUN curl -fsSL $(curl -s https://api.github.com/repos/vmware/govmomi/releases/latest | \
    grep browser_download_url | grep -i govc_linux_x86_64 | cut -d '"' -f 4) | \
    tar -C /usr/local/bin -zxf -

##====================================
## Cloud Foundry CLI
## https://github.com/cloudfoundry/cli
##====================================
#RUN wget -nv -O - "http://cli.run.pivotal.io/stable?release=linux64-binary&source=github" | tar -C /usr/local/bin -zxf -
#
##====================================
## AWS CLI
##====================================
#RUN pip3 install awscli
#
## compatibility with CloudBees AWS CLI Plugin which expects pip to be installed as user
#RUN mkdir -p ${JENKINS_HOME}/.local/bin/ \
#  && ln -s /usr/local/bin/pip ${JENKINS_HOME}/.local/bin/pip \
#  && chown -R ${user}:${group} ${JENKINS_HOME}/.local
#
##====================================
## Kubernetes CLI
## See https://storage.googleapis.com/kubernetes-release/release/stable.txt
##====================================
#RUN curl -fsSL https://storage.googleapis.com/kubernetes-release/release/v1.16.1/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl
#
##====================================
## OPENSHIFT V3 CLI
## Only install "oc" executable, don't install "openshift", "oadmin"...
## See https://github.com/openshift/origin/releases
##====================================
#RUN mkdir /var/tmp/openshift \
#        && wget -nv -O - "https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz" \
#        | tar -C /var/tmp/openshift --strip-components=1 -zxf - 2> /dev/null \
#        && mv /var/tmp/openshift/oc /usr/local/bin \
#        && rm -rf /var/tmp/openshift
#
##==========
## TERRAFORM CLI
## refs:
##   https://linuxbuz.com/linuxhowto/install-terraform-ubuntu
##   https://blog.gripdev.xyz/2020/07/14/terraform-docker-ubuntu-20-04-go-1-14-and-memlock-down-the-rabbit-hole/
##==========
#RUN curl -fsSL https://apt.releases.hashicorp.com/gpg > /tmp/hashicorp.dkey; \
#    apt-key add /tmp/hashicorp.dkey && \
#    add-apt-repository \
#        "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
#    apt-get update && \
#    apt-get -y --no-install-recommends install terraform

## Resolve "apt-key is deprecated. Manage keyring files in trusted.gpg.d instead"
## ref: https://stackoverflow.com/questions/68992799/warning-apt-key-is-deprecated-manage-keyring-files-in-trusted-gpg-d-instead
## ref: https://stackoverflow.com/questions/60137344/docker-how-to-solve-the-public-key-error-in-ubuntu-while-installing-docker
#RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | \
#    apt-key add - && \
#    add-apt-repository \
#        "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
#    apt-get update && \
#    apt-get -y --no-install-recommends install terraform

##==========
## PACKER CLI
## refs:
##   https://stackoverflow.com/questions/53147975/install-packer-in-jenkins-slave-using-dockerfile
##==========
#RUN add-apt-repository \
#        "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
#    apt-get update && \
#    apt-get -y --no-install-recommends install packer

#RUN PACKER_VERSION=1.6.2 \
#RUN PACKER_VERSION=$(wget -q -O - https://releases.hashicorp.com/packer/ | grep packer_ | sed 's/.*packer_\(.*\)\<.*/\1/' | uniq | head -1) \
#RUN PACKER_VERSION=$(curl -fsSL https://releases.hashicorp.com/packer/ | grep packer_ | sed 's/.*packer_\(.*\)\<.*/\1/' | uniq | head -1) \
RUN PACKER_VERSION=1.9.0-alpha \
  && curl -fsSL https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip | \
    gunzip > /usr/local/bin/packer && \
    chmod +x /usr/local/bin/packer
#RUN wget https://releases.hashicorp.com/packer/1.3.2/packer_1.6.2_linux_amd64.zip
#RUN unzip packer_1.3.2_linux_amd64.zip -d packer

###==========
### Chef inspec
### refs:
###   https://docs.chef.io/inspec/install/
###==========
#RUN curl -fsSL https://omnitruck.chef.io/install.sh | bash -s -- -P inspec
## ref: https://stackoverflow.com/questions/43654656/dockerfile-if-else-condition-with-external-arguments
RUN if [ "$INSTALL_INSPEC" = "YES" ] ; then \
      curl -fsSL https://omnitruck.chef.io/install.sh | bash -s -- -P inspec ; \
    fi

##====================================
## JMETER
##====================================
#RUN mkdir /opt/jmeter \
#      && wget -nv -O - "https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-5.3.tgz" \
#      | tar -xz --strip=1 -C /opt/jmeter
#
###====================================
### NODE JS
### See https://github.com/nodesource/distributions/blob/master/README.md
### See https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
###====================================
##RUN curl -fsSL https://deb.nodesource.com/setup_10.x | bash \
##    && apt-get install -y nodejs \
##    && apt-get clean
##RUN curl -fsSL https://deb.nodesource.com/setup_17.x | bash \
##  && hwclock --hctosys \
##  && apt-get install -y nodejs
#
## RUN curl -fsSL https://deb.nodesource.com/setup_17.x | bash \
#RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash \
#  && apt-get install -y nodejs
#
##====================================
## YARN, GRUNT, GULP
##====================================
#RUN npm install --global grunt-cli yarn gulp
#
###==========
### Selenium
###==========
##
##ENV SELENIUM_MAJOR_VERSION=3.141
##ENV SELENIUM_VERSION=3.141.59
##RUN  mkdir -p /opt/selenium \
##  && wget --no-verbose http://selenium-release.storage.googleapis.com/$SELENIUM_MAJOR_VERSION/selenium-server-standalone-$SELENIUM_VERSION.jar -O /opt/selenium/selenium-server-standalone.jar
##
##RUN pip3 install -U selenium
##
### https://github.com/SeleniumHQ/docker-selenium/blob/master/StandaloneFirefox/Dockerfile
##
##ENV SCREEN_WIDTH=1360
##ENV SCREEN_HEIGHT=1020
##ENV SCREEN_DEPTH=24
##ENV DISPLAY=:99.0
##
#
###=====
### XVFB
###=====
##RUN apt-get update -qqy \
##  && apt-get -qqy --no-install-recommends install \
##    xvfb \
##  && apt-get clean
##
###=========
### Firefox
###=========
##ARG FIREFOX_VERSION=78.0.2esr
##
### don't install firefox with apt-get because there are some problems,
### install the binaries downloaded from mozilla
### see https://github.com/SeleniumHQ/docker-selenium/blob/3.0.1-fermium/NodeFirefox/Dockerfile#L13
### workaround "D-Bus library appears to be incorrectly set up; failed to read machine uuid"
### run "dbus-uuidgen > /var/lib/dbus/machine-id"
##
##RUN apt-get update -qqy \
##  && apt-get -qqy --no-install-recommends install firefox dbus \
##  && rm -rf /var/lib/apt/lists/* /var/cache/apt/* \
##  && wget --no-verbose -O /tmp/firefox.tar.bz2 https://download-installer.cdn.mozilla.net/pub/firefox/releases/$FIREFOX_VERSION/linux-x86_64/en-US/firefox-$FIREFOX_VERSION.tar.bz2 \
##  && apt-get -y purge firefox \
##  && rm -rf /opt/firefox \
##  && tar -C /opt -xjf /tmp/firefox.tar.bz2 \
##  && rm /tmp/firefox.tar.bz2 \
##  && mv /opt/firefox /opt/firefox-$FIREFOX_VERSION \
##  && ln -fs /opt/firefox-$FIREFOX_VERSION/firefox /usr/bin/firefox \
##  && apt-get clean
##
##RUN dbus-uuidgen > /var/lib/dbus/machine-id
##
###======================
### Firefox GECKO DRIVER
###======================
##
##ARG GECKO_DRIVER_VERSION=v0.26.0
##RUN wget -nv -O - "https://github.com/mozilla/geckodriver/releases/download/$GECKO_DRIVER_VERSION/geckodriver-$GECKO_DRIVER_VERSION-linux64.tar.gz" \
##      | tar -xz -C /usr/bin
#
#
#RUN rm -rf /var/lib/apt/lists/*

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
