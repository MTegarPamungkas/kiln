param(
  [string]$Version = "latest",
  [string]$Repo = "MTegarPamungkas/kiln",
  [string]$InstallDir = "$env:LOCALAPPDATA\kiln\bin"
)

$ErrorActionPreference = "Stop"
$Asset = "kiln-windows-x64.exe"

if ($Version -eq "latest") {
  $BaseUrl = "https://github.com/$Repo/releases/latest/download"
} else {
  $BaseUrl = "https://github.com/$Repo/releases/download/$Version"
}

$TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("kiln-install-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $TempDir | Out-Null

try {
  $BinPath = Join-Path $TempDir $Asset
  $SumsPath = Join-Path $TempDir "SHA256SUMS.txt"

  Write-Host "Downloading $Asset from $BaseUrl..."
  Invoke-WebRequest -Uri "$BaseUrl/$Asset" -OutFile $BinPath
  Invoke-WebRequest -Uri "$BaseUrl/SHA256SUMS.txt" -OutFile $SumsPath

  $ExpectedLine = Get-Content $SumsPath | Where-Object { $_ -match "\s$([regex]::Escape($Asset))$" } | Select-Object -First 1
  if (-not $ExpectedLine) {
    throw "Checksum for $Asset not found in SHA256SUMS.txt"
  }
  $Expected = ($ExpectedLine -split "\s+")[0].ToLowerInvariant()
  $Actual = (Get-FileHash -Path $BinPath -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($Actual -ne $Expected) {
    throw "Checksum mismatch for $Asset (expected $Expected, got $Actual)"
  }

  New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
  $Target = Join-Path $InstallDir "kiln.exe"
  Move-Item -Force -Path $BinPath -Destination $Target

  $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
  $Entries = if ($UserPath) { $UserPath -split ";" } else { @() }
  if ($Entries -notcontains $InstallDir) {
    $NewPath = if ($UserPath) { "$UserPath;$InstallDir" } else { $InstallDir }
    [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
    Write-Host "Added $InstallDir to your user PATH. Restart your terminal to use 'kiln'."
  }

  Write-Host "Installed kiln to $Target"
} finally {
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $TempDir
}
