# Haxe Compiler including Haxelib

# Building Haxe: https://github.com/HaxeFoundation/haxe/blob/development/extra/BUILDING.md
# Installing Opam: https://opam.ocaml.org/doc/Install.html
# Haxe CI build script for 4.3.6: https://github.com/HaxeFoundation/haxe/blob/4.3.6/.github/workflows/main.yml

# The debian based distro to build and use the Haxe compiler from.
ARG os=debian:12.8-slim
# The Haxe version, can be a tag or a full commit id.
ARG version=4.3.6

# Global variables
ARG HAXE_COMPILER_DIR=/usr/src/haxe

FROM $os AS build-stage
ARG version
ARG os
ARG HAXE_COMPILER_DIR

USER root

#################
# Install Tools #
#################

# Install add-apt-repository with python3-launchpadlib to fix https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1029766
RUN set -ex ;\
	apt-get update -qqy ;\
	apt-get install -qqy software-properties-common python3-launchpadlib ;\
	apt-get update -qqy ;\
	add-apt-repository --help

# Install curl
RUN set -ex ;\
	apt update -qqy ;\
	apt install curl -qqy

###############
# Install Git #
###############

RUN set -ex ;\
	apt update -qqy ;\
	apt install -qqy git-all

################
# Install Haxe #
################
ENV HAXE_COMPILER_DIR=$HAXE_COMPILER_DIR

# Install Ocaml (https://opam.ocaml.org/doc/Install.html)
# provides newer version of mbedtls
ENV OPAMYES=1
RUN set -ex ;\
	add-apt-repository ppa:haxe/ocaml -y ;\
	apt-get update -qqy ;\
	apt-get install -qqy ocaml-nox camlp5 opam libpcre2-dev zlib1g-dev libgtk2.0-dev libmbedtls-dev ninja-build libstring-shellquote-perl libipc-system-simple-perl
RUN set -ex ;\
	opam init --disable-sandboxing ;\
	opam update ;\
	opam switch create 5.0.0

# Install Neko
ENV NEKOPATH=/usr/src/neko
ARG RUNNER_TEMP=/usr/src/tmp
ARG PLATFORM=linux64
ARG NEKO_BINARY=https://build.haxe.org/builds/neko/$PLATFORM/neko_2025-04-15_master_e2fa58b.tar.gz
RUN set -ex ;\
	mkdir $RUNNER_TEMP ;\
	# brought from https://github.com/HaxeFoundation/haxe/blob/development/.github/workflows/main.yml#L144
	curl -sSL $NEKO_BINARY -o $RUNNER_TEMP/neko_binary.tar.gz ;\
	tar -xf $RUNNER_TEMP/neko_binary.tar.gz -C $RUNNER_TEMP ;\
		# move into NEKOPATH
		rm -fr $RUNNER_TEMP/neko_binary.tar.gz ;\
		mv $RUNNER_TEMP/neko-*-* $NEKOPATH ;\
	mkdir -p /usr/local/bin ;\
	mkdir -p /usr/local/include ;\
	mkdir -p /usr/local/lib/neko ;\
	mv $NEKOPATH/neko  /usr/local/bin/ ;\
	mv $NEKOPATH/nekoc  /usr/local/bin/ ;\
	mv $NEKOPATH/nekoml  /usr/local/bin/ ;\
	mv $NEKOPATH/nekotools  /usr/local/bin/ ;\
	mv $NEKOPATH/libneko.*                      /usr/local/lib/ ;\
	mv $NEKOPATH/include/*                      /usr/local/include/ ;\
	mv $NEKOPATH/*.ndll                         /usr/local/lib/ ;\
		# clean things
		rm -fr $RUNNER_TEMP ;\
		rm -fr $NEKOPATH ;\
		neko -version
ENV NEKOPATH=/usr/local/bin/

# Clone Haxe sources
WORKDIR $HAXE_COMPILER_DIR
RUN set -ex ;\
	git init ;\
	git remote add origin https://github.com/HaxeFoundation/haxe.git ;\
	git fetch --depth 1 origin $version ;\
	git checkout FETCH_HEAD ;\
	# fix to avoid timeout when pulling many submodules
	git config --global url."https://".insteadOf git:// ;\
	git submodule update --init --recursive

# Install Haxe dependencies
# RUN apt install libmbedtls-dev libpcre3-dev neko neko-dev pkg-config xdot zlib1g-dev -y
# RUN apt install libpcre2-dev zlib1g-dev libmbedtls-dev

# Install OCaml libraries
RUN set -ex ;\
	opam pin add haxe . --kind=path --no-action ;\
	# fix for https://github.com/HaxeFoundation/haxe/issues/11787#issuecomment-2413147609
	opam pin add extlib 1.7.9 ;\
	opam pin add luv 0.5.12 ;\
	# try first with --assume-depexts and fallback without it to handle
	# the case where its is not allowed (this seems to depends on the $os) 
	opam install haxe --deps-only --assume-depexts || opam install haxe --deps-only ;\ 
	opam list
	# make

# Build Haxe
RUN set -ex ;\
	eval $(opam env) ;\
	opam config exec -- make -s -j`nproc` STATICLINK=1 haxe ;\
	opam config exec -- make -s haxelib ;\
	make install ;\
		# install via the package manager to avoid https://github.com/HaxeFoundation/haxe.org/issues/75#issuecomment-1049233669
		# delete neko then (still used for building haxe)
		rm -f /usr/local/bin/*neko* ;\
		rm -f /usr/local/bin/*.ndll ;\
		apt install -qqy neko ;\
		neko -version ;\
		haxe --version ;\
		haxelib version ;\
		# setup haxelib
		haxelib setup /usr/local/haxelib

# Install Haxe
RUN make install

