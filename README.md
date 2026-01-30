# in CLI tool

![Demo](.github/assets/demo.gif)

`in` is a lightweight Bash-based CLI tool that allows you to execute commands in directories simultaneously or sequentially. It supports glob patterns, brace expansion, comma-separated lists, directory auto-creation, and parallel execution.

## Features

- **Flexible Targets**: Specify directories using standard wildcards (`project*`), brace expansion (by shell), comma-separated lists (`front,back`), or exact paths.
- **Auto-creation**: Optionally create directories if they don't exist (`--create`).
- **Parallel Execution**: Run commands concurrently across directories using `-P`.
- **Zero Dependencies**: Pure Bash script (requires Bash 4+).
- **Subshell Isolation**: Commands run in subshells, keeping your current working directory intact.

## Installation

### Automatic
Run the installer script:
```bash
curl -sL https://raw.githubusercontent.com/inevolin/in-cli/main/install.sh | bash
```

### Manual
1. Clone the repo or download `in.sh`.
2. Make it executable:
   ```bash
   chmod +x in.sh
   ```
3. Move to your path:
   ```bash
   sudo mv in.sh /usr/local/bin/in
   ```

## Usage

```bash
in [OPTIONS] [DIRECTORIES...] [--] COMMAND...
```

### Examples

**Run `git pull` in all matching project directories:**
```bash
in project* git pull
```

**Run `npm install` in frontend and backend:**
```bash
in frontend,backend npm install
```

**Create a new directory and initialize a git repo inside it:**
```bash
in --create new-lib git init
```

**Run `pnpm build` in 4 directories in parallel:**
```bash
in -P 4 repos/* pnpm build
```

**Use `--` to handle ambiguous arguments or filenames:**
```bash
in dir1 dir2 -- grep -r "TODO" .
```

### Options

| Flag | Description |
|------|-------------|
| `-h`, `--help` | Show help message. |
| `-c`, `--create` | Create directories if they do not exist. |
| `-P`, `--parallel N` | Run in parallel with `N` jobs (default: 1). |
| `-v`, `--verbose` | Enable verbose output (debug logs). |

## License

MIT License. See [LICENSE](LICENSE) for details.
