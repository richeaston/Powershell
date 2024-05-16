Clear-Host
$excluded = @('onedrive', 'edge', 'ui.xaml')
if (!(test-path .\My-Installed-apps.csv)) {
    Write-Warning "No File Catalogue found!"
}
else {
    $excluded = @('onedrive', 'edge', 'ui.xaml')
    foreach ($app in (Import-Csv -Path .\My-Installed-apps.csv)) {
        if ($app.Name -notmatch ($excluded -join '|')) {
            Write-Host "Searching for " -NoNewline -ForegroundColor Yellow
            Write-Host $app.Name -ForegroundColor Cyan -NoNewline
            Write-Host ", Please Wait..." -ForegroundColor Yellow
            $appsearch = winget search --id $app.ID --exact
            if ($appsearch) {
                Write-Output $appsearch
                Winget install --id $app.ID --exact --silent --accept-package-agreements --accept-source-agreements
                Write-Host ""
            }
        }
        else {
            Write-Host "⚠️  $($app.Name) Excluded.!" -ForegroundColor Magenta
        }
    }
    Write-host "`n✔️  File Catalogue Processed." -ForegroundColor Green
}
