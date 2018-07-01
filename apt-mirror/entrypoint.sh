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

for repo_url in "$@"; do
  curl -s -o /etc/apt/mirror.list "${repo_url}"
  apt-mirror
  [[ -z ${REPO_HOST} ]] || generate-local-list-file ${REPO_HOST} ${repo_url}
  rm -f /etc/apt/mirror.list
done
