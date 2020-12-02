# ubu-lts - An Ubuntu base Docker from scratch.

Note: This document serves dual purpose as the README for a GitHub repo and for the DockerHub repository built from it (as an automated build).

This provides a base Docker container with the Ubuntu OS. It is called "ubu-lts" after the Ubuntu long-term service release and is versioned based on the date of the patch to the release. Currently, this is the so-called "Focal Fossa" version.

The goal of providing this is to make it easier to take control of an entire Docker image chain for reproducibility, which requires locking down the base image. The trade off in doing so is also locking in any security flaws. The [original open-source repository](ttps://github.com/tianon/docker-brew-ubuntu-core) that builds the [official Ubuntu base image](https://hub.docker.com/_/ubuntu) is not easily reused by independent pipelines to build their own containers or to control exactly which version is used when. This one is intended to be simpler.

## Versioning

Container are tagged using the following scheme:

* "ubu-lts:latest" - The latest version of the container.
* "ubu-lts:\<ubuntu.ver\>" - The latest build for a container based on the specified version of the Ubuntu core.
* "ubu-lts:\<ubuntu.ver\>-\<build.ver\> - A specific build for a specific Ubuntu based container.

## Local Build

To build a container locally based on a specific release by tag, clone the tagged commit, `cd` into the repo, and run the `build.sh` script.

```
git clone --branch <tag> --depth 1 https://github.com/JefferysDockers/ubu-lts
cd ubu-lts
./build.sh
```

To just clone the latest tagged release, you can try leaving off the "--branch \<tag\>" option. That will work as long as the latest commit on the master branch of GitHub has a tag. It probably does, but if you get an error saying something about "no tag available" you'll have to try again, cloning the repo using the tag explicitly.

## License notes

Licensing is complicated and not what I want to spend my time on, but here is my best attempt to license and comply with existing licenses:

### Generally [MIT](https://opensource.org/licenses/MIT) licensed

This GitHub repo is based on [Tianon's source github repo](https://github.com/tianon/docker-brew-ubuntu-core) which is used to build the [Ubuntu base DockerHub distributions](https://hub.docker.com/_/ubuntu). I am using the MIT licensed for my repo to maximize what can be done with it as far as I have the ability to. Different licensing applies to the Dockerfile and to the Ubuntu container contents based on the original licenses of what they were derived from.

### Dockerfile is [Apache 2](https://opensource.org/licenses/Apache-2.0) licensed.

The Dockerfile in this repo is licensed under the Apache 2 License, based on the license for the GitHub repository it is derived from. That repository uses a significant amount of automation to build all the various versions of Ubuntu containers, including the [update.sh](https://github.com/tianon/docker-brew-ubuntu-core/blob/master/update.sh) script that generates Dockerfiles on demand. The Dockerfile in this repo is based on that script. 

### The container is "[Ubuntu](https://ubuntu.com/licensing)" licensed

Ubuntu and Canonical have a reasonable interest in people not thinking my container has anything to do with them or their trademarks. So any use of Ubuntu or Canonical (or Focal, if that is also trademarked) is only to describe where the original sources can be obtained. This container is not otherwise associated with Ubuntu or Canonical and is in no way official or sanctioned. However, since its contents are as identical as I can make them, it is licensed under the same terms as their official container. The Ubuntu licence statement is [here](https://ubuntu.com/licensing)

### The Ubuntu tarball and manifest are "[Ubuntu](https://ubuntu.com/licensing)" licensed

The Ubuntu tarball and manifest in the root of this repository are the meat of the base container. It is from [an open canonical web site](https://partner-images.canonical.com/core/) described in the official repo README. This tarball is unpacked to form the base of the container, which allows bootstrapping a base image. Again, although these tarballs come from a Canonical web site for the Ubuntu core and are used unmodified here there is nothing that makes my use of them official or sanctioned.

## Important Links

* The official DockerHub repository for Ubuntu - https://hub.docker.com/_/ubuntu
* How Ubuntu does releases - https://ubuntu.com/about/release-cycle
* Development code names - https://wiki.ubuntu.com/DevelopmentCodeNames
* Tianon's GitHub repository backing the official DockerHub container - https://github.com/tianon/docker-brew-ubuntu-core
* Where the core tarballs come from - https://partner-images.canonical.com/core/
* Original source with better description of some of the build commands in Tianon's GitHub repo - 
https://github.com/moby/moby/blob/9a9fc01af8fb5d98b8eec0740716226fadb3735c/contrib/mkimage/debootstrap
* The DockerHub repo for this container - https://hub.docker.com/r/jefferys/ubu-lts
* The GitHub repo for source to build this container - https://github.com/JefferysDockers/ubu-lts

## How the container build process works:

### The distro tarball

The core of the built-from-scratch distro is a pre-built tarball from the above Canonical/Ubuntu core link. It must be local (in the root build context alongside the Dockerfile) for the build to work. I have copied the local *.tar.gz and `*.manifest` files from that remote site.

I'm including the checksum file for the tarball so it can be verified locally. I don't think the tarball or the sha sums can be changed once committed so if you do a pull by commit hash instead of by tag, it should get both unchanged. To independently verify the tarball and/or checksums, just check the original sources (if still available, they update pretty often and only the most recent are available). You can trust a commit hash pull thereafter.

A "one-line" local test command in Bash for verifying sha256 against a local copy of the checksum file, assuming you have openssl and are in the root directory of the repo:

    checkSha256() { diff <(openssl dgst -sha256 "$1" | cut -d " " -f 2) \
    <(grep amd64 "$2" | cut -d " " -f 1) || echo "**FAIL**" ; }; \
    checkSha256 "ubuntu-focal-core-cloudimg-amd64-root.tar.gz" "SHA256SUMS"

### The Dockerfile

Just unpacking the tarball into the docker container creates a working Linux image, but a few specific tweaks are useful for docker as listed at the Moby link above. I modified the comments on each in my Dockerfile based on my understanding of what is being done.

### Building

DockerHub automation provides for ENV variables in the build environment and a default build process whose steps can be over-ridden by appropriately named scripts in a "hooks" directory. To allow both manual (local) builds and automated DockerHub builds, the `build.sh` script mimics the DockerHub build environment by setting ENV variables and then calling the hooks/build script to build the container.

The only difficulty in doing this is providing the "TAG" environmental variable, which is based on the Git tag of the particular GitHub commit that DockerHub is building. Building from a local repo requires reading that with Git, which only works if the local repo contains a tag. If it contains more than one tag, the tag from the last commit in the repo with a tag is used. To build a specific tag, clone only that tagged commit (see [Local Build](#local-b uild), above).

### DockerHub automation

Every commit on the master branch of the GitHub repo is a release and should be tagged with a different tag formatted as "\<container.tag\>-\<build.tag\>"

Pushing a new tag with a hyphen to GitHub master branch will trigger DockerHub to build a new container using the hooks/build script and add it to the container repo with three tags, as "ubu-lts:latest" ubu-lts:\<container.tag\> and "ubu-lts:\<container.tag\>-\<build.tag\>".

Note that there may be brief periods where the leading commit on the master branch is not tagged, or when the :latest tagged container does not match with the latest contents and /or build tagged versions due to time spent spent by DockerHub's build process and by parallel execution of commands.