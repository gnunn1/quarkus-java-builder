#!/bin/bash 

# WORK_DIR  the directory where the application binaries are built
# DESTINATION_NAME  - the fully qualified destination image name where the 
# MVN_CMD_ARGS - the maven command arguments e.g. clean install
# build image will deployed e.g. quay.io/myrepo/app:1.0

set -eux

PUSH=${PUSH:-'true'}

cd $WORK_DIR

# get the build artifact name 
ARTIFACT_NAME=$(mvn org.apache.maven.plugins:maven-help-plugin:3.1.1:evaluate -Dexpression=project.build.finalName -q -DforceStdout)
ARTIFACT_NAME_PKG=$(mvn org.apache.maven.plugins:maven-help-plugin:3.1.1:evaluate -Dexpression=project.packaging -q -DforceStdout)

# compute the app name with packaging
APP_NAME="$ARTIFACT_NAME-runner.$ARTIFACT_NAME_PKG"

# build the java project 
mvn ${MVN_CMD_ARGS:-clean install}

echo "Building container image with APP: $APP_NAME"

# define the container base image
containerID=$(buildah from docker.io/fabric8/java-jboss-openjdk8-jdk:1.5.4)

# mount the container root FS
appFS=$(buildah mount $containerID)

mkdir -p $appFS/deployments/lib/

cp target/lib/* $appFS/deployments/lib/
cp target/$APP_NAME  $appFS/deployments/$APP_NAME

# Add environment variables
buildah config --env 'JAVA_APP_DIR=/deployments'  $containerID
# Add user to run the container as
buildah config --user jboss  $containerID
# Add entry  point for the application
buildah config --entrypoint '["/deployments/run-java.sh"]'  $containerID

buildah config --author "devx@redhat.com" --created-by "devx@redhat.com" --label Built-By=buildah $containerID

IMAGEID=$(buildah commit $containerID $DESTINATION_NAME)

echo "Succesfully committed $DESTINATION_NAME with image id $IMAGEID"

# Push the image to regisry 
echo "To push ? $PUSH"

if [ "$PUSH" = "false" ];
then
  echo "Pushing $DESTINATION_NAME to local storage"
  buildah push $IMAGEID oci:/var/lib/containers/storage:$DESTINATION_NAME
else  
  echo "Pushing $DESTINATION_NAME to remote container repository"
  buildah push --tls-verify=false $IMAGEID $DESTINATION_NAME
fi 
