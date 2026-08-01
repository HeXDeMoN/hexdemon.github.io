MDBList Up Next Manager
======================

Quick usage guide for MDBList_Up_Next_Manager.ps1

Prerequisites
- PowerShell (Windows PowerShell / PowerShell Core)

Usage

1) Set API key via environment variable (recommended for scripts/CI):

```powershell
$env:MDBLIST_APIKEY = 'YOUR_API_KEY_HERE'
& 'G:\github\hexdemon.github.io\MDBlist\MDBList_Up_Next_Manager.ps1'
```

2) Or pass the API key directly when running the script:

```powershell
& 'G:\github\hexdemon.github.io\MDBlist\MDBList_Up_Next_Manager.ps1' -ApiKey 'YOUR_API_KEY_HERE'
```

3) Interactive workflow:
- Choose `1` to export your Up Next list to CSV.
- Edit `upnext_shows.csv` in the `MDBlist` folder and set `drop` or `mark_complete` to `TRUE` for items you want to act on.
- Choose `2` to drop shows marked `drop` or `3` to mark shows complete.

Files
- `upnext_shows.csv` — CSV exported/used by the script (created in the same folder as the script).
- `MDBList_Up_Next_Manager.ps1` — main script.

Security notes
- Prefer `MDBLIST_APIKEY` env var or injected CI secrets over putting keys in scripts.
- For long-term secure storage on Windows, consider PowerShell SecretManagement/SecretStore or Windows Credential Manager.

Troubleshooting
- If you see `System.Object[]` in the API output, the script now prints human-readable `updated` counts and `not_found` entries.
- If the script prompts for an API key, it did not find an env var or `-ApiKey` argument.

Contact
- Open an issue in the repo if you want additional features (logging, dry-run, bulk retries).
