# lp-api

A command-line tool written in Go for interacting with the Launchpad API at https://api.launchpad.net/devel.html

This project includes an [Agent Skill](https://agentskills.io/) that enables AI coding agents to work with Canonical's Launchpad platform for Ubuntu/Debian development, bug tracking, and build management.

## Quick Examples

**Query resources:**
* `lp-api get people/+me` - Get your own account on Launchpad
* `lp-api get bugs/1` - Get bug #1 on Launchpad
* `lp-api get ubuntu ws.op==searchTasks tags==focal tags==jammy tags_combinator==All ws.show==total_size` - Get the bug count for ubuntu project with both focal and jammy tags

**Modify resources:**
* `lp-api patch bugs/123456 tags:='["focal","jammy"]'` - Update bug tags
* `lp-api patch bugs/123456 description:='"Updated description"'` - Modify bug description

**Add comments:**
* `lp-api post bugs/123456 ws.op=newMessage subject="Update" content="Status update"` - Add comment to bug
* `lp-api post ~owner/project/+git/repo/+merge/123 ws.op=createComment subject="Review feedback" content="Detailed review comments..."` - Add comment to merge proposal

**File uploads:**
* `lp-api post bugs/123456 ws.op=addAttachment attachment=@error.log comment="Production error log"` - Attach log file to bug (comment is required)
* `lp-api post bugs/123456 ws.op=addAttachment attachment=@screenshot.png comment="UI bug" description="Screenshot showing the issue"` - Attach image with description
* `lp-api post bugs/123456 ws.op=addAttachment attachment=@fix.patch comment="Proposed fix" is_patch=true` - Attach patch file

**Download builds:**
* `BUILD=$(lp-api get ~ubuntu-cdimage/+livefs/ubuntu/jammy/ubuntu | lp-api .builds_collection_link | jq -r '.entries | .[0] | .web_link'); echo $BUILD` - Get the latest build for Ubuntu jammy
* `while read -r LINK; do lp-api download "$LINK"; done < <(lp-api get "~${BUILD//*~/}" ws.op==getFileUrls | jq -r .[])` - Download all artifacts from the latest build

## Install

Download the prebuilt binary for your platform from the [GitHub releases](https://github.com/fourdollars/lp-api/releases) page and place it in your PATH.

Alternatively, you can install using Go:
```bash
go install github.com/fourdollars/lp-api@latest
```

## Documentation

### For End Users
- See the [Quick Examples](#quick-examples) above for common use cases
- Run `lp-api -help` for command-line options

### For AI Coding Agents
This repository includes a comprehensive [Agent Skill](https://agentskills.io/) at `launchpad/SKILL.md` that provides:
- Detailed API usage patterns and workflows
- Authentication setup and troubleshooting
- Helper functions for common Launchpad operations
- Best practices for bug tracking, package management, and build automation

The skill enables AI agents to work effectively with Canonical's Launchpad platform for Ubuntu/Debian development tasks.

**Using the skill:**
- Compatible with [OpenCode](https://opencode.ai/), [Claude Desktop](https://claude.ai/download), [Cline](https://github.com/cline/cline), and other skills-compatible AI agents
- See the full documentation in [launchpad/SKILL.md](launchpad/SKILL.md)
