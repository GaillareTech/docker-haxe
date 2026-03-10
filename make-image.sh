#!/bin/bash

DHAXE_IMAGE_NAME=dhaxe:4.3.6

function is_image_available() {
	if [ -z "$(docker images -q $1 2> /dev/null)" ]; then
		echo "$1"
	fi
}

function _make_dhaxe_image() {

	local BUILD_FLAGS=$@
	if [[ -z "$BUILD_FLAGS" ]]; then
		BUILD_FLAGS="--pull=false --build-arg from=debian:12.8-slim"
	fi

	local HERE="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

	echo "Build image $DHAXE_IMAGE_NAME"
	docker build -t $DHAXE_IMAGE_NAME $BUILD_FLAGS $HERE
}

if [ "$1" = "--force" ]; then
	shift;
	_make_dhaxe_image $@
elif [ $(is_image_available $DHAXE_IMAGE_NAME) ]; then
	_make_dhaxe_image $@
fi