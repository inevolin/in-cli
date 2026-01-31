#!/bin/bash

################################################################################
# test_in.sh - Comprehensive test suite for the 'in' CLI tool
#
# Purpose:
#   Tests all features and edge cases of the 'in' tool including:
#   - Single and multiple directory execution
#   - Glob patterns and comma-separated lists
#   - Parallel execution with -P option
#   - Argument parsing (implicit vs explicit -- separator)
#   - Error handling (missing dirs, no command, etc.)
#
# Usage:
#   ./tests/test_in.sh
#
# Requirements:
#   - Bash 3.2+
#   - in.sh in parent or current directory
################################################################################

# Resolve absolute path to in.sh (works from root or tests directory)
if [[ -f "./in.sh" ]]; then
    IN_TOOL="$(pwd)/in.sh"
elif [[ -f "../in.sh" ]]; then
    IN_TOOL="$(cd .. && pwd)/in.sh"
else
    echo "Error: Could not find in.sh"
    exit 1
fi

TEST_DIR="$(pwd)/tmp_test_env"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

FAILED_TESTS=0

setup() {
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR" || exit 1
}

teardown() {
    cd ..
    rm -rf "$TEST_DIR"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED_TESTS++))
}

assert_exit_code() {
    local expected=$1
    local actual=$2
    local msg="$3"
    if [[ "$expected" != "$actual" ]]; then
        log_fail "$msg (Expected exit code $expected, got $actual)"
        return 1
    else
        log_pass "$msg"
        return 0
    fi
}

assert_file_exists() {
    local file="$1"
    local msg="$2"
    if [[ -f "$file" ]]; then
        log_pass "$msg"
    else
        log_fail "$msg (File $file does not exist)"
    fi
}

assert_dir_exists() {
    local dir="$1"
    local msg="$2"
    if [[ -d "$dir" ]]; then
        log_pass "$msg"
    else
        log_fail "$msg (Directory $dir does not exist)"
    fi
}

assert_output_contains() {
    local output="$1"
    local substring="$2"
    local msg="$3"
    if [[ "$output" == *"$substring"* ]]; then
        log_pass "$msg"
    else
        log_fail "$msg ('$substring' not found in output)"
        # echo "Output was: $output"
    fi
}

assert_output_does_not_contain() {
    local output="$1"
    local substring="$2"
    local msg="$3"
    if [[ "$output" != *"$substring"* ]]; then
        log_pass "$msg"
    else
        log_fail "$msg ('$substring' found in output but shouldn't be)"
    fi
}

# --- Tests ---

test_help() {
    output=$("$IN_TOOL" --help)
    assert_output_contains "$output" "Usage: in" "Help check"
}

test_single_dir() {
    setup
    mkdir dir1
    output=$("$IN_TOOL" dir1 touch worked.txt)
    assert_exit_code 0 $? "Single directory execution"
    assert_file_exists "dir1/worked.txt" "File created in dir1"
}

test_multiple_dirs() {
    setup
    mkdir dir1 dir2
    output=$("$IN_TOOL" dir1 dir2 touch worked.txt)
    assert_exit_code 0 $? "Multiple directory execution"
    assert_file_exists "dir1/worked.txt" "File created in dir1"
    assert_file_exists "dir2/worked.txt" "File created in dir2"
}

test_comma_list() {
    setup
    mkdir dir1 dir2
    output=$("$IN_TOOL" dir1,dir2 touch worked.txt)
    assert_exit_code 0 $? "Comma list execution"
    assert_file_exists "dir1/worked.txt" "File created in dir1"
    assert_file_exists "dir2/worked.txt" "File created in dir2"
}

test_comma_list_with_glob() {
    setup
    mkdir dir1 dir2 dir3
    # "dir[12],dir3"
    output=$("$IN_TOOL" "dir[12],dir3" touch worked.txt)
    assert_exit_code 0 $? "Comma list with glob execution"
    assert_file_exists "dir1/worked.txt" "File created in dir1"
    assert_file_exists "dir2/worked.txt" "File created in dir2"
    assert_file_exists "dir3/worked.txt" "File created in dir3"
}

test_glob_pattern_shell_expansion() {
    setup
    mkdir project_a project_b other
    # Case 1: Shell expands project* -> project_a project_b
    output=$("$IN_TOOL" project* touch worked.txt)
    assert_exit_code 0 $? "Glob shell expansion execution"
    assert_file_exists "project_a/worked.txt" "File created in project_a"
    assert_file_exists "project_b/worked.txt" "File created in project_b"
    if [[ -f "other/worked.txt" ]]; then
       log_fail "Glob matched 'other' incorrectly"
    else
       log_pass "Glob did not match 'other'"
    fi
}

test_glob_pattern_quoted() {
    setup
    mkdir project_a project_b
    # Case 2: Quoted glob passed to tool "project*"
    output=$("$IN_TOOL" "project*" touch worked.txt)
    assert_exit_code 0 $? "Quoted glob expansion execution"
    assert_file_exists "project_a/worked.txt" "File created in project_a"
    assert_file_exists "project_b/worked.txt" "File created in project_b"
}

test_separator() {
    setup
    mkdir dir1
    # Arguments that look like dirs but are part of command
    output=$("$IN_TOOL" dir1 -- echo "hello")
    assert_output_contains "$output" "hello" "Separator usage"
    assert_exit_code 0 $? "Separator exit code"
}

# Tests for create flag removed

test_parallel() {
    setup
    mkdir d1 d2 d3
    
    start_time=$(date +%s)
    # 3 jobs, run sync sleep 1. Seq = 3s. Parallel = 1s.
    output=$("$IN_TOOL" -P 3 d1 d2 d3 sleep 1)
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    assert_exit_code 0 $? "Parallel execution success"
    
    # We allow some overhead. 3s sequential.
    if [[ $duration -lt 3 ]]; then
        log_pass "Parallel execution confirmed ($duration s < 3s)"
    else
        log_fail "Parallel execution took too long ($duration s)"
    fi
}

test_complex_spaces() {
    setup
    mkdir "space dir"
    "$IN_TOOL" "space dir" touch "file with space.txt"
    assert_file_exists "space dir/file with space.txt" "Spaces in directory and filenames"
}

test_implicit_split_heuristic() {
   setup
   mkdir dir1
   # "dir1" is a dir. "echo" is a command. "hello" is arg.
   # Should interpret dir1 as dir.
   output=$("$IN_TOOL" dir1 echo hello)
   assert_output_contains "$output" "hello" "Implicit split heuristic"
}

test_no_args() {
    output=$("$IN_TOOL" 2>&1)
    assert_exit_code 1 $? "No args returns failure"
    assert_output_contains "$output" "Usage: in" "No args shows usage"
}

test_no_command() {
    setup
    mkdir dir1
    output=$("$IN_TOOL" dir1 2>&1)
    assert_exit_code 1 $? "No command returns failure"
    assert_output_contains "$output" "No command specified" "No command error message"
}

test_non_matching_glob() {
    setup
    # Should warn/log but not fail entirely if some match? 
    # Or if ONLY non-matching glob?
    # Logic in in.sh lines 220+: "matched no files".
    # And then lines 240+: if unique_dirs is 0, exit 1.
    
    output=$("$IN_TOOL" nonmatching* ls 2>&1)
    assert_exit_code 1 $? "Non-matching glob failure"
    assert_output_contains "$output" "No valid directories" "Error message content"
}

test_verbose() {
    setup
    mkdir dir1
    output=$("$IN_TOOL" -v dir1 echo hi 2>&1)
    assert_output_contains "$output" "[in] Target directories" "Verbose logging"
}

echo "Running tests against $IN_TOOL..."

# Ensure executable
chmod +x "$IN_TOOL"

test_help
test_single_dir
test_multiple_dirs
test_comma_list
test_comma_list_with_glob
test_glob_pattern_shell_expansion
test_glob_pattern_quoted
test_separator
test_parallel
test_complex_spaces
test_implicit_split_heuristic
test_no_args
test_no_command
test_non_matching_glob
test_verbose

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    teardown
    exit 0
else
    echo -e "${RED}$FAILED_TESTS tests failed.${NC}"
    teardown
    exit 1
fi
