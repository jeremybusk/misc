#!/usr/bin/env bash
## Set BASH environment so it will fail properly throwing exit code
set -euxo pipefail
#set -v
# Prep docker image - must be ran as priviledged for nested docker
docker rm -f pusher
#docker run -dit -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd)/scripts:/scripts --name pusher ubuntu:16.04
docker run -dit -v /var/run/docker.sock:/var/run/docker.sock --name pusher ubuntu:16.04
docker cp rchain-docker-build-push.sh pusher:/ 
docker exec -it pusher /bin/bash -c "./rchain-docker-build-push.sh"
