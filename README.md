# dev-env

Infrastructure-as-Code easy environment setup for Windows + WSL2 development machine.

Allows to easily restart from a fresh machine: install WSL2, clone one repository, run one command, and have complete development environment back in ~10 minutes.

```
Windows (desktop only)
│
├── VS Code, Windows Terminal, Browser, Docker Desktop (optional)
├── Linear, Obsidian, SourceTree, Postman (quality of life)
│
└── WSL2 Ubuntu
    │
    ├── zsh + Oh My Zsh + Powerlevel10k
    ├── mise (language + CLI versions)
    ├── uv (Python project environments)
    ├── Homebrew (extra Linux CLI formulae)
    ├── AWS CLI, kubectl, helm, k9s, terraform
    ├── C/C++ toolchain (apt)
    └── ~/code
```

Everything development-related lives inside **WSL2**.

---

## Fresh Machine Setup (Exact Steps)

### Part 1 — Windows (one-time, manual)

Run these in **PowerShell as Administrator**:

```powershell
# Enable WSL2 and install Ubuntu
wsl --install -d Ubuntu

# Ensure WSL2 is the default
wsl --set-default-version 2

# Verify (VERSION should be 2)
wsl -l -v
```

Restart if prompted. Open **Ubuntu** from the Start menu and create your Linux username/password.

#### Windows apps (manual install)

| App | Purpose |
|-----|---------|
| [VS Code](https://code.visualstudio.com/) | Editor (use Remote - WSL) |
| [Windows Terminal](https://aka.ms/terminal) | Terminal |
| Browser | Docs, dashboards |
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | Containers (optional) |
| [Linear](https://linear.app/) | Issue tracking |
| [Obsidian](https://obsidian.md/) | Notes |
| [SourceTree](https://www.sourcetreeapp.com/) | Git GUI |
| [Postman](https://www.postman.com/) | API testing |

**VS Code extensions (recommended):**

- Remote - WSL
- Python, Ruff
- Go
- Java Extension Pack
- C/C++
- Docker
- YAML, Kubernetes

Enable Docker Desktop WSL integration: **Settings → Resources → WSL Integration → Ubuntu**.

---

### Part 2 — WSL2 Ubuntu (automated)

Open Ubuntu and run:

```bash
# 1. Update base system
sudo apt update && sudo apt upgrade -y

# 2. Install git if missing
sudo apt install -y git

# 3. Clone this repo (recommended location)
cd ~
git clone https://github.com/dfoshidero/dev-env.git
cd dev-env

# 4. Run the installer
chmod +x install.sh
./install.sh
```

The installer will:

1. Ask which languages to install (Python, Node.js, Go, Java, C/C++ toolchain) — press **Enter** to accept the default (`Y`) for each
2. Install apt packages (build tools, git, zsh, fzf, etc.)
3. Set up zsh, Oh My Zsh, and Powerlevel10k (theme, fonts, and terminal config)
4. Link dotfiles into `$HOME`
5. Install mise and selected tool versions from `config/mise.toml`
6. Install uv (if Python selected), Homebrew (Linux CLI formulae), AWS CLI, Kubernetes tools
7. Create `~/code` folder structure
8. Configure Git (prompts for name/email) and SSH keys
9. Verify installations
10. Optionally run language smoke tests

Powerlevel10k setup installs the Meslo Nerd Font and configures Windows Terminal and VS Code. The repo no longer ships a prebuilt `~/.p10k.zsh`, so the Powerlevel10k configuration wizard runs automatically the first time zsh starts — follow its prompts to generate your own `~/.p10k.zsh`. You can re-run `p10k configure` anytime to change the style. Close and reopen terminal tabs after install if glyphs still look wrong.

Example language prompts:

```bash
Install Python? [Y/n]: y
Install Node.js? [Y/n]: n
Install Go? [Y/n]: y
Install Java? [Y/n]: n
Install C/C++ toolchain? [Y/n]: y
```

Skipped languages are not installed, verified, or smoke-tested. Shared CLI tools (`kubectl`, `helm`, `k9s`, `terraform`) are always installed.

After install, the installer automatically restarts your shell into zsh, which launches the Powerlevel10k configuration wizard on first run so you can build your prompt. New WSL sessions also open in `~` instead of `/mnt/c/Users/...` (Windows Terminal's default).

Want to reconfigure your prompt later?

```bash
p10k configure
```

Open a project from WSL:

```bash
cd ~/code/personal/my-project
code .
```

---

## Repository Structure

```
dev-env/
├── install.sh              # Single entrypoint
├── bootstrap.sh            # Shared helpers
├── config/
│   ├── mise.toml           # Global tool versions
│   ├── apt-packages.txt    # Ubuntu packages
│   ├── folders.txt         # ~/code layout
│   └── gitconfig           # Non-secret Git defaults
├── dotfiles/               # Shell config (symlinked to ~)
├── scripts/                # Focused installers
├── templates/              # Project scaffolds
└── tests/                  # Post-install smoke tests
```

---

## Updating Your Environment

### Change a tool version

Edit `config/mise.toml`:

```toml
[tools]
node = "22"    # change to "24" when ready
python = "3.13"
```

Then on any machine:

```bash
cd ~/dev-env
git pull
./install.sh
# or just:
mise install
```

### Add an apt package

Add to `config/apt-packages.txt`, then:

```bash
./install.sh
```

### Add a shell alias

Edit `dotfiles/aliases.zsh`, commit, push, pull on other machines. Re-run `./install.sh` to refresh symlinks.

---

## Environment Model

| Layer | Managed by | Location |
|-------|-----------|----------|
| Machine setup | this repo | `~/dev-env` |
| Language versions | mise | `~/.config/mise/config.toml` |
| Python venvs | uv | per-project `.venv/` |
| Node frameworks | npm/pnpm | per-project `node_modules/` |
| AWS credentials | you | `~/.aws/` |
| Kubeconfig | you | `~/.kube/config` |
| Project overrides | you | `.mise.toml`, `pyproject.toml`, etc. |

### Local secrets and work config

Tokens, PATs, and work-specific paths from your old shell config belong in `~/.dev-env-local.zsh`, not in this repo:

```bash
cp ~/dev-env/dotfiles/dev-env-local.example.zsh ~/.dev-env-local.zsh
# edit ~/.dev-env-local.zsh with your tokens and paths
```

That file is sourced early from `.zshrc` and is gitignored.

### Global vs project-local

**Global (machine):** language runtimes and shared CLIs

```
python, node, go, java, git, aws, kubectl, k9s, helm, terraform
```

**Project-local:** frameworks and build tools

```
vite, expo, next, react, typescript, eslint, jest, prettier, fastapi, pytest
```

Do **not** install Vite or Expo globally. Use project-local tooling:

```bash
npm create vite@latest my-app
npx create-expo-app@latest my-app
```

---

## Python Environments

**Rule:** `mise` = which Python version exists. `uv` = project venv + packages.

### Global default

`config/mise.toml`:

```toml
[tools]
python = "3.13"
```

### Per-project override

`my-api/.mise.toml`:

```toml
[tools]
python = "3.12"
```

### Workflow

```bash
cd ~/code/personal/my-api
mise install
uv init          # new project
uv add fastapi pytest ruff
uv sync          # existing project
uv run python main.py
uv run pytest
uv run ruff check .
```

### Project layout

```
my-api/
├── .mise.toml       # commit
├── pyproject.toml   # commit
├── uv.lock          # commit
├── .venv/           # do NOT commit (disposable)
└── src/
```

### Multiple Python versions

Each project can pin its own version via `.mise.toml`. `uv` creates `.venv` using the active mise Python when you `cd` into the project.

### Clean up clutter

```bash
rm -rf .venv    # remove one project's env
uv sync         # recreate it
```

No central `environments/` folder needed.

---

## Node Environments

```bash
# Global (mise)
node = "22"
corepack enable   # pnpm/yarn without global framework installs

# Per project
cd my-app
npm install
npm run dev
```

---

## Go, Java, C/C++

| Language | Version | Project files |
|----------|---------|---------------|
| Go | mise | `go.mod`, `cmd/`, `internal/` |
| Java | mise | `build.gradle` or `pom.xml` |
| C/C++ | apt (`gcc`, `clang`, `cmake`) | `CMakeLists.txt`, `Makefile` |

All compilation happens in WSL/Linux — no Windows compilers.

---

## AWS & Kubernetes

```bash
aws configure                    # ~/.aws/credentials
kubectl config get-contexts      # ~/.kube/config
k9s                              # terminal UI
```

Credentials never go in this repo.

---

## Scaffold New Projects

```bash
./scripts/new-project.sh python my-api personal
./scripts/new-project.sh react dashboard work
./scripts/new-project.sh go scraper
./scripts/new-project.sh java spring-api
./scripts/new-project.sh c parser
```

Templates live in `templates/`:

- `python` — uv + pyproject.toml
- `react-vite` — React + Vite (project-local)
- `go-cli` — Go CLI layout
- `java-gradle` — Java + Gradle
- `c-cmake` — C + CMake

---

## Folder Structure

```
~
├── .config, .local, .cache
├── .aws, .kube, .ssh
├── dev-env/          # this repo
└── code/
    ├── personal/
    ├── work/
    ├── experiments/
    ├── archive/
    ├── learning/
    ├── c/
    ├── go/
    └── java/
```

---

## Verification & Smoke Tests

Check installed tools:

```bash
./scripts/verify.sh
```

Run end-to-end language tests (creates temp projects, cleans up):

```bash
./tests/run-smoke-tests.sh
```

Smoke tests verify:

- Python (uv + mise)
- Node.js
- Go (`go run`)
- Java (`javac` + `java`)
- C (`gcc`)
- C++ (`clang++` / `g++`)

---

## Re-run Anytime

`./install.sh` is **idempotent** — safe to run multiple times. It skips what's already installed and updates what's changed.

Quick update alias (after shell reload):

```bash
dev-update    # git pull + ./install.sh
dev-verify    # version check
dev-test      # smoke tests
```

---

## License

Personal dev environment — use and adapt freely.
