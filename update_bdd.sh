#!/bin/sh
printf '\033c\033]0;%s\a' update_bdd
base_path="$(dirname "$(realpath "$0")")"
"$base_path/update_bdd.x86_64" "$@"
