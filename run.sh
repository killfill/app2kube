#!/usr/bin/env bash -e

runfile=$(readlink "$0" || echo "$0")
dir=$(dirname "$runfile")
appfile="deploy.yaml"

function show_usage() {
    echo "Usage: $0 apply|delete|dump|build|push|run|inspect [-f deploy.yaml]"
    exit 0
}

command="$1"
[ -z "$command" ] && show_usage

shift

while getopts "f:h" opt; do
    case $opt in
        h)
            show_usage
            ;;
        f)
            appfile="$OPTARG"
            shift; shift
            ;;
    esac
done

[ ! -f "$appfile" ] && echo "File $appfile does not exists" && show_usage
source="$(cat $appfile | envsubst)"
tag=$(yq .image < $appfile)

case $command in
    apply)
        kcl run $dir/load.k $dir/render_kube.k -D source="$source" | kubectl apply -f -
        ;;
    delete)
        kcl run $dir/load.k $dir/render_kube.k -D source="$source" | kubectl delete -f -
        ;;
    dump)
        kcl run $dir/load.k $dir/render_kube.k -D source="$source"
        ;;
    build)
        created=$(docker image inspect $tag 2>/dev/null | jq -r ".[0].Created")
        if [ "$created" != "null" ]; then
            echo "WARNING: Image $tag already exists, it was created on ${created}. "
        fi
        DOCKER_BUILD_PLATFORMS=${DOCKER_BUILD_PLATFORMS:-linux/amd64}
        if [ "$DOCKER_BUILD_NO_CACHE" = "true" ]; then
            DOCKER_BUILD_NO_CACHE="--no-cache"
        else
            DOCKER_BUILD_NO_CACHE=""
        fi
        echo "Building image $tag for platforms $DOCKER_BUILD_PLATFORMS with args: $DOCKER_BUILD_NO_CACHE"
        # [ -f Dockerfile ] && docker buildx build --platform $DOCKER_BUILD_PLATFORMS $DOCKER_BUILD_NO_CACHE --load -t $tag .
        [ -f Dockerfile ] && docker buildx build --platform $DOCKER_BUILD_PLATFORMS $DOCKER_BUILD_NO_CACHE --push -t $tag .
        [ ! -f Dockerfile ] && (command pack &> /dev/null && pack build $tag $@ || echo "No Dockerfile or pack CLI found. Cannot build image")
        ;;
    push)
        docker push $tag
        ;;
    inspect)
        docker run --rm -it -P $tag bash
        ;;
    run)
        docker run --rm -it -P $tag
        ;;
    *)
        show_usage
esac
