#!/usr/bin/env bash
# vim: ts=2 sw=2 sts=2 et

set -e -u

: ${REPO_HOST:=}

function generate-local-list-file {
  local host=$1
  [[ -n ${host} ]] || return 1
  local url=$2
  [[ -n ${url} ]] || return 2
  local path=${url#*//}
  mkdir -p $(dirname ${path})
  cat /etc/apt/mirror.list | perl -wpl -e "s@https?://@\$&${host}/@g" > ${path}
}

repo_url=$1
shift

if [[ $# -ge 1 ]]; then
    curl -s -o mirror.list "${repo_url}"

    echo -n > /etc/apt/mirror.list
    for arch in "$@"; do
      sed "s/deb http/deb [arch=${arch}] http/; /^#/d" < mirror.list >> /etc/apt/mirror.list
    done

    apt-mirror
    mv mirror.list /etc/apt/mirror.list
  else
    curl -s -o /etc/apt/mirror.list "${repo_url}"
    apt-mirror
fi

[[ -z ${REPO_HOST} ]] || generate-local-list-file ${REPO_HOST} ${repo_url}
rm -f /etc/apt/mirror.list
