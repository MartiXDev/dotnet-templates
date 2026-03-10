#!/usr/bin/env sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
project_root="."
scaffold_variant="default"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project-root)
      project_root="$2"
      shift 2
      ;;
    --variant)
      scaffold_variant="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

project_root="$(CDPATH= cd -- "$project_root" && pwd)"

case "$scaffold_variant" in
  default|no-frontend|api-only)
    ;;
  *)
    echo "Unsupported scaffold variant '$scaffold_variant'." >&2
    exit 1
    ;;
esac

to_windows_path() {
  input_path="$1"

  if command -v wslpath >/dev/null 2>&1; then
    wslpath -w "$input_path"
    return 0
  fi

  case "$input_path" in
    /mnt/?/*)
      drive_letter="$(printf '%s' "$input_path" | cut -d/ -f3 | tr '[:lower:]' '[:upper:]')"
      remaining_path="$(printf '%s' "$input_path" | cut -d/ -f4- | tr '/' '\\')"
      printf '%s:\\%s\n' "$drive_letter" "$remaining_path"
      ;;
    /?/*)
      drive_letter="$(printf '%s' "$input_path" | cut -d/ -f2 | tr '[:lower:]' '[:upper:]')"
      remaining_path="$(printf '%s' "$input_path" | cut -d/ -f3- | tr '/' '\\')"
      printf '%s:\\%s\n' "$drive_letter" "$remaining_path"
      ;;
    *)
      printf '%s\n' "$input_path"
      ;;
  esac
}

if command -v pwsh >/dev/null 2>&1; then
  pwsh_cmd="pwsh"
elif command -v pwsh.exe >/dev/null 2>&1; then
  pwsh_cmd="pwsh.exe"
else
  echo "PowerShell 7 (pwsh) was not found on PATH." >&2
  exit 1
fi

script_path="$script_dir/validate-generated-repo.ps1"
project_root_arg="$project_root"

case "$pwsh_cmd" in
  *.exe)
    script_path="$(to_windows_path "$script_path")"
    project_root_arg="$(to_windows_path "$project_root")"
    ;;
esac

exec "$pwsh_cmd" -NoLogo -NoProfile -File "$script_path" -ProjectRoot "$project_root_arg" -ScaffoldVariant "$scaffold_variant"
