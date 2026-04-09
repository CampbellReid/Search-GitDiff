function Search-GitDiff {
    <#
    .SYNOPSIS
        Search for a pattern across added lines in a git commit diff.

    .PARAMETER CommitId
        The git commit hash to inspect.

    .PARAMETER Pattern
        A regex pattern to search for in added lines.

    .PARAMETER IncludeRemoved
        Also search removed lines (prefixed with '-'). Results are shown separately.

    .EXAMPLE
        Search-GitDiff -CommitId abc1234 -Pattern "shouldUseNewPanelSystem"

    .EXAMPLE
        Search-GitDiff abc1234 "featureFlag\w+" -IncludeRemoved
    #>
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$CommitId,

        [Parameter(Mandatory, Position = 1)]
        [string]$Pattern,

        [switch]$IncludeRemoved
    )

    $addedResults   = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[PSCustomObject]]]::new()
    $removedResults = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[PSCustomObject]]]::new()

    $currentFile   = $null
    $currentLineNum = 0

    git show $CommitId | ForEach-Object {
        $line = $_

        # New file in the diff
        if ($line -match '^diff --git a/.+ b/(.+)$') {
            $currentFile    = $matches[1]
            $currentLineNum = 0
        }
        # Hunk header — extract the new-file start line: @@ -old +new[,count] @@
        elseif ($line -match '^\@\@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? \@\@') {
            $currentLineNum = [int]$matches[1]
        }
        # File header lines — skip, do not affect line counter
        elseif ($line -match '^\+\+\+' -or $line -match '^---') {
            # no-op
        }
        # Added line
        elseif ($line -match '^\+') {
            $content = $line.Substring(1)
            if ($content -match $Pattern) {
                if (-not $addedResults.ContainsKey($currentFile)) {
                    $addedResults[$currentFile] = [System.Collections.Generic.List[PSCustomObject]]::new()
                }
                $addedResults[$currentFile].Add([PSCustomObject]@{ Line = $currentLineNum; Content = $content })
            }
            $currentLineNum++
        }
        # Removed line — does not advance the new-file line counter
        elseif ($line -match '^-') {
            if ($IncludeRemoved) {
                $content = $line.Substring(1)
                if ($content -match $Pattern) {
                    if (-not $removedResults.ContainsKey($currentFile)) {
                        $removedResults[$currentFile] = [System.Collections.Generic.List[PSCustomObject]]::new()
                    }
                    $removedResults[$currentFile].Add([PSCustomObject]@{ Line = $currentLineNum; Content = $content })
                }
            }
        }
        # Context line — advances counter but not a match candidate
        else {
            $currentLineNum++
        }
    }

    function Write-Results {
        param($results, $label, $lineColor)

        $totalMatches = 0
        $results.Keys | Sort-Object | ForEach-Object {
            $file = $_
            Write-Host ""
            Write-Host $file -ForegroundColor Cyan
            $results[$file] | ForEach-Object {
                Write-Host ("  L{0,-5} {1}" -f $_.Line, $_.Content) -ForegroundColor $lineColor
                $totalMatches++
            }
        }

        $fileCount = $results.Count
        Write-Host ""
        if ($totalMatches -eq 0) {
            Write-Host "No $label matches found." -ForegroundColor DarkGray
        } else {
            Write-Host "[$label] $totalMatches match(es) across $fileCount file(s)  |  pattern: '$Pattern'  |  commit: $CommitId" -ForegroundColor Green
        }
    }

    Write-Results -results $addedResults   -label "Added"   -lineColor Yellow
    if ($IncludeRemoved) {
        Write-Results -results $removedResults -label "Removed" -lineColor Red
    }
}
