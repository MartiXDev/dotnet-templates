#!/usr/bin/env sh
set -eu

if [ "$#" -lt 1 ]; then
  echo "Usage: ./scripts/generated-assets.sh <refresh|verify> [sample-name] [output-path]" >&2
  exit 1
fi

command_name="$1"
sample_name="${2:-SampleApp}"
output_path="${3:-}"

case "$command_name" in
  refresh|verify)
    ;;
  *)
    echo "Unsupported command '$command_name'." >&2
    echo "Usage: ./scripts/generated-assets.sh <refresh|verify> [sample-name] [output-path]" >&2
    exit 1
    ;;
esac

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_root="$(CDPATH= cd -- "$script_dir/.." && pwd)"
hive_root="$(mktemp -d "${TMPDIR:-/tmp}/martix-template-hive.XXXXXX")"

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

if command -v dotnet >/dev/null 2>&1; then
  dotnet_cmd="dotnet"
elif command -v dotnet.exe >/dev/null 2>&1; then
  dotnet_cmd="dotnet.exe"
elif [ -x "/mnt/c/Program Files/dotnet/dotnet.exe" ]; then
  dotnet_cmd="/mnt/c/Program Files/dotnet/dotnet.exe"
elif [ -x "/c/Program Files/dotnet/dotnet.exe" ]; then
  dotnet_cmd="/c/Program Files/dotnet/dotnet.exe"
else
  echo "dotnet was not found on PATH." >&2
  exit 1
fi

cleanup() {
  rm -rf "$hive_root"
  if [ "$command_name" = "verify" ] && [ -z "${KEEP_OUTPUT:-}" ]; then
    if [ -n "${sample_base_root:-}" ] && [ -d "$sample_base_root" ]; then
      rm -rf "$sample_base_root"
    elif [ -n "${sample_root:-}" ] && [ -d "$sample_root" ]; then
      rm -rf "$sample_root"
    fi
  fi
}

trap cleanup EXIT INT TERM

if [ -n "$output_path" ]; then
  case "$output_path" in
    /*)
      sample_root="$output_path"
      ;;
    *)
      sample_root="$repo_root/$output_path"
      ;;
  esac
elif [ "$command_name" = "refresh" ]; then
  sample_root="$repo_root/bin/generated-assets/$sample_name"
else
  sample_base_root="$(mktemp -d "${TMPDIR:-/tmp}/martix-generated-assets.XXXXXX")"
  sample_root="$sample_base_root/$sample_name"
fi

if [ "$command_name" = "refresh" ] && [ "${KEEP_EXISTING:-}" != "true" ] && [ -d "$sample_root" ]; then
  rm -rf "$sample_root"
fi

repo_root_arg="$repo_root"
sample_root_arg="$sample_root"
hive_root_arg="$hive_root"

case "$dotnet_cmd" in
  *.exe)
    repo_root_arg="$(to_windows_path "$repo_root")"
    sample_root_arg="$(to_windows_path "$sample_root")"
    hive_root_arg="$(to_windows_path "$hive_root")"
    ;;
esac

"$dotnet_cmd" new install "$repo_root_arg" --debug:custom-hive "$hive_root_arg"
"$dotnet_cmd" new martix-webapi -n "$sample_name" -o "$sample_root_arg" --force --debug:custom-hive "$hive_root_arg"

sh "$script_dir/validate-generated-repo.sh" --project-root "$sample_root"

printf '%s completed for generated sample: %s\n' "$command_name" "$sample_root"
