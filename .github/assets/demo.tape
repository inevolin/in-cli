# demo.tape - VHS recording script for 'in' CLI promotional GIF
#
# Usage: vhs .github/assets/demo.tape (run from repository root)
#

# Output configuration
Output .github/assets/demo.gif

# Terminal appearance settings
Set FontSize 24
Set Width 1200
Set Height 360
Set Padding 20

# Setup the environment (hidden from viewer)
Hide
Type "chmod +x in.sh" 
Enter
# Create a fresh demo directory
Type "rm -rf demo_env"
Enter
Type "mkdir -p demo_env/packages"
Enter
# Move to workspace
Type "cd demo_env/packages"
Enter
# Create subdirectories
Type "mkdir auth-service payment-service user-service"
Enter
# Alias 'in' to the script in the root directory
Type "alias in=../../in.sh"
Enter
Type "clear"
Enter
Show

# Scene 1: Batch File Operations
Type "# Create config files in all service directories"
Sleep 500ms
Enter
Type "in *-service touch .env"
Sleep 800ms
Enter
Sleep 3s

# Clear for next scene
Type "clear"
Enter

# Scene 2: Parallel Execution
Type "# Run build scripts in parallel"
Sleep 500ms
Enter
Type "in -P 3 * bash -c 'echo building...; sleep 0.5'"
Sleep 800ms
Enter
Sleep 3s

# Clear for next scene
Type "clear"
Enter

# Scene 3: Shell Features
Type "# Execute complex shell commands (pipes, wildcards)"
Sleep 500ms
Enter
Type "in -s * 'ls -a | grep .env'"
Sleep 800ms
Enter
Sleep 3s

# Cleanup (hidden)
Hide
Type "cd ../.."
Enter
Type "rm -rf demo_env"
Enter
