#!/bin/sh

NAME="ubu-lts"
read TAG < "TAG"

docker build . \
   -t ${NAME}:${TAG} \
   -t ${NAME}:latest