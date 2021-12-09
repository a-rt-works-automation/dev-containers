#!/bin/bash
#export https_proxy=
#export http_proxy=
export HTTPS_PROXY=$https_proxy
export HTTP_PROXY=$http_proxy
export NO_PROXY=$no_proxy
export GPG_TTY=$(tty)

export PATH=$HOME/.local/bin:/usr/local/go/bin:$PATH

export SSL_CERT_FILE='/etc/ssl/certs/ca-certificates.crt'
export REQUESTS_CA_BUNDLE='/etc/ssl/certs/ca-certificates.crt'