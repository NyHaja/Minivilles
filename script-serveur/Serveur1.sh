#!/bin/sh
printf '\033c\033]0;%s\a' Serveur
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Serveur1.x86_64" "$@"
