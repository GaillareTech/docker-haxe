HERE="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

echo "Pull base image to allow offline caching"
OS=debian:12.8-slim
docker image pull $OS

echo "Build image dhaxe:4.3.6"
docker build --pull -t dhaxe:4.3.6 --build-arg os=$OS $HERE