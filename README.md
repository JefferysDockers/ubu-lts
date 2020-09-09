# Notes on the Ubuntu base docker

The goal is to take control of the entire Docker image chain for reproducibility, which requires locking down the base image. That locks in any security flaws too, of course.

## License notes

Licensing is complicated and not what I want to spend my time on, but here is my best attempt to license and comply with existing licenses:

This is essentially my copy of part of the [source github repo](https://github.com/tianon/docker-brew-ubuntu-core) that builds the [Ubuntu base DockerHub distributions](https://hub.docker.com/_/ubuntu). I use the MIT license to maximize what can be done with the content of this repository as far as I have the ability to license it.

The Dockerfile is licensed under the Apache 2 License, as that is what the source github repository is licensed under. I have modified some things in it, and am making the modifications public here. That means the Dockerfile is transitively Apache licensed. Ubuntu and Cannonical have a reasonable interest in people not thinking my modified versions have anything to do with them or their trademarks. So any use of Ubuntu or Cannonical (or Focal, if that is also trademarked) is only to describe where the original, unmodified sources can be obtained. This distribution is not otherwise associated with Ubuntu or Cannonical and is in no way official or sanctioned.

In addition to the Dockerfile, the original repo included local copies of tarball files (and manifests) that are the meat of the base container. It is from [an open canonical web site](https://partner-images.canonical.com/core/) described in the source repo README. There are additional versions of core ubuntu distributions there. It is required to use a local copy of the tarball to allow bootstrapping a base image, and a copy of a distro tarball (and manifest) are included in this repo. Again, although these tarballs come from a Cannonical web site and are used unmodified here there is nothing that makes my use of them official or sanctioned.

## Important Links

* The official docker hub repository for Ubuntu - https://hub.docker.com/_/ubuntu
* How Ubuntu does releases - https://ubuntu.com/about/release-cycle
* Development code names - https://wiki.ubuntu.com/DevelopmentCodeNames
* The Ubuntu Docker GitHub page linked to from the Docker hub repo - https://github.com/tianon/docker-brew-ubuntu-core
* Where the actual core tarballs are from - https://partner-images.canonical.com/core/
* Where most updates to the core as specified in the source github repo came from - 
https://github.com/moby/moby/blob/9a9fc01af8fb5d98b8eec0740716226fadb3735c/contrib/mkimage/debootstrap

## How the build process works:

There is a bunch of automation supported in the source repo for building multiple things and doing it automatically. I don't need that, I just want to build one version once, so this repo leaves most of that out.

### The distro tarball

The core of the build from scratch is a pre-built tarball from the above canonical ubuntu core link. It must be local (in the root build context alongside the Dockerfile) for the build to work. I have copied the local *.tar.gz and *.manifest from the remote site.

I'm including the checksum file for the tarball so it can be verified locally. I don't think this can be changed once committed, a pull by commit hash should be fixed; if you don't trust my copy of the checksums, you only need to check once against the original remote, then you can trust the commit hash pull thereafter.

A "one-line" local test command in Bash for verifying sha256 against the local copy of the checksum file, assuming you have openssl

    checkSha256() { diff <(openssl dgst -sha256 "$1" | cut -d " " -f 2) \
    <(grep amd64 "$2" | cut -d " " -f 1) || echo "**FAIL**" }; \
    checkSha256 "ubuntu-focal-core-cloudimg-amd64-root.tar.gz" "SHA256SUMS"

### The Dockerfile

Just unpacking the tarball into the docker container creates a working linux image, but a few specific tweaks are useful for docker as listed at the Moby link above. I modified the comments on each one in line with my understading of what is being done.

### DockerHub automation

Pushing a new master branch commit will build a new "ubu-lts:latest" dockerhub tagged image.

Pushing a new docker commit tag to master will build a new "ubu-lts:\<tag\> dockerhub tagged images, as long as the tag begins with a number, e.g "ubu-lts:2020.09.03-0.0.1"

Convention is to tag image releases with the base version and then the version of this repo that builds it. That tag will be saved in a file named TAG in the root. The TAG file's content is just the tag on the first line, no leading or trailing whitespace, and no trailing line feed. Note that the TAG file must be kept in sync with the actual github tag manually; it can not be fixed after the fact except by changing a publicly pushed tag, which is a bad idea.

Every push to master is a release and should be tagged with a different tag (reflected in the TAG file).

### Locally building the Image

There is a simple `build.sh` script. To manually build a local image, just clone the repo (its big due to the local tarball files), cd to the repo base directory, and run `$ ./build.sh` to build the local docker image (and tag it). 

## Current release:

Based on Ubuntu 20.04 - Focal Fossa, build 20200903 - https://partner-images.canonical.com/core/focal/20200903/

