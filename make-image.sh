#!/bin/bash

DHAXE_IMAGE_NAME=dhaxe:4.3.6

function _make_dhaxe_image() {

	local BUILD_FLAGS=$@
	if [[ -z "$BUILD_FLAGS" ]]; then
		BUILD_FLAGS="--pull --build-arg from=debian:12.8-slim"
	fi

	local HERE="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

	echo "Build image $DHAXE_IMAGE_NAME"
	docker build -t $DHAXE_IMAGE_NAME $BUILD_FLAGS $HERE
}

_make_dhaxe_image $@