#!/bin/bash

################################################################################
# test_install.sh - Test suite for the install.sh script
#
# Purpose:
#   Tests the installation script in various scenarios including:
#   - Installation to existing directories
#   - Creation of missing directories
#   - User-level installation (no sudo required)
#   - PATH verification warnings
#   - Local and remote installation modes
################################################################################

# Resolve absolute path to install.sh
if [[ -f "./install.sh" ]]; then
    INSTALL_SCRIPT="$(pwd)/install.sh"
elif [[ -f "../install.sh" ]]; then
    INSTALL_SCRIPT="$(cd .. && pwd)/install.sh"
else
    echo "Error: Could not find install.sh"
    exit 1
fi

if [[ -f "./in.sh" ]]; then
    IN_SCRIPT="$(pwd)/in.sh"
elif [[ -f "../in.sh" ]]; then
    IN_SCRIPT="$(cd .. && pwd)/in.sh"
else
    echo "Error: Could not find in.sh"
    exit 1
fi

TEST_DIR="$(pwd)/tmp_install_test"

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

assert_file_exists() {
    local file="$1"
    local msg="$2"
    if [[ -f "$file" ]]; then
        log_pass "$msg"
    else
        log_fail "$msg (File $file does not exist)"
    fi
}

assert_file_executable() {
    local file="$1"
    local msg="$2"
    if [[ -x "$file" ]]; then
        log_pass "$msg"
    else
        log_fail "$msg (File $file is not executable)"
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
    fi
}

# --- Tests ---

test_install_to_existing_dir() {
    setup
    # Create a fake bin directory
    mkdir -p custom_bin
    
    # Copy install.sh and in.sh to test directory
    cp "$INSTALL_SCRIPT" .
    cp "$IN_SCRIPT" .
    
    # Modify install script to use our custom directory
    sed -i.bak 's|CANDIDATE_DIRS=(|CANDIDATE_DIRS=(\n    "'$TEST_DIR'/custom_bin"|' install.sh
    
    # Run install
    output=$(bash install.sh 2>&1)
    
    assert_file_exists "custom_bin/in" "Install to existing directory"
    assert_file_executable "custom_bin/in" "Installed file is executable"
    assert_output_contains "$output" "Successfully installed" "Success message shown"
    
    teardown
}

test_install_creates_user_directory() {
    setup
    
    # Copy scripts
    cp "$INSTALL_SCRIPT" .
    cp "$IN_SCRIPT" .
    
    # Test that the script contains logic to create directories and use .local/bin
    if grep -q 'mkdir -p "$dir"' install.sh && grep -q ".local/bin" install.sh; then
        log_pass "Install script has directory creation logic"
    else
        log_fail "Install script missing directory creation logic"
    fi
    
    teardown
}

test_install_from_local_file() {
    setup
    
    mkdir -p bin
    cp "$INSTALL_SCRIPT" .
    cp "$IN_SCRIPT" .
    
    # Modify to use local bin
    sed -i.bak 's|CANDIDATE_DIRS=(|CANDIDATE_DIRS=(\n    "'$TEST_DIR'/bin"|' install.sh
    
    # Run install (should copy local in.sh)
    output=$(bash install.sh 2>&1)
    
    assert_file_exists "bin/in" "Local file installation"
    assert_output_contains "$output" "Successfully installed" "Success message"
    
    # Verify it's actually the script
    if grep -q "Execute commands on multiple targets" bin/in; then
        log_pass "Installed file contains expected content"
    else
        log_fail "Installed file doesn't contain expected content"
    fi
    
    teardown
}

test_install_download_mode() {
    setup
    
    mkdir -p bin
    cp "$INSTALL_SCRIPT" .
    # Don't copy in.sh - should trigger download mode
    
    # Modify to use local bin
    sed -i.bak 's|CANDIDATE_DIRS=(|CANDIDATE_DIRS=(\n    "'$TEST_DIR'/bin"|' install.sh
    
    # Run install (should attempt download, but will fail without network)
    # We just verify it tries to download
    output=$(bash install.sh 2>&1 || true)
    
    if [[ "$output" == *"Downloading"* ]] || [[ "$output" == *"curl"* ]]; then
        log_pass "Download mode triggered when local file missing"
    else
        log_fail "Download mode not triggered"
    fi
    
    teardown
}

test_path_warning() {
    setup
    
    mkdir -p weird_custom_bin
    cp "$INSTALL_SCRIPT" .
    cp "$IN_SCRIPT" .
    
    # Modify to use a directory definitely not in PATH
    sed -i.bak 's|CANDIDATE_DIRS=(|CANDIDATE_DIRS=(\n    "'$TEST_DIR'/weird_custom_bin"|' install.sh
    
    # Run install
    output=$(bash install.sh 2>&1)
    
    # Should warn about PATH
    assert_output_contains "$output" "not in your PATH" "PATH warning shown"
    assert_output_contains "$output" "export PATH=" "PATH fix suggestion shown"
    
    teardown
}

test_script_syntax() {
    # Just verify install.sh has valid bash syntax
    if bash -n "$INSTALL_SCRIPT" 2>/dev/null; then
        log_pass "Install script has valid syntax"
    else
        log_fail "Install script has syntax errors"
    fi
}

test_installed_script_works() {
    setup
    
    mkdir -p bin
    cp "$INSTALL_SCRIPT" .
    cp "$IN_SCRIPT" .
    
    # Modify to use local bin
    sed -i.bak 's|CANDIDATE_DIRS=(|CANDIDATE_DIRS=(\n    "'$TEST_DIR'/bin"|' install.sh
    
    # Run install
    bash install.sh >/dev/null 2>&1
    
    # Test that installed script actually works
    if [[ -x "bin/in" ]]; then
        output=$(bin/in --help 2>&1)
        assert_output_contains "$output" "Usage: in" "Installed script runs and shows help"
    else
        log_fail "Installed script not executable"
    fi
    
    teardown
}

test_custom_command_name() {
    setup
    
    mkdir -p bin
    cp "$INSTALL_SCRIPT" .
    cp "$IN_SCRIPT" .
    
    # Modify install script to use our custom directory
    sed -i.bak 's|CANDIDATE_DIRS=(|CANDIDATE_DIRS=(\n    "'$TEST_DIR'/bin"|' install.sh
    
    # Run install with custom name argument
    output=$(bash install.sh "indo" 2>&1)
    
    assert_file_exists "bin/indo" "Install with custom name 'indo'"
    assert_file_executable "bin/indo" "Installed 'indo' is executable"
    assert_output_contains "$output" "Successfully installed 'indo'" "Success message for 'indo' shown"
    
    # Check that default 'in' was NOT installed
    if [[ ! -f "bin/in" ]]; then
        log_pass "Default 'in' was NOT installed"
    else
        log_fail "Default 'in' WAS installed (should not be)"
    fi
    
    teardown
}

echo "Running installation tests..."

test_script_syntax
test_install_to_existing_dir
test_install_creates_user_directory
test_install_from_local_file
test_install_download_mode
test_path_warning
test_installed_script_works
test_custom_command_name

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "${GREEN}All installation tests passed!${NC}"
    exit 0
else
    echo -e "${RED}$FAILED_TESTS installation tests failed.${NC}"
    exit 1
fi
