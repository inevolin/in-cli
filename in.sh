#!/usr/bin/env bash

# in.sh - Execute commands in multiple directories
#
# Usage: in [OPTIONS] [DIRECTORIES...] [--] COMMAND...
#
# M.I.T License

set -u

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
create_dirs=0
dry_run=0
verbose=0

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
    echo "  -c, --create  Create directories if they don't exist"
    echo "  -P, --parallel N  Run in parallel with N jobs (default: 1)"
    echo "  -v, --verbose Show verbose output"
    echo
    echo "Examples:"
    echo "  in project* git status"
    echo "  in frontend,backend npm install"
    echo "  in --create new-project git init"
    echo "  in -P 4 repos/* git pull"
}

log() {
    if [[ $verbose -eq 1 ]]; then
        echo -e "${dray}[in] $1${NC}" >&2
    fi
}

error() {
    echo -e "${RED}[error] $1${NC}" >&2
}

info() {
    echo -e "${BLUE}[in] $1${NC}"
}

success() {
    echo -e "${GREEN}✔ $1${NC}"
}

# Parse options
# We handle long options manually or use simple getopts
# Since we have mixed args (dirs and command), standard getopts is easiest for flags
# but we need to handle the non-flag args carefully.

# Transform long options to short ones
for arg in "$@"; do
  shift
  case "$arg" in
    "--help") set -- "$@" "-h" ;;
    "--create") set -- "$@" "-c" ;;
    "--parallel") set -- "$@" "-P" ;;
    "--verbose") set -- "$@" "-v" ;;
    *) set -- "$@" "$arg" ;;
  esac
done

OPTIND=1
while getopts "hcP:v" opt; do
    case "$opt" in
    h)
        print_usage
        exit 0
        ;;
    c)
        create_dirs=1
        ;;
    P)
        parallelism=$OPTARG
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

shift $((OPTIND - 1))

if [[ $# -eq 0 ]]; then
    print_usage
    exit 1
fi

# Separate directories from command
# Heuristic: Scan args.
# - If "--" is found, everything before is dirs, after is cmd.
# - Else, consume args as dirs as long as matches heuristic:
#   - Exists as dir
#   - Contains comma (list)
#   - Contains glob char (*, ?, [, ]) (pattern string)
#   - Or if --create is set AND it's the specific arg index?
#     For "in --create newdir cmd", newdir doesn't exist.
#     Simple heuristic:
#     - If arg is existing dir -> DIR
#     - If arg has comma -> DIR
#     - If arg has glob -> DIR
#     - If create_dirs=1 AND we haven't found a command yet AND it looks like a path (no spaces? not a standard command?) => Let's just assume strict split if ambiguous.
#     The most robust implicit split:
#     - Consume until first Non-Dir/Non-Pattern arg.
#     - Special case: If create_dirs is set, accept the *first* argument as a dir even if missing.

raw_dirs=()
command_args=()
split_found=0

# Check for explicit separator '--'
args=("$@")
explicit_split_index=-1
for ((i=0; i<$#; i++)); do
    if [[ "${args[i]}" == "--" ]]; then
        explicit_split_index=$i
        break
    fi
done

if [[ $explicit_split_index -ge 0 ]]; then
    # explicit split
    for ((i=0; i<$explicit_split_index; i++)); do
        raw_dirs+=("${args[i]}")
    done
    # command is everything after
    for ((i=$explicit_split_index+1; i<$#; i++)); do
        command_args+=("${args[i]}")
    done
else
    # implicit split
    parsing_dirs=1
    for arg in "$@"; do
        if [[ $parsing_dirs -eq 1 ]]; then
            is_dir_spec=0
            
            # 1. Existing directory?
            if [[ -d "$arg" ]]; then 
                is_dir_spec=1
            fi
            
            # 2. Comma list?
            if [[ "$arg" == *","* ]]; then
                is_dir_spec=1
            fi

            # 3. Glob pattern? (Very naive check if user passed quoted glob)
            if [[ "$arg" == *"*"* ]] || [[ "$arg" == *"?"* ]] || [[ "$arg" == *"["* ]]; then
                is_dir_spec=1
            fi

            # 4. Create flag special case: First arg is assumed dir if --create passed
            if [[ $create_dirs -eq 1 && ${#raw_dirs[@]} -eq 0 ]]; then
                is_dir_spec=1
            fi

            if [[ $is_dir_spec -eq 1 ]]; then
                raw_dirs+=("$arg")
            else
                parsing_dirs=0
                command_args+=("$arg")
            fi
        else
            command_args+=("$arg")
        fi
    done
fi

if [[ ${#raw_dirs[@]} -eq 0 ]]; then
    error "No target directories specified."
    exit 1
fi

if [[ ${#command_args[@]} -eq 0 ]]; then
    error "No command specified."
    exit 1
fi

# Resolve directories
target_dirs=()

for raw in "${raw_dirs[@]}"; do
    # 1. Handle comma separated
    IFS=',' read -ra PARTS <<< "$raw"
    for part in "${PARTS[@]}"; do
        # 2. Expand globs (if passed as string or just raw part)
        # Note: If shell expanded globs, we got them as separate args in raw_dirs already.
        # This handles quoted globs or globs resulting from comma split (e.g. "dir1,dir*")
        
        # Check if part contains wildcards
        if [[ "$part" == *"*"* ]] || [[ "$part" == *"?"* ]] || [[ "$part" == *"["* ]]; then
             # Try to expand
             # We use compgen or just loop
             expanded=( $part )
             if [[ "${expanded[0]}" == "$part" && ! -e "$part" && $create_dirs -eq 0 ]]; then
                 # Expansion failed / no match
                 log "Pattern '$part' matched no files."
             else
                 for e in "${expanded[@]}"; do
                    # Only add if directory or if we are creating
                    if [[ -d "$e" ]] || [[ $create_dirs -eq 1 ]]; then
                        target_dirs+=("$e")
                    fi
                 done
             fi
        else
            target_dirs+=("$part")
        fi
    done
done

# Deduplicate directories
# (Simple awk dedup preserving order)
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

run_command() {
    local dir="$1"
    shift
    local cmd=("$@")
    
    # Check/Create dir
    if [[ ! -d "$dir" ]]; then
        if [[ $create_dirs -eq 1 ]]; then
            info "Creating directory: $dir"
            mkdir -p "$dir" || { error "Failed to create $dir"; return 1; }
        else
            error "Directory not found: $dir"
            return 1
        fi
    fi

    # Run
    # Use subshell
    (
        cd "$dir" || exit 1
        
        # Verbose header
        if [[ $parallelism -eq 1 ]]; then
             echo -e "${YELLOW}in ${dir} \$ ${NC}${cmd[*]}"
        else
             # For parallel, output might interleave, so implies simpler output or buffered?
             # For now, just print.
             echo -e "${YELLOW}[$dir]${NC} running..."
        fi

        "${cmd[@]}"
    )
}

# Function to manage parallel execution
run_parallel() {
    local max=$parallelism
    local active=0
    local pids=()
    
    for d in "${unique_dirs[@]}"; do
        run_command "$d" "${command_args[@]}" &
        pids+=($!)
        ((active++))

        if [[ $active -ge $max ]]; then
            wait -n 2>/dev/null || wait # wait -n bash 4.3+, fallback
            ((active--))
        fi
    done
    wait
}

if [[ $parallelism -gt 1 ]]; then
    run_parallel
else
    for d in "${unique_dirs[@]}"; do
        run_command "$d" "${command_args[@]}"
    done
fi
