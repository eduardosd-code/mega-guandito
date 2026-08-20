param(
    [string]$SourcePath = "$PSScriptRoot\..\docs\concept\sector_07_enemy_spritesheet.png",
    [string]$OutputRoot = "$PSScriptRoot\..\assets\enemies\sector_07"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$animations = @(
    @('scrapper','idle',6,145,126,222,76,64,64,'feet'), @('scrapper','run',8,367,126,230,76,64,64,'feet'),
    @('scrapper','attack_1',4,597,126,241,76,64,64,'feet'), @('scrapper','attack_2',5,838,126,270,76,64,64,'feet'),
    @('scrapper','hit',3,1108,126,151,76,64,64,'feet'), @('scrapper','death',6,1259,126,258,76,64,64,'feet'),
    @('bulwark','idle',6,146,334,227,88,96,96,'feet'), @('bulwark','walk',6,374,334,180,88,96,96,'feet'),
    @('bulwark','attack_hammer_fist',5,555,334,194,88,96,96,'feet'), @('bulwark','attack_charge',6,750,334,194,88,96,96,'feet'),
    @('bulwark','attack_backhand',4,945,334,185,88,96,96,'feet'), @('bulwark','hit',3,1131,334,137,88,96,96,'feet'),
    @('bulwark','death',7,1269,334,248,88,96,96,'feet'),
    @('sentry','hover_idle',6,145,548,216,78,64,64,'center'), @('sentry','move',4,362,548,143,78,64,64,'center'),
    @('sentry','pulse_shot',5,506,548,284,78,64,64,'center'), @('sentry','triple_pulse',7,791,548,343,78,64,64,'center'),
    @('sentry','hit',3,1135,548,134,78,64,64,'center'), @('sentry','death',6,1270,548,247,78,64,64,'center'),
    @('hound','idle',6,146,740,164,72,160,96,'feet'), @('hound','walk_prowl',6,311,740,164,72,160,96,'feet'),
    @('hound','charge',5,476,740,185,72,160,96,'feet'), @('hound','pounce',6,662,740,184,72,160,96,'feet'),
    @('hound','claw_combo',6,847,740,205,72,160,96,'feet'), @('hound','energy_burst',8,1053,740,242,72,160,96,'feet'),
    @('hound','hit',3,1296,740,74,72,160,96,'feet'), @('hound','death',8,1371,740,146,72,160,96,'feet')
)

# The production sheet is not a true atlas. These four isolated scale-reference
# poses are the only silhouettes safe enough to use without slicing characters.
# They are repeated as explicit placeholders until clean source frames arrive.
$safePoses = @{
    scrapper = @(25,228,55,48); bulwark = @(18,438,68,59)
    sentry = @(18,648,58,44); hound = @(14,839,120,51)
}

function Test-Backdrop([System.Drawing.Color]$color) {
    return $color.A -gt 0 -and $color.R -lt 72 -and $color.G -lt 72 -and $color.B -lt 82 -and
        (($color.B - $color.R) -ge 4) -and (($color.B - $color.G) -ge 1)
}

function Remove-Backdrop([System.Drawing.Bitmap]$bitmap) {
    $w = $bitmap.Width; $h = $bitmap.Height
    $visited = New-Object 'bool[]' ($w * $h)
    $queue = New-Object 'int[]' ($w * $h)
    $head = 0; $tail = 0
    for ($x = 0; $x -lt $w; $x++) {
        foreach ($y in @(0, ($h - 1))) { $i = $y * $w + $x; if (-not $visited[$i] -and (Test-Backdrop $bitmap.GetPixel($x,$y))) { $visited[$i]=$true; $queue[$tail++]=$i } }
    }
    for ($y = 0; $y -lt $h; $y++) {
        foreach ($x in @(0, ($w - 1))) { $i = $y * $w + $x; if (-not $visited[$i] -and (Test-Backdrop $bitmap.GetPixel($x,$y))) { $visited[$i]=$true; $queue[$tail++]=$i } }
    }
    $dx = @(1,-1,0,0); $dy = @(0,0,1,-1)
    while ($head -lt $tail) {
        $i=$queue[$head++]; $x=$i % $w; $y=[math]::Floor($i/$w); $bitmap.SetPixel($x,$y,[Drawing.Color]::Transparent)
        for ($d=0; $d-lt 4; $d++) { $nx=$x+$dx[$d]; $ny=$y+$dy[$d]; if ($nx-lt 0 -or $ny-lt 0 -or $nx-ge $w -or $ny-ge $h) { continue }; $ni=$ny*$w+$nx; if (-not $visited[$ni] -and (Test-Backdrop $bitmap.GetPixel($nx,$ny))) { $visited[$ni]=$true; $queue[$tail++]=$ni } }
    }
}

function Build-Atlas($source, $spec) {
    $enemy=$spec[0]; $name=$spec[1]; $count=[int]$spec[2]; $sx=[int]$spec[3]; $sy=[int]$spec[4]; $sw=[int]$spec[5]; $sh=[int]$spec[6]
    $fw=[int]$spec[7]; $fh=[int]$spec[8]; $pivot=$spec[9]
    $atlas = [Drawing.Bitmap]::new(($fw*$count),$fh,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics=[Drawing.Graphics]::FromImage($atlas); $graphics.Clear([Drawing.Color]::Transparent); $graphics.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $pose = $safePoses[$enemy]
    for ($frame=0; $frame-lt $count; $frame++) {
        $x0=[int]$pose[0]; $sy=[int]$pose[1]; $cw=[int]$pose[2]; $sh=[int]$pose[3]
        $crop=$source.Clone([Drawing.Rectangle]::new($x0,$sy,$cw,$sh),[Drawing.Imaging.PixelFormat]::Format32bppArgb); Remove-Backdrop $crop
        $minX=$cw; $minY=$sh; $maxX=-1; $maxY=-1
        for ($y=0;$y-lt $sh;$y++){for($x=0;$x-lt $cw;$x++){if($crop.GetPixel($x,$y).A -gt 24){$minX=[math]::Min($minX,$x);$maxX=[math]::Max($maxX,$x);$minY=[math]::Min($minY,$y);$maxY=[math]::Max($maxY,$y)}}}
        if ($maxX -ge 0) {
            $bw=$maxX-$minX+1; $bh=$maxY-$minY+1; $scale=[math]::Min(($fw-4)/$bw,($fh-4)/$bh); $tw=[math]::Max(1,[math]::Round($bw*$scale)); $th=[math]::Max(1,[math]::Round($bh*$scale)); $tx=$frame*$fw+[math]::Round(($fw-$tw)/2); $ty= if($pivot -eq 'center'){[math]::Round(($fh-$th)/2)}else{$fh-2-$th}
            $graphics.DrawImage($crop,[Drawing.Rectangle]::new($tx,$ty,$tw,$th),[Drawing.Rectangle]::new($minX,$minY,$bw,$bh),[Drawing.GraphicsUnit]::Pixel)
        }
        $crop.Dispose()
    }
    $graphics.Dispose(); $dir=Join-Path $OutputRoot "$enemy\sprites"; [IO.Directory]::CreateDirectory($dir)|Out-Null; $path=Join-Path $dir "$name.png"; $atlas.Save($path,[Drawing.Imaging.ImageFormat]::Png); $atlas.Dispose(); Write-Output "BUILT $enemy/$name ($count frames, ${fw}x${fh})"
}

$source = New-Object Drawing.Bitmap ([IO.Path]::GetFullPath($SourcePath))
foreach ($spec in $animations) { Build-Atlas $source $spec }
$source.Dispose()
