# Changelog

All notable changes to the Launchpad skill will be documented in this file.

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
- `resource-paths.md`: Complete guide to Launchpad API resource paths
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

- `api-operations.md`: Web service operations and query parameters
  - Common operations: searchTasks, newMessage, subscribe, getFileUrls, retry, cancel
  - Bug operations with all filter options
  - Build operations (getFileUrls, retry, cancel)
  - PPA operations (copyPackage, syncSource, deletePackage)
  - Person/Team operations (getByEmail, findTeam)
  - Query parameters (ws.show, ws.start, ws.size)
  - Collection filters (dates, status, importance, tags)
  - Sorting and pagination
  - Three workflow pattern examples

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
- Compatible with: lp-api latest (go install github.com/fourdollars/lp-api@latest)
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
