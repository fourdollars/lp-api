# Launchpad API Basics

## CLI Usage

### Command Options
```bash
-conf string      # Config file path (default: ~/.config/lp-api.toml; use -conf to specify local path)
-debug           # Show debug messages including OAuth headers
-help            # Show help message
-key string      # OAuth consumer key (default: "System-wide: golang...")
-output string   # Save output to file instead of stdout
-staging         # Use Launchpad staging server (api.staging.launchpad.net)
-timeout duration # API request timeout (default: 10s)
```

### Authentication
The tool handles OAuth authentication automatically.
- **Interactive:** First run creates `.lp-api.toml` and prompts for authorization.
- **CI/CD:** Export `LAUNCHPAD_TOKEN="oauth_token:oauth_secret:consumer_key"`.

## Core Operations

### 1. Resource Querying (GET)
Query any Launchpad resource by its path.
```bash
lp-api get <resource-path> [query-parameters]
```
Example: `lp-api get people/+me`

### 2. Resource Modification (PATCH)
Update existing resources using JSON data with `:=` syntax.
```bash
lp-api patch <resource-path> field:='json-value'
```
Example: `lp-api patch bugs/12345 tags:='["focal"]'`

### 3. Resource Creation (POST)
Create new resources or invoke operations (like `newMessage`, `searchTasks`).
```bash
lp-api post <resource-path> ws.op=<operation> param=value
```
Example: `lp-api post bugs/12345 ws.op=newMessage content="Comment"`

### 4. Resource Replacement (PUT)
Replace entire resource with JSON file content.
```bash
lp-api put <resource-path> <json-file>
```

### 5. Resource Deletion (DELETE)
Remove resources when permissions allow.
```bash
lp-api delete <resource-path>
```

### 6. Piping Resource Links
Extract and follow resource links from JSON output using the `.fieldname` syntax.
```bash
lp-api get <resource> | lp-api .<link-field>
```
Example: `lp-api get ubuntu | lp-api .series_collection_link`

## URL Structure
The Launchpad API is RESTful.
- **Base URL:** `https://api.launchpad.net/devel/`
- **Resources:** Accessed by hierarchy (e.g., `ubuntu/noble`, `bugs/1`).

## Common Parameters

### Pagination & Control
- `ws.start`: Offset for results (default: 0).
- `ws.size`: Number of results to return (default varies, max often 300).
- `ws.show`: Set to `total_size` to get only the count of results.

```bash
# Get count of bugs
lp-api get ubuntu ws.op==searchTasks ws.show==total_size
```

### Date Filters
Many collections support these filters:
- `created_since`, `created_before`
- `modified_since`, `modified_before`
- Format: `YYYY-MM-DD`

### Sorting
- `order_by`: Field name. Prefix with `-` for descending order (e.g., `-date_created`).

## Miscellaneous Resources

### Translations
- **Project Translations:** `<project>/+translations`
- **Templates:** `<project>/+pots/<template-name>`

### Specifications (Blueprints)
- **List:** `<project>/+specs`
- **Specific:** `<project>/+spec/<name>`

### Questions
- **List:** `<project>/+questions`
- **Specific:** `<project>/+question/<id>`

### Builders
- **List:** `+builds`
- **Specific:** `+builds/<builder-name>`

## Discovering Operations
To find what operations are available for a resource, you can often check the `resource_type_link` or look for `ws.op` values in the WADL documentation.

Common operations include:
- `searchTasks` (Bugs)
- `getFileUrls` (Builds)
- `getPublishedSources` (Archives)