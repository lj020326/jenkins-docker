
# How to automate Jenkins setup with Docker and JCasC

Jenkins setup typically done through a web-based setup wizard can be a slow and error-prone.  Jenkins Configuration as Code (JCasC) method can help us to automate the setup of Jenkins using Docker.

As a part of our [Server Management Services](https://bobcares.com/server-management/), we help our Customers with Docker related requests regularly.

Let us today discuss the steps to perform this task.

## **How to automate Jenkins setup with Docker and Jenkins configuration as code?**

Here will automate the installation and configuration of Jenkins using Docker and the Jenkins Configuration as Code (JCasC) method.

This involves the following steps:

1.  Disabling the Setup Wizard
2.  Installing Jenkins Plugins
3.  Specifying the Jenkins URL
4.  Creating a User
5.  Setting Up Authorization
6.  Setting Up Build Authorization
7.  Enabling Agent to Controller Access Control

Let us look at each of these steps in detail.

## **Disabling the Setup Wizard**

The jenkins/jenkins image allows us to enable or disable the setup wizard by passing in a system property named `jenkins.install.runSetupWizard` via the `JAVA_OPTS` environment variable.

First, create a new directory inside the server to store the files that will be created:

```shell
$ mkdir -p $HOME/playground/jcasc
```

Then, navigate inside that directory:

```shell
$ cd $HOME/playground/jcasc
```

Next, using your editor, create a new file named Dockerfile:

```shell
$ nano $HOME/playground/jcasc/Dockerfile
```

Then, copy the following content into the Dockerfile:

```Dockerfile
FROM jenkins/jenkins:latest
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
```

Here, we are using the FROM instruction to specify jenkins/jenkins:latest as the base image, and the ENV instruction to set the JAVA_OPTS environment variable.

Save the file and exit the editor by pressing CTRL+X followed by Y.

With these modifications in place, build a new custom Docker image and assign it a unique tag (we will use jcasc here):

```shell
$ docker build -t jenkins:jcasc .
```

Now, we will see output similar to the following:

```shell
Sending build context to Docker daemon 2.048kB
Step 1/2 : FROM jenkins/jenkins:latest
---> 1f4b0aaa986e
Step 2/2 : ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
---> 7566b15547af
Successfully built 7566b15547af
Successfully tagged jenkins:jcasc
```

Once built, run the custom image by running docker run:

```shell
$ docker run --name jenkins --rm -p 8080:8080 jenkins:jcasc
```

Jenkins will take a short period of time to initiate. When Jenkins is ready, we will see a  message that Jenkins is fully up and running

Now, open up the browser to server_ip:8080. We will immediately see the dashboard without the setup wizard.

Here, the web interface may show warnings on the missing authentication, authorization schemes, and incorrect permission of anonymous users.

##  **Installing Jenkins Plugins**

To use JCasC, we need to install the Configuration as Code plugin. We can confirm the installed plugin list by navigating to http://server_ip:8080/pluginManager/installed.

To automate the plugin installation process, we can make use of an installation script present inside the container at /usr/local/bin/install-plugins.sh. To use it, you would need to:

-   Create a text file containing a list of plugins to install
-   Copy it into the Docker image
-   Run the install-plugins.sh script to install the plugins

First, using the editor, create a new file named plugins.txt:

```shell
$ nano $HOME/playground/jcasc/plugins.txt
```

Then, add in the following newline-separated list of plugin names and versions (using the format :):

```text
ant:latest
antisamy-markup-formatter:latest
build-timeout:latest
cloudbees-folder:latest
configuration-as-code:latest
credentials-binding:latest
email-ext:latest
git:latest
github-branch-source:latest
gradle:latest
ldap:latest
mailer:latest
matrix-auth:latest
pam-auth:latest
pipeline-github-lib:latest
pipeline-stage-view:latest
ssh-slaves:latest
timestamper:latest
workflow-aggregator:latest
ws-cleanup:latest
```

Finally, Save the file and exit the editor.

The list contains the Configuration as Code plugin, as well as all the plugins suggested by the setup wizard. For example, we have the Git plugin, which allows Jenkins to work with Git repositories. We can also find a list of the most popular community-contributed plugins at plugins.jenkins.io.

#### **Copy file into the Docker image**

Next, open up the Dockerfile file that we created in the initial step. In it, add a COPY instruction to copy the plugins.txt file into the /usr/share/jenkins/ref/ directory inside the image. This is where Jenkins normally looks for plugins. Then, include an additional RUN instruction to run the install-plugins.sh script:

```Dockerfile
FROM jenkins/jenkins
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
```

Save the file and exit the editor. Then, build a new image using the revised Dockerfile:

```shell
$ docker build -t jenkins:jcasc .
```

This step involves downloading and installing many plugins into the image and may take some time to run depending on your internet connection. Once the plugins have finished installing, run the new Jenkins image:

```shell
$ docker run --name jenkins --rm -p 8080:8080 jenkins:jcasc
```

Now if we navigate to the plugin list on the plugin Manager interface, we will see a solid checkbox next to all the plugins we specified inside plugins.txt, as well as a faded checkbox next to plugins, which are dependencies of those plugins.

After confirming that the Configuration As Code plugin is installed, terminate the container process by pressing CTRL+C.

## **Specifying the Jenkins URL**

The Jenkins URL is a URL for the Jenkins instance that is routable from the devices that need to access it.

We can set the Jenkins URL using the Configuration as Code plugin with the steps below:

1.  Define the desired configuration of the Jenkins instance inside a declarative configuration file.
2.  Copy the configuration file into the Docker image.
3.  Set the CASC_JENKINS_CONFIG environment variable to the path of the configuration file to instruct the Configuration as Code plugin to read it.

First, create a new file named jenkins_casc.yml:

```shell
$ nano $HOME/playground/jcasc/jenkins_casc.yml
```

Then, add in the following lines:

```yaml
unclassified:
  location:
    url: http://server_ip:8080/
```

unclassified.location.url is the path for setting the Jenkins URL.

Save the jenkins_casc.yml file, exit your editor, and open the Dockerfile file:

```shell
$ nano $HOME/playground/jcasc/Dockerfile
```

Add a COPY instruction to the end of the Dockerfile that copies the jenkins_casc.yml file into the image at /var/jenkins_home/jenkins_casc.yml. We have chosen /var/jenkins_home/ because that is the default directory where Jenkins stores all of its data:

```Dockerfile
FROM jenkins/jenkins:latest
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
COPY jenkins_casc.yml /var/jenkins_home/jenkins_casc.yml
```

Next add an `ENV` instruction that sets the `CASC_JENKINS_CONFIG` environment variable:

```Dockerfile
FROM jenkins/jenkins:latest
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
ENV CASC_JENKINS_CONFIG /var/jenkins_home/jenkins_casc.yml
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
#RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --clean-download-directory --list --view-security-warnings -f /usr/share/jenkins/ref/plugins.txt
COPY jenkins_casc.yml /var/jenkins_home/jenkins_casc.yml
```

We have put the ENV instruction near the top because it is something that we are unlikely to change. By placing it before the COPY and RUN instructions, we can avoid invalidating the cached layer if we were to update the jenkins_casc.yml or plugins.txt.

Save the file and exit the editor. Next, build the image and run the updated Jenkins image as we did in the initial step.

Now, navigate to server_ip:8080/configure and scroll down to the Jenkins URL field. Confirm that the Jenkins URL has been set to the same value specified in the jenkins_casc.yml file.

Lastly, stop the container process by pressing CTRL+C.

## **Creating a User**

In this step, we will set up a basic, password-based authentication scheme and create a new user named admin.

Start by opening the jenkins_casc.yml file:

```shell
$ nano $HOME/playground/jcasc/jenkins_casc.yml
```

Then, add in the highlighted snippet:

```yaml
jenkins:
securityRealm:
local:
allowsSignup: false
users:
- id: ${JENKINS_ADMIN_ID}
password: ${JENKINS_ADMIN_PASSWORD}
unclassified:
...
```

The local security realm means to use basic authentication where users must specify their ID/username and password.  
Further the allowsSignup: false, prevents anonymous users from creating an account through the web interface.

Next, build a new image to incorporate the changes made to the jenkins_casc.yml file:

```shell
$ docker build -t jenkins:jcasc .
```

Then, run the updated Jenkins image whilst passing in the JENKINS_ADMIN_ID and JENKINS_ADMIN_PASSWORD environment variables via the –env option:

```shell
$ docker run --name jenkins --rm -p 8080:8080 --env JENKINS_ADMIN_ID=admin --env JENKINS_ADMIN_PASSWORD=password jenkins:jcasc
```

We can now go to server_ip:8080/login and log in using the specified credentials.

Finish this step by pressing CTRL+C to stop the container.

## **Setting Up Authorization**

In this step, we will use the Matrix Authorization Strategy plugin to configure permissions for your admin user. By default, the Jenkins core installation provides us with three authorization strategies:

-   unsecured: every user, including anonymous users, have full permissions to do everything
-   legacy: any users with the role admin are given full permissions, whilst other users, including anonymous users, are given read access.
-   loggedInUsersCanDoAnything: anonymous users are given either no access or read-only access. Authenticated users have full permissions to do everything.

The Matrix Authorization Strategy plugin provides a granular authorization strategy. It allows us to set user permissions globally, as well as per project/job.

It also allows us to use the jenkins.authorizationStrategy.globalMatrix.permissions JCasC property to set global permissions. To use it, open the jenkins_casc.yml file:

```shell
$ nano $HOME/playground/jcasc/jenkins_casc.yml
```

And add in the highlighted snippet:

```yaml
...
- id: ${JENKINS_ADMIN_ID}
password: ${JENKINS_ADMIN_PASSWORD}
authorizationStrategy:
globalMatrix:
permissions:
- "Overall/Administer:admin"
- "Overall/Read:authenticated"
unclassified:
...
```

The globalMatrix property sets global permissions. Here, we are granting the Overall/Administer permissions to the admin user. We are also granting Overall/Read permissions all authenticated users.

Save the jenkins_casc.yml file, exit your editor, and build a new image:

```shell
$ docker build -t jenkins:jcasc .
```

Then, run the updated Jenkins image:

```shell
$ docker run --name jenkins --rm -p 8080:8080 --env JENKINS_ADMIN_ID=admin --env JENKINS_ADMIN_PASSWORD=password jenkins:jcasc
```

Before you continue, stop the container by pressing CTRL+C.

## **Setting Up Build Authorization**

By default, all jobs are run as the system user, which has a lot of system privileges.

As this is a security weak point, jobs should be run using the same Jenkins user that configured or triggered it. Thus, to achieve this, we need to install an additional plugin called the Authorize Project plugin.

Open plugins.txt:

```shell
$ nano $HOME/playground/jcasc/plugins.txt
```

And add the highlighted line:

```text
ant:latest
antisamy-markup-formatter:latest
authorize-project:latest
build-timeout:latest
...
```

The plugin provides a new build authorization strategy, which we would need to specify in the JCasC configuration. Exit out of the plugins.txt file and open the jenkins_casc.yml file:

```shell
$ nano $HOME/playground/jcasc/jenkins_casc.yml
```

Add the highlighted block to your jenkins_casc.yml file:

```yaml
...
- "Overall/Administer:admin"
- "Overall/Read:authenticated"
security:
queueItemAuthenticator:
authenticators:
- global:
strategy: triggeringUsersAuthorizationStrategy
unclassified:
...
```

Save the file and exit the editor. Then, build a new image using the modified plugins.txt and jenkins_casc.yml files:

```shell
$ docker build -t jenkins:jcasc .
```

Then, run the updated Jenkins image:

```shell
$ docker run --name jenkins --rm -p 8080:8080 --env JENKINS_ADMIN_ID=admin --env JENKINS_ADMIN_PASSWORD=password jenkins:jcasc
```

Stop the container by running CTRL+C before continuing.

## **Enabling Agent to Controller Access Control**

Jenkins supports distributed builds using an agent/controller configuration. The controller is responsible for providing the web UI, exposing an API for clients to send requests to, and co-ordinating builds. The agents are the instances that execute the jobs.

The benefit of this configuration is that it is more scalable and fault-tolerant. If one of the servers running Jenkins goes down, other instances can take up the extra load.

However, there may be instances where the agents cannot be trusted by the controller. Enabling Agent to Controller Access Control, we can control which commands and files the agents have access to.

To enable Agent to Controller Access Control, open the jenkins_casc.yml file:

```shell
$ nano $HOME/playground/jcasc/jenkins_casc.yml
```

Then, add the following highlighted lines:

```yaml
...
- "Overall/Administer:admin"
- "Overall/Read:authenticated"
remotingSecurity:
enabled: true
security:
queueItemAuthenticator:
...
```

Now, save the file and build a new image:

```shell
$ docker build -t jenkins:jcasc .
```

Run the updated Jenkins image:

```shell
$ docker run --name jenkins --rm -p 8080:8080 --env JENKINS_ADMIN_ID=admin --env JENKINS_ADMIN_PASSWORD=password jenkins:jcasc
```

## **Conclusion**

In short, Jenkins Configuration as Code (JCasC) method can help us to automate the setup of Jenkins using Docker. 

## Reference

* https://www.jenkins.io/doc/book/managing/casc/
* https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/README.md
* https://github.com/jenkinsci/ldap-plugin/blob/master/src/test/resources/jenkins/security/plugins/ldap/casc.yml
* https://bobcares.com/blog/jenkins-setup-docker/
* https://github.com/EMnify/jenkins-casc-docker
* https://github.com/emnify/jenkins-casc-docker/blob/master/Dockerfile
* https://github.com/emnify/jenkins-casc-docker/blob/master/plugins.txt


