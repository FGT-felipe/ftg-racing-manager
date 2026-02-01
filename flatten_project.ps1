# Script para aplanar estructura de proyecto Flutter
$ErrorActionPreference = "Stop"

# 1. Identificar si existe una subcarpeta que contenga pubspec.yaml
Write-Host "[*] Buscando carpeta del proyecto..." -ForegroundColor Yellow
$rootPath = Get-Location
$subFolder = Get-ChildItem -Directory | Where-Object { Test-Path (Join-Path $_.FullName "pubspec.yaml") } | Select-Object -First 1

if ($null -eq $subFolder) {
    Write-Host "[-] ERROR: No se encontró ninguna subcarpeta con 'pubspec.yaml' en $($rootPath.Path)." -ForegroundColor Red
    return
}

Write-Host "[+] Proyecto detectado en: '$($subFolder.Name)'" -ForegroundColor Cyan
Write-Host "[*] Moviendo archivos y carpetas a la raíz..." -ForegroundColor Yellow

# 2. Mover TODO el contenido (incluyendo archivos ocultos como .gitignore, .metadata, etc.)
# Obtenemos todos los items (Force incluye ocultos), excluyendo la carpeta .git para no romper el repo
$items = Get-ChildItem -Path $subFolder.FullName -Force | Where-Object { $_.Name -ne ".git" }

foreach ($item in $items) {
    $targetPath = Join-Path $rootPath $item.Name
    
    # Manejar conflictos de nombre: sobrescribir eliminando el destino previo si existe
    if (Test-Path $targetPath) {
        Write-Host "    - Reemplazando: $($item.Name)" -ForegroundColor Gray
        Remove-Item -Path $targetPath -Recurse -Force
    }
    
    Move-Item -Path $item.FullName -Destination $targetPath -Force
}

# 3. Borrar la subcarpeta original que ahora debería estar vacía o solo con .git
Write-Host "[*] Limpiando carpeta residual..." -ForegroundColor Yellow
if (Test-Path $subFolder.FullName) {
    Remove-Item -Path $subFolder.FullName -Recurse -Force
}

# 4. Ejecutar flutter pub get
Write-Host "[*] Reparando dependencias..." -ForegroundColor Yellow
flutter pub get

# 5. Re-vincular Firebase
Write-Host "[*] Iniciando configuración de FlutterFire..." -ForegroundColor Yellow
Write-Host "    (Selecciona tu proyecto e opciones interactivamente a continuación)" -ForegroundColor Gray
dart pub global run flutterfire_cli:flutterfire configure

Write-Host "`n[+] LISTO: El proyecto ha sido aplanado y las dependencias actualizadas." -ForegroundColor Green