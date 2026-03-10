#!/usr/bin/env sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
sample_name="SampleApp"
output_root="bin/generated-assets"
output_path=""
keep_existing="false"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --sample-name)
      sample_name="$2"
      shift 2
      ;;
    --output-root)
      output_root="$2"
      shift 2
      ;;
    --output-path)
      output_path="$2"
      shift 2
      ;;
    --keep-existing)
      keep_existing="true"
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [ -z "$output_path" ]; then
  output_path="$output_root/$sample_name"
fi

if [ "$keep_existing" = "true" ]; then
  KEEP_EXISTING=true exec "$script_dir/generated-assets.sh" refresh "$sample_name" "$output_path"
fi

exec "$script_dir/generated-assets.sh" refresh "$sample_name" "$output_path"
