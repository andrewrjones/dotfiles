#!/usr/bin/env zsh
# From https://gist.github.com/mathd/5ccfe70edc70c129828fadb9f54c7f5e
# Worktree Manager (zsh) — v2
# - Sourceable from .zshrc (no copy/paste edits needed)
# - Auto-detects current git repo (no <project> arg)
# - Supports deep trees (mirrors repo path under W_WORKTREES_DIR)
# - Trailing-slash normalization + newline-safe parsing
# - Safer branch handling (reuse local/remote if present)
# - Inline completion (no external file)

# =========
# Config — override these in your ~/.zshrc *before* sourcing this file
# example:
#   export W_PROJECTS_DIR="$HOME/Sources"
#   export W_WORKTREES_DIR="$HOME/Sources-Worktree"
#   export W_DEFAULT_BRANCH_PREFIX="$USER"
# =========
: ${W_PROJECTS_DIR:="$HOME/projects"}
: ${W_WORKTREES_DIR:="$HOME/projects/worktrees"}
: ${W_DEFAULT_BRANCH_PREFIX:=""}           # branch name prefix (<prefix>/<worktree>)
: ${W_SUPPORT_LEGACY_CORE_WTS:=""}         # non-empty enables ~/projects/core-wts listing

# Normalize trailing slashes to prevent // in paths
W_PROJECTS_DIR=${W_PROJECTS_DIR%/}
W_WORKTREES_DIR=${W_WORKTREES_DIR%/}

# -----------------------
# Utilities
# -----------------------
_w_die()  { print -r -- "$*" >&2; return 1 }
_w_info() { print -r -- "$*" }

# Return repo root (empty if not in a git repo)
_w_repo_root() { git rev-parse --show-toplevel 2>/dev/null || true }

# Relpath target relative to base (python3 preferred for portability)
_w_relpath() {
  local target="$1" base="$2"
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$target" "$base" <<'PY'
import os,sys
T,B = sys.argv[1], sys.argv[2]
print(os.path.relpath(T, B))
PY
    return
  fi
  if command -v realpath >/dev/null 2>&1; then
    realpath --relative-to="$base" "$target" 2>/dev/null && return
  fi
  # last-resort fallback
  local t="$target:A" b="$base:A" common="$b" up=""
  while [[ "$t" != "$common"* ]]; do
    common=${common:h}
    up="../$up"
    [[ "$common" == "/" ]] && break
  done
  print -r -- "$up${t#${common}/}"
}

# Compute repo-relative path under projects dir (supports deep trees)
_w_repo_rel_under_projects() {
  local root="$1" projects="${W_PROJECTS_DIR%/}"
  case "$root" in
    ${projects}/*) print -r -- "${root#${projects}/}" ;;
    *) basename -- "$root" ;;
  esac
}

# Resolve repo_root, repo_rel, and worktrees_base; prints exactly 3 lines
_w_where() {
  local repo_root="$1"
  [[ -z "$repo_root" ]] && repo_root=$(_w_repo_root)
  [[ -z "$repo_root" ]] && return 1
  local repo_rel=$(_w_repo_rel_under_projects "$repo_root")
  local wts_base="$W_WORKTREES_DIR/$repo_rel"
  printf "%s\n%s\n%s\n" "$repo_root" "$repo_rel" "$wts_base"
}

# List helpers
_w_list_repo_wts() {
  local base="$1"
  [[ -d "$base" ]] || return 0
  local wt
  for wt in "$base"/*(N/); do
    print -r -- "  • ${wt:t}"
  done
}

_w_list_all_wts() {
  [[ -d "$W_WORKTREES_DIR" ]] || return 0
  set -o null_glob
  local dir
  for dir in "$W_WORKTREES_DIR"/**/*(N/); do
    if [[ -n $(print -l -- "$dir"/*(N/)) ]]; then
      local rel=$(_w_relpath "$dir" "$W_WORKTREES_DIR")
      print -r -- "[$rel]"
      _w_list_repo_wts "$dir"
      print
    fi
  done
  if [[ -n $(print -l -- "$W_WORKTREES_DIR"/*(N/)) ]]; then
    print -r -- "[.]"
    _w_list_repo_wts "$W_WORKTREES_DIR"
    print
  fi
  unsetopt null_glob
}

# Branch helpers
_w_branch_exists_local()  { git show-ref --verify --quiet "refs/heads/$1"; }
_w_branch_exists_remote() { git ls-remote --exit-code --heads origin "$1" >/dev/null 2>&1; }

# Ensure branch exists locally:
# - If only remote exists, fetch it
# - If neither exists, create from current HEAD
_w_ensure_branch() {
  local branch="$1"   # e.g., user/feature-x
  if _w_branch_exists_local "$branch"; then return 0; fi
  if _w_branch_exists_remote "$branch"; then
    git fetch origin "$branch":"$branch" --quiet || return 1
    return 0
  fi
  git branch "$branch" >/dev/null 2>&1 || return 1
}

# Build a branch name from an optional prefix and a leaf.
# - trims leading slash from leaf and trailing slash from prefix
# - if prefix is empty, returns just the leaf
_w_branch_name() {
  local leaf="${1#/}"                     # strip any leading /
  local prefix="${2:-$W_DEFAULT_BRANCH_PREFIX}"
  prefix="${prefix%/}"                    # strip any trailing /
  if [[ -n "$prefix" ]]; then
    print -r -- "${prefix}/${leaf}"
  else
    print -r -- "${leaf}"
  fi
}

# -----------------------
# Core command
# -----------------------
w() {
  emulate -L zsh
  setopt extended_glob

  # If absolutely no args, fail fast before any path logic
  if (( $# == 0 )); then
    _w_die "Usage: w <worktree> [command...] | w --list [--all] | w --rm [--force] <worktree> | w --clean | w --home"
    return 1
  fi

  # Flags
  if [[ "$1" == "--where" ]]; then
    local out=$(_w_where) || return 1
    print -r -- "$out"
    return 0
  elif [[ "$1" == "--list" ]]; then
    shift
    if [[ "$1" == "--all" ]]; then
      _w_info "=== All Worktrees ==="
      _w_list_all_wts
      if [[ -n "$W_SUPPORT_LEGACY_CORE_WTS" && -d "$W_PROJECTS_DIR/core-wts" ]]; then
        _w_info "[core] (legacy)"; _w_list_repo_wts "$W_PROJECTS_DIR/core-wts"; print
      fi
      return 0
    fi
    local out=$(_w_where) || return 1
    local -a parts; parts=(${(f)out})
    local wts_base="${parts[3]}"
    _w_info "=== Worktrees for current repo ==="
    _w_list_repo_wts "$wts_base"
    if [[ -n "$W_SUPPORT_LEGACY_CORE_WTS" && -d "$W_PROJECTS_DIR/core-wts" ]]; then
      print; _w_info "[core] (legacy)"; _w_list_repo_wts "$W_PROJECTS_DIR/core-wts"
    fi
    return 0
  elif [[ "$1" == "--rm" ]]; then
    shift
    local force_flag=""
    if [[ "$1" == "--force" ]]; then
      force_flag="--force"
      shift
    fi
    local worktree="$1"
    if [[ -z "$worktree" ]]; then
      _w_die "Usage: w --rm [--force] <worktree>"
      return 1
    fi
    local out=$(_w_where) || { _w_die "Run inside a git repo"; return 1; }
    local -a parts; parts=(${(f)out})
    local repo_root="${parts[1]}" wts_base="${parts[3]}"
    local wt_path="$wts_base/$worktree"
    [[ -d "$wt_path" ]] || _w_die "Worktree not found: $wt_path"
    (cd "$repo_root" && git worktree remove $force_flag "$wt_path")
    return $?
  elif [[ "$1" == "--clean" ]]; then
    local out=$(_w_where) || { _w_die "Run inside a git repo"; return 1; }
    local -a parts; parts=(${(f)out})
    local repo_root="${parts[1]}" wts_base="${parts[3]}"
    if [[ ! -d "$wts_base" ]]; then
      _w_info "No worktrees to clean"
      return 0
    fi
    local wt count=0
    for wt in "$wts_base"/*(N/); do
      _w_info "Removing worktree: ${wt:t}"
      (cd "$repo_root" && git worktree remove "$wt") && ((count++))
    done
    if (( count > 0 )); then
      _w_info "Cleaned $count worktree(s)"
    else
      _w_info "No worktrees were removed"
    fi
    return 0
  elif [[ "$1" == "--home" ]]; then
    # Find the main repository (not worktree)
    local main_repo
    # First try to get the main worktree from git worktree list
    main_repo=$(git worktree list --porcelain 2>/dev/null | awk '/^worktree / && !seen {print $2; seen=1}')
    if [[ -z "$main_repo" ]]; then
      # Fallback: use current repo root (might be main repo)
      main_repo=$(_w_repo_root)
    fi
    [[ -z "$main_repo" ]] && { _w_die "Could not find main repository"; return 1; }
    _w_info "Returning to main repo: $main_repo"
    cd "$main_repo"
    return 0
  fi

  # Normal usage: w <worktree> [command...]
  local worktree="$1"; shift || true
  if [[ -z "$worktree" ]]; then
    _w_die "Usage: w <worktree> [command...] | w --list [--all] | w --rm [--force] <worktree> | w --clean | w --home"
    return 1
  fi

  local out=$(_w_where) || { _w_die "Run inside a git repo"; return 1; }
  local -a parts; parts=(${(f)out})
  local repo_root="${parts[1]}" repo_rel="${parts[2]}" wts_base="${parts[3]}"

  mkdir -p -- "$wts_base"

  # sanitize leaf used for both branch tail and directory name
  local leaf="$worktree"
  leaf=${leaf// /-}         # spaces -> dashes
  leaf=${leaf#/}            # strip leading slash
  leaf=${leaf//\/\//\/}     # collapse double slashes

  # compute branch name (prefix may be empty -> just 'leaf')
  local branch_name
  branch_name=$(_w_branch_name "$leaf")
  [[ -z "$branch_name" ]] && { _w_die "Empty branch name"; return 1; }

  # optionally validate branch ref format
  if ! git check-ref-format --branch "$branch_name" >/dev/null 2>&1; then
    _w_die "Invalid branch name: $branch_name"
    return 1
  fi

  local wt_path="$wts_base/$leaf"

  if [[ ! -d "$wt_path" ]]; then
    _w_info "Creating worktree: $wt_path (branch: $branch_name)"
    (
      cd "$repo_root" || true
      git fetch --all --prune --quiet || true
      _w_ensure_branch "$branch_name" || exit 1
      git worktree add "$wt_path" "$branch_name" || exit 1
    ) || { _w_die "Failed to create worktree"; return 1; }
  fi

  if (( $# == 0 )); then
    _w_info "Switching to worktree: $wt_path"
    cd "$wt_path"
  else
    local old=$PWD
    cd "$wt_path"
    eval "$*"
    local rc=$?
    cd "$old"
    return $rc
  fi
}

# -----------------------
# Completion (inline)
# -----------------------
_w_complete() {
  emulate -L zsh
  setopt extended_glob
  local curcontext="$curcontext" state line; typeset -A opt_args
  _arguments -C \
    '--where[Show resolved paths]' \
    '--list[List worktrees (repo-local)]' \
    '(-)--rm[Remove a worktree]' \
    '(-)--clean[Remove all worktrees]' \
    '(-)--home[Return to main repo directory]' \
    '1:worktree-or-flag:->pos1' \
    '*::command:->rest' || return 0

  case $state in
    pos1)
      local suggs=( '--where' '--list' '--rm' '--clean' '--home' )
      local out=$(_w_where 2>/dev/null)
      if [[ -n $out ]]; then
        local -a parts; parts=(${(f)out})
        local wts_base="${parts[3]}" wt
        for wt in "$wts_base"/*(N/); do suggs+="${wt:t}"; done
      fi
      _describe -t opts 'options/worktrees' suggs
      ;;
    rest)
      _command_names -e
      ;;
  esac
}
compdef _w_complete w

# -----------------------
# Optional helpers — only define if no alias/function exists with same name
# -----------------------
_w_safe_define_helper() {
  local name="$1"; shift
  if alias -L "$name" &>/dev/null; then return 0; fi
  if typeset -f -- "$name" &>/dev/null; then return 0; fi
  eval "function $name { $* }"
}
_w_safe_define_helper gst  'git -c color.status=always status -sb'
_w_safe_define_helper gaa  'git add -A'
_w_safe_define_helper gcmsg 'git commit -m "$*"'
_w_safe_define_helper gp   'git push'
_w_safe_define_helper gco  'git checkout "$@"'
_w_safe_define_helper gd   'git -c color.diff=always diff "$@"'
_w_safe_define_helper gl   'git -c color.ui=always log --oneline --graph --decorate -n 30'

# End of file