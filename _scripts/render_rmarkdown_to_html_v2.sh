#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

IMAGE="${RJOURNAL_RENDER_DOCKER_IMAGE:-rjournal-rmarkdown-renderer:v2}"
DOCKERFILE="${RJOURNAL_RENDER_DOCKERFILE:-$ROOT/_scripts/render/docker/Dockerfile}"
BUILD_CONTEXT="${RJOURNAL_RENDER_DOCKER_BUILD_CONTEXT:-$ROOT/_scripts/render/docker}"
BUILD_MODE="${RJOURNAL_RENDER_DOCKER_BUILD:-auto}"
DOCKER_CONFIG_DIR="${RJOURNAL_RENDER_DOCKER_CONFIG:-$ROOT/tmp/docker-config}"
DOCKER_BUILDKIT_MODE="${RJOURNAL_RENDER_DOCKER_BUILDKIT:-0}"
MEMORY="${RJOURNAL_RENDER_DOCKER_MEMORY:-8g}"
MEMORY_SWAP="${RJOURNAL_RENDER_DOCKER_MEMORY_SWAP:-$MEMORY}"
CPUS="${RJOURNAL_RENDER_DOCKER_CPUS:-2}"
PIDS_LIMIT="${RJOURNAL_RENDER_DOCKER_PIDS_LIMIT:-512}"
docker_workers="${RJOURNAL_RENDER_DOCKER_WORKERS:-1}"
docker_item_timeout="${RJOURNAL_RENDER_DOCKER_ITEM_TIMEOUT:-300}"
render_collections="_articles,_news"
render_sample=
render_seed=1
render_timeout=300
render_use_cache=1
render_log_path="tmp/render.log"
host_log_path="$ROOT/$render_log_path"

R_LIST_ITEMS='
args <- commandArgs(TRUE)
mode <- args[[1]]
collection_names <- strsplit(args[[2]], ",", fixed = TRUE)[[1]]
sample_arg <- args[[3]]
sample_n <- if (identical(sample_arg, "")) NULL else as.integer(sample_arg)
seed <- as.integer(args[[4]])
source("_scripts/render.R", local = .GlobalEnv)
items <- switch(
  mode,
  all = discover_items(collection_names = collection_names, sample_n = sample_n, seed = seed),
  pending = discover_pending_items(collection_names = collection_names, sample_n = sample_n, seed = seed),
  stop("Unknown list mode: ", mode, call. = FALSE)
)
cat(paste(items$item_dir, collapse = "\n"))
if (nrow(items) > 0) cat("\n")
'

R_RENDER_ITEM='
args <- commandArgs(TRUE)
item <- args[[1]]
log_path <- args[[2]]
timeout <- as.integer(args[[3]])
cache <- identical(args[[4]], "1")
source("_scripts/render.R", local = .GlobalEnv)
result <- render_one_item(item, timeout = timeout, log_path = log_path, cache = cache)
quit(status = render_result_exit_status(result), save = "no")
'

print_help() {
  cat <<'EOF'
Render archived R Markdown articles in Docker.

Usage:
  _scripts/render_rmarkdown_to_html_v2.sh [options]
  _scripts/render_rmarkdown_to_html_v2.sh --item=<path> [options]
  _scripts/render_rmarkdown_to_html_v2.sh --list-items [options]
  _scripts/render_rmarkdown_to_html_v2.sh (-h | --help)
  _scripts/render_rmarkdown_to_html_v2.sh --version

Options:
  -h --help                 Show this screen.
  --version                 Show version.
  --collections=<names>     Comma-separated collection directories.
  --sample=<n>              Render a deterministic sample of n items.
  --seed=<n>                Sampling seed, default 1.
  --workers=<n>             Parallel Docker container count.
  --container-timeout=<n>   Per-item Docker container timeout in seconds; default 300, 0 disables.
  --item=<path>             Render one item directory.
  --list-items              Print candidate item directories and exit.
  --timeout=<seconds>       Per-item rmarkdown::render timeout in seconds, default 300.
  --log=<path>              Render trace log path under tmp/.
  --no-cache                Do not enable knitr chunk caching in generated Rmd.

Environment:
  RJOURNAL_RENDER_DOCKER_MEMORY      Per-item container memory limit, default 8g.
  RJOURNAL_RENDER_DOCKER_CPUS        Per-item CPU quota, default 2.
  RJOURNAL_RENDER_DOCKER_WORKERS     Parallel Docker container count, default 1.
  RJOURNAL_RENDER_DOCKER_ITEM_TIMEOUT
                                      Per-item Docker container timeout, default 300; 0 disables.
  RJOURNAL_RENDER_DOCKER_BUILD       auto, 1, or 0.
  RJOURNAL_RENDER_DOCKER_IMAGE       Docker image tag.
  RJOURNAL_RENDER_DOCKER_CONFIG      Docker CLI config directory.
  RJOURNAL_RENDER_DOCKER_BUILDKIT    Docker build backend flag, default 0.
EOF
}

print_version() {
  printf 'render_rmarkdown_to_html_v2.sh\n'
}

validate_positive_integer() {
  local value="$1"
  local option="$2"

  if [[ ! "$value" =~ ^[1-9][0-9]*$ ]]; then
    printf '%s must be a positive integer: %s\n' "$option" "$value" >&2
    exit 2
  fi
}

validate_non_negative_integer() {
  local value="$1"
  local option="$2"

  if [[ ! "$value" =~ ^[0-9]+$ ]]; then
    printf '%s must be a non-negative integer: %s\n' "$option" "$value" >&2
    exit 2
  fi
}

set_docker_workers() {
  validate_positive_integer "$1" "$2"
  docker_workers="$1"
}

set_docker_item_timeout() {
  validate_non_negative_integer "$1" "$2"
  docker_item_timeout="$1"
}

set_render_sample() {
  validate_positive_integer "$1" "$2"
  render_sample="$1"
}

set_render_seed() {
  validate_positive_integer "$1" "$2"
  render_seed="$1"
}

set_render_timeout() {
  validate_positive_integer "$1" "$2"
  render_timeout="$1"
}

set_render_collections() {
  local value="$1"
  local option="$2"
  local collection

  if [[ -z "$value" ]]; then
    printf '%s must include at least one collection.\n' "$option" >&2
    exit 2
  fi
  case "$value" in
    /*|*,,*|*,|,*|../*|*/../*|..|*/..)
      printf '%s must be a comma-separated list of repository-relative collection directories: %s\n' "$option" "$value" >&2
      exit 2
      ;;
  esac
  IFS=',' read -r -a collections_array <<< "$value"
  for collection in "${collections_array[@]}"; do
    if [[ -z "$collection" || "$collection" == /* || "$collection" == *".."* ]]; then
      printf '%s contains an invalid collection directory: %s\n' "$option" "$collection" >&2
      exit 2
    fi
  done
  render_collections="$value"
}

set_log_path() {
  local raw_log_path="$1"
  local relative_log_path

  if [[ -z "$raw_log_path" ]]; then
    printf -- '--log requires a path.\n' >&2
    exit 2
  fi

  if [[ "$raw_log_path" == /* ]]; then
    if [[ "$raw_log_path" == "$ROOT/"* ]]; then
      relative_log_path="${raw_log_path#"$ROOT"/}"
    else
      printf 'Absolute --log paths must be inside the repository for Docker rendering: %s\n' "$raw_log_path" >&2
      exit 2
    fi
  else
    relative_log_path="$raw_log_path"
  fi

  case "$relative_log_path" in
    tmp/*)
      ;;
    *)
      printf 'Docker render --log paths must be under tmp/: %s\n' "$raw_log_path" >&2
      exit 2
      ;;
  esac

  case "$relative_log_path" in
    ../*|*/../*|..|*/..)
      printf 'Docker render --log paths cannot contain parent-directory components: %s\n' "$raw_log_path" >&2
      exit 2
      ;;
  esac

  render_log_path="$relative_log_path"
  host_log_path="$ROOT/$relative_log_path"
}

requested_item=
list_only=0

set_docker_workers "$docker_workers" "RJOURNAL_RENDER_DOCKER_WORKERS"
set_docker_item_timeout "$docker_item_timeout" "RJOURNAL_RENDER_DOCKER_ITEM_TIMEOUT"

while [[ "$#" -gt 0 ]]; do
  arg="$1"
  shift
  case "$arg" in
    -h|--help)
      print_help
      exit 0
      ;;
    --version)
      print_version
      exit 0
      ;;
    --collections=*)
      set_render_collections "${arg#--collections=}" "--collections"
      ;;
    --collections)
      if [[ "$#" -eq 0 ]]; then
        printf -- '--collections requires a value.\n' >&2
        exit 2
      fi
      set_render_collections "$1" "--collections"
      shift
      ;;
    --sample=*)
      set_render_sample "${arg#--sample=}" "--sample"
      ;;
    --sample)
      if [[ "$#" -eq 0 ]]; then
        printf -- '--sample requires a value.\n' >&2
        exit 2
      fi
      set_render_sample "$1" "--sample"
      shift
      ;;
    --seed=*)
      set_render_seed "${arg#--seed=}" "--seed"
      ;;
    --seed)
      if [[ "$#" -eq 0 ]]; then
        printf -- '--seed requires a value.\n' >&2
        exit 2
      fi
      set_render_seed "$1" "--seed"
      shift
      ;;
    --workers=*)
      set_docker_workers "${arg#--workers=}" "--workers"
      ;;
    --workers)
      if [[ "$#" -eq 0 ]]; then
        printf -- '--workers requires a value.\n' >&2
        exit 2
      fi
      set_docker_workers "$1" "--workers"
      shift
      ;;
    --container-timeout=*|--item-timeout=*)
      set_docker_item_timeout "${arg#*=}" "${arg%%=*}"
      ;;
    --container-timeout|--item-timeout)
      if [[ "$#" -eq 0 ]]; then
        printf '%s requires a value.\n' "$arg" >&2
        exit 2
      fi
      set_docker_item_timeout "$1" "$arg"
      shift
      ;;
    --timeout=*)
      set_render_timeout "${arg#--timeout=}" "--timeout"
      ;;
    --timeout)
      if [[ "$#" -eq 0 ]]; then
        printf -- '--timeout requires a value.\n' >&2
        exit 2
      fi
      set_render_timeout "$1" "--timeout"
      shift
      ;;
    --item=*)
      requested_item="${arg#--item=}"
      ;;
    --item)
      if [[ "$#" -eq 0 ]]; then
        printf -- '--item requires a path.\n' >&2
        exit 2
      fi
      requested_item="$1"
      shift
      ;;
    --list-items)
      list_only=1
      ;;
    --log=*)
      set_log_path "${arg#--log=}"
      ;;
    --log)
      if [[ "$#" -eq 0 ]]; then
        printf -- '--log requires a path.\n' >&2
        exit 2
      fi
      set_log_path "$1"
      shift
      ;;
    --no-cache)
      render_use_cache=0
      ;;
    *)
      printf 'Unknown option: %s\n' "$arg" >&2
      exit 2
      ;;
  esac
done

if [[ "$list_only" -eq 1 && -n "$requested_item" ]]; then
  printf -- '--list-items and --item cannot be used together.\n' >&2
  exit 2
fi

if [[ -n "$requested_item" ]]; then
  if [[ "$requested_item" == "$ROOT/"* ]]; then
    requested_item="/work/${requested_item#"$ROOT"/}"
  elif [[ "$requested_item" == /* && "$requested_item" != /work/* ]]; then
    printf 'Absolute --item paths must be inside the repository for Docker rendering: %s\n' "$requested_item" >&2
    exit 2
  fi
fi

container_track_file="$ROOT/tmp/render-containers-$$.txt"
container_log_dir="$ROOT/tmp/render-container-logs"
mkdir -p "$ROOT/tmp/home" "$container_log_dir" "$DOCKER_CONFIG_DIR" "$(dirname "$host_log_path")"
if [[ ! -f "$DOCKER_CONFIG_DIR/config.json" ]]; then
  printf '{}\n' > "$DOCKER_CONFIG_DIR/config.json"
fi
export DOCKER_CONFIG="$DOCKER_CONFIG_DIR"
: > "$container_track_file"

docker_cli() {
  HOME="$ROOT/tmp/home" DOCKER_CONFIG="$DOCKER_CONFIG_DIR" \
    docker --config "$DOCKER_CONFIG_DIR" "$@"
}

dockerfile_hash() {
  local files=("$DOCKERFILE")

  if [[ -f "$BUILD_CONTEXT/entrypoint.sh" ]]; then
    files+=("$BUILD_CONTEXT/entrypoint.sh")
  fi

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${files[@]}" | sha256sum | awk '{print $1}'
    return 0
  fi
  shasum -a 256 "${files[@]}" | shasum -a 256 | awk '{print $1}'
}

image_dockerfile_hash() {
  docker_cli image inspect \
    -f '{{ index .Config.Labels "org.rjournal.render.dockerfile-sha" }}' \
    "$IMAGE" 2>/dev/null || true
}

build_render_image() {
  local hash="$1"

  HOME="$ROOT/tmp/home" DOCKER_CONFIG="$DOCKER_CONFIG_DIR" DOCKER_BUILDKIT="$DOCKER_BUILDKIT_MODE" \
    docker --config "$DOCKER_CONFIG_DIR" build \
    --pull=false \
    --label "org.rjournal.render.dockerfile-sha=$hash" \
    -f "$DOCKERFILE" \
    -t "$IMAGE" \
    "$BUILD_CONTEXT"
}

build_image() {
  local hash
  local image_hash

  hash="$(dockerfile_hash)"

  case "$BUILD_MODE" in
    0|false|FALSE|no|NO)
      return 0
      ;;
    1|true|TRUE|yes|YES)
      build_render_image "$hash"
      return 0
      ;;
    auto)
      if ! docker_cli image inspect "$IMAGE" >/dev/null 2>&1; then
        build_render_image "$hash"
        return 0
      fi
      image_hash="$(image_dockerfile_hash)"
      if [[ "$image_hash" != "$hash" ]]; then
        printf 'Docker image %s is stale; rebuilding from %s.\n' "$IMAGE" "$DOCKERFILE" >&2
        build_render_image "$hash"
      fi
      return 0
      ;;
    *)
      printf 'RJOURNAL_RENDER_DOCKER_BUILD must be auto, 1, or 0.\n' >&2
      exit 2
      ;;
  esac
}

require_docker_access() {
  local output

  if ! command -v docker >/dev/null 2>&1; then
    printf 'Docker is required for render_rmarkdown_to_html_v2.sh, but docker is not on PATH.\n' >&2
    exit 2
  fi

  if [[ "$docker_item_timeout" -gt 0 ]] && ! command -v timeout >/dev/null 2>&1; then
    printf 'The timeout command is required when RJOURNAL_RENDER_DOCKER_ITEM_TIMEOUT is greater than 0.\n' >&2
    exit 2
  fi

  if ! output="$(docker_cli info 2>&1 >/dev/null)"; then
    printf 'Docker is not reachable by this user.\n' >&2
    if [[ -n "$output" ]]; then
      printf 'docker info: %s\n' "$output" >&2
    fi
    printf 'Start Docker and make sure your user can access the Docker socket or context.\n' >&2
    printf 'On Linux, that usually means adding the user to the docker group and starting a new login session, or using an accessible rootless Docker context.\n' >&2
    exit 2
  fi
}

docker_common_args=(
  --workdir /work
  --user "$(id -u):$(id -g)"
  --security-opt seccomp=unconfined
  --env HOME=/work/tmp/home
  --env TMPDIR=/work/tmp
  --env TMP=/work/tmp
  --env TEMP=/work/tmp
  --env TZ=UTC
  --env LANG=C.UTF-8
  --env LC_ALL=C.UTF-8
  --env LC_COLLATE=C.UTF-8
  --env LC_CTYPE=C.UTF-8
  --env LC_MESSAGES=C.UTF-8
  --env LC_MONETARY=C.UTF-8
  --env LC_NUMERIC=C.UTF-8
  --env LC_TIME=C.UTF-8
  --env RJOURNAL_RENDER_USE_SYSTEM_LIBRARY=1
  --mount "type=bind,source=$ROOT,target=/work,readonly"
  --mount "type=bind,source=$ROOT/tmp,target=/work/tmp"
  --mount "type=bind,source=$ROOT/_articles,target=/work/_articles"
  --mount "type=bind,source=$ROOT/_news,target=/work/_news"
)

cleanup_containers() {
  local containers=()
  local container

  if [[ -f "$container_track_file" ]]; then
    while IFS= read -r container; do
      if [[ -n "$container" ]]; then
        containers+=("$container")
      fi
    done < "$container_track_file"
  fi

  if [[ "${#containers[@]}" -gt 0 ]] && command -v docker >/dev/null 2>&1; then
    docker_cli rm -f "${containers[@]}" >/dev/null 2>&1 || true
  fi

  rm -f "$container_track_file"
}
trap cleanup_containers EXIT

append_render_log() {
  local level="$1"
  local message="$2"
  printf '%s %s %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$level" "$message" >> "$host_log_path"
}

list_items() {
  local mode="$1"

  docker_cli run --rm "${docker_common_args[@]}" "$IMAGE" \
    Rscript -e "$R_LIST_ITEMS" "$mode" "$render_collections" "$render_sample" "$render_seed"
}

sanitize_container_name() {
  local value="$1"
  value="${value//[^a-zA-Z0-9_.-]/-}"
  printf '%s' "$value"
}

item_collection() {
  local item="$1"
  printf '%s' "$(basename "$(dirname "$item")")"
}

item_slug() {
  local item="$1"
  printf '%s' "$(basename "$item")"
}

item_host_html_file() {
  local item="$1"
  local collection
  local slug

  collection="$(item_collection "$item")"
  slug="$(item_slug "$item")"
  printf '%s/%s/%s/%s.html' "$ROOT" "$collection" "$slug" "$slug"
}

run_item_container() {
  local item="$1"
  local index="$2"
  local slug
  local collection
  local name
  local log_file
  local html_file
  local had_html
  local has_html
  local container_xvfb_log
  local start_status
  local timed_out
  local oom_killed
  local exit_code
  local reason

  slug="$(item_slug "$item")"
  collection="$(item_collection "$item")"
  name="$(sanitize_container_name "rjournal-render-${slug}-$$-${index}")"
  log_file="$container_log_dir/$collection/$slug.log"
  html_file="$(item_host_html_file "$item")"
  container_xvfb_log="/work/tmp/render-container-logs/$collection/$slug.xvfb.log"
  if [[ -f "$html_file" ]]; then
    had_html=1
  else
    had_html=0
  fi
  mkdir -p "$(dirname "$log_file")"

  append_render_log "INFO" "event=render_container_create_started collection=$collection slug=$slug container=$name log=$log_file"
  docker_cli create \
    --name "$name" \
    --memory "$MEMORY" \
    --memory-swap "$MEMORY_SWAP" \
    --cpus "$CPUS" \
    --pids-limit "$PIDS_LIMIT" \
    "${docker_common_args[@]}" \
    --env "RJOURNAL_RENDER_XVFB_LOG=$container_xvfb_log" \
    "$IMAGE" \
    rjournal-render-entrypoint \
    Rscript -e "$R_RENDER_ITEM" "$item" "$render_log_path" "$render_timeout" "$render_use_cache" >/dev/null
  printf '%s\n' "$name" >> "$container_track_file"

  append_render_log "INFO" "event=render_container_starting collection=$collection slug=$slug container=$name log=$log_file"
  timed_out=0
  set +e
  if [[ "$docker_item_timeout" -gt 0 ]]; then
    HOME="$ROOT/tmp/home" DOCKER_CONFIG="$DOCKER_CONFIG_DIR" \
      timeout --kill-after=10s "${docker_item_timeout}s" \
      docker --config "$DOCKER_CONFIG_DIR" start -a "$name" > "$log_file" 2>&1
  else
    docker_cli start -a "$name" > "$log_file" 2>&1
  fi
  start_status=$?
  if [[ "$docker_item_timeout" -gt 0 && ( "$start_status" -eq 124 || "$start_status" -eq 137 ) ]]; then
    timed_out=1
    printf 'Render container timed out after %ss; removing %s.\n' "$docker_item_timeout" "$name" >> "$log_file"
    docker_cli rm -f "$name" >> "$log_file" 2>&1 || true
  fi
  set -e

  if [[ "$timed_out" -eq 1 ]]; then
    oom_killed="false"
    exit_code="124"
  else
    oom_killed="$(docker_cli inspect -f '{{.State.OOMKilled}}' "$name" 2>/dev/null || printf 'false')"
    exit_code="$(docker_cli inspect -f '{{.State.ExitCode}}' "$name" 2>/dev/null || printf '%s' "$start_status")"
  fi
  append_render_log "INFO" "event=render_container_finished collection=$collection slug=$slug container=$name exit_code=$exit_code"
  docker_cli rm -f "$name" >/dev/null 2>&1 || true
  if [[ -f "$html_file" ]]; then
    has_html=1
  else
    has_html=0
  fi

  if [[ "$start_status" -ne 0 || "$exit_code" -ne 0 ]]; then
    if [[ "$timed_out" -eq 1 ]]; then
      reason="timeout"
      append_render_log "ERROR" "event=render_container_timed_out collection=$collection slug=$slug container=$name timeout=${docker_item_timeout}s log=$log_file"
    elif [[ "$oom_killed" == "true" ]]; then
      reason="oom"
    else
      reason="nonzero_exit"
    fi
    append_render_log "ERROR" "event=render_item_failed collection=$collection slug=$slug reason=$reason exit_code=$exit_code log=$log_file"
    printf 'Render container failed for %s/%s: %s (exit %s)\n' "$collection" "$slug" "$reason" "$exit_code" >&2
    printf 'Container log: %s\n' "$log_file" >&2
    tail -n 40 "$log_file" >&2 || true
    return 1
  fi

  if [[ "$had_html" -eq 0 && "$has_html" -eq 1 ]]; then
    last_item_outcome="created"
  elif [[ "$had_html" -eq 1 && "$has_html" -eq 1 ]]; then
    last_item_outcome="existing"
  else
    last_item_outcome="no_html"
  fi
  append_render_log "INFO" "event=render_item_completed collection=$collection slug=$slug outcome=$last_item_outcome html=$html_file"
  return 0
}

item_label() {
  local item="$1"
  printf '%s/%s' "$(item_collection "$item")" "$(item_slug "$item")"
}

run_item_with_progress() {
  local item="$1"
  local index="$2"
  local total="$3"
  local label
  local start_time
  local elapsed

  label="$(item_label "$item")"
  printf '[%s/%s] Rendering %s (log: tmp/render-container-logs/%s.log)\n' "$index" "$total" "$label" "$label" >&2
  start_time="$(date +%s)"

  if run_item_container "$item" "$index"; then
    elapsed=$(($(date +%s) - start_time))
    case "${last_item_outcome:-unknown}" in
      created)
        printf '[%s/%s] Created %s.html (%ss)\n' "$index" "$total" "$label" "$elapsed" >&2
        ;;
      existing)
        printf '[%s/%s] Skipped existing %s.html (%ss)\n' "$index" "$total" "$label" "$elapsed" >&2
        ;;
      no_html)
        printf '[%s/%s] Completed %s without HTML output (%ss)\n' "$index" "$total" "$label" "$elapsed" >&2
        ;;
      *)
        printf '[%s/%s] Completed %s (%ss)\n' "$index" "$total" "$label" "$elapsed" >&2
        ;;
    esac
    return 0
  fi

  elapsed=$(($(date +%s) - start_time))
  printf '[%s/%s] Failed %s (%ss)\n' "$index" "$total" "$label" "$elapsed" >&2
  return 1
}

wait_for_render_job() {
  if ! wait -n; then
    failures=$((failures + 1))
  fi
  active_jobs=$((active_jobs - 1))
}

require_docker_access
build_image

if [[ "$list_only" -eq 1 ]]; then
  list_items all
  exit 0
fi

if [[ -n "$requested_item" ]]; then
  if run_item_with_progress "$requested_item" 1 1; then
    exit 0
  fi
  printf '1 render container failed. See %s for details.\n' "$host_log_path" >&2
  exit 1
fi

printf 'Discovering pending render items with Docker image %s.\n' "$IMAGE" >&2
if ! item_output="$(list_items pending)"; then
  printf 'Failed to discover pending render items with Docker image %s.\n' "$IMAGE" >&2
  exit 1
fi

pending_items=()
while IFS= read -r item; do
  case "$item" in
    /work/*)
      pending_items+=("$item")
      ;;
  esac
done <<< "$item_output"

if [[ "${#pending_items[@]}" -eq 0 ]]; then
  printf 'No new render items found.\n' >&2
  exit 0
fi

printf 'Rendering %s pending item(s) with Docker image %s using %s worker(s).\n' "${#pending_items[@]}" "$IMAGE" "$docker_workers" >&2

failures=0
index=0
total="${#pending_items[@]}"
active_jobs=0
for item in "${pending_items[@]}"; do
  index=$((index + 1))
  run_item_with_progress "$item" "$index" "$total" &
  active_jobs=$((active_jobs + 1))
  if [[ "$active_jobs" -ge "$docker_workers" ]]; then
    wait_for_render_job
  fi
done
while [[ "$active_jobs" -gt 0 ]]; do
  wait_for_render_job
done

if [[ "$failures" -gt 0 ]]; then
  printf '%s render container(s) failed. See %s for details.\n' "$failures" "$host_log_path" >&2
  exit 1
fi

printf 'Rendered %s item(s) successfully.\n' "$total" >&2
