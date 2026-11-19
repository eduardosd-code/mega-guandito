# Derives Guandito's Zero-style movement atlases (wall_slide, wall_jump,
# air_dash, charge_ready) from the normalized runtime atlases produced by
# build_guandito_sprites.ps1. Every output keeps the 64x64 frame and the
# (32,63) foot pivot of its source pose; only FX pixels are added.
param(
    [string]$RuntimeDirectory = "$PSScriptRoot\..\assets\characters\guandito\sprites\runtime"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$references = @([System.Drawing.Bitmap].Assembly.Location)
if ($PSVersionTable.PSEdition -eq 'Core') {
    $runtimeDirectory = Split-Path $references[0]
    foreach ($name in 'System.Drawing.Primitives', 'System.Private.Windows.GdiPlus', 'System.Private.Windows.Core', 'System.Private.CoreLib', 'System.Runtime', 'System.Collections') {
        $path = Join-Path $runtimeDirectory "$name.dll"
        if (Test-Path $path) { $references += $path }
    }
}
Add-Type -ReferencedAssemblies $references -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;

public static class GuanditoZeroMoves {
    static readonly Color Lime = Color.FromArgb(255, 0x93, 0xE2, 0x2B);
    static readonly Color Orange = Color.FromArgb(255, 0xFF, 0x71, 0x38);
    static readonly Color Spark = Color.FromArgb(255, 0xF4, 0xFF, 0xD8);
    static readonly Color Cyan = Color.FromArgb(255, 0x5A, 0xD1, 0xFF);
    static readonly Color Gold = Color.FromArgb(255, 0xFF, 0xD8, 0x4A);

    static Bitmap Frame(string atlasPath, int index) {
        var frame = new Bitmap(64, 64, PixelFormat.Format32bppArgb);
        using (var atlas = new Bitmap(atlasPath))
            for (int y = 0; y < 64; y++) for (int x = 0; x < 64; x++)
                frame.SetPixel(x, y, atlas.GetPixel(index * 64 + x, y));
        return frame;
    }

    static bool Solid(Bitmap b, int x, int y) {
        return x >= 0 && y >= 0 && x < 64 && y < 64 && b.GetPixel(x, y).A > 24;
    }

    static int LeftEdge(Bitmap b, int y) {
        for (int x = 0; x < 64; x++) if (Solid(b, x, y)) return x;
        return -1;
    }

    static void Put(Bitmap b, int x, int y, Color c, int alpha) {
        if (x < 0 || y < 0 || x >= 64 || y >= 64 || b.GetPixel(x, y).A > 24) return;
        b.SetPixel(x, y, Color.FromArgb(alpha, c.R, c.G, c.B));
    }

    // Wall is behind Guandito (left in source orientation). Friction sparks
    // at the boots and a dashed scrape streak along the back.
    static Bitmap WallSlide(string fall, int i) {
        var b = Frame(fall, i % 3);
        for (int y = 26; y < 50; y++) {
            int lx = LeftEdge(b, y);
            if (lx > 0 && (y + i * 2) % 5 < 3) Put(b, lx - 1, y, Spark, 110);
        }
        int[][] sparks = {
            new[] { -2, 0 }, new[] { -3, -2 }, new[] { -4, 1 }, new[] { -2, -5 }, new[] { -5, -3 }
        };
        for (int y = 54; y < 63; y++) {
            int lx = LeftEdge(b, y);
            if (lx <= 0) continue;
            for (int s = 0; s < sparks.Length; s++) {
                if ((s + i) % 3 == 0) continue;
                Put(b, lx + sparks[s][0], y + sparks[s][1] - (i * 2) % 4, s % 2 == 0 ? Lime : Orange, 255);
            }
            Put(b, lx - 1, y, Spark, 220);
            break;
        }
        return b;
    }

    // Kick-off burst against the wall behind, fading over three frames.
    static Bitmap WallJump(string jumpStart, string jumpUp, int i) {
        var b = i == 0 ? Frame(jumpStart, 2) : Frame(jumpUp, i - 1);
        int cy = 54, lx = -1;
        for (int y = 63; y > 30 && lx < 0; y--) { lx = LeftEdge(b, y); cy = y - 3; }
        if (lx < 0) return b;
        int radius = 4 + i * 3, alpha = 255 - i * 90;
        for (int a = 0; a < 360; a += 30) {
            if (i > 0 && (a < 90 || a > 270)) continue;
            double r = a * Math.PI / 180.0;
            int px = lx - 2 - (int)Math.Round(Math.Abs(Math.Cos(r)) * radius);
            int py = cy + (int)Math.Round(Math.Sin(r) * radius);
            Put(b, px, py, (a / 30) % 2 == 0 ? Lime : Spark, alpha);
        }
        return b;
    }

    // Mid-air dash: two cyan after-images behind the body plus speed lines.
    static Bitmap AirDash(string dash, int i) {
        var body = Frame(dash, i);
        var b = new Bitmap(64, 64, PixelFormat.Format32bppArgb);
        int[] offsets = { 14 + i, 7 + i };
        int[] alphas = { 60, 120 };
        for (int k = 0; k < 2; k++)
            for (int y = 0; y < 64; y++) for (int x = 0; x < 64; x++) {
                int sx = x + offsets[k];
                if (sx >= 64 || body.GetPixel(sx, y).A < 200) continue;
                b.SetPixel(x, y, Color.FromArgb(alphas[k], Cyan.R, Cyan.G, Cyan.B));
            }
        for (int y = 0; y < 64; y++) for (int x = 0; x < 64; x++) {
            var c = body.GetPixel(x, y);
            if (c.A > 24) b.SetPixel(x, y, c);
        }
        int[] rows = { 30, 38, 46, 53 };
        for (int r = 0; r < rows.Length; r++) {
            int y = rows[r] + ((r + i) % 2), lx = LeftEdge(body, y);
            if (lx < 0) continue;
            int start = lx - 18 - ((r * 5 + i * 3) % 6);
            for (int x = start; x < start + 6 + (r % 2) * 3; x++) Put(b, x, y, Spark, 170);
        }
        body.Dispose();
        return b;
    }

    // Idle pose with a pulsing gold rim and reactor sparks: charge is ready.
    static Bitmap ChargeReady(string idle, int i) {
        var b = Frame(idle, i);
        int alpha = (i % 2 == 0) ? 255 : 150;
        var rim = new bool[64, 64];
        for (int y = 0; y < 64; y++) for (int x = 0; x < 64; x++)
            if (!Solid(b, x, y) && (Solid(b, x - 1, y) || Solid(b, x + 1, y) || Solid(b, x, y - 1) || Solid(b, x, y + 1)))
                rim[x, y] = true;
        for (int y = 0; y < 64; y++) for (int x = 0; x < 64; x++)
            if (rim[x, y] && y < 63) b.SetPixel(x, y, Color.FromArgb(alpha, Gold.R, Gold.G, Gold.B));
        int[][] motes = { new[] { 14, 20 }, new[] { 50, 16 }, new[] { 10, 38 }, new[] { 54, 34 } };
        for (int m = 0; m < motes.Length; m++) {
            int my = motes[m][1] - ((i * 3 + m * 2) % 8);
            Put(b, motes[m][0], my, m % 2 == i % 2 ? Gold : Spark, 230);
        }
        return b;
    }

    static void Save(Bitmap[] frames, string path) {
        using (var atlas = new Bitmap(frames.Length * 64, 64, PixelFormat.Format32bppArgb)) {
            for (int f = 0; f < frames.Length; f++) {
                for (int y = 0; y < 64; y++) for (int x = 0; x < 64; x++)
                    atlas.SetPixel(f * 64 + x, y, frames[f].GetPixel(x, y));
                frames[f].Dispose();
            }
            atlas.Save(path, ImageFormat.Png);
        }
    }

    public static void Build(string dir) {
        Func<string, string> p = n => System.IO.Path.Combine(dir, n + ".png");
        Save(new[] { WallSlide(p("fall"), 0), WallSlide(p("fall"), 1), WallSlide(p("fall"), 2) }, p("wall_slide"));
        Save(new[] { WallJump(p("jump_start"), p("jump_up"), 0), WallJump(p("jump_start"), p("jump_up"), 1), WallJump(p("jump_start"), p("jump_up"), 2) }, p("wall_jump"));
        Save(new[] { AirDash(p("dash"), 0), AirDash(p("dash"), 1), AirDash(p("dash"), 2) }, p("air_dash"));
        Save(new[] { ChargeReady(p("idle"), 0), ChargeReady(p("idle"), 1), ChargeReady(p("idle"), 2), ChargeReady(p("idle"), 3) }, p("charge_ready"));
    }
}
'@

$runtimeRoot = [IO.Path]::GetFullPath($RuntimeDirectory)
[GuanditoZeroMoves]::Build($runtimeRoot)
Write-Output "BUILT wall_slide: 192x64"
Write-Output "BUILT wall_jump: 192x64"
Write-Output "BUILT air_dash: 192x64"
Write-Output "BUILT charge_ready: 256x64"
