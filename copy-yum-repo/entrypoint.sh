#!/bin/bash
# vim: ts=2 sw=2 sts=2 et

set -e
set -u

for repo_url in "$@"; do
  repo_file="/etc/yum.repos.d/$(basename $repo_url)"
  curl -s -o "$repo_file" "$repo_url"
  for line in $(perl -wnl -00 -e '($name, $path) = $_ =~ /\[(\S+)\].*baseurl=https?:\/\/[^\/]+\/(\S+)/s and print "$name]$path"' "$repo_file"); do
    repo="$(echo $line | cut -f1 -d']')"
    path="$(echo $line | cut -f2 -d']')"
    reposync -n -p /var/repo/$path --norepopath -r "$repo" && createrepo --update /var/repo/$path
  done
  rm -f "$repo_file"
done
