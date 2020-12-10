#!/bin/sh

# To build manually, clone the repo shallowly (to avoid extra rootfs tarballs)
# then cd to the repo root and run ./build.sh, this file.
#
# The meat of the file is relocated to hooks/build to mesh easily with
# DockerHub's auto build process.

export DOCKER_REPO="jefferys/ubu-lts"
export DOCKERFILE_PATH="Dockerfile"
TAG=$(git tag --sort committerdate)
export DOCKER_TAG=${TAG##*$'\n'}
if [[ -z "$DOCKER_TAG" ]]; then
   echo "No tag available in the current repo" >&2
   exit 1
fi

./hooks/build