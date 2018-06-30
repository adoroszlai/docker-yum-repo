#!/bin/bash
# vim: ts=2 sw=2 sts=2 et

set -e -u

: ${REPO_HOST:=}

function get-repo-file {
  local repo_url="$1"
  cd /etc/yum.repos.d
  rm -f *.repo
  curl --remote-name --silent "${repo_url}"
  echo $(pwd -P)/$(basename ${repo_url})
}

function copy-packages {
  local repo_url=$1
  shift

  local repo_file=$(get-repo-file "${repo_url}")

  get-urls $(repotrack -n --urls "$@")
  create-repos $(grep 'baseurl=' ${repo_file} | cut -f3- -d'/')
  copy-gpg-keys "${repo_file}"
  rm -f "${repo_file}"
  [[ -z ${REPO_HOST} ]] || generate-local-repo-file ${REPO_HOST} ${repo_url}
}

function copy-repo {
  for repo_url in "$@"; do
    local repo_file=$(get-repo-file "${repo_url}")
    for line in $(perl -wnl -00 -e '($name, $path) = $_ =~ /\[(\S+)\].*baseurl=https?:\/\/(\S+)/s and print "$name]$path"' "${repo_file}"); do
      local repo="$(echo ${line} | cut -f1 -d']')"
      local path="$(echo ${line} | cut -f2 -d']')"
      reposync -n -p /var/repo/${path} --norepopath -r "${repo}"
      create-repos ${path}
    done
    copy-gpg-keys "${repo_file}"
    rm -f "${repo_file}"
    [[ -z ${REPO_HOST} ]] || generate-local-repo-file ${REPO_HOST} ${repo_url}
  done
}

function copy-gpg-keys {
  local repo_file=$1
  get-urls $(grep 'gpgkey=' ${repo_file} | cut -f2 -d'=')
}

function create-repos {
  for dir in "$@"; do
    [[ -d ${dir} ]] || continue
    echo "Creating repo in ${dir}"
    createrepo -q --update /var/repo/${dir}
  done
}

function get-urls {
  for url in "$@"; do
    local path=$(echo ${url} | cut -f3- -d'/')
    if [[ -r ${path} ]]; then
      local -i local_size=$(wc -c < ${path})
      if [[ $local_size -gt 0 ]]; then
        local -i remote_size=$(curl --silent --head ${url} | fgrep 'Content-Length' | cut -f2 -d' ' | tr -d '\r')
        if [[ $local_size -eq $remote_size ]]; then
          echo "Skipping ${url}"
          continue
        fi
      fi
    fi
    echo "Downloading ${url}"
    curl --create-dirs --output ${path} --remote-time --silent ${url}
  done
}

function generate-local-repo-file {
  local host=$1
  [[ -n ${host} ]] || return 1
  local url=$2
  [[ -n ${url} ]] || return 2
  local path=$(echo ${url} | cut -f3- -d'/')
  mkdir -p $(dirname ${path})
  curl --create-dirs --remote-time --silent ${url} | perl -wpl -e "s@https?://@\$&${host}/@g" > ${path}
}

function usage {
  echo "Usage:"
  echo "  repo <repo_url> [<repo_url> ...]"
  echo "  repo-file <repo_host> <repo_url>"
  echo "  pkg <repo_url> <pkg_name> [<pkg_name> ...]"
}

cmd=${1:-help}

case ${cmd} in
  pkg)
    shift
    copy-packages "$@"
    ;;
  repo)
    shift
    copy-repo "$@"
    ;;
  http*)
    # backwards compatibility
    copy-repo "$@"
    ;;
  repo-file)
    shift
    if [[ $# -lt 2 ]]; then
      usage
      exit 1
    fi
    generate-local-repo-file "$@"
    ;;
  *)
    usage
    ;;
esac
