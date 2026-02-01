# in CLI tool

![Demo](.github/assets/demo.gif)

`in` is a lightweight Bash-based CLI tool that allows you to execute commands in directories simultaneously or sequentially. It supports glob patterns, brace expansion, comma-separated lists, and parallel execution.

- **Flexible Targets**: Specify directories using standard wildcards (`project*`), brace expansion (by shell), comma-separated lists (`front,back`), or exact paths.
- **Parallel Execution**: Run commands concurrently across directories using `-P`.
- **Zero Dependencies**: Pure Bash script (requires Bash 3.2+).
- **Subshell Isolation**: Commands run in subshells, keeping your current working directory intact.


## Usage

```bash
in [OPTIONS] [DIRECTORIES...] [--] COMMAND...
```

**Recommendation:** It is optional but highly recommended to **quote your command** string (e.g., `in * "git status"`).

Quoting is **mandatory** if your command contains:
- Shell operators: `&&`, `||`, `;`, `|`, `>`
- Wildcards belonging to the command: `*`, `?` (e.g., `rm *.log`)

### Options

| Flag | Description |
|------|-------------|
| `-d`, `--dry` | Dry run (print commands without executing). |
| `-h`, `--help` | Show help message. |
| `-P`, `--parallel N` | Run in parallel with `N` jobs (default: 1). |
| `-v`, `--verbose` | Enable verbose output (debug logs). |

### Examples

See [EXAMPLES.md](EXAMPLES.md) for 50+ real-world examples.

```bash
# Git operations
in project* git status
in repos/* git pull

# Package management
in packages/* npm install
in frontend,backend yarn build

# Parallel execution (faster builds)
in -P 4 packages/* pnpm build

# Command Chaining (runs in shell automatically when quoted)
in packages/* "pnpm update && git commit -am 'update' && git push"
in services/* "docker build . || echo 'Build failed'"

# Dry Run (Preview what will happen)
in -d packages/* "rm -rf node_modules"

# Shell features (pipes, redirects, wildcards inside dir)
in src/* "ls -l | grep .ts"
in logs/* "rm *.old"
in ./* "wc -l *.json > stats.txt"
```

### Important Note on Wildcards

When using wildcards (glob patterns) like `*.txt` in your command, your shell (bash/zsh) will try to expand them **before** running `in` ⚠️

- ❌ **Incorrect:** `in projects/* ls *.txt` *Issue:* The shell expands `*.txt` in your *current* directory, not inside `projects/*`. If no txt files exist locally, it might fail or pass the literal string.

- ✅ **Correct:** `in projects/* ls my-file.txt` *Works because no wildcards are used.*

- ✅ **Correct:** `in projects/* "ls *.txt"` *Why:* By quoting `"ls *.txt"`, `in` automatically enables shell mode, protecting the wildcard from your current shell so it expands inside each target directory.

## Installation

### Automatic (Recommended)
Run the installer script: 
```bash
curl -sL https://raw.githubusercontent.com/inevolin/in-cli/main/install.sh | bash
```

### Manual
1. Clone the repo or download `in.sh`.
2. Make it executable: `chmod +x in.sh`
3. Move to your path: `sudo mv in.sh /usr/local/bin/in`

## Motivation

While tools like `find` and `xargs` are powerful, constructing correct commands for simple tasks is often cumbersome and error-prone.

**Compare:**

Running `git status` in all subdirectories:

**With `find`:**
```bash
find . -maxdepth 1 -type d -not -name '.' -execdir git status \;
```

**With `xargs`:**
```bash
ls -d */ | xargs -I {} sh -c 'cd {} && git status'
```

**With `in`:**
```bash
in * git status
```

**Why `in` is simpler:**
- **No boilerplate**: Forget about `-maxdepth`, `-execdir`, `-print0`, or complex `xargs` flags.
- **Intuitive**: It works just like running a command, but applied to multiple places.
- **Safety defaults**: Handles directory paths with spaces correctly without arcane flags.
- **Easy Parallelism**: Just add `-P 4` to run 4 jobs at once. Doing this with `xargs` often leads to complex quoting or syntax.

## Uninstallation

To remove `in`, delete the executable from your path:

```bash
sudo rm "$(which in)"
```

## Testing

This project includes a comprehensive test suite covering all features and regressions.

```bash
# Run all tests
./tests/test_in.sh
./tests/test_install.sh
./tests/test_shell_mode.sh
```

## Requirements

- **Shell**: Bash 3.2 or higher
- **Operating Systems**: 
  - Linux (all distributions)
  - macOS 10.5+
  - BSD systems (FreeBSD, OpenBSD, NetBSD)
  - Windows (via WSL, Git Bash, or Cygwin)
- **Dependencies**: None (pure Bash)

## Contributing

Contributions are welcome! Feel free to open a pull request with improvements, bug fixes, or new features.

## License

MIT License. See [LICENSE](LICENSE) for details.
