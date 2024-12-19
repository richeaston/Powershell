# Define the path to the Google Chrome bookmarks file
$bookmarksFilePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Bookmarks"

# Check if the bookmarks file exists
if (Test-Path $bookmarksFilePath) {
    # Read the contents of the bookmarks file
    $bookmarksContent = Get-Content $bookmarksFilePath -Raw | ConvertFrom-Json

    # Function to recursively retrieve bookmarks from the "Go-Ahead" section
    function Get-SFWBookmarks {
        param (
            [Parameter(Mandatory = $true)]
            $nodes
        )

        $results = @()

        foreach ($node in $nodes) {
            if ($node.name -eq '[favfolder]' -and $node.type -eq 'folder') {
                foreach ($child in $node.children) {
                    if ($child.type -eq 'url') {
                        $results += [PSCustomObject]@{
                            Name = $child.name
                            URL  = $child.url
                        }
                    }
                    elseif ($child.type -eq 'folder' -and $child.children) {
                        # Check for URLs in subfolders
                        $results += Get-SFWBookmarks -nodes $child.children
                    }
                }
            }
        }

        return $results
    }

    # Initialize an array to hold Go-Ahead bookmarks
    $SFWBookmarks = @()

    # Check all roots for the Go-Ahead folder
    foreach ($root in $bookmarksContent.roots.PSObject.Properties) {
        if ($root.Value.children) {
            $SFWBookmarks += Get-SFWBookmarks -nodes $root.Value.children
        }
    }

    # Output the Go-Ahead bookmarks
    if ($SFWBookmarks.Count -eq 0) {
        Write-Host "No bookmarks found in the 'Go-Ahead' section."
        exit
    }
}
else {
    Write-Host "Bookmarks file not found."
    exit
}

# Load the Windows Forms assembly for SendKeys
Add-Type -AssemblyName System.Windows.Forms

# Function to close the currently focused Chrome tab
function Close-ChromeTab {
    Start-Sleep -Milliseconds 500  # Brief delay to allow for focus
    [System.Windows.Forms.SendKeys]::SendWait("^{w}")  # Send Ctrl + W to close the tab
    Write-Host "Closed the current Chrome tab."
}

# Infinite loop to keep opening URLs until stopped manually
while ($true) {
    # Select a random bookmark
    $randomIndex = Get-Random -Minimum 0 -Maximum $SFWdBookmarks.Count
    $randomBookmark = $SFWdBookmarks[$randomIndex]

    # Open the URL in Chrome
    Start-Process "C:\Program Files\Google\Chrome\Application\chrome.exe" -ArgumentList $randomBookmark.URL

    # Wait for a random time between 10 and 15 seconds
    $waitTime = Get-Random -Minimum 10 -Maximum 60
    Start-Sleep -Seconds $waitTime

    # Close the currently focused Chrome tab
    Close-ChromeTab
    Write-Host "Closed the Chrome instance for: $($randomBookmark.Name) ($($randomBookmark.URL)) after $waitTime seconds."
}
