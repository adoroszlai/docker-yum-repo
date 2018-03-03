#!/bin/bash
# vim: ts=2 sw=2 sts=2 et

set -e -u

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

  local urls=$(repotrack -n --urls "$@")
  for url in ${urls}; do
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

  for dir in $(grep 'baseurl=' ${repo_file} | cut -f3- -d'/'); do
    [[ -d ${dir} ]] || continue
    echo "Creating repo in ${dir}"
    createrepo -q --update /var/repo/${dir}
  done

  rm -f "${repo_file}"
}

function copy-repo {
  for repo_url in "$@"; do
    local repo_file=$(get-repo-file "${repo_url}")
    for line in $(perl -wnl -00 -e '($name, $path) = $_ =~ /\[(\S+)\].*baseurl=https?:\/\/(\S+)/s and print "$name]$path"' "${repo_file}"); do
      local repo="$(echo ${line} | cut -f1 -d']')"
      local path="$(echo ${line} | cut -f2 -d']')"
      reposync -n -p /var/repo/${path} --norepopath -r "${repo}"
      echo "Creating repo in ${path}"
      createrepo -q --update /var/repo/${path}
    done
    rm -f "${repo_file}"
  done
}

function usage {
  echo "Usage:"
  echo "  repo <repo_url> [<repo_url> ...]"
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
  *)
    usage
    ;;
esac
