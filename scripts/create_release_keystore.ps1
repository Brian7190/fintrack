$ErrorActionPreference = "Stop"

$keystore = "android\upload-keystore.jks"

if (Test-Path $keystore) {
    Write-Host "Ya existe $keystore. No se sobrescribirá." -ForegroundColor Yellow
    exit 1
}

Write-Host "Se abrirá keytool para crear la firma de producción de FinTrack." -ForegroundColor Cyan
Write-Host "Guarda las contraseñas en un lugar seguro; las necesitarás para futuras actualizaciones." -ForegroundColor Yellow

keytool -genkeypair -v `
    -keystore $keystore `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -alias fintrack

Write-Host "Keystore creado en $keystore" -ForegroundColor Green
Write-Host "Ahora copia android\key.properties.example a android\key.properties y coloca las contraseñas que elegiste." -ForegroundColor Cyan
