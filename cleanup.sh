#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CUSTOM=$(basename ${DIR})

source .env

PRE="----->"
BUILDREPO=${BUILDREPO:-localbuild}
SRC_REPO=$DIR/src_repo

echo
echo "Excalidraw cleanup.sh"
echo "CAUTION: this will remove a running excalidraw service stack completely!"
echo -ne "Answer 'yes' if you really want to proceed: "
read yo

[ "${yo}" != "yes" ] && exit 0

echo $PRE Stopping container...
docker-compose down

echo $PRE Removing images...
docker rmi $BUILDREPO/excalidraw
docker rmi $BUILDREPO/excalidraw-json
docker rmi $BUILDREPO/excalidraw-room
docker rmi $BUILDREPO/nginx
docker rmi $BUILDREPO/base
docker rmi minio/minio:RELEASE.2020-11-25T22-36-25Z
docker rmi minio/mc

echo $PRE Removing volumes...
docker volume rm excalidraw-docker_excalidraw-notused

echo $PRE Removing network...
docker network rm excalidraw-net

echo $PRE Removing folders...
rm -rf $DIR/data
rm $DIR/excalidraw
rm -rf $SRC_REPO/excalidraw
rm -rf $SRC_REPO/excalidraw-room
rm -rf $SRC_REPO/excalidraw-json

echo 
echo $PRE "Ready. If you want to start over, run ./build.sh again."
echo
echo
