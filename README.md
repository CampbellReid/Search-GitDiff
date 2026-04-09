# Search-GitDiff

A PowerShell utility for searching patterns within specific git commit diffs.

## Features

- Search for regex patterns across added lines in a specific git commit.
- Optionally search across removed lines as well.
- Results are organized by file and include line numbers.
- Color-coded output for readability.

## Installation

1. Clone this repository or download `Search-GitDiff.ps1`.
2. Dot-source the script in your PowerShell session:
   ```powershell
   . .\Search-GitDiff.ps1
   ```

## Usage

### Basic Search
Search for a pattern in added lines of a commit:
```powershell
Search-GitDiff -CommitId <CommitHash> -Pattern "YourRegexPattern"
```

### Search with Removed Lines
Search for a pattern in both added and removed lines:
```powershell
Search-GitDiff -CommitId <CommitHash> -Pattern "YourRegexPattern" -IncludeRemoved
```

## Examples

```powershell
Search-GitDiff -CommitId abc1234 -Pattern "shouldUseNewPanelSystem"
Search-GitDiff abc1234 "featureFlag\w+" -IncludeRemoved
```
