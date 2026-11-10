# The badge pictures (shared/Badges.luau) and the Loot Crate's pass and product icons, from captures of the game's own
# models taken in Studio on a flat magenta or green backdrop (art/renders/badges/*_raw.png, 1920 x 1080), or a crop of a
# real view or the game icon. Each is keyed out, centred on a dark background with a glow in its colour, like the kit
# passes (pass_icons.ps1). Roblox shows badges as circles, so they get a ring and keep inside it; the crate icons stay square.
#   powershell -ExecutionPolicy Bypass -File art/scripts/badge_icons.ps1
#   writes art/marketing/Badge_<Key>.png and Pass_CrateKeeper.png, Product_LootCrate.png (512 x 512)
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class BadgeKey {
    // Backdrop pixels become see-through and edges lose the backdrop's tint. key: "magenta" or "green".
    // Returns the keyed image cropped to what's left (plus a small margin).
    public static Bitmap Key(Bitmap source, string key) {
        int w = source.Width, h = source.Height;
        BitmapData src = source.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        byte[] a = new byte[Math.Abs(src.Stride) * h];
        Marshal.Copy(src.Scan0, a, 0, a.Length);
        source.UnlockBits(src);
        byte[] b = new byte[w * h * 4];
        int minX = w, minY = h, maxX = 0, maxY = 0;
        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                int i = y * src.Stride + x * 4;
                int o = (y * w + x) * 4;
                int blue = a[i], green = a[i + 1], red = a[i + 2];
                int spill = key == "green" ? green - Math.Max(red, blue) : Math.Min(red, blue) - green;
                double alpha = 1.0 - Math.Min(1.0, Math.Max(0.0, (spill - 70) / 90.0));
                if (alpha < 1.0) {
                    if (key == "green") { green = Math.Min(green, Math.Max(red, blue) + 30); }
                    else { int cap = green + 30; red = Math.Min(red, Math.Max(cap, blue - 60)); blue = Math.Min(blue, Math.Max(cap, red)); }
                }
                b[o] = (byte)blue; b[o + 1] = (byte)green; b[o + 2] = (byte)red; b[o + 3] = (byte)(alpha * 255);
                if (alpha > 0.5) { if (x < minX) minX = x; if (x > maxX) maxX = x; if (y < minY) minY = y; if (y > maxY) maxY = y; }
            }
        }
        Bitmap keyed = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        BitmapData dst = keyed.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
        Marshal.Copy(b, 0, dst.Scan0, b.Length);
        keyed.UnlockBits(dst);
        int m = 6;
        Rectangle box = Rectangle.FromLTRB(Math.Max(0, minX - m), Math.Max(0, minY - m), Math.Min(w, maxX + m), Math.Min(h, maxY + m));
        Bitmap cropped = keyed.Clone(box, PixelFormat.Format32bppArgb);
        keyed.Dispose();
        return cropped;
    }
}
"@

$root = Join-Path $PSScriptRoot ".."
$raw = Join-Path $root "renders\badges"
$out = Join-Path $root "marketing"
$size = 512

function New-Canvas([int[]]$c) {
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.InterpolationMode = 'HighQualityBicubic'
    $g.PixelOffsetMode = 'HighQuality'
    $g.Clear([System.Drawing.Color]::FromArgb(255, 9, 14, 30))
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddEllipse(-96, -110, 704, 704)
    $glow = New-Object System.Drawing.Drawing2D.PathGradientBrush $path
    $glow.CenterColor = [System.Drawing.Color]::FromArgb(235, $c[0], $c[1], $c[2])
    $glow.SurroundColors = @([System.Drawing.Color]::FromArgb(0, $c[0], $c[1], $c[2]))
    $g.FillRectangle($glow, 0, 0, $size, $size)
    return @($bmp, $g)
}

# Draws a keyed picture so it fits in a box `fit` pixels wide and tall, centred a little low
function Add-Subject($g, $picture, [int]$fit) {
    $scale = [Math]::Min($fit / $picture.Width, $fit / $picture.Height)
    $w = [int]($picture.Width * $scale)
    $h = [int]($picture.Height * $scale)
    $g.DrawImage($picture, [int](($size - $w) / 2), [int](($size - $h) / 2 + 6), $w, $h)
}

function Add-Ring($g, [int[]]$c) {
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, $c[0], $c[1], $c[2])), 12
    $g.DrawEllipse($pen, 10, 10, $size - 20, $size - 20)
    $inner = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(200, 9, 14, 30)), 3
    $g.DrawEllipse($inner, 18, 18, $size - 36, $size - 36)
}

function Save($bmp, $g, [string]$name) {
    $g.Dispose()
    $file = Join-Path $out $name
    $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    "wrote $name"
}

# A keyed model on a glow. ring: badge (circle) or not (square pass icon)
function Keyed([string]$source, [string]$key, [int[]]$color, [int]$fit, [bool]$ring, [string]$name) {
    $canvas = New-Canvas $color
    $picture = [BadgeKey]::Key([System.Drawing.Bitmap]::FromFile((Join-Path $raw $source)), $key)
    Add-Subject $canvas[1] $picture $fit
    $picture.Dispose()
    if ($ring) { Add-Ring $canvas[1] $color }
    Save $canvas[0] $canvas[1] $name
}

# A square cut from a real picture, filling the circle
function Cropped([string]$source, [int]$x, [int]$y, [int]$side, [int[]]$color, [string]$name) {
    $canvas = New-Canvas $color
    $picture = [System.Drawing.Image]::FromFile($source)
    $canvas[1].DrawImage($picture, (New-Object System.Drawing.Rectangle 0, 0, $size, $size), (New-Object System.Drawing.Rectangle $x, $y, $side, $side), 'Pixel')
    $picture.Dispose()
    Add-Ring $canvas[1] $color
    Save $canvas[0] $canvas[1] $name
}

$gold = @(242, 193, 78)
# Welcome: the game icon's island and crystal, without the title
Cropped (Join-Path $out "icon.png") 76 8 360 @(120, 200, 255) "Badge_Welcome.png"
Keyed "WarzoneUnlocked_raw.png" "green" @(255, 96, 72) 360 $true "Badge_WarzoneUnlocked.png"
# Into the Pit: looking down into the Warzone's void pit in Market Square
Cropped (Join-Path $raw "WarzoneEntered_raw.png") 420 0 1080 @(150, 80, 255) "Badge_WarzoneEntered.png"
Keyed "FirstKill_raw.png" "magenta" @(110, 220, 90) 370 $true "Badge_FirstKill.png"
Keyed "FirstCrate_raw.png" "magenta" $gold 320 $true "Badge_FirstCrate.png"
# The Loot Crate's own pass and product (square, like the kit passes)
Keyed "LootCrate_raw.png" "magenta" $gold 400 $false "Pass_CrateKeeper.png"
Keyed "LootCrate_raw.png" "magenta" @(170, 110, 255) 400 $false "Product_LootCrate.png"
