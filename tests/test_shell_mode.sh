#!/bin/bash
# tests/test_shell_mode.sh

# Resolve absolute path to in.sh
if [[ -f "./in.sh" ]]; then
    IN_TOOL="$(pwd)/in.sh"
elif [[ -f "../in.sh" ]]; then
    IN_TOOL="$(cd .. && pwd)/in.sh"
else
    # Fallback to assuming we are in tests/ dir
    IN_TOOL="$(cd .. && pwd)/in.sh"
fi

IN_ABS="$IN_TOOL"

TEST_DIR="tmp_shell_test"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

log_pass() { echo -e "\033[0;32m[PASS]\033[0m $1"; }
log_fail() { echo -e "\033[0;31m[FAIL]\033[0m $1"; exit 1; }

echo "--- Test Shell Mode Glob Expansion ---"
mkdir -p subdir
cd subdir
touch a.webui b.webui c.ignore

# We are in tmp_shell_test/subdir
# We want to run command in ".", matching *.webui

# Standard mode: in . ls *.webui
# If we pass literal *.webui, it fails without shell mode
# (assuming internal ls execution logic)
# Note: quoting "*.webui" prevents the *test runner shell* from expanding it, passing it literally to `in`.

output=$("$IN_ABS" . ls "*.webui" 2>&1)
if [[ "$output" == *"No such file or directory"* ]]; then
    log_pass "Standard mode failed to expand glob (expected)"
else
    # ls might list 'No such file' or literal '*.webui' depending on implementation
    # But effectively it shouldn't match a.webui b.webui
    if [[ "$output" != *"a.webui"* ]]; then
       log_pass "Standard mode did not match a.webui"
    else
       log_fail "Standard mode expanded glob unexpectedly! Output: $output"
    fi
fi

# Implicit Shell Mode (Standard)
# in . "ls *.webui"
# Should work because it's a single argument command string
output=$("$IN_ABS" . "ls *.webui" 2>&1)
if [[ "$output" == *"a.webui"* && "$output" == *"b.webui"* ]]; then
    log_pass "Implicit shell mode expanded glob correctly"
else
    log_fail "Shell mode failed to expand glob. Output: $output"
fi

# Implicit shell mode check 2: Shell operators (pipe)
# in . "echo hello | grep he"
output=$("$IN_ABS" . "echo hello | grep he" 2>&1)
if [[ "$output" == *"hello"* ]]; then
     log_pass "Implicit shell mode handled pipe correctly"
else
     log_fail "Implicit shell mode failed pipe. Output: $output"
fi

cd ../..
rm -rf "$TEST_DIR"
echo "All shell mode tests passed."
