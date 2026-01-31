#!/usr/bin/env bash

################################################################################
# in.sh - Execute commands on multiple targets (files or directories)
#
# Purpose:
#   A lightweight CLI tool that runs shell commands across multiple targets
#   simultaneously or in parallel. Supports glob patterns, comma-separated lists,
#   auto-creation of directories, and parallel execution.
#
# Usage:
#   in [OPTIONS] [DIRECTORIES...] [--] COMMAND...
#
# Features:
#   - Flexible directory targeting (globs, comma lists, exact paths)
#   - Parallel execution with -P option
#   - Subshell isolation (doesn't change your current directory)
#   - Compatible with Bash 3.2+
#
# License: MIT
# Repository: https://github.com/inevolin/in-cli
################################################################################

set -u  # Exit on undefined variables

version="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
dray='\033[1;30m'
NC='\033[0m' # No Color

# Default settings
parallelism=1
dry_run=0
verbose=0
shell_mode=0

print_usage() {
    echo "Usage: in [OPTIONS] [DIRECTORIES...] [--] COMMAND..."
    echo
    echo "Run a command in one or more directories."
    echo
    echo "Arguments:"
    echo "  DIRECTORIES   Glob patterns, comma-separated lists, or direct paths."
    echo "  COMMAND       The command to run in each directory."
    echo
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo "  -P, --parallel N  Run in parallel with N jobs (default: 1)"
    echo "  -s, --shell       Execute command via shell (enables globs/pipes)"
    echo "  -v, --verbose Show verbose output"
    echo
    echo "Examples:"
    echo "  in project* git status"
    echo "  in frontend,backend npm install"
    echo "  in -P 4 repos/* git pull"
    echo "  in -s repos/* 'ls *.json'   (expand globs inside directory)"
}

log() {
    if [[ $verbose -eq 1 ]]; then
        echo -e "${dray}[in] $1${NC}" >&2
    fi
}

error() {
    echo -e "${RED}[error] $1${NC}" >&2
}

warn() {
    echo -e "${YELLOW}[warning] $1${NC}" >&2
}

info() {
    echo -e "${BLUE}[in] $1${NC}"
}

success() {
    echo -e "${GREEN}✔ $1${NC}"
}

################################################################################
# Option Parsing
# We transform long options (--help) to short ones (-h) for getopts compatibility,
# then use getopts to parse flags. This allows both -c and --create syntax.
################################################################################

# Transform long options to short ones for getopts
for arg in "$@"; do
  shift
  case "$arg" in
    "--help") set -- "$@" "-h" ;;
    "--parallel") set -- "$@" "-P" ;;
    "--shell") set -- "$@" "-s" ;;
    "--verbose") set -- "$@" "-v" ;;
    *) set -- "$@" "$arg" ;;
  esac
done

OPTIND=1
while getopts "hP:sv" opt; do
    case "$opt" in
    h)
        print_usage
        exit 0
        ;;
    P)
        parallelism=$OPTARG
        ;;
    s)
        shell_mode=1
        ;;
    v)
        verbose=1
        ;;
    *)
        print_usage
        exit 1
        ;;
    esac
done

shift $((OPTIND - 1))  # Remove parsed flags from argument list

if [[ $# -eq 0 ]]; then
    print_usage
    exit 1
fi

################################################################################
# Argument Separation (Directories vs Command)
#
# Challenge: Distinguish between directory arguments and command arguments.
# Example: "in dir1 dir2 git pull" - where do dirs end and command begin?
#
# Solution: Two modes:
#   1. Explicit mode: Use "--" separator (e.g., "in dir1 dir2 -- git pull")
#   2. Implicit mode: Auto-detect based on heuristics:
#      - Existing directories
#      - Patterns containing commas (dir1,dir2)
#      - Glob characters (*, ?, [)
#      - First arg when --create is used (even if it doesn't exist)
################################################################################

raw_dirs=()
command_args=()
split_found=0

# Check for explicit separator "--"
args=("$@")
explicit_split_index=-1
for ((i=0; i<$#; i++)); do
    if [[ "${args[i]}" == "--" ]]; then
        explicit_split_index=$i
        break
    fi
done

if [[ $explicit_split_index -ge 0 ]]; then
    # Explicit mode: Everything before "--" is directories, after is command
    for ((i=0; i<$explicit_split_index; i++)); do
        raw_dirs+=("${args[i]}")
    done
    for ((i=$explicit_split_index+1; i<$#; i++)); do
        command_args+=("${args[i]}")
    done
else
    # Implicit mode: Use heuristics to detect where directories end
    parsing_dirs=1
    for arg in "$@"; do
        if [[ $parsing_dirs -eq 1 ]]; then
            is_dir_spec=0
            
            # Heuristic 1: Is it an existing file/directory OR a symlink?
            # We treat all existing paths as potential targets.
            # We also include broken symlinks (-L) to prevent them from being mistaken for commands.
            # Directories are kept; files/links are filtered out and warned about later.
            if [[ -e "$arg" || -L "$arg" ]]; then 
                is_dir_spec=1
            fi
            
            # Heuristic 2: Contains comma? (e.g., "dir1,dir2,dir3")
            if [[ "$arg" == *","* ]]; then
                is_dir_spec=1
            fi

            # Heuristic 3: Contains glob characters? (*, ?, [)
            # Handles quoted globs like "project*" that shell didn't expand
            if [[ "$arg" == *"*"* ]] || [[ "$arg" == *"?"* ]] || [[ "$arg" == *"["* ]]; then
                is_dir_spec=1
            fi

            # Heuristic 4: --create flag special case
            # Removed (feature removed)

            # Apply the verdict: Is this arg a target spec or start of command?
            if [[ $is_dir_spec -eq 1 ]]; then
                raw_dirs+=("$arg")
            else
                # First non-target arg marks start of command
                parsing_dirs=0
                command_args+=("$arg")
            fi
        else
            # Already in command mode, add all remaining args
            command_args+=("$arg")
        fi
    done
fi

# Validate we have both directories and a command
if [[ ${#raw_dirs[@]} -eq 0 ]]; then
    error "No target directories specified."
    exit 1
fi

if [[ ${#command_args[@]} -eq 0 ]]; then
    error "No command specified."
    exit 1
fi

################################################################################
# Directory Resolution
# Expands comma-separated lists and glob patterns into actual directory paths.
# Example: "dir1,dir*" becomes ["dir1", "dir2", "dir3"] if those exist.
################################################################################
target_dirs=()

for raw in "${raw_dirs[@]}"; do
    # Step 1: Split comma-separated directory lists
    # Example: "dir1,dir2,dir3" → ["dir1", "dir2", "dir3"]
    IFS=',' read -ra PARTS <<< "$raw"
    
    for part in "${PARTS[@]}"; do
        # Step 2: Expand glob patterns
        # Note: If the shell already expanded globs (unquoted), we got separate args.
        # This handles quoted globs like "project*" or globs from comma splits like "dir1,proj*"
        
        if [[ "$part" == *"*"* ]] || [[ "$part" == *"?"* ]] || [[ "$part" == *"["* ]]; then
            # Contains wildcard characters - attempt glob expansion
            expanded=( $part )  # Let bash expand the pattern
            
            if [[ "${expanded[0]}" == "$part" && ! -e "$part" ]]; then
                # Expansion failed (no matches) and --create not set
                log "Pattern '$part' matched no files."
            else
                # Expansion succeeded
                for e in "${expanded[@]}"; do
                    # Add directories only
                    if [[ -d "$e" ]]; then
                        target_dirs+=("$e")
                    elif [[ -f "$e" ]]; then
                        warn "Ignoring file '$e' (only directories are supported)."
                    elif [[ -L "$e" ]]; then
                        warn "Ignoring broken symlink '$e'."
                    fi
                 done
             fi
        else
            # No wildcards - add as-is if directory or creating
            if [[ -d "$part" ]]; then
                target_dirs+=("$part")
            elif [[ -f "$part" ]]; then
                warn "Ignoring file '$part' (only directories are supported)."
            elif [[ -L "$part" ]]; then
                warn "Ignoring broken symlink '$part'."
            else
                 # If it doesn't exist...
                 target_dirs+=("$part")
            fi
        fi
    done
done

# Deduplicate targets while preserving order
# Example: ["dir1", "dir2", "dir1"] → ["dir1", "dir2"]
# Uses awk to track seen entries and only print first occurrence
if [[ ${#target_dirs[@]} -gt 0 ]]; then
    unique_dirs=()
    while IFS= read -r line; do
        unique_dirs+=("$line")
    done < <(printf "%s\n" "${target_dirs[@]}" | awk '!x[$0]++')
else
    unique_dirs=()
fi

if [[ ${#unique_dirs[@]} -eq 0 ]]; then
    error "No valid directories found."
    exit 1
fi

log "Target directories: ${unique_dirs[*]}"
log "Command: ${command_args[*]}"

################################################################################
# Command Execution
# Runs the specified command in each target directory using subshells.
# Supports both sequential and parallel execution modes.
################################################################################

run_command() {
    local target="$1"
    shift
    local cmd=("$@")
    
    # Mode 1: Directory Target
    if [[ -d "$target" ]]; then
        # Execute command in subshell (CD into directory)
        (
            cd "$target" || exit 1
            
            # Print execution header
            if [[ $parallelism -eq 1 ]]; then
                echo -e "${YELLOW}in ${target} \$ ${NC}${cmd[*]}"
            else
                echo -e "${YELLOW}[${target}]${NC} running..."
            fi

            if [[ $shell_mode -eq 1 ]]; then
                # Join args with spaces and execute via shell
                # This allows globs like "*.txt" to be expanded inside the directory
                eval "${cmd[*]}"
            else
                "${cmd[@]}"
            fi
        )
    else
        error "Target directory not found: $target"
        return 1
    fi
}

################################################################################
# Parallel Execution Manager
# Limits concurrent processes to the specified parallelism level.
# Uses background jobs (&) and wait to manage process pool.
################################################################################

run_parallel() {
    local max=$parallelism
    local active=0
    local pids=()
    
    for d in "${unique_dirs[@]}"; do
        # Start command in background
        run_command "$d" "${command_args[@]}" &
        pids+=($!)
        ((active++))

        # If we hit the parallelism limit, wait for one job to finish
        if [[ $active -ge $max ]]; then
            wait -n 2>/dev/null || wait  # wait -n requires Bash 4.3+, fallback to wait
            ((active--))
        fi
    done
    # Wait for all remaining background jobs to complete
    wait
}

################################################################################
# Main Execution
# Choose between parallel or sequential execution based on -P flag
################################################################################

if [[ $parallelism -gt 1 ]]; then
    # Parallel mode: Run commands concurrently with process pool
    run_parallel
else
    # Sequential mode: Run commands one directory at a time
    for d in "${unique_dirs[@]}"; do
        run_command "$d" "${command_args[@]}"
    done
fi
