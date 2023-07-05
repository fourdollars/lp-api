package main

import (
	"os"
	"testing"
)

func Test_get(t *testing.T) {
	backupArgs := os.Args
	os.Args = append(os.Args, "-staging")
	os.Args = append(os.Args, "-output")
	os.Args = append(os.Args, "payload.json")
	os.Args = append(os.Args, "get")
	os.Args = append(os.Args, "bugs/1923283")
	main()
	os.Args = backupArgs
}

func Test_put(t *testing.T) {
	t.Cleanup(func() {
		os.Remove("payload.json")
	})
	backupArgs := os.Args

	os.Args = append(os.Args, "-staging")
	os.Args = append(os.Args, "-output")
	os.Args = append(os.Args, "")
	os.Args = append(os.Args, "put")
	os.Args = append(os.Args, "bugs/1923283")
	os.Args = append(os.Args, "payload.json")
	main()
	os.Args = backupArgs
}

func Test_patch(t *testing.T) {
	backupArgs := os.Args

	os.Args = append(os.Args, "-staging")
	os.Args = append(os.Args, "patch")
	os.Args = append(os.Args, "bugs/1923283")
	os.Args = append(os.Args, "tags:=[\"focal\",\"jammy\"]")
	main()
	os.Args = backupArgs

	os.Args = append(os.Args, "-staging")
	os.Args = append(os.Args, "patch")
	os.Args = append(os.Args, "bugs/1923283")
	os.Args = append(os.Args, "tags:=[]")
	main()
	os.Args = backupArgs
}

func Test_post(t *testing.T) {
	backupArgs := os.Args

	os.Args = append(os.Args, "-staging")
	os.Args = append(os.Args, "post")
	os.Args = append(os.Args, "bugs/1923283")
	os.Args = append(os.Args, "ws.op=newMessage")
	os.Args = append(os.Args, "content=test")
	main()
	os.Args = backupArgs
}

func Test_productionAPI(t *testing.T) {
	os.Clearenv()
	os.Setenv("LAUNCHPAD_TOKEN", "::")
	backupArgs := os.Args

	os.Args = append(os.Args, "-debug")
	os.Args = append(os.Args, "get")
	os.Args = append(os.Args, "https://api.launchpad.net/devel/bugs/1")
	main()
	os.Args = backupArgs
}

func Test_stagingAPI(t *testing.T) {
	os.Clearenv()
	os.Setenv("LAUNCHPAD_TOKEN", "::")
	backupArgs := os.Args

	os.Args = append(os.Args, "-debug")
	os.Args = append(os.Args, "get")
	os.Args = append(os.Args, "https://api.staging.launchpad.net/devel/bugs/1")
	main()
	os.Args = backupArgs
}

func Test_download(t *testing.T) {
	t.Cleanup(func() {
		os.Remove("data")
	})
	os.Clearenv()
	os.Setenv("LAUNCHPAD_TOKEN", "::")
	backupArgs := os.Args

	os.Args = append(os.Args, "-debug=0")
	os.Args = append(os.Args, "download")
	os.Args = append(os.Args, "https://api.launchpad.net/devel/bugs/1/+attachment/26604/data")
	main()
	os.Args = backupArgs
}
