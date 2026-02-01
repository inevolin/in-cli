#!/bin/bash

# tests.sh - Run all tests in the tests/ directory

FAILED=0

# Ensure we are running from the root of the repo
cd "$(dirname "$0")" || exit 1

echo "Starting test suite..."
echo

for t in tests/*.sh; do
    # Skip non-executable files if any match (though glob matches .sh)
    [ -f "$t" ] || continue
    
    echo "--------------------------------------------------------------------------------"
    echo "Running $t"
    echo "--------------------------------------------------------------------------------"
    
    # Run the test script
    # We use ./ explicitly
    if ./"$t"; then
        echo "✔ $t passed"
        echo
    else
        echo "✘ $t FAILED"
        echo
        FAILED=1
    fi
done

if [[ $FAILED -eq 0 ]]; then
    echo "=========================================="
    echo "All tests passed successfully!"
    echo "=========================================="
    exit 0
else
    echo "=========================================="
    echo "Some tests failed. Check logs above."
    echo "=========================================="
    exit 1
fi
