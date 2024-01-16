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
        [ -f Dockerfile ] && docker buildx build --platform linux/amd64 --load -t $tag .
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
