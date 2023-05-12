# lp-api
A command line tool made by golang to interact with Launchpad API https://api.launchpad.net/devel.html

* `lp-api get people/+me` to get your own account on Launchpad.
* `lp-api get bugs/1` to get bug #1 on Launchpad.
* `lp-api get ubuntu ws.op==searchTasks tags==focal tags==jammy tags_combinator==All ws.show==total_size` to get the bug number of ubuntu project with both of focal and jammy tags.

## Install
`go install github.com/fourdollars/lp-api@latest`
