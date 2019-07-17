#!/bin/bash 

# WORK_DIR  the directory where the application binaries are built
# DESTINATION_NAME  - the fully qualified destination image name where the 
# MVN_CMD_ARGS - the maven command arguments e.g. clean install
# build image will deployed e.g. quay.io/myrepo/app:1.0

set -eux

TLSVERIFY=${TLSVERIFY:-'true'}

cd $WORK_DIR

# get the build artifact name 
ARTIFACT_NAME=$(mvn org.apache.maven.plugins:maven-help-plugin:3.1.1:evaluate -Dexpression=project.build.finalName -q -DforceStdout)
ARTIFACT_NAME_PKG=$(mvn org.apache.maven.plugins:maven-help-plugin:3.1.1:evaluate -Dexpression=project.packaging -q -DforceStdout)

# compute the app name with packaging if not available in env
APP_NAME=${APP_NAME:-"$ARTIFACT_NAME-runner.$ARTIFACT_NAME_PKG"}

# build the java project 
mvn ${MVN_CMD_ARGS:-clean install}
