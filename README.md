# in CLI tool

![Demo](.github/assets/demo.gif)

`in` is a lightweight Bash-based CLI tool that allows you to execute commands in directories simultaneously or sequentially. It supports glob patterns, brace expansion, comma-separated lists, and parallel execution.

## Features

- **Flexible Targets**: Specify directories using standard wildcards (`project*`), brace expansion (by shell), comma-separated lists (`front,back`), or exact paths.
- **Parallel Execution**: Run commands concurrently across directories using `-P`.
- **Zero Dependencies**: Pure Bash script (requires Bash 3.2+).
- **Subshell Isolation**: Commands run in subshells, keeping your current working directory intact.

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

## Uninstallation

To remove `in`, delete the executable from your path:

```bash
sudo rm "$(which in)"
```

## Usage

```bash
in [OPTIONS] [DIRECTORIES...] [--] COMMAND...
```

### Options

| Flag | Description |
|------|-------------|
| `-h`, `--help` | Show help message. |
| `-P`, `--parallel N` | Run in parallel with `N` jobs (default: 1). |
| `-s`, `--shell` | Execute command string via shell (enables globbing/pipes). |
| `-v`, `--verbose` | Enable verbose output (debug logs). |

### Examples

```bash
# Git operations
in project* git status
in repos/* git pull

# Package management
in packages/* npm install
in frontend,backend yarn build

# Parallel execution (faster builds)
in -P 4 packages/* pnpm build

# Shell features (pipes, redirects, wildcards inside dir)
# Use -s/--shell and quotes
in -s src/* "ls -l | grep .ts"
in -s logs/* "rm *.old"
in -s ./* "wc -l *.json"
```

### ⚠️ Important Note on Wildcards

When using wildcards (glob patterns) like `*.txt` in your command, your shell (bash/zsh) will try to expand them **before** running `in`.

❌ **Incorrect:** `in projects/* ls *.txt` *Issue:* The shell expands `*.txt` in your *current* directory, not inside `projects/*`. If no txt files exist locally, it might fail or pass the literal string.

✅ **Correct (Standard Mode):** `in projects/* ls my-file.txt` *Works because no wildcards are used.*

✅ **Correct (Shell Mode):** `in -s projects/* "ls *.txt"` *Why:* By quoting `"ls *.txt"` and using `-s`, the wildcard is protected from your current shell and expanded inside each target directory.

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
