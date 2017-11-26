#!/usr/bin/env bash
# vim: ts=2 sw=2 sts=2 et

set -e
set -u

for repo_url in "$@"; do
  curl -s -o /etc/apt/mirror.list "$repo_url"
  apt-mirror
  rm -f /etc/apt/mirror.list
done
