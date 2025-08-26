#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Sets wallpaper and lock screen images via Windows registry modifications.

.DESCRIPTION
    This script sets the desktop wallpaper and lock screen background by directly
    modifying Windows registry entries. Requires administrator privileges.

.PARAMETER WallpaperPath
    Full path to the wallpaper image file

.PARAMETER LockScreenPath
    Full path to the lock screen image file

.EXAMPLE
    .\Set-WallpaperLockScreen.ps1 -WallpaperPath "C:\Images\wallpaper.jpg" -LockScreenPath "C:\Images\lockscreen.jpg"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$WallpaperPath,
    
    [Parameter(Mandatory=$true)]
    [string]$LockScreenPath
)

# Function to validate image file exists and is valid format
function Test-ImageFile {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        throw "Image file not found: $Path"
    }
    
    $validExtensions = @('.jpg', '.jpeg', '.png', '.bmp', '.gif')
    $extension = [System.IO.Path]::GetExtension($Path).ToLower()
    
    if ($extension -notin $validExtensions) {
        throw "Invalid image format: $extension. Supported formats: $($validExtensions -join ', ')"
    }
    
    return $true
}

# Function to set wallpaper via registry
function Set-WallpaperRegistry {
    param([string]$ImagePath)
    
    Write-Host "Setting wallpaper to: $ImagePath" -ForegroundColor Green
    
    try {
        # Set wallpaper path in registry
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value $ImagePath -Force
        
        # Set wallpaper style (2 = Stretch, 6 = Fit, 10 = Fill, 0 = Center, 1 = Tile)
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallpaperStyle" -Value "10" -Force
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "TileWallpaper" -Value "0" -Force
        
        # Refresh desktop
        $code = @'
        using System;
        using System.Runtime.InteropServices;
        public class Wallpaper {
            [DllImport("user32.dll", CharSet = CharSet.Auto)]
            public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
        }
'@
        
        Add-Type -TypeDefinition $code
        [Wallpaper]::SystemParametersInfo(20, 0, $ImagePath, 3)
        
        Write-Host "Wallpaper set successfully!" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to set wallpaper: $($_.Exception.Message)"
        return $false
    }
    
    return $true
}

# Function to set lock screen via registry
function Set-LockScreenRegistry {
    param([string]$ImagePath)
    
    Write-Host "Setting lock screen to: $ImagePath" -ForegroundColor Green
    
    try {
        # Create PersonalizationCSP registry key if it doesn't exist
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
            Write-Host "Created PersonalizationCSP registry key" -ForegroundColor Yellow
        }
        
        # Set lock screen image path
        Set-ItemProperty -Path $regPath -Name "LockScreenImagePath" -Value $ImagePath -Force
        Set-ItemProperty -Path $regPath -Name "LockScreenImageUrl" -Value $ImagePath -Force
        Set-ItemProperty -Path $regPath -Name "LockScreenImageStatus" -Value 1 -Force
        
        # Additional registry entries for lock screen
        $regPath2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
        if (-not (Test-Path $regPath2)) {
            New-Item -Path $regPath2 -Force | Out-Null
            Write-Host "Created Personalization policy registry key" -ForegroundColor Yellow
        }
        
        Set-ItemProperty -Path $regPath2 -Name "LockScreenImage" -Value $ImagePath -Force
        Set-ItemProperty -Path $regPath2 -Name "NoLockScreenSlideshow" -Value 1 -Force
        
        # User-specific lock screen setting
        $userRegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen\Creative"
        if (-not (Test-Path $userRegPath)) {
            New-Item -Path $userRegPath -Force | Out-Null
        }
        
        Set-ItemProperty -Path $userRegPath -Name "LandscapeAssetPath" -Value $ImagePath -Force
        Set-ItemProperty -Path $userRegPath -Name "PortraitAssetPath" -Value $ImagePath -Force
        
        Write-Host "Lock screen set successfully!" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to set lock screen: $($_.Exception.Message)"
        return $false
    }
    
    return $true
}

# Main execution
Write-Host "=== Wallpaper and Lock Screen Registry Setter ===" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script requires administrator privileges. Please run as administrator."
    exit 1
}

try {
    # Validate input files
    Write-Host "Validating image files..." -ForegroundColor Yellow
    Test-ImageFile -Path $WallpaperPath
    Test-ImageFile -Path $LockScreenPath
    Write-Host "Image files validated successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Set wallpaper
    Write-Host "Setting wallpaper..." -ForegroundColor Yellow
    $wallpaperSuccess = Set-WallpaperRegistry -ImagePath $WallpaperPath
    Write-Host ""
    
    # Set lock screen
    Write-Host "Setting lock screen..." -ForegroundColor Yellow
    $lockScreenSuccess = Set-LockScreenRegistry -ImagePath $LockScreenPath
    Write-Host ""
    
    # Summary
    Write-Host "=== Summary ===" -ForegroundColor Cyan
    Write-Host "Wallpaper: $(if($wallpaperSuccess){'✓ Success'}else{'✗ Failed'})" -ForegroundColor $(if($wallpaperSuccess){'Green'}else{'Red'})
    Write-Host "Lock Screen: $(if($lockScreenSuccess){'✓ Success'}else{'✗ Failed'})" -ForegroundColor $(if($lockScreenSuccess){'Green'}else{'Red'})
    Write-Host ""
    
    if ($wallpaperSuccess -and $lockScreenSuccess) {
        Write-Host "All changes applied successfully! You may need to lock/unlock your screen or restart to see the lock screen changes." -ForegroundColor Green
    } else {
        Write-Host "Some operations failed. Check the error messages above." -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}

Write-Host ""
Write-Host "Script completed." -ForegroundColor Cyan
