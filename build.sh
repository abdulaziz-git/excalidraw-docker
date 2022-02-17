#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CUSTOM=$(basename ${DIR})

source .env

MK="base nginx excalidraw excalidraw-room"

BUILDREPO=${BUILDREPO:-localbuild}
SRC_REPO=$DIR/src_repo

# -------------------------------------------------------------------

PRE="------>"

mkdir -p ./data/{minio,nginx}

echo $PRE Checkout excalidraw repo...
if [ ! -d "$SRC_REPO/excalidraw" ]; then
    git clone https://github.com/excalidraw/excalidraw.git $SRC_REPO/excalidraw
    ln -s $SRC_REPO/excalidraw $DIR/excalidraw
fi

echo $PRE Checkout excalidraw-room repo...
if [ ! -d "$SRC_REPO/excalidraw-room" ]; then
    git clone https://github.com/excalidraw/excalidraw-room.git $SRC_REPO/excalidraw-room
fi

if [ -n "$(docker swarm join-token manager 2>&1 | grep 'not a swarm manager')" ]; then
    echo $PRE Initializing Docker swarm...
    docker swarm init
fi

if [ $(docker network ls | grep excalidraw-net | wc -l) = 0 ]; then
    echo $PRE Creating overlay network...
    docker network create --driver=overlay --attachable excalidraw-net
fi

echo $PRE Stopping all services...
docker-compose down

if [ "$1" == "--rebuild-all" ]; then
    echo $PRE Removing Docker images for excalidraw...
    docker rmi $BUILDREPO/excalidraw 2> /dev/null
    docker rmi $BUILDREPO/excalidraw-room 2> /dev/null
    docker rmi $BUILDREPO/nginx 2> /dev/null
    docker rmi $BUILDREPO/base 2> /dev/null
fi

BUILDARG="--build-arg BUILDREPO=$BUILDREPO"
if [ -n "${PROXY}" ]; then
    BUILDARG="$BUILDARG --build-arg http_proxy=${PROXY}/ --build-arg https_proxy=${PROXY}/"
fi

for i in $MK; do
    echo $PRE Docker build local images $i...

    cd $SRC_REPO/$i

    [ ! -z "${REACT_APP_BACKEND_V1_GET_URL+x}" ]  && sed -i.bak '/REACT_APP_BACKEND_V1_GET_URL=/s#=.*#='"${REACT_APP_BACKEND_V1_GET_URL}"'#' .env 2> /dev/null
    [ ! -z "${REACT_APP_BACKEND_V2_GET_URL+x}" ]  && sed -i.bak '/REACT_APP_BACKEND_V2_GET_URL=/s#=.*#='"${REACT_APP_BACKEND_V2_GET_URL}"'#' .env 2> /dev/null
    [ ! -z "${REACT_APP_BACKEND_V2_POST_URL+x}" ] && sed -i.bak '/REACT_APP_BACKEND_V2_POST_URL=/s#=.*#='"${REACT_APP_BACKEND_V2_POST_URL}"'#' .env 2> /dev/null
    [ ! -z "${REACT_APP_SOCKET_SERVER_URL+x}" ]   && sed -i.bak '/REACT_APP_SOCKET_SERVER_URL=/s#=.*#='"${REACT_APP_SOCKET_SERVER_URL}"'#' .env 2> /dev/null
    [ ! -z "${REACT_APP_FIREBASE_CONFIG+x}" ]     && sed -i.bak '/REACT_APP_FIREBASE_CONFIG=/s#=.*#='"${REACT_APP_FIREBASE_CONFIG}"'#' .env 2> /dev/null

    docker build ${BUILDARG} -t $BUILDREPO/$i:latest .

done

cd $DIR

