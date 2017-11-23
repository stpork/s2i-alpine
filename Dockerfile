FROM openjdk:8-jdk-alpine

MAINTAINER stpork from Mordor team


ENV OCP_VERSION=v3.6.1 \
OCP_BUILD=008f2d5 \
CLI_VERSION=7.2.0 \
CLI_BUILD=16285777 \
GRADLE_VERSION=4.3 \
MAVEN_VERSION=3.5.2 \
RUN_USER=daemon \
RUN_GROUP=daemon \
MAVEN_HOME=/usr/local/maven \
GRADLE_HOME=/usr/local/gradle \
HOME=/opt/app-root \
STI_SCRIPTS_PATH=/usr/libexec/s2i

ENV M2_HOME=$MAVEN_HOME \
PATH=$MAVEN_HOME/bin:$GRADLE_HOME/bin:$PATH \
JAVA_TOOL_OPTIONS=-Duser.home=${HOME}

LABEL io.k8s.description="Platform for building and running Spring Boot applications" \
io.k8s.display-name="S2I Spring Boot Maven 3" \
io.openshift.expose-services="8080:http" \
io.openshift.tags="builder,java,java8,maven,maven3,springboot" \
io.openshift.s2i.scripts-url=image://${STI_SCRIPTS_PATH}

RUN set -x \
&& CURL_OPTS=-kfsSL \
&& apk update -qq \
&& apk add --no-cache ca-certificates curl git bash openssl nano \
&& update-ca-certificates --fresh \
&& rm -rf /var/lib/{apt,dpkg,cache,log}/ /tmp/* /var/tmp/* \
&& mkdir -p ${MAVEN_HOME} \
&& mkdir -p ${HOME} \
&& mkdir -p ${STI_SCRIPTS_PATH} \
&& curl ${CURL_OPTS} \
"http://www.nic.funet.fi/pub/mirrors/apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
| tar -xz --strip-components=1 -C ${MAVEN_HOME} \
&& mkdir -p ${HOME}/.m2 \
&& curl ${CURL_OPTS} ${XML_URL} \
"https://bitbucket.org/stpork/bamboo-agent/downloads/settings.xml" \
-o ${HOME}/.m2/settings.xml \
&& USR_LOCAL_BIN=/usr/local/bin \
&& curl ${CURL_OPTS} \
"http://github.com/openshift/origin/releases/download/${OCP_VERSION}/openshift-origin-client-tools-${OCP_VERSION}-${OCP_BUILD}-linux-64bit.tar.gz" \
| tar -xz --strip-components=1 -C ${USR_LOCAL_BIN} \
&& cd ${HOME} \
&& curl ${CURL_OPTS} \
"http://bobswift.atlassian.net/wiki/download/attachments/${CLI_BUILD}/atlassian-cli-${CLI_VERSION}-distribution.zip" \
-o atlassian-cli.zip \
&& unzip -q atlassian-cli.zip \
&& mv atlassian-cli-${CLI_VERSION}/* ${USR_LOCAL_BIN} \
&& rm -rf atlassian-cli* \
&& curl ${CURL_OPTS} ${GRADLE_URL} \
"https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
-o gradle.zip \
&& mkdir -p $GRADLE_HOME \
&& unzip -q gradle.zip \
&& mv gradle-${GRADLE_VERSION}/* ${GRADLE_HOME} \
&& rm -rf gradle* \
&& chown -R ${RUN_USER}:${RUN_GROUP} ${HOME} \
&& chmod -R 777 ${HOME} \
&& chown -R ${RUN_USER}:${RUN_GROUP} ${USR_LOCAL_BIN} \
&& chmod -R 777 ${USR_LOCAL_BIN}

USER ${RUN_USER}:${RUN_GROUP}

EXPOSE 8080

# Add configuration files, bashrc and other tweaks
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

RUN chown -R ${RUN_USER}:${RUN_GROUP} ${HOME}
USER {RUN_USER}:${RUN_GROUP}

WORKDIR ${HOME}/src

# Set the default CMD to print the usage of the language image
CMD $STI_SCRIPTS_PATH/usage
