# Specification: Add `lp_list_series` function to `common-workflows.sh`

## Overview
This track adds a new utility function `lp_list_series` to `launchpad/scripts/common-workflows.sh`. This function will allow users to quickly list all series (releases) associated with a Launchpad project (defaulting to Ubuntu).

## Functional Requirements
- **Function Name:** `lp_list_series`
- **Arguments:**
    - `project` (Optional): The Launchpad project name. Defaults to `ubuntu`.
- **Behavior:**
    1. Query the project resource from Launchpad.
    2. Follow the `series_collection_link`.
    3. Iterate through the entries in the series collection.
- **Output:**
    - Format: Tabular text.
    - Fields:
        - `Name` (e.g., `jammy`)
        - `Status` (e.g., `Active`)
        - `Display Name` (e.g., `The Jammy Jellyfish`)
        - `Web Link` (e.g., `https://launchpad.net/ubuntu/jammy`)

## Non-Functional Requirements
- **Consistency:** Follow the existing coding style and naming conventions in `common-workflows.sh`.
- **Dependency:** Utilize existing `lp-api` tool and `jq` for processing.

## Acceptance Criteria
- Running `lp_list_series` (no args) lists Ubuntu series in a table.
- Running `lp_list_series cloud-init` lists series for the `cloud-init` project.
- Output includes Name, Status, Display Name, and Web Link for each series.

## Out of Scope
- Filtering series by status (e.g., "only active").
- Sorting series (will use Launchpad's default order).
