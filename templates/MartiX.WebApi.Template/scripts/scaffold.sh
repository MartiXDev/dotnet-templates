#!/usr/bin/env sh
set -eu

if [ "$#" -lt 1 ]; then
  echo "Usage: ./scripts/scaffold.sh <bootstrap|update|verify> [args...]" >&2
  exit 1
fi

command_name="$1"
shift

case "$command_name" in
  bootstrap|update|verify)
    ;;
  *)
    echo "Unsupported scaffold command '$command_name'." >&2
    echo "Usage: ./scripts/scaffold.sh <bootstrap|update|verify> [args...]" >&2
    exit 1
    ;;
esac

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_root="$(CDPATH= cd -- "$script_dir/.." && pwd)"
project_path="$repo_root/.scaffold/src/MartiX.WebApi.Template.Scaffold/MartiX.WebApi.Template.Scaffold.csproj"

if [ ! -f "$project_path" ]; then
  echo "Scaffold runner project was not found at '$project_path'." >&2
  exit 1
fi

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

project_path_arg="$project_path"
repo_root_arg="$repo_root"

case "$dotnet_cmd" in
  *.exe)
    project_path_arg="$(to_windows_path "$project_path")"
    repo_root_arg="$(to_windows_path "$repo_root")"
    ;;
esac

"$dotnet_cmd" run --project "$project_path_arg" -- "$command_name" --repo-root "$repo_root_arg" "$@"
