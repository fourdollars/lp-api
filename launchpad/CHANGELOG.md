# Changelog

All notable changes to the Launchpad skill will be documented in this file.

## [1.1.3] - 2026-01-08

### Added
- **Merge Proposal Management**: Added documentation and workflows for reviewing, commenting on, and managing Git merge proposals.
- **Workflow**: Added "Workflow 6: Merge Proposal Review" to SKILL.md and GEMINI.md.

## [1.1.2] - 2026-01-07

### Changed
- **Installation**: Updated installation instructions to recommend downloading prebuilt binaries from GitHub releases as the primary method, with `go install` as an alternative.

## [1.1.1] - 2026-01-06

### Added
- **Git Merge Proposals**: Added comprehensive support for working with Git merge proposals
  - List merge proposals for repositories
  - Get merge proposal details including diffs and comments
  - Add review comments to merge proposals with `createComment` operation
  - View all comments on a merge proposal
  - Get preview diffs before merging

## [1.1.0] - 2026-01-04

### Changed
- **Modular Documentation**: Refactored the large, generic reference files into focused, topic-based guides for better discoverability and context management:
  - `archive.md`: Archives and PPAs
  - `basics.md`: API concepts, pagination, and miscellaneous resources
  - `bugs.md`: Comprehensive bug tracking
  - `git.md`: Git repositories and build recipes
  - `livefs.md`: LiveFS build monitoring
  - `package-sets.md`: Package set management
  - `people.md`: People, teams, and memberships
  - `project.md`: Projects, milestones, and releases
- **Cleanup**: Removed legacy `api-operations.md` and `resource-paths.md`.

### Fixed
- **Scripts**: Fixed syntax errors in `wadl-helper.sh` that caused parsing failures in some shell environments.

## [1.0.4] - 2026-01-04

### Added
- **Bug Workflow Helpers**: Added helper function to list all tasks for a bug
  - `lp_get_bug_tasks`: List all tasks (targets and statuses) for a specific bug
- **Utility Helpers**: Added generic field extraction helper
  - `lp_get_field`: Extract a single top-level field from any resource
- **Documentation**: Updated `common-workflows.sh` help output to include all recent functions

## [1.0.3] - 2026-01-04

### Added
- **Bug Workflow Helpers**: Added helper functions for common bug checks
  - `lp_bug_has_tag`: Check if a bug has a specific tag
  - `lp_bug_task_status`: Get the status of a bug task for a specific target

## [1.0.2] - 2026-01-04

### Added
- **Package Set Management**: Added documentation and support for working with Launchpad package sets
  - New reference: `package-sets/<distro>/<series>/<name>` in `package-sets.md`
  - New operation: `getSourcesIncluded`
  - New helper function: `lp_get_package_set_sources` in `common-workflows.sh`
- **Package Upload Monitoring**: Added support for checking package uploads in distributions
  - New operation: `getPackageUploads` in `series.md`
  - New helper function: `lp_check_package_uploads` in `common-workflows.sh`
  - New reference: `Package Upload Monitoring` in key capabilities

## [1.0.1] - 2026-01-04

### Added
- **File Upload Support**: Added comprehensive support for uploading files to Launchpad bugs and resources
  - `addAttachment` operation documentation
  - Automatic MIME type detection
  - Support for patches, logs, images, and configuration files
- **Series Management**: Added tools and documentation for working with distribution series (e.g., focal, jammy)
  - New script: `scripts/list_series.sh` for listing active series
  - New reference: `references/series.md` for series operations
- **WADL Validation**: Added strict validation against Launchpad's API schema
  - New asset: `assets/launchpad-wadl.xml` (API definition)
  - New script: `scripts/wadl-helper.sh` for validating commands
- **Gemini CLI Support**: Full port and optimization for Gemini CLI
  - Added `GEMINI.md` context file
  - Added `gemini-extension.json` manifest
- **New Workflows**: Expanded common workflows from 3 to 5
  - Workflow 4: Complete Bug Management (create, comment, update, subscribe)
  - Workflow 5: Bulk Comment Addition

## [1.0.0] - 2026-01-02

### Added
- Initial release of Launchpad skill for GitHub Copilot CLI
- Core capabilities for interacting with Launchpad API via lp-api tool
- Comprehensive SKILL.md with 7 main operation categories:
  - Resource Querying (GET)
  - Resource Modification (PATCH)
  - Resource Creation (POST)
  - Resource Replacement (PUT)
  - Resource Deletion (DELETE)
  - Piping Resource Links
  - File Downloads
- Three common workflow patterns:
  - Bug Investigation
  - Package Build Monitoring
  - Batch Bug Updates
- Authentication documentation (environment variable and config file methods)
- Command options and error handling guidance

### References
- Modular API Reference Guides:
  - People & Teams (person, team, memberships)
  - Bugs & Bug Tracking (bugs, tasks, messages, attachments)
  - Projects & Products (projects, series, branches)
  - Distributions & Packages (distros, source packages, binary packages)
  - Builds & Build Farm (LiveFS builds, source builds, builders)
  - PPAs (archives, packages, publishing)
  - Source Code Management (Git repos, Bazaar branches)
  - Translations, Specifications, Questions, Milestones
  - Collections & Pagination patterns
  - Resource link fields
  - Discovery tips and common mistakes
  - Web service operations and query parameters
  - Sorting and pagination
  - Workflow pattern examples

### Scripts
- `common-workflows.sh`: Reusable bash function library
  - Bug Workflows: 6 functions (info, search, count, comment, update tags, subscribe)
  - Build Workflows: 5 functions (latest build, status, download artifacts, wait, failed builds)
  - Package Workflows: 2 functions (info, bugs)
  - PPA Workflows: 2 functions (list packages, copy package)
  - Person/Team Workflows: 2 functions (info, members)
  - Utility Functions: 5 functions (follow link, pretty print, extract links, show links, paginate)
  - Example Workflows: 3 complete examples
  - Self-documenting help output

### Documentation
- README.md: Installation and usage guide
  - Prerequisites and installation steps
  - Authentication setup methods
  - Usage examples with Copilot
  - Resource documentation overview
  - Development and contribution guide
  - Troubleshooting section
  - Links to additional resources

### Metadata
- Skill triggers: Launchpad, Ubuntu development, package builds, bug tracking on launchpad.net
- Compatible with: lp-api latest (https://github.com/fourdollars/lp-api/releases)
- Tested with: Launchpad API devel (https://api.launchpad.net/devel.html)

## Future Enhancements (Planned)

### Potential Additions
- [ ] More specialized workflow scripts for common Ubuntu development tasks
- [ ] Template files for common JSON payloads (PUT operations)
- [ ] Integration examples with CI/CD systems
- [ ] Advanced filtering examples for complex queries
- [ ] Batch operation templates with progress tracking
- [ ] Examples for working with Launchpad translations
- [ ] Blueprint/specification management workflows
- [ ] Question and Answer workflows

### Community Contributions Welcome
- Additional workflow patterns from real-world usage
- Project-specific templates and configurations
- Performance optimization tips
- Error handling improvements
- Documentation enhancements
