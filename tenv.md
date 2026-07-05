# tenv — IaC version manager

[tenv](https://tofuutils.github.io/tenv/) is a single version manager for **OpenTofu**, **Terraform**, **Terragrunt**, **Terramate**, and **Atmos**. It is written in Go and is the official successor to [tfenv](https://github.com/tfutils/tfenv) and [tofuenv](https://github.com/tofuutils/tofuenv).

Instead of installing each tool separately or juggling multiple version managers, tenv installs versioned binaries under one directory and exposes proxy commands (`terraform`, `tofu`, `terragrunt`, …) that pick the right version for your project.

## Table of contents

- [Why use tenv](#why-use-tenv)
- [Installation](#installation)
  - [macOS (Homebrew)](#macos-homebrew)
  - [Linux](#linux)
  - [Windows](#windows)
  - [Verify](#verify)
  - [Homebrew conflicts](#homebrew-conflicts)
- [Shell setup](#shell-setup)
- [Directory layout](#directory-layout)
- [Tool aliases](#tool-aliases)
- [Setting up Terraform](#setting-up-terraform)
- [Setting up OpenTofu](#setting-up-opentofu)
- [Setting up Terragrunt](#setting-up-terragrunt)
- [Recommended environment variables](#recommended-environment-variables)
- [Migrating to tenv](#migrating-to-tenv)
  - [General migration checklist](#general-migration-checklist)
  - [Migrating from tfenv](#migrating-from-tfenv)
  - [Migrating from tofuenv](#migrating-from-tofuenv)
  - [Migrating from a standalone Terraform install](#migrating-from-a-standalone-terraform-install)
  - [Migrating from a standalone OpenTofu install](#migrating-from-a-standalone-opentofu-install)
  - [Migrating from a standalone Terragrunt install](#migrating-from-a-standalone-terragrunt-install)
  - [Migrating from asdf](#migrating-from-asdf)
- [Example: this repository](#example-this-repository)
- [Troubleshooting](#troubleshooting)
- [Further reading](#further-reading)

## Why use tenv

- One tool for OpenTofu, Terraform, and Terragrunt (and more)
- Reads the same version files as tfenv/tofuenv (`.terraform-version`, `.opentofu-version`, `.terragrunt-version`)
- Parses `required_version` and Terragrunt HCL constraints automatically
- Works on macOS, Linux, Windows, and BSD
- Optional checksum and signature verification (cosign / PGP)

## Installation

### macOS (Homebrew)

```bash
brew install tenv
```

If this fails with *conflicting formulae* (`opentofu`, `terragrunt`, `tfenv`), see [Homebrew conflicts](#homebrew-conflicts) below.

Other options: [MacPorts](https://tofuutils.github.io/tenv/), Nix, or a manual download from the [GitHub releases page](https://github.com/tofuutils/tenv/releases).

### Linux

Examples:

```bash
# Debian / Ubuntu (Cloudsmith repo — see official docs for setup)
sudo apt install tenv

# Arch (AUR)
yay tenv-bin

# Snap
snap install tenv
```

### Windows

```bash
winget install Tofuutils.Tenv
# or: choco install tenv
# or: scoop install tenv
```

### Verify

```bash
tenv version
```

### Homebrew conflicts

If you already have `opentofu`, `terragrunt`, or `tfenv` from Homebrew, `brew install tenv` fails because all of them provide the same proxy binaries (`tofu`, `terragrunt`, `terraform`).

Note the versions you use today, then unlink the old formulae before installing tenv:

```bash
terraform version
tofu version
terragrunt --version

brew unlink opentofu terragrunt tfenv
brew install tenv
export PATH="$(tenv update-path)"

# Reinstall the same versions via tenv (adjust as needed)
tenv tf install 1.15.7
tenv tofu install 1.11.5
tenv tg install 0.99.4
tenv tf use 1.15.7
tenv tofu use 1.11.5
tenv tg use 0.99.4

which terraform tofu terragrunt   # should point under tenv, not /opt/homebrew/bin

# When everything works, remove the old formulae
brew uninstall opentofu terragrunt tfenv
rm -rf ~/.tfenv   # optional tfenv cache cleanup
```

`brew unlink` only removes symlinks from `/opt/homebrew/bin`; it does not delete the formulae. You can reinstall them later if needed, but they will conflict with tenv again.

## Shell setup

After installation, make sure tenv’s proxy binaries come **before** any system-wide Terraform, OpenTofu, or Terragrunt install on your `PATH`.

```bash
export PATH="$(tenv update-path)"
```

Add that line to your shell profile (`~/.zshrc`, `~/.bashrc`, etc.) so it runs in every new terminal.

If `which terraform` points to `/usr/local/bin/terraform` (or similar) instead of tenv’s shim, the command above fixes it.

Optional shell completion (Homebrew installs this automatically):

```bash
tenv completion zsh > ~/.tenv.completion.zsh
echo 'source "$HOME/.tenv.completion.zsh"' >> ~/.zshrc
```

## Directory layout

By default, tenv stores everything under:

```
~/.tenv/
├── OpenTofu/
├── Terraform/
├── Terragrunt/
└── ...
```

Override with `TENV_ROOT` if needed.

## Tool aliases

| Tool       | tenv subcommand   | Proxy command | Legacy env prefix |
|------------|-------------------|---------------|-------------------|
| OpenTofu   | `tenv tofu`       | `tofu`        | `TOFUENV_`        |
| Terraform  | `tenv tf`         | `terraform`   | `TFENV_`          |
| Terragrunt | `tenv tg`         | `terragrunt`  | `TG_`             |

Run `tenv` with no arguments for an interactive menu.

---

## Setting up Terraform

### Install a version

```bash
tenv tf install 1.15.7          # exact version
tenv tf install latest-stable   # latest stable release
tenv tf install min-required    # lowest version allowed by required_version in .tf files
tenv tf install latest-allowed  # highest version allowed by required_version
```

### Set the global default

```bash
tenv tf use 1.15.7
```

This writes `~/.tenv/Terraform/version`.

### Pin a project

Create a file in the project root (or a parent directory):

```bash
tenv tf use 1.15.7 --working-dir
# creates .terraform-version
```

Or manually:

```
# .terraform-version
1.15.7
```

When you run `terraform` inside that directory, tenv selects that version automatically.

### Useful commands

```bash
tenv tf list              # installed versions
tenv tf list-remote       # available remote versions
tenv tf detect            # show which version would be used here
terraform version         # run via tenv proxy
```

---

## Setting up OpenTofu

### Install a version

```bash
tenv tofu install 1.10.0
tenv tofu install latest-stable
tenv tofu install min-required
```

### Set the global default

```bash
tenv tofu use 1.10.0
```

### Pin a project

```bash
tenv tofu use 1.10.0 --working-dir
# creates .opentofu-version
```

Or manually:

```
# .opentofu-version
1.10.0
```

### Useful commands

```bash
tenv tofu list
tenv tofu detect
tofu version
```

---

## Setting up Terragrunt

### Install a version

```bash
tenv tg install 0.78.0
tenv tg install latest-stable
```

### Set the global default

```bash
tenv tg use 0.78.0
```

### Pin a project

```bash
tenv tg use 0.78.0 --working-dir
# creates .terragrunt-version
```

Supported version files:

- `.terragrunt-version`
- `.tgswitchrc`
- `version` field in `.tgswitch.toml`

tenv can also read `terragrunt_version_constraint` and `terraform_version_constraint` from `terragrunt.hcl` or `root.hcl`.

### Useful commands

```bash
tenv tg list
tenv tg detect
terragrunt --version
```

---

## Recommended environment variables

Add these to your shell profile for a smoother day-to-day workflow:

```bash
export TENV_AUTO_INSTALL=true   # install missing versions on first use
export PATH="$(tenv update-path)"
```

Other useful variables:

| Variable            | Purpose                                      |
|---------------------|----------------------------------------------|
| `TENV_ROOT`         | Custom install directory (default `~/.tenv`) |
| `TENV_AUTO_INSTALL` | Auto-install missing versions              |
| `TENV_GITHUB_TOKEN` | Avoid GitHub API rate limits in CI           |
| `TFENV_TERRAFORM_VERSION` | Override Terraform version           |
| `TOFUENV_TOFU_VERSION`    | Override OpenTofu version            |
| `TG_VERSION`              | Override Terragrunt version          |

tenv keeps **tfenv** and **tofuenv** environment variable names for compatibility (`TFENV_*`, `TOFUENV_*`).

---

## Migrating to tenv

tenv is designed as a drop-in replacement. Your existing version files and most commands continue to work; you mainly swap the manager and fix your `PATH`.

### General migration checklist

1. **Install tenv** (see [Installation](#installation)).
2. **Update `PATH`** so tenv proxies take precedence (`tenv update-path`).
3. **Keep your version files** — tenv reads the same formats.
4. **Install the versions you need** with `tenv <tool> install …` (or enable `TENV_AUTO_INSTALL=true`).
5. **Remove the old manager** and any conflicting binaries from `PATH`.
6. **Verify** with `tenv tf detect`, `tenv tofu detect`, `tenv tg detect`, and `which terraform`.

---

### Migrating from tfenv

tfenv and tenv use the same version file and nearly the same CLI.

| tfenv                         | tenv equivalent              |
|-------------------------------|------------------------------|
| `tfenv install 1.15.7`        | `tenv tf install 1.15.7`     |
| `tfenv use 1.15.7`            | `tenv tf use 1.15.7`         |
| `tfenv list`                  | `tenv tf list`               |
| `tfenv install` (no arg)      | `tenv tf install`            |
| `.terraform-version`          | unchanged                    |
| `TFENV_TERRAFORM_VERSION`     | still supported              |

**Steps:**

```bash
brew install tenv
export PATH="$(tenv update-path)"

# Reinstall versions (or copy ~/.tfenv/versions/* → ~/.tenv/Terraform/ manually)
tenv tf install 1.15.7
tenv tf use 1.15.7

terraform version   # should run via tenv

# Remove tfenv when satisfied
brew uninstall tfenv
rm -rf ~/.tfenv   # optional cleanup
```

Your `.terraform-version` files in projects require **no changes**.

---

### Migrating from tofuenv

tofuenv commands map directly to `tenv tofu`:

| tofuenv                       | tenv equivalent                |
|-------------------------------|--------------------------------|
| `tofuenv install 1.10.0`      | `tenv tofu install 1.10.0`     |
| `tofuenv use 1.10.0`            | `tenv tofu use 1.10.0`         |
| `.opentofu-version`           | unchanged                      |
| `TOFUENV_TOFU_VERSION`        | still supported                |

**Steps:**

```bash
brew install tenv
export PATH="$(tenv update-path)"

tenv tofu install 1.10.0
tenv tofu use 1.10.0

tofu version

brew uninstall tofuenv
rm -rf ~/.tofuenv   # optional cleanup
```

---

### Migrating from a standalone Terraform install

If Terraform was installed via HashiCorp’s package, Homebrew (`brew install terraform`), or a manual binary:

**Steps:**

```bash
brew install tenv
export PATH="$(tenv update-path)"

tenv tf install latest-stable
tenv tf use latest-stable

which terraform    # should point under ~/.tenv or tenv’s bin dir
terraform version

# Remove the old install, e.g.:
brew uninstall terraform
# or remove /usr/local/bin/terraform manually
```

Pin each project with `.terraform-version` so teammates and CI use the same version.

---

### Migrating from a standalone OpenTofu install

Same pattern as standalone Terraform:

```bash
brew install tenv
export PATH="$(tenv update-path)"

tenv tofu install latest-stable
tenv tofu use latest-stable

which tofu
tofu version

brew uninstall opentofu   # if installed via Homebrew
```

Keep or add `.opentofu-version` in project roots.

---

### Migrating from a standalone Terragrunt install

If Terragrunt was installed manually, via Homebrew, or with another switcher (e.g. `tgswitch`):

**Steps:**

```bash
brew install tenv
export PATH="$(tenv update-path)"

tenv tg install latest-stable
tenv tg use latest-stable

which terragrunt
terragrunt --version

brew uninstall terragrunt   # if applicable
```

Version files supported by tgswitch (`.terragrunt-version`, `.tgswitchrc`, `.tgswitch.toml`) work with tenv without modification.

---

### Migrating from asdf

If you used asdf plugins for terraform/opentofu/terragrunt:

1. Note the versions in your `.tool-versions` file — tenv reads `.tool-versions` as part of its resolution order.
2. Install tenv and set `PATH` via `tenv update-path`.
3. Install the same versions:

   ```bash
   tenv tf install 1.15.7
   tenv tofu install 1.10.0
   tenv tg install 0.78.0
   ```

4. Optionally remove the asdf plugins once tenv works.

You can keep `.tool-versions` for a while during transition, or replace entries with tool-specific files (`.terraform-version`, etc.).

---

## Example: this repository

For the Azure basic example (`azure/basic/`), which requires Terraform `>= 1.15.0`:

```bash
cd azure/basic

tenv tf install min-required   # installs lowest allowed version from providers.tf
tenv tf use min-required --working-dir

terraform init
terraform plan
```

Or pin explicitly:

```bash
echo "1.15.7" > .terraform-version
tenv tf install    # reads .terraform-version and installs if missing
```

---

## Troubleshooting

**Wrong binary is executed**

```bash
which terraform tofu terragrunt
export PATH="$(tenv update-path)"
```

**Version not installed**

```bash
export TENV_AUTO_INSTALL=true
# or manually:
tenv tf install 1.15.7
```

**See which version tenv would pick**

```bash
tenv tf detect
tenv tofu detect
tenv tg detect
```

**GitHub rate limits in CI**

Set `TENV_GITHUB_TOKEN` (or use a GitHub App via `TENV_GITHUB_APP_*` variables).

---

## Further reading

- Official docs: https://tofuutils.github.io/tenv/
- GitHub repository: https://github.com/tofuutils/tenv
- tfenv (legacy): https://github.com/tfutils/tfenv
- tofuenv (legacy): https://github.com/tofuutils/tofuenv
