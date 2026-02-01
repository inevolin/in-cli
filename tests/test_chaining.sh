#!/bin/bash
# tests/test_chaining.sh

# Resolve absolute path to in.sh
if [[ -f "./in.sh" ]]; then
    IN_TOOL="$(pwd)/in.sh"
elif [[ -f "../in.sh" ]]; then
    IN_TOOL="$(cd .. && pwd)/in.sh"
else
    IN_TOOL="$(cd .. && pwd)/in.sh"
fi

IN_ABS="$IN_TOOL"
TEST_DIR="tmp_chain_test"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

log_pass() { echo -e "\033[0;32m[PASS]\033[0m $1"; }
log_fail() { echo -e "\033[0;31m[FAIL]\033[0m $1"; exit 1; }

echo "--- Test Command Chaining and Operators ---"

mkdir -p dir_chain
cd dir_chain

# Test 1: && (AND) operator
# Requirement: implicit shell mode should handle && if quoted
echo "Testing && operator..."
"$IN_ABS" . "touch a && touch b" > /dev/null
if [[ -f "a" && -f "b" ]]; then
    log_pass "&& operator executed both commands inverted"
else
    log_fail "&& operator failed. a: $([ -f a ] && echo yes), b: $([ -f b ] && echo yes)"
fi

# Clean up
rm a b 2>/dev/null

# Test 2: && operator short-circuit
# If first fails, second should not run
echo "Testing && short-circuit..."
"$IN_ABS" . "false && touch c" > /dev/null
if [[ ! -f "c" ]]; then
    log_pass "&& operator short-circuited correctly (c not created)"
else
    log_fail "&& operator did NOT short-circuit (c created)"
fi

# Test 3: || (OR) operator
# If first succeeds, second should not run
echo "Testing || short-circuit..."
"$IN_ABS" . "true || touch d" > /dev/null
if [[ ! -f "d" ]]; then
    log_pass "|| operator short-circuited correctly (d not created)"
else
    log_fail "|| operator did NOT short-circuit (d created)"
fi

# Test 4: || operator failover
# If first fails, second should run
echo "Testing || failover..."
"$IN_ABS" . "false || touch e" > /dev/null
if [[ -f "e" ]]; then
    log_pass "|| operator failed over correctly (e created)"
else
    log_fail "|| operator did NOT fail over (e not created)"
fi

# Test 5: ; (SEMICOLON) operator
# Both should run regardless
echo "Testing ; operator..."
"$IN_ABS" . "false; touch f" > /dev/null
if [[ -f "f" ]]; then
    log_pass "; operator executed subseq command correctly"
else
    log_fail "; operator failed"
fi

# Test 6: Environment variables inside string (Single Quotes vs Double Quotes behavior)
# This tests that the script doesn't mangle variables passed to it.
# Note: We rely on the caller shell to handle quoting, but we verify `eval` respects it.

echo "Testing variables..."
# Pass literal '$VAR' to script (using single quotes in calling shell)
# in . 'export VAR=hello; echo $VAR > g'
"$IN_ABS" . 'export VAR=hello; echo $VAR > g' > /dev/null
if [[ "$(cat g)" == "hello" ]]; then
    log_pass "Variable expansion inside eval worked"
else
    log_fail "Variable expansion failed. Content of g: $(cat g)"
fi

# Test 7: Redirection >
# Already used implicitly above, but explicit check
echo "Testing redirection >..."
"$IN_ABS" . "echo content > h" > /dev/null
if [[ "$(cat h)" == "content" ]]; then
    log_pass "Redirection > worked"
else
    log_fail "Redirection > failed"
fi

# Test 8: Quotes inside quotes
# in . "echo 'quoted string' > i"
echo "Testing nested quotes..."
"$IN_ABS" . "echo 'quoted string' > i" > /dev/null
if [[ "$(cat i)" == "quoted string" ]]; then
    log_pass "Nested quotes preserved"
else
    log_fail "Nested quotes failed. Content of i: $(cat i)"
fi

# Test 9: Complex chaining
echo "Testing complex chain..."
"$IN_ABS" . "touch j && echo 'success' > k || echo 'fail' > k" > /dev/null
if [[ -f "j" && "$(cat k)" == "success" ]]; then
    log_pass "Complex chain (&& and ||) worked"
else
    log_fail "Complex chain failed"
fi

cd ../..
rm -rf "$TEST_DIR"
echo "All chaining tests passed."
