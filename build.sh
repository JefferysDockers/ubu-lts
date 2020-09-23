#!/bin/sh

# To build manually, clone the repo shallowly (to avoid extra rootfs tarballs)
# then cd to the repo root and run ./build.sh, this file.
#
# The meat of the file is relocated to hooks/build to mesh easily with
# DockerHub's auto build process.

# Note that some of the automation available for building from the DockerHub
# UI may be ignored due to replacing the build step with the hook script.

export DOCKER_REPO="jefferys/ubu-lts"
export DOCKERFILE_PATH="Dockerfile"

./hooks/build