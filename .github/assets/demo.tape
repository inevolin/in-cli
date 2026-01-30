# Where to save the output
Output demo.gif

# Window settings
Set FontSize 24
Set Width 1200
Set Height 600

# Setup the environment (hidden from viewer)
Hide
Type "chmod +x in.sh" 
Enter
# Create a fresh demo directory
Type "rm -rf demo_env"
Enter
Type "mkdir demo_env"
Enter
Type "cd demo_env"
Enter
# Copy mock pnpm
Type "cp ../tests/mock_pnpm.sh ./pnpm"
Enter
Type "export PATH=$PWD:$PATH"
Enter
# Alias 'in' to the script in the parent directory so it looks authentic
Type "alias in=../in.sh"
Enter
Type "clear"
Enter
Show

# Scene 1: Batch creation and git init
Type "in --create auth,payment,users git init"
Sleep 800ms
Enter
# Wait for output
Sleep 4s

# Clear for next scene
Type "clear"
Enter

# Scene 2: Parallel execution
Type "# Run build scripts in parallel across directories"
Sleep 1s
Enter
Type "in -P 3 * pnpm build"
Sleep 500ms
Enter
Sleep 2s

# Scene 3: Checking status
Type "in * git status -s"
Sleep 500ms
Enter
Sleep 3s

# Cleanup (hidden)
Hide
Type "cd .."
Enter
Type "rm -rf demo_env"
Enter
