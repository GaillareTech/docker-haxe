# Haxe Compiler including Haxelib

# Building Haxe: https://github.com/HaxeFoundation/haxe/blob/development/extra/BUILDING.md
# Installing Opam: https://opam.ocaml.org/doc/Install.html
# Haxe CI build script for 4.3.7: https://github.com/HaxeFoundation/haxe/blob/4.3.7/.github/workflows/main.yml

# The debian based distro to build and use the Haxe compiler from.
ARG from=debian
# The Haxe version, can be a tag or a full commit id.
ARG version=4.3.7

# Global variables
ARG HAXE_COMPILER_DIR=/usr/src/haxe

FROM $from AS build-stage
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
	apt-get update -qqy ;\
	apt-get install curl -qqy

###############
# Install Git #
###############

RUN set -ex ;\
	apt-get update -qqy ;\
	apt-get install -qqy git-all

################
# Install Haxe #
################
ENV HAXE_COMPILER_DIR=$HAXE_COMPILER_DIR
ARG RUNNER_TEMP=/usr/src/tmp

# Install Neko
ENV NEKOPATH=/usr/src/neko
ARG PLATFORM=linux64
ARG NEKO_BINARY=https://build.haxe.org/builds/neko/$PLATFORM/neko_latest.tar.gz
RUN set -ex ;\
	mkdir $RUNNER_TEMP ;\
	# brought from https://github.com/HaxeFoundation/haxe/blob/development/.github/workflows/main.yml#L144
	curl -sSL $NEKO_BINARY -o $RUNNER_TEMP/neko_binary.tar.gz ;\
	tar -xf $RUNNER_TEMP/neko_binary.tar.gz -C $RUNNER_TEMP ;\
	# move into NEKOPATH
	rm -fr $RUNNER_TEMP/neko_binary.tar.gz ;\
	mv $RUNNER_TEMP/neko-*-* $NEKOPATH ;\
	mkdir -p /usr/bin ;\
	mkdir -p /usr/include ;\
	mkdir -p /usr/lib/neko ;\
	ln -s  $NEKOPATH/neko       /usr/bin/ ;\
	ln -s  $NEKOPATH/nekoc        /usr/bin/ ;\
	ln -s  $NEKOPATH/nekoml       /usr/bin/ ;\
	ln -s  $NEKOPATH/nekotools    /usr/bin/ ;\
	ln -s  $NEKOPATH/libneko.*  /usr/lib/ ;\
	ln -s  $NEKOPATH/include/*  /usr/include/ ;\
	ln -s  $NEKOPATH/*.ndll     /usr/lib/neko/ ;\
		# clean things
		rm -fr $RUNNER_TEMP ;\
		neko -version

# Install Ocaml (https://opam.ocaml.org/doc/Install.html)
# provides newer version of mbedtls
ENV OPAMYES=1
RUN set -ex ;\
	apt-get install -qqy unzip rsync darcs bubblewrap ocaml-nox libpcre2-dev zlib1g-dev libgtk2.0-dev libmbedtls-dev ninja-build libstring-shellquote-perl libipc-system-simple-perl ;\
	mkdir $RUNNER_TEMP ;\
	curl -sSL https://github.com/ocaml/opam/releases/download/2.3.0/opam-2.3.0-x86_64-linux -o $RUNNER_TEMP/opam ;\
	install $RUNNER_TEMP/opam /usr/local/bin/opam ;\
	# clean things
		rm -fr $RUNNER_TEMP

RUN set -ex ;\
	opam init --disable-sandboxing ;\
	opam update ;\
	opam switch create 5.3.0

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

# Install OCaml libraries
RUN set -ex ;\
	opam pin add haxe . --kind=path --no-action ;\
	opam install haxe --deps-only --assume-depexts || opam install haxe --deps-only ;\ 
	opam list

# Build Haxe
RUN set -ex ;\
	eval $(opam env) ;\
	opam config exec -- make -s -j`nproc` STATICLINK=1 haxe ;\
	opam config exec -- make -s haxelib ;\
	make install ;\
	haxelib setup /usr/local/haxelib

# Install Haxe
RUN make install

