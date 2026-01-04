# Initial Concept
A command-line tool made by golang to interact with Launchpad API https://api.launchpad.net/devel.html

# Product Guide: lp-api

## Vision
To provide a fast, scriptable, and intuitive command-line interface for interacting with Canonical's Launchpad platform, enabling developers and maintainers to manage bugs, builds, and resources without leaving the terminal.

## Target Users
- **Ubuntu and Debian package maintainers:** Managing bug tasks, tags, and series.
- **Automation developers:** Integrating Launchpad interactions into CI/CD pipelines and scripts.
- **Release managers:** Monitoring build statuses and tracking project milestones.

## Core Goals
- **Simplicity:** Provide a direct mapping to Launchpad API operations (GET, PATCH, POST).
- **Efficiency:** Support batch updates and complex queries through a concise CLI syntax.
- **Robustness:** Handle file attachments and build artifact downloads reliably.

## Key Features
- **Resource Querying:** Easy retrieval of Launchpad objects using predictable paths and filters.
- **State Modification:** PATCH and POST support for updating bug reports, series, and projects.
- **File Management:** Built-in support for attaching logs, screenshots, and patches to bug reports.
- **Build Monitoring:** Tools to track and download artifacts from LiveFS and package builds.