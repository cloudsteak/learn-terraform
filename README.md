# Learn Terraform

This repository is a collection of small Terraform projects for learning Infrastructure as Code.

Each example focuses on one concept and keeps the code minimal so you can read, run, and understand it quickly.

## Table of contents

- [Topics](#topics)
- [Cloud providers](#cloud-providers)
- [Tools](#tools)
- [Getting started](#getting-started)

## Topics

Examples are grouped around common Terraform fundamentals:

- **Basic** — minimal provider setup and a first resource
- **Remote state** — storing and sharing state outside your local machine
- **Modules** — reusing and composing Terraform code

## Cloud providers

Projects are organized by cloud provider:

| Provider | Examples |
|----------|----------|
| [Azure](./azure/) | [basic](./azure/basic/) |
| AWS | _coming soon_ |
| GCP | _coming soon_ |

See each provider directory for a short overview and links to its examples.

## Tools

Examples assume a local Terraform setup. For installing and switching Terraform, OpenTofu, and Terragrunt versions, see [tenv.md](./tenv.md).

If `brew install tenv` fails because `opentofu`, `terragrunt`, or `tfenv` is already installed, see [Homebrew conflicts](./tenv.md#homebrew-conflicts) in that guide.

## Getting started

1. Install [tenv](./tenv.md) and ensure `terraform` runs via the tenv proxy (`which terraform`).
2. Pick a provider, open its README, then follow the README in the example you want to try.

Currently available:

- [Azure — basic](./azure/basic/README.md)
