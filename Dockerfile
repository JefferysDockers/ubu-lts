FROM scratch

# Essentially the same as the Docker file at
#    https://github.com/tianon/docker-brew-ubuntu-core/blob/dist-amd64/focal/Dockerfile
# That repo and hence this file is licensed under the Apache License 2.0. Most
# of the comments have been rewritten here to include details locally.

# Add the entire distro to the root of the container
# This file is downloaded from https://partner-images.canonical.com/core/
# and is used unmodified. The checksums are published there and in
# the repo alongside this file.
ADD ubuntu-focal-core-cloudimg-amd64-root.tar.gz /

# This step modifies a few things from the raw ubuntu core for Docker. It is
# all in one step to keep the number of layers low as this is a base image
# that might be used many times. Most of this is based on how package
# installation will be done in a Dockerized container, i.e. all at build
# time and generally not again thereafter. This allows optimizing for
# size and build time installs.
#
# Runs with:
#   -x   To ensure any failures exit
#   -e   To trace commands as this runs
RUN set -xe \
	\
# Trying to start daemons during an image build is likely to blow up badly.
# The policy-rc.d provides a way to prevent package install scripts from
# doing so. 
	&& echo '#!/bin/sh' > /usr/sbin/policy-rc.d \
	&& echo 'exit 101' >> /usr/sbin/policy-rc.d \
	&& chmod +x /usr/sbin/policy-rc.d \
	\
# Nothing should be using the legacy upstart init system to. Replacing the
# /sbin/initctl program with one that does nothing prevents communicating
# with any upstart daemons that might be installed, and setting a dpkg
# diversion prevents any package from installing a different /sbin/initctl.
# [Not sure why this doesn't just use the simple file creation method above,
# unless it is for tiny optimization reasons] [Not sure if this applies
# anymore, but not going to take it out.]
	&& dpkg-divert --local --rename --add /sbin/initctl \
	&& cp -a /usr/sbin/policy-rc.d /sbin/initctl \
	&& sed -i 's/^exit.*/exit 0/' /sbin/initctl \
	\
# Power failures during package installs can leave the package and the file
# system in a corrupt state with things half-installed and wedged. So package
# installs call sync() to write everything out to disk; this slows things
# significantly. This is not needed for docker build package installs which
# can just be started over from scratch. Configuring apt to use
# force-unsafe-io turns off the sync() calls.
	&& echo 'force-unsafe-io' > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup \
	\
# Package installation uses and leaves caches, but these are not needed after
# the Docker build. So need to ensure apt-clean is run. But apparently there
# is some difficulty in doing this, so caches are cleared using post-install
# hooks and config parameters.
	&& echo 'DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' > /etc/apt/apt.conf.d/docker-clean \
	&& echo 'APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' >> /etc/apt/apt.conf.d/docker-clean \
	&& echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";' >> /etc/apt/apt.conf.d/docker-clean \
	\
# Probably don't need the translation files for packages, this prevents those
# from being installed.
	&& echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/docker-no-languages \
	\
# To save space, ensure that apt package lists are stored only in gzipped format
   && echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/docker-gzip-indexes \
	\
# If a package is installed as a dependency, and the package it was installed
# for is removed, the dependency is uninstalled too, when no other package
# needs it. Needing it normally includes if any package suggests it, even if
# suggested packages are not being installed. Once its installed, why remove
# it if it might be useful? To save space. Docker images put a premium on
# space, so configure apt to ignore suggestions when deciding what dependencies
# prevent deletion.
	&& echo 'Apt::AutoRemove::SuggestsImportant "false";' > /etc/apt/apt.conf.d/docker-autoremove-suggests \
   \
# Allows systemd to realize it is running in a container by making
# systemd-detect-virt return "docker"
# See: https://github.com/systemd/systemd/blob/aa0c34279ee40bce2f9681b496922dedbadfca19/src/basic/virt.c#L434
   && mkdir -p /run/systemd && echo 'docker' > /run/systemd/container

# Default action when running the container is to start a bash shell
CMD ["/bin/bash"]
