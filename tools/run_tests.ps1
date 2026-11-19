# Runs every headless smoke test and exits non-zero if any fails.
# Usage: powershell -File tools/run_tests.ps1 [-Godot <path-to-godot-console-exe>]
param([string]$Godot = $env:GODOT)
if (-not $Godot) { $Godot = "Godot_v4.7.2-stable_win64_console.exe" }
$root = Split-Path -Parent $PSScriptRoot
$tests = @(
  "combat_phase2_smoke", "player_movement_feel_smoke", "sector07_smoke",
  "playtest_recorder_smoke", "phase4_visual_smoke", "phase6_enemy_visual_smoke",
  "phase7_combat_lab_smoke", "zero_kit_smoke", "sector07_zero_route_smoke", "hound_phase_smoke", "enemy_fsm_smoke"
)
& $Godot --headless --path $root --import | Out-Null
$failed = @()
foreach ($t in $tests) {
  Write-Host "== $t"
  $out = & $Godot --headless --path $root --script "res://tests/$t.gd" 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0 -or $out -match "SCRIPT ERROR") { $failed += $t; Write-Host $out; Write-Host "FAIL $t" -ForegroundColor Red }
  else { Write-Host "PASS $t" -ForegroundColor Green }
}
if ($failed.Count) { Write-Host "Failed: $($failed -join ', ')"; exit 1 }
Write-Host "All $($tests.Count) tests passed."
