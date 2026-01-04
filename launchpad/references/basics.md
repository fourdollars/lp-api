# Launchpad API Basics

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
