[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$UnityEditor,[switch]$GenerateOnly)
$ErrorActionPreference='Stop'
$Project=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if(!(Test-Path $UnityEditor)){throw "Unity Editor not found: $UnityEditor"}
$Validation=Join-Path $Project 'Validation'
$Receipt=Join-Path $Validation 'UNITY_IMPORT_RECEIPT.json'
if(Test-Path $Receipt){Remove-Item -LiteralPath $Receipt}
$SetupLog=Join-Path $Validation 'unity-generate.log'
& $UnityEditor -batchmode -quit -projectPath $Project -buildTarget Win64 -executeMethod NeonRequiem.Editor.DistrictBuilder.Generate -logFile $SetupLog
if($LASTEXITCODE -ne 0 -or !(Test-Path $Receipt)){throw "Unity generation/compilation failed. Read $SetupLog. No playable build exists."}
if($GenerateOnly){Write-Host 'Generated editable LowTide scene. Open it in Unity and perform visual/gameplay review.';exit 0}
$Tests=Join-Path $Validation 'EditMode.xml'
if(Test-Path $Tests){Remove-Item -LiteralPath $Tests}
& $UnityEditor -batchmode -projectPath $Project -runTests -testPlatform EditMode -assemblyNames NeonRequiem.Tests -testResults $Tests -logFile (Join-Path $Validation 'unity-tests.log')
if($LASTEXITCODE -ne 0 -or !(Test-Path $Tests)){throw 'EditMode tests did not complete. No Windows delivery was produced.'}
[xml]$Report=Get-Content $Tests -Raw
$Root=$Report.'test-run'
if([int]$Root.passed -lt 11 -or [int]$Root.failed -ne 0){throw 'Expected all 11 mission rule tests to pass. Inspect Validation\EditMode.xml.'}
$BuildReceipt=Join-Path $Project 'Builds\BUILD_RECEIPT.json'
if(Test-Path $BuildReceipt){Remove-Item -LiteralPath $BuildReceipt}
& $UnityEditor -batchmode -quit -projectPath $Project -buildTarget Win64 -executeMethod NeonRequiem.Editor.WindowsBuild.Build -logFile (Join-Path $Validation 'unity-build.log')
if($LASTEXITCODE -ne 0 -or !(Test-Path $BuildReceipt)){throw 'Windows build failed. Read Validation\unity-build.log.'}
$Game=Join-Path $Project 'Builds\Windows'
foreach($Part in @('NeonRequiem.exe','UnityPlayer.dll','NeonRequiem_Data\globalgamemanagers')){if(!(Test-Path (Join-Path $Game $Part))){throw "Incomplete player: $Part"}}
$Zip=Join-Path $Project 'Builds\Neon_Requiem_Windows.zip'
$Python=Get-Command python -ErrorAction Stop
& $Python.Source (Join-Path $PSScriptRoot 'package_player.py') $Game $Zip
if($LASTEXITCODE -ne 0){throw 'Player ZIP verification failed.'}
Write-Host "Windows build exists: $Zip"
Write-Host 'Still required: launch the EXE, complete Tools\MANUAL_VALIDATION.md and capture actual screenshots.'
