#!/bin/bash
# vim: ts=2 sw=2 sts=2 et

set -e -u

: ${DEBUG:=0}
: ${DRY_RUN:=false}
: ${REPO_HOST:=}

run-command() {
  CMD="$@"
  if [[ "$DRY_RUN" == "false" ]]; then
    debug "$CMD"
    "$@"
  else
    debug [DRY_RUN] "$CMD"
  fi
}

debug() {
  [[ ${DEBUG} -gt 0 ]] && echo "[DEBUG] $@" 1>&2
}

function get-repo-file {
  local repo_url="$1"
  cd /etc/yum.repos.d
  rm -f *.repo
  curl --remote-name --silent "${repo_url}"
  local repo_file=$(pwd -P)/$(basename "${repo_url}")
  if [[ -n "${REPO_HOST}" ]]; then
    repo_file=${repo_file/\/\/${REPO_HOST}\/}
  fi
  echo "${repo_file}"
}

function copy-packages {
  local repo_url=$1
  shift

  local repo_file=$(get-repo-file "${repo_url}")

  get-urls $(repotrack -n --urls "$@")
  create-repos $(grep 'baseurl=' ${repo_file} | cut -f3- -d'/')
  copy-gpg-keys "${repo_file}"
  run-command rm -f "${repo_file}"
  [[ -z ${REPO_HOST} ]] || generate-local-repo-file ${REPO_HOST} ${repo_url}
}

function copy-repo {
  for repo_url in "$@"; do
    local repo_file=$(get-repo-file "${repo_url}")
    for line in $(perl -wnl -00 -e '($name, $path) = $_ =~ /\[(\S+)\].*baseurl=https?:\/\/(\S+)/s and print "$name]$path"' "${repo_file}"); do
      local repo="$(echo ${line} | cut -f1 -d']')"
      local path="$(echo ${line} | cut -f2 -d']')"
      run-command reposync -n -p /var/repo/${path} --norepopath -r "${repo}"
      create-repos ${path}
    done
    copy-gpg-keys "${repo_file}"
    run-command rm -f "${repo_file}"
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
    run-command createrepo -q --update /var/repo/${dir}
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
    run-command curl --create-dirs --output ${path} --remote-time --silent ${url}
  done
}

function generate-local-repo-file {
  local host=$1
  [[ -n ${host} ]] || return 1
  local url=$2
  [[ -n ${url} ]] || return 2
  local path=$(echo ${url} | sed -e "s@//${host}/@//@" | cut -f3- -d'/')
  run-command mkdir -p "$(dirname ${path})"
  run-command curl --create-dirs --output "${path}" --remote-time --silent "${url}"
  run-command perl -wpl -i -e "s@https?://@\$&${host}/@g" ${path}
}

function usage {
  echo "Usage:"
  echo "  repo <repo_url> [<repo_url> ...]"
  echo "  repo-file <repo_host> <repo_url>"
  echo "  pkg <repo_url> <pkg_name> [<pkg_name> ...]"
  echo "  file <url> [<url> ...]"
}

while getopts ":nv" opt; do
  case "${opt}" in
    n)
      DRY_RUN=true
      ;;
    v)
      DEBUG=1
      ;;
  esac
done
shift $((${OPTIND} - 1))

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
  file)
    shift
    get-urls "$@"
    ;;
  *)
    usage
    ;;
esac
