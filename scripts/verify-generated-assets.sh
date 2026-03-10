#!/usr/bin/env sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
sample_name="SampleApp"
output_root="bin/generated-assets"
output_path=""
keep_output="false"

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
    --keep-output|--keep-project)
      keep_output="true"
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [ -z "$output_path" ] && [ "$keep_output" = "true" ]; then
  output_path="$output_root/$sample_name"
fi

if [ "$keep_output" = "true" ]; then
  KEEP_OUTPUT=true exec "$script_dir/generated-assets.sh" verify "$sample_name" "$output_path"
fi

exec "$script_dir/generated-assets.sh" verify "$sample_name" "$output_path"
