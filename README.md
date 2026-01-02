# lp-api
A command line tool made by golang to interact with Launchpad API https://api.launchpad.net/devel.html

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

**File uploads:**
* `lp-api post bugs/123456 ws.op=addAttachment attachment=@error.log comment="Production error log"` - Attach log file to bug (comment is required)
* `lp-api post bugs/123456 ws.op=addAttachment attachment=@screenshot.png comment="UI bug" description="Screenshot showing the issue"` - Attach image with description
* `lp-api post bugs/123456 ws.op=addAttachment attachment=@config.yaml comment="Config file" description="Configuration that triggers the bug"` - Attach config file

**Download builds:**
* `BUILD=$(lp-api get ~ubuntu-cdimage/+livefs/ubuntu/jammy/ubuntu | lp-api .builds_collection_link | jq -r '.entries | .[0] | .web_link'); echo $BUILD` - Get the latest build for Ubuntu jammy
* `while read -r LINK; do lp-api download "$LINK"; done < <(lp-api get "~${BUILD//*~/}" ws.op==getFileUrls | jq -r .[])` - Download all artifacts from the latest build

## Install
`go install github.com/fourdollars/lp-api@latest`

## Documentation
See `launchpad/SKILL.md` for comprehensive usage guide and examples.
