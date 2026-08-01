<#
    MDBList Up Next Manager (Enhanced Version)
    Features:
      ✔ Fetch ALL Up Next shows
      ✔ Sort by last_watched_at (newest → oldest)
      ✔ Deduplicate by mdblist_id
      ✔ Export CSV with:
            title
            mdblist_id
            last_watched_at
            completion_percentage
            drop
            mark_complete
      ✔ Drop shows using /sync/dropped
      ✔ Mark shows complete using /sync/watched
#>

# -----------------------------
# CONFIG / PARAMS
# -----------------------------
param(
    [string]$ApiKey = $env:MDBLIST_APIKEY
)

if (-not $ApiKey) {
    $secure = Read-Host -Prompt "Enter MDBList API key" -AsSecureString
    $ApiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    )
}

$CsvPath  = "$PSScriptRoot\upnext_shows.csv"

# Export resolved ApiKey to global scope so dot-sourced sessions and manual function calls can access it
Set-Variable -Name ApiKey -Value $ApiKey -Scope Global -Force
Set-Variable -Name MDBLIST_APIKEY -Value $ApiKey -Scope Global -Force

# -----------------------------
# FUNCTION: EXPORT UP NEXT
# -----------------------------
function Export-UpNextToCsv {
    Write-Host "Fetching Up Next..."

    $url = "https://api.mdblist.com/upnext?apikey=$ApiKey&limit=500&offset=0"
    Write-Host "Request URL: $url"

    try {
        $response = Invoke-RestMethod -Uri $url -Method GET -ErrorAction Stop
    }
    catch {
        Write-Host "Error fetching Up Next" -ForegroundColor Red
        Write-Host $_.Exception.Message
        return
    }

    if (-not $response.items) {
        Write-Host "No items returned."
        return
    }

    # Deduplicate by mdblist ID
    $unique = $response.items |
        Group-Object { $_.show.ids.mdblist } |
        ForEach-Object { $_.Group[0] }

    # Sort by last watched date (newest first)
    $sorted = $unique | Sort-Object { $_.last_watched_at } -Descending

    # Build CSV rows
    $rows = foreach ($item in $sorted) {

        $watched = $item.progress.watched_episode_count
        $total   = $item.progress.total_episode_count

        # Calculate percentage safely
        if ($total -eq 0) {
            $percent = 0
        } else {
            $percent = [math]::Round(($watched / $total) * 100, 2)
        }

        [PSCustomObject]@{
            title                 = $item.show.title
            mdblist_id            = $item.show.ids.mdblist
            last_watched_at       = $item.last_watched_at
            completion_percentage = $percent
            drop                  = $false
            mark_complete         = $false
        }
    }

    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host "CSV created: $CsvPath"
}

# -----------------------------
# FUNCTION: DROP SHOWS
# -----------------------------
function Drop-ShowsFromCsv {
    if (-not (Test-Path $CsvPath)) {
        Write-Host "CSV not found: $CsvPath"
        return
    }

    $csv = Import-Csv $CsvPath
    $toDrop = $csv | Where-Object { $_.drop -eq "true" }

    if ($toDrop.Count -eq 0) {
        Write-Host "No shows marked for dropping."
        return
    }

    foreach ($show in $toDrop) {
        Write-Host "Dropping: $($show.title) (ID: $($show.mdblist_id))"

        $payload = @{
            shows = @(
                @{
                    ids = @{
                        mdblist = [string]($show.mdblist_id).Trim()   # ensure ID is a string
                    }
                }
            )
        } | ConvertTo-Json -Depth 5

        $dropUrl = "https://api.mdblist.com/sync/dropped?apikey=$ApiKey"

        try {
            $result = Invoke-RestMethod -Uri $dropUrl -Method POST -Body $payload -ContentType "application/json" -ErrorAction Stop
            Write-Host "Dropped: $($show.title)"

            if ($result.updated) {
                $u = $result.updated
                Write-Host "Updated counts - movies:$($u.movies) shows:$($u.shows) seasons:$($u.seasons) episodes:$($u.episodes)"
            }

            if ($result.not_found) {
                $nf = $result.not_found
                $types = @('movies','shows','seasons','episodes')
                foreach ($t in $types) {
                    $items = $nf.$t
                    if ($items -and $items.Count -gt 0) {
                        Write-Host "Not found ($t):"
                        foreach ($it in $items) {
                            if ($it.ids -and $it.ids.mdblist) {
                                Write-Host " - mdblist:$($it.ids.mdblist) - $($it.error)"
                            }
                            elseif ($it.ids) {
                                Write-Host " - ids: $((($it.ids) | ConvertTo-Json -Depth 3)) - $($it.error)"
                            }
                            else {
                                Write-Host " - $((($it) | ConvertTo-Json -Depth 3))"
                            }
                        }
                    }
                }
            }

            if ($result.errors) {
                Write-Host "Errors:"
                Write-Host ($result.errors | ConvertTo-Json -Depth 5)
            }
        }
        catch {
            Write-Host "Failed to drop: $($show.title)" -ForegroundColor Red
            Write-Host $_.Exception.Message
        }
    }
}

# -----------------------------
# FUNCTION: MARK COMPLETE
# -----------------------------
function Mark-ShowsCompleteFromCsv {
    if (-not (Test-Path $CsvPath)) {
        Write-Host "CSV not found: $CsvPath"
        return
    }

    $csv = Import-Csv $CsvPath
    $toComplete = $csv | Where-Object { $_.mark_complete -eq "true" }

    if ($toComplete.Count -eq 0) {
        Write-Host "No shows marked for completion."
        return
    }

    foreach ($show in $toComplete) {
        Write-Host "Marking complete: $($show.title) (ID: $($show.mdblist_id))"

        $payload = @{
            shows = @(
                @{
                    ids = @{
                        mdblist = [string]($show.mdblist_id).Trim()   # ensure ID is a string
                    }
                }
            )
        } | ConvertTo-Json -Depth 5

        $completeUrl = "https://api.mdblist.com/sync/watched?apikey=$ApiKey"

        try {
            $result = Invoke-RestMethod -Uri $completeUrl -Method POST -Body $payload -ContentType "application/json" -ErrorAction Stop
            Write-Host "Marked complete: $($show.title)"

            if ($result.updated) {
                $u = $result.updated
                Write-Host "Updated counts - movies:$($u.movies) shows:$($u.shows) seasons:$($u.seasons) episodes:$($u.episodes)"
            }

            if ($result.not_found) {
                $nf = $result.not_found
                $types = @('movies','shows','seasons','episodes')
                foreach ($t in $types) {
                    $items = $nf.$t
                    if ($items -and $items.Count -gt 0) {
                        Write-Host "Not found ($t):"
                        foreach ($it in $items) {
                            if ($it.ids -and $it.ids.mdblist) {
                                Write-Host " - mdblist:$($it.ids.mdblist) - $($it.error)"
                            }
                            elseif ($it.ids) {
                                Write-Host " - ids: $((($it.ids) | ConvertTo-Json -Depth 3)) - $($it.error)"
                            }
                            else {
                                Write-Host " - $((($it) | ConvertTo-Json -Depth 3))"
                            }
                        }
                    }
                }
            }

            if ($result.errors) {
                Write-Host "Errors:"
                Write-Host ($result.errors | ConvertTo-Json -Depth 5)
            }
        }
        catch {
            Write-Host "Failed to mark complete: $($show.title)" -ForegroundColor Red
            Write-Host $_.Exception.Message
        }
    }
}

# -----------------------------
# MAIN MENU
# -----------------------------
Write-Host "MDBList Up Next Manager"
Write-Host "1) Export Up Next to CSV"
Write-Host "2) Drop shows marked in CSV"
Write-Host "3) Mark shows complete in CSV"
$choice = Read-Host "Choose an option"

switch ($choice) {
    "1" { Export-UpNextToCsv }
    "2" { Drop-ShowsFromCsv }
    "3" { Mark-ShowsCompleteFromCsv }
    default { Write-Host "Invalid choice." }
}
