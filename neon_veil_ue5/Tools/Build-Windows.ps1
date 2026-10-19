[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$UEPath,
    [ValidateSet('Development','Shipping')][string]$Configuration='Shipping',
    [switch]$SourceOnly
)
$ErrorActionPreference='Stop'
$ProjectRoot=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Project=Join-Path $ProjectRoot 'NeonVeil.uproject'
$Build=Join-Path $UEPath 'Engine\Build\BatchFiles\Build.bat'
$Editor=Join-Path $UEPath 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe'
$UAT=Join-Path $UEPath 'Engine\Build\BatchFiles\RunUAT.bat'
foreach($File in @($Project,$Build,$Editor,$UAT)) {
    if(!(Test-Path $File)){ throw "Required file missing: $File" }
}
$Version=Get-Content (Join-Path $UEPath 'Engine\Build\Build.version') -Raw | ConvertFrom-Json
if($Version.MajorVersion -ne 5 -or $Version.MinorVersion -ne 4) {
    throw 'This source targets UE 5.4. Install UE 5.4.x or deliberately port and validate the source before packaging.'
}
Write-Host 'Building the actual native Editor module (UnrealHeaderTool + C++ compiler)...'
& $Build NeonVeilEditor Win64 Development $Project -WaitMutex -NoHotReloadFromIDE
if($LASTEXITCODE -ne 0){throw "Editor module compilation failed: $LASTEXITCODE. Read the UnrealBuildTool output; no package was created."}
$Receipt=Join-Path $ProjectRoot 'Saved\BootstrapReceipt.json'
# Only a fresh receipt can establish that this import run completed.
if(Test-Path $Receipt){Remove-Item -LiteralPath $Receipt}
$Bootstrap=Join-Path $PSScriptRoot 'bootstrap.py'
& $Editor $Project -run=pythonscript "-script=$Bootstrap" -unattended -nop4 -nosplash -NullRHI -stdout -FullStdOutLogOutput
if($LASTEXITCODE -ne 0 -or !(Test-Path $Receipt)){throw 'Asset/map bootstrap failed. Read Saved\Logs\NeonVeil.log. No packaged-game claim is valid.'}
if($SourceOnly){Write-Host 'Editor target and imported project are ready for Play In Editor validation. Packaging skipped by request.';exit 0}
$Archive=Join-Path $ProjectRoot 'BuildOutput'
& $UAT BuildCookRun "-project=$Project" -noP4 -utf8output -platform=Win64 "-clientconfig=$Configuration" -build -cook -allmaps -stage -pak -iostore -archive "-archivedirectory=$Archive" -prereqs
if($LASTEXITCODE -ne 0){throw "Windows build/cook/package failed: $LASTEXITCODE. No complete standalone delivery exists."}
$Launchers=@(Get-ChildItem $Archive -Filter NeonVeil.exe -File -Recurse)
if($Launchers.Count -eq 0){throw 'Packaging returned success but no NeonVeil.exe exists.'}
$GameRoot=($Launchers | Sort-Object { $_.FullName.Length } | Select-Object -First 1).Directory.FullName
$RuntimeBinaries=@(Get-ChildItem (Join-Path $GameRoot 'NeonVeil\Binaries\Win64') -Filter 'NeonVeil*.exe' -File)
if($RuntimeBinaries.Count -eq 0){throw 'Bootstrap EXE exists but the actual game binary is missing.'}
$Packs=@(Get-ChildItem $GameRoot -Filter '*.utoc' -File -Recurse)
$Containers=@(Get-ChildItem $GameRoot -Filter '*.ucas' -File -Recurse)
if($Packs.Count -eq 0 -or $Containers.Count -eq 0){throw 'Cooked IoStore game data is missing.'}
Copy-Item (Join-Path $ProjectRoot 'PLAYER_README.txt') (Join-Path $GameRoot 'READ_ME.txt') -Force
$Zip=Join-Path $Archive 'Neon_Veil_UE5_Windows.zip'
# Archive the entire staged tree: launcher, Binaries, Engine, Content/Paks and prerequisites.
# Python zipfile supports ZIP64 for large UE packages; Compress-Archive has a 2 GB file limit.
$Python=Get-Command python -ErrorAction Stop
& $Python.Source (Join-Path $PSScriptRoot 'package_windows.py') $GameRoot $Zip
if($LASTEXITCODE -ne 0){throw 'ZIP packaging or integrity validation failed.'}
Write-Host "Packaged build exists: $Zip"
Write-Host 'NEXT REQUIRED CHECK: launch the game and complete Tools\MANUAL_VALIDATION.md on the target Windows GPU.'
