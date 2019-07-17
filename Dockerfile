FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

ARG MAVEN_VERSION=3.6.1
ARG GRAAL_VM_VERSION=19.0.2
ENV USER_HOME_DIR="/root"
ARG SHA=b4880fb7a3d81edd190a029440cdf17f308621af68475a4fe976296e71ff4a4b546dd6d8a58aaafba334d309cc11e638c52808a4b0e818fc0fd544226d952544
ARG MAVEN_BASE_URL=https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries
ARG GRAAL_VM_BASE_URL=https://github.com/oracle/graal/releases/download/vm-${GRAAL_VM_VERSION}

ARG PKGS="gcc findutils openssl openssl-devel cryptsetup-libs glibc-devel zlib-devel"
ARG STATIC_PKGS="glibc-static zlib-static"
ARG CONTAINER_TOOL_PKGS="buildah podman"

USER root

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
    && curl -fsSL -o /tmp/apache-maven.tar.gz ${MAVEN_BASE_URL}/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
    && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
    && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn \
    && mkdir -p /opt/graalvm  \
    && curl -fsSL -o /tmp/graalvm-ce-amd64.tar.gz ${GRAAL_VM_BASE_URL}/graalvm-ce-linux-amd64-${GRAAL_VM_VERSION}.tar.gz \
    && tar -xzf /tmp/graalvm-ce-amd64.tar.gz -C /opt/graalvm --strip-components=1  \
    && /opt/graalvm/bin/gu install native-image \
    && rm -f /tmp/apache-maven.tar.gz  /tmp/graalvm-ce-amd64.tar.gz \
    && dnf -y update \
    && dnf -y install --nodocs $PKGS \
    && dnf -y install --nodocs $STATIC_PKGS $CONTAINER_TOOL_PKGS \
    && dnf -y install --nodocs $CONTAINER_TOOL_PKGS \
    && dnf -y clean all \
    && mkdir -p /project

ENV BUILDAH_ISOLATION chroot
ENV STORAGE_DRIVER vfs

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"
ENV GRAALVM_HOME /opt/graalvm
ENV JAVA_HOME /opt/graalvm
ENV WORK_DIR /project
ENV PATH $PATH:$JAVA_HOME/bin

COPY settings.xml /usr/share/maven/ref
ADD ./bin/*.sh /usr/local/bin/

WORKDIR /project

ENTRYPOINT [ "/usr/local/bin/entrypoint-run.sh" ]
CMD [ "mvn","-v" ]