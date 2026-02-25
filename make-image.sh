HERE="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

echo "Pull base image to allow offline caching"
OS=debian:12.8-slim
docker image pull $OS

echo "Build image haxe:4.3.6-gllr"
docker build --pull -t haxe:4.3.6-gllr --build-arg os=$OS $HERE