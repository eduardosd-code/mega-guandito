param(
    [string]$SourceDirectory = "$PSScriptRoot\..\assets\characters\guandito\sprites\source_reconstruction",
    [string]$OutputDirectory = "$PSScriptRoot\..\assets\characters\guandito\sprites\runtime"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$drawingAssembly = [System.Drawing.Bitmap].Assembly.Location
$runtimeDirectory = Split-Path $drawingAssembly
$references = @(
    $drawingAssembly,
    (Join-Path $runtimeDirectory 'System.Drawing.Primitives.dll'),
    (Join-Path $runtimeDirectory 'System.Private.Windows.GdiPlus.dll'),
    (Join-Path $runtimeDirectory 'System.Private.Windows.Core.dll'),
    (Join-Path $runtimeDirectory 'System.Private.CoreLib.dll'),
    (Join-Path $runtimeDirectory 'System.Runtime.dll'),
    (Join-Path $runtimeDirectory 'System.Collections.dll')
)
Add-Type -ReferencedAssemblies $references -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class GuanditoSpriteBuilder {
    static bool IsBackground(Color c) {
        int hi = Math.Max(c.R, Math.Max(c.G, c.B));
        int lo = Math.Min(c.R, Math.Min(c.G, c.B));
        return lo >= 205 && hi - lo <= 22;
    }

    static Bitmap EnsureTransparency(Bitmap source) {
        var bitmap = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb);
        using (var graphics = Graphics.FromImage(bitmap)) graphics.DrawImageUnscaled(source, 0, 0);
        if (bitmap.GetPixel(0, 0).A < 250) return bitmap;

        int width = bitmap.Width, height = bitmap.Height;
        var visited = new bool[width * height];
        var queue = new int[width * height];
        int head = 0, tail = 0;
        for (int x = 0; x < width; x++) {
            int top = x, bottom = (height - 1) * width + x;
            if (!visited[top] && IsBackground(bitmap.GetPixel(x,0))) { visited[top] = true; queue[tail++] = top; }
            if (!visited[bottom] && IsBackground(bitmap.GetPixel(x,height-1))) { visited[bottom] = true; queue[tail++] = bottom; }
        }
        for (int y = 0; y < height; y++) {
            int left = y * width, right = left + width - 1;
            if (!visited[left] && IsBackground(bitmap.GetPixel(0,y))) { visited[left] = true; queue[tail++] = left; }
            if (!visited[right] && IsBackground(bitmap.GetPixel(width-1,y))) { visited[right] = true; queue[tail++] = right; }
        }
        int[] dx = { 1, -1, 0, 0 }, dy = { 0, 0, 1, -1 };
        while (head < tail) {
            int i = queue[head++], x = i % width, y = i / width;
            bitmap.SetPixel(x, y, Color.Transparent);
            for (int d = 0; d < 4; d++) {
                int nx = x + dx[d], ny = y + dy[d];
                if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;
                int ni = ny * width + nx;
                if (!visited[ni] && IsBackground(bitmap.GetPixel(nx,ny))) { visited[ni] = true; queue[tail++] = ni; }
            }
        }
        return bitmap;
    }

    public static void Build(string sourcePath, string outputPath, int frameCount) {
        using (var loaded = new Bitmap(sourcePath))
        using (var source = EnsureTransparency(loaded))
        using (var atlas = new Bitmap(frameCount * 64, 64, PixelFormat.Format32bppArgb)) {
            double segmentWidth = (double)source.Width / frameCount;
            var bodyCenterX = new double[frameCount];
            var bodyFootY = new int[frameCount];
            var bodyHeights = new int[frameCount];

            // Locate the densest vertical column window. This finds Guandito's
            // body while ignoring the long hammer and cables used by attacks.
            for (int frame = 0; frame < frameCount; frame++) {
                int x0 = (int)Math.Floor(frame * segmentWidth);
                int x1 = (int)Math.Floor((frame + 1) * segmentWidth) - 1;
                int segmentPixels = x1 - x0 + 1;
                var columns = new int[segmentPixels];
                for (int y = 0; y < source.Height; y++) for (int x = x0; x <= x1; x++)
                    if (source.GetPixel(x,y).A > 24) columns[x - x0]++;
                int windowWidth = Math.Min(segmentPixels, Math.Max(24, source.Height / 2));
                int current = 0; for (int x = 0; x < windowWidth; x++) current += columns[x];
                int best = current, bestStart = 0;
                for (int x = windowWidth; x < segmentPixels; x++) {
                    current += columns[x] - columns[x - windowWidth];
                    if (current > best) { best = current; bestStart = x - windowWidth + 1; }
                }
                int bodyX0 = x0 + bestStart, bodyX1 = bodyX0 + windowWidth - 1;
                int minY = source.Height - 1, maxY = 0, pixelCount = 0;
                long weightedX = 0;
                for (int y = 0; y < source.Height; y++) for (int x = bodyX0; x <= bodyX1; x++) {
                    if (source.GetPixel(x,y).A <= 24) continue;
                    minY = Math.Min(minY,y); maxY = Math.Max(maxY,y);
                    weightedX += x; pixelCount++;
                }
                if (pixelCount == 0) throw new InvalidDataException("No body found in " + sourcePath + " frame " + frame);
                bodyCenterX[frame] = (double)weightedX / pixelCount;
                bodyFootY[frame] = maxY;
                bodyHeights[frame] = maxY - minY + 1;
            }
            var sortedHeights = (int[])bodyHeights.Clone();
            Array.Sort(sortedHeights);
            double commonScale = 48.0 / sortedHeights[sortedHeights.Length / 2];

            using (var graphics = Graphics.FromImage(atlas)) {
                graphics.Clear(Color.Transparent);
                graphics.CompositingMode = CompositingMode.SourceCopy;
                graphics.CompositingQuality = CompositingQuality.HighSpeed;
                graphics.InterpolationMode = InterpolationMode.NearestNeighbor;
                graphics.PixelOffsetMode = PixelOffsetMode.Half;
                for (int frame = 0; frame < frameCount; frame++) {
                    int x0 = (int)Math.Floor(frame * segmentWidth);
                    int x1 = (int)Math.Floor((frame + 1) * segmentWidth) - 1;
                    int sourceW = x1 - x0 + 1;
                    int targetW = Math.Max(1, (int)Math.Round(sourceW * commonScale));
                    int targetH = Math.Max(1, (int)Math.Round(source.Height * commonScale));
                    int targetX = frame * 64 + 32 - (int)Math.Round((bodyCenterX[frame] - x0) * commonScale);
                    int targetY = 63 - (int)Math.Round(bodyFootY[frame] * commonScale);
                    graphics.DrawImage(source, new Rectangle(targetX, targetY, targetW, targetH), new Rectangle(x0, 0, sourceW, source.Height), GraphicsUnit.Pixel);
                }
            }
            Directory.CreateDirectory(Path.GetDirectoryName(outputPath));
            atlas.Save(outputPath, ImageFormat.Png);
        }
    }
}
'@

$animations = [ordered]@{
    idle = 6; run = 8; jump_start = 3; jump_up = 3; fall = 3; land = 3
    dash_start = 2; dash = 3; dash_end = 2
    light_1 = 4; light_2 = 5; light_3 = 6
    heavy_start = 4; heavy_attack = 3; heavy_recovery = 5; air_light = 5
    dodge_start = 2; dodge_invulnerable = 3; dodge_exposed = 4
    hit = 3; death = 7; module_install = 8
}

$sourceRoot = [IO.Path]::GetFullPath($SourceDirectory)
$outputRoot = [IO.Path]::GetFullPath($OutputDirectory)
foreach ($entry in $animations.GetEnumerator()) {
    $source = Join-Path $sourceRoot ($entry.Key + '_source.png')
    $output = Join-Path $outputRoot ($entry.Key + '.png')
    [GuanditoSpriteBuilder]::Build($source, $output, $entry.Value)
    Write-Output ("BUILT {0}: {1}x64" -f $entry.Key, ($entry.Value * 64))
}
