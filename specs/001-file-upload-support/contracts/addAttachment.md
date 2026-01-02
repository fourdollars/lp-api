# Contract: addAttachment Operation

**Operation**: `ws.op=addAttachment`  
**Resource**: Bug (`bugs/<bug_id>`)  
**HTTP Method**: POST  
**Content-Type**: multipart/form-data

## Request Format

### CLI Command
```bash
lp-api post bugs/<bug_id> ws.op=addAttachment attachment=@<filepath> description="<text>"
```

### HTTP Request (multipart/form-data)

```http
POST /devel/bugs/123456 HTTP/1.1
Host: api.launchpad.net
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW
Authorization: OAuth oauth_consumer_key="...", oauth_token="...", ...

------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="ws.op"

addAttachment
------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="data"; filename="error.log"
Content-Type: text/plain

[File content here]
------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="description"

Error log from production server
------WebKitFormBoundary7MA4YWxkTrZu0gW--
```

## Request Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ws.op` | string | Yes | Must be "addAttachment" |
| `data` | binary | Yes | File content (multipart field with filename) |
| `comment` | string | **Yes** | **Required** comment to add with attachment |
| `filename` | string | **Yes** | **Required** filename (auto-filled from file path) |
| `description` | string | No | Optional human-readable description of attachment |
| `is_patch` | boolean | No | Whether file is a code patch (default: false) |
| `content_type` | string | No | MIME type (auto-detected if omitted) |

### CLI to HTTP Parameter Mapping

| CLI Syntax | HTTP Parameter | Notes |
|------------|----------------|-------|
| `ws.op=addAttachment` | `ws.op` | Operation name |
| `attachment=@/path/file.log` | `data` field + `filename` | @ prefix triggers file read, filename auto-filled |
| `comment="text"` | `comment` | **Required** - comment text |
| `description="text"` | `description` | Optional description |

## Response Format

### Success Response (201 Created)

```json
{
  "self_link": "https://api.launchpad.net/devel/bugs/123456/+attachment/789012",
  "web_link": "https://bugs.launchpad.net/bugs/123456/+attachment/789012",
  "resource_type_link": "https://api.launchpad.net/devel/#bug_attachment",
  "http_etag": "\"abc123...\"",
  "title": "error.log",
  "data_link": "https://launchpadlibrarian.net/12345/error.log",
  "type": "Unspecified",
  "is_patch": false,
  "message_link": null
}
```

**Key Fields**:
- `self_link`: API URL for the attachment resource
- `web_link`: Browser URL to view attachment
- `data_link`: Direct download URL
- `title`: Filename as stored
- `type`: Attachment type classification

### Error Responses

#### 401 Unauthorized
```json
{
  "error_summary": "Unauthorized",
  "error_message": "You need to be logged in to add attachments"
}
```

#### 404 Not Found
```json
{
  "error_summary": "Not Found",
  "error_message": "Bug with ID 999999 does not exist"
}
```

#### 413 Payload Too Large
```json
{
  "error_summary": "Request Entity Too Large",
  "error_message": "The file size exceeds the maximum allowed (10MB)"
}
```

#### 400 Bad Request
```json
{
  "error_summary": "Bad Request",
  "error_message": "Required parameter 'data' is missing"
}
```

## Test Cases

### Test Case 1: Upload Text File (Log)
```bash
# Given: A text log file
echo "ERROR: Connection timeout" > /tmp/test.log

# When: Attaching to bug
lp-api post bugs/1 ws.op=addAttachment attachment=@/tmp/test.log comment="Test log"

# Then: Response contains attachment metadata
# Expected output (stdout):
{
  "self_link": "https://api.launchpad.net/devel/bugs/1/+attachment/...",
  "title": "test.log",
  "data_link": "https://launchpadlibrarian.net/.../test.log"
}

# Exit code: 0
```

### Test Case 2: Upload Image File
```bash
# Given: A PNG screenshot
# (assuming screenshot.png exists)

# When: Attaching to bug
lp-api post bugs/1 ws.op=addAttachment attachment=@screenshot.png comment="UI bug screenshot" description="Shows rendering issue"

# Then: Image is uploaded
# Expected: Similar JSON response with image MIME type
# Exit code: 0
```

### Test Case 3: Missing Required Comment Error
```bash
# Given: File exists but no comment provided
# When: Attempting to attach without comment
lp-api post bugs/1 ws.op=addAttachment attachment=@/tmp/test.log

# Then: Clear error message
# Expected output (stderr):
Error: 'comment' parameter is required when attaching files

# Exit code: 1 (non-zero)
```

### Test Case 4: File Not Found Error
```bash
# Given: Non-existent file path
# When: Attempting to attach
lp-api post bugs/1 ws.op=addAttachment attachment=@/nonexistent/file.log comment="Test"

# Then: Clear error message
# Expected output (stderr):
Error: File not found: /nonexistent/file.log

# Exit code: 1 (non-zero)
```

### Test Case 4: Permission Denied Error
```bash
# Given: File without read permission
touch /tmp/noperm.log && chmod 000 /tmp/noperm.log

# When: Attempting to attach
lp-api post bugs/1 ws.op=addAttachment attachment=@/tmp/noperm.log

# Then: Clear error message
# Expected output (stderr):
Error: Cannot read file: permission denied

# Exit code: 1 (non-zero)
```

### Test Case 5: Large File Upload
```bash
# Given: A 5MB file
dd if=/dev/zero of=/tmp/large.bin bs=1M count=5

# When: Attaching to bug
lp-api post bugs/1 ws.op=addAttachment attachment=@/tmp/large.bin description="Large file test"

# Then: Upload completes or API returns size error
# Expected: Either success or API error passed through to stderr
```

## Implementation Checklist

- [ ] Detect `@` prefix in CLI parameter values
- [ ] Extract file path from `attachment=@<path>` syntax
- [ ] Validate file exists and is readable
- [ ] Read file content into memory
- [ ] Detect MIME type from file extension
- [ ] Construct multipart/form-data request body
- [ ] Set proper Content-Type header with boundary
- [ ] Include all form fields (ws.op, data, description, etc.)
- [ ] Send POST request with OAuth authentication
- [ ] Parse JSON response on success
- [ ] Output response to stdout (JSON format)
- [ ] Handle errors with clear messages to stderr
- [ ] Return appropriate exit codes (0 = success, 1 = error)

## Notes

- **File size limit**: Likely 5-10MB based on typical bug tracker limits (verify with API)
- **MIME type**: Auto-detection preferred, but optional manual override via `content_type=` param
- **Multiple files**: Not supported in MVP (P1), single file per command invocation
- **Binary safety**: Multipart encoding handles binary data correctly (no base64 needed)
- **Streaming**: Not required for typical attachment sizes, in-memory reading is sufficient
