# CI/CD Foundation

This repository aims at
- minimizing onboarding of new applications and workload through
- generic, reusable, and secure continuous integration (CI) and deployment (CD) pipelines
- helping you to reach the highest [SLSA level](https://slsa.dev/spec/v1.0/levels)
- permitting scale by reducing engineering, maintenance, and audit efforts
- empowering you to establish and/or strengthen your [DORA capabilities](https://dora.dev/capabilities/)

## Google Cloud Professional Services Organization (PSO) Offering

The repository contains open-sourced code and documentation from the Google Cloud Professional Services Organization (PSO) Apps team.
Please reach out to your Google account team, your [Technical Account Manager (TAM)](https://cloud.google.com/tam), or a [Google Cloud Partner](https://cloud.google.com/partners) for a "CI/CD Foundation" engagement that is structured as follows:

### 📅 Workshop 1: Architecture

Establishing the foundations for the subsequent Cloud development workshop in your GCP Organization.

[`infra/`](infra/) - Infra-as-Code (IaC)
- of a simplified infrastructure deployment for the hands-on workshop
- reference architecture for a GCP Organization

### 📅 Workshop 2: Hands-On

Overview of [Software Delivery Shield](https://cloud.google.com/software-supply-chain-security/docs/sds/overview),
[SLSA](https://slsa.dev/), and
hands-on exercises ([`exercises/`](exercises/)), e.g.,
the deployment and customization of a sample application ([`apps/`](apps/)).

### 📅 Workshop 3: Continuous Integration (CI)

Deepdive of Continuous Integration (CI) on Google Cloud and planning of design for customer environment.

### 📅 Workshop 4: Continuous Deployment (CD)

Deepdive of Continuous Delivery (CD) on Google Cloud, design of environment(s) fitting customer requirements including multi-tenancy and security.
Creation of a target development environment based on the design decisions.

## Google Cloud Skills Boost

An Advanced Challenge Lab of the Google Cloud learning platform is based on the CI/CD Foundation.
The dedicated [`qwiklabs`](../qwiklabs) branch is reflecting the codebase that is both used for
1. setting up the lab (using the [`infra/simplified`](infra/simplified/) infra-as-code) and
2. by the learners for onboarding an application for CI/CD and learn about Cloud Deploy releases, rollouts, approvals, and deployment parameters.

## Call to Action

Interested in implementing a robust CI/CD foundation for your projects? Contact your Google Cloud representative and/or explore the code and documentation in this repository to get started.

- [How to Contribute](docs/contributing.md)
- [Code of Conduct](docs/code-of-conduct.md)
