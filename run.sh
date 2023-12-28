#!/usr/bin/env bash -e

runfile=$(readlink "$0" || echo "$0")
dir=$(dirname "$runfile")
appfile="deploy.yaml"

function show_usage() {
    echo "Usage: $0 apply|delete|dump|build|push|inspect [-f deploy.yaml]"
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
        docker buildx build --platform linux/amd64 --load -t $tag .
        ;;
    push)
        docker push $tag
        ;;
    inspect)
        docker run --rm -it $tag bash
        ;;
    *)
        show_usage
esac
