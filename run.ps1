# run.ps1
Write-Host "=== Running Grade App ===" -ForegroundColor Green

# Ensure emulator is running
$devices = adb devices
if ($devices -notmatch "emulator") {
    Write-Host "Starting emulator..." -ForegroundColor Yellow
    flutter emulators --launch Pixel_6a
    Start-Sleep -Seconds 20
}

# Run the app
Write-Host "Starting Grade App..." -ForegroundColor Green
flutter run