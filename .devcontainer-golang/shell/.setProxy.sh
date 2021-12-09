#!/bin/bash

# set -x

usage() {
    echo "USAGE: $0"

    echo "  [--toggle] Toggle on of off proxy settings"
    echo "  [-h|--help] Usage message"
}

invalidParams() {
    echo "Missing required param: $1"
    usage
    exit 1
}

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --toggle)
        toggle="$2"
        shift
        shift
        ;;
        -h|--help)
        help="true"
        shift
        ;;
        *)
        usage
        exit 1
        ;;
    esac
done

http_proxy="http://proxy.cmltd.net.au:8080"
https_proxy="http://proxy.cmltd.net.au:8080"

if [[ $toggle = "on" ]]
then
    echo "Setting Proxy to -> $http_proxy : $https_proxy"
    export http_proxy=$http_proxy
    export https_proxy=$https_proxy
    export no_proxy=localhost,127.0.0.0/8,*.local
    export ALL_PROXY=$http_proxy
    git config --global http.proxy $http_proxy
    git config --global https.proxy $https_proxy

else
    echo 'Unsetting Proxy'

    unset http_proxy
    unset https_proxy
    unset ALL_PROXY
    git config --global --unset http.proxy
    git config --global --unset https.proxy
fi