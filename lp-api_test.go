package main

import (
	"os"
	"os/exec"
	"strings"
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

func Test_timeout10s(t *testing.T) {
	os.Clearenv()
	os.Setenv("LAUNCHPAD_TOKEN", "::")
	backupArgs := os.Args

	os.Args = append(os.Args, "-debug")
	os.Args = append(os.Args, "-timeout")
	os.Args = append(os.Args, "10s")
	os.Args = append(os.Args, "get")
	os.Args = append(os.Args, "https://api.launchpad.net/devel/bugs/1")
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

func Test_fileUpload_staging(t *testing.T) {
	// Ensure we use config file credentials, not dummy env vars from other tests
	os.Unsetenv("LAUNCHPAD_TOKEN")

	// Create a test file
	tmpDir := t.TempDir()
	testFile := tmpDir + "/test-upload.log"
	testContent := []byte("Test log content from lp-api integration test\n")
	if err := os.WriteFile(testFile, testContent, 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	backupArgs := os.Args
	defer func() { os.Args = backupArgs }()

	// Reset os.Args to just the program name
	os.Args = []string{os.Args[0]}
	os.Args = append(os.Args, "-staging")
	os.Args = append(os.Args, "post")
	os.Args = append(os.Args, "bugs/1923283")
	os.Args = append(os.Args, "ws.op=addAttachment")
	os.Args = append(os.Args, "attachment=@"+testFile)
	os.Args = append(os.Args, "comment=Integration test attachment from lp-api_test.go")
	os.Args = append(os.Args, "description=Automated test file upload")

	// Note: This test may fail if staging server is unavailable
	// That's expected behavior - staging is not always online
	main()
}

func Test_fileUpload_withDescription_staging(t *testing.T) {
	// Ensure we use config file credentials
	os.Unsetenv("LAUNCHPAD_TOKEN")

	// Create a test file with different content
	tmpDir := t.TempDir()
	testFile := tmpDir + "/test-upload-2.txt"
	testContent := []byte("Another test file with description\n")
	if err := os.WriteFile(testFile, testContent, 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	backupArgs := os.Args
	defer func() { os.Args = backupArgs }()

	os.Args = []string{os.Args[0]}
	os.Args = append(os.Args, "-staging")
	os.Args = append(os.Args, "post")
	os.Args = append(os.Args, "bugs/1923283")
	os.Args = append(os.Args, "ws.op=addAttachment")
	os.Args = append(os.Args, "attachment=@"+testFile)
	os.Args = append(os.Args, "comment=Test with description field")
	os.Args = append(os.Args, "description=This tests the optional description parameter")

	// Note: This test may fail if staging server is unavailable
	main()
}

func Test_fileUpload_missingComment(t *testing.T) {
	if os.Getenv("TEST_SUBPROCESS") == "1" {
		// Create a test file
		tmpDir := t.TempDir()
		testFile := tmpDir + "/test-upload-error.log"
		testContent := []byte("This should fail due to missing comment\n")
		if err := os.WriteFile(testFile, testContent, 0644); err != nil {
			t.Fatalf("Failed to create test file: %v", err)
		}

		// Create dummy config to bypass auth flow
		configFile := tmpDir + "/dummy_config.toml"
		configContent := []byte("oauth_consumer_key = \"foo\"\noauth_token = \"bar\"\noauth_token_secret = \"baz\"\n")
		if err := os.WriteFile(configFile, configContent, 0644); err != nil {
			t.Fatalf("Failed to create config file: %v", err)
		}

		// Ensure we use config file credentials
		os.Unsetenv("LAUNCHPAD_TOKEN")

		os.Args = []string{os.Args[0]}
		os.Args = append(os.Args, "-staging")
		os.Args = append(os.Args, "-conf", configFile)
		os.Args = append(os.Args, "post")
		os.Args = append(os.Args, "bugs/1923283")
		os.Args = append(os.Args, "ws.op=addAttachment")
		os.Args = append(os.Args, "attachment=@"+testFile)
		// Intentionally omit comment parameter

		main()
		return
	}

	cmd := exec.Command(os.Args[0], "-test.run=Test_fileUpload_missingComment")
	cmd.Env = append(os.Environ(), "TEST_SUBPROCESS=1")
	output, err := cmd.CombinedOutput()

	// Check exit code
	if e, ok := err.(*exec.ExitError); ok && !e.Success() {
		// Expected exit status 1
		stderr := string(output)
		if !strings.Contains(stderr, "comment") && !strings.Contains(stderr, "required") {
			t.Errorf("Expected error message about missing comment, got: %s", stderr)
		}
		return
	}

	t.Fatalf("process ran with err %v, want exit status 1", err)
}

func Test_fileUpload_fileNotFound(t *testing.T) {
	if os.Getenv("TEST_SUBPROCESS") == "1" {
		// Create dummy config to bypass auth flow
		tmpDir := t.TempDir()
		configFile := tmpDir + "/dummy_config.toml"
		configContent := []byte("oauth_consumer_key = \"foo\"\noauth_token = \"bar\"\noauth_token_secret = \"baz\"\n")
		if err := os.WriteFile(configFile, configContent, 0644); err != nil {
			t.Fatalf("Failed to create config file: %v", err)
		}

		// Ensure we use config file credentials
		os.Unsetenv("LAUNCHPAD_TOKEN")

		os.Args = []string{os.Args[0]}
		os.Args = append(os.Args, "-staging")
		os.Args = append(os.Args, "-conf", configFile)
		os.Args = append(os.Args, "post")
		os.Args = append(os.Args, "bugs/1923283")
		os.Args = append(os.Args, "ws.op=addAttachment")
		os.Args = append(os.Args, "attachment=@/nonexistent/file.log")
		os.Args = append(os.Args, "comment=This should fail")

		main()
		return
	}

	cmd := exec.Command(os.Args[0], "-test.run=Test_fileUpload_fileNotFound")
	cmd.Env = append(os.Environ(), "TEST_SUBPROCESS=1")
	output, err := cmd.CombinedOutput()

	// Check exit code
	if e, ok := err.(*exec.ExitError); ok && !e.Success() {
		// Expected exit status 1
		stderr := string(output)
		if !strings.Contains(stderr, "File not found") {
			t.Errorf("Expected 'File not found' error message, got: %s", stderr)
		}
		return
	}

	t.Fatalf("process ran with err %v, want exit status 1", err)
}

func TestIsFileAttachment(t *testing.T) {
	tests := []struct {
		name  string
		param string
		want  bool
	}{
		{"valid file with @ prefix", "@file.log", true},
		{"absolute path", "@/absolute/path.txt", true},
		{"relative path", "@../relative/file.png", true},
		{"no @ prefix", "file.log", false},
		{"empty string", "", false},
		{"only @", "@", true},
		{"double @", "@@file.log", true},
		{"@ with spaces", "@file with spaces.log", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := isFileAttachment(tt.param); got != tt.want {
				t.Errorf("isFileAttachment(%q) = %v, want %v", tt.param, got, tt.want)
			}
		})
	}
}

func TestExtractFilePath(t *testing.T) {
	tests := []struct {
		name  string
		param string
		want  string
	}{
		{"valid file", "@file.log", "file.log"},
		{"absolute path", "@/absolute/path.txt", "/absolute/path.txt"},
		{"relative path", "@../relative/file.png", "../relative/file.png"},
		{"no @ prefix", "file.log", ""},
		{"empty string", "", ""},
		{"only @", "@", ""},
		{"double @", "@@file.log", "@file.log"},
		{"@ with spaces", "@file with spaces.log", "file with spaces.log"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := extractFilePath(tt.param); got != tt.want {
				t.Errorf("extractFilePath(%q) = %q, want %q", tt.param, got, tt.want)
			}
		})
	}
}

func TestReadFileContent(t *testing.T) {
	// Create temporary test files
	tmpDir := t.TempDir()

	// Test reading valid text file
	t.Run("read valid text file", func(t *testing.T) {
		testFile := tmpDir + "/test.txt"
		content := []byte("test content")
		if err := os.WriteFile(testFile, content, 0644); err != nil {
			t.Fatalf("Failed to create test file: %v", err)
		}

		data, err := readFileContent(testFile)
		if err != nil {
			t.Errorf("readFileContent() error = %v", err)
		}
		if string(data) != string(content) {
			t.Errorf("readFileContent() = %q, want %q", string(data), string(content))
		}
	})

	// Test reading binary file
	t.Run("read binary file", func(t *testing.T) {
		testFile := tmpDir + "/test.bin"
		content := []byte{0x00, 0x01, 0x02, 0xFF}
		if err := os.WriteFile(testFile, content, 0644); err != nil {
			t.Fatalf("Failed to create test file: %v", err)
		}

		data, err := readFileContent(testFile)
		if err != nil {
			t.Errorf("readFileContent() error = %v", err)
		}
		if len(data) != len(content) {
			t.Errorf("readFileContent() length = %d, want %d", len(data), len(content))
		}
	})

	// Test file not found error
	t.Run("file not found", func(t *testing.T) {
		_, err := readFileContent(tmpDir + "/nonexistent.txt")
		if err == nil {
			t.Error("readFileContent() expected error for non-existent file")
		}
	})
}

func TestDetectContentType(t *testing.T) {
	tests := []struct {
		name     string
		filepath string
		want     string
	}{
		{"text log", "file.log", "text/"},
		{"text file", "file.txt", "text/plain"},
		{"png image", "screenshot.png", "image/png"},
		{"jpg image", "photo.jpg", "image/jpeg"},
		{"json file", "config.json", "application/json"},
		{"yaml file", "config.yaml", "application/"},
		{"tar.gz archive", "backup.tar.gz", "application/gzip"},
		{"unknown extension", "file.xyz", "application/octet-stream"},
		{"uppercase extension", "FILE.LOG", "text/"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := detectContentType(tt.filepath)
			// Some MIME types may have charset suffix
			if !strings.HasPrefix(got, tt.want) {
				t.Errorf("detectContentType(%q) = %q, want prefix %q", tt.filepath, got, tt.want)
			}
		})
	}
}

func TestBuildMultipartBody(t *testing.T) {
	attachment := FileAttachment{
		Path:        "/tmp/test.log",
		Filename:    "test.log",
		ContentType: "text/plain",
		Data:        []byte("test file content"),
	}

	params := map[string]string{
		"ws.op":       "addAttachment",
		"description": "Test description",
	}

	body, contentType, err := buildMultipartBody(attachment, params)
	if err != nil {
		t.Fatalf("buildMultipartBody() error = %v", err)
	}

	// Verify content type header
	if !strings.HasPrefix(contentType, "multipart/form-data; boundary=") {
		t.Errorf("Content-Type = %q, want prefix 'multipart/form-data; boundary='", contentType)
	}

	// Verify body is not empty
	if body.Len() == 0 {
		t.Error("buildMultipartBody() returned empty body")
	}
}
