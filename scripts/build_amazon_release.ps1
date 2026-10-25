$ErrorActionPreference = "Stop"

Write-Host "=== FinTrack - Build Amazon Appstore (Fire OS) ===" -ForegroundColor Cyan

if (-not (Test-Path "android\key.properties")) {
    Write-Host "ERROR: Falta android\key.properties con la firma de producción." -ForegroundColor Red
    Write-Host "Copia android\key.properties.example a android\key.properties y configura tu keystore." -ForegroundColor Yellow
    exit 1
}

flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test

Write-Host "Generando AAB para Amazon con integraciones Google desactivadas..." -ForegroundColor Cyan
flutter build appbundle --release --dart-define=AMAZON_BUILD=true

$aab = "build\app\outputs\bundle\release\app-release.aab"

if (-not (Test-Path $aab)) {
    Write-Host "ERROR: No se generó el AAB esperado." -ForegroundColor Red
    exit 1
}

Write-Host "Build correcto:" -ForegroundColor Green
Get-Item $aab | Select-Object FullName, Length, LastWriteTime
