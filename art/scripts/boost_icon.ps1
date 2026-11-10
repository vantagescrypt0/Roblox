# The Boost Crystal's product icon: a render of the crystal on flat green (taken in a Studio playtest with a
# ViewportFrame), keyed out and put on a dark background with a teal glow, like the kit passes (pass_icons.ps1).
#   powershell -ExecutionPolicy Bypass -File art/scripts/boost_icon.ps1 <render.png>
#   writes art/marketing/Product_BoostCrystal.png (512 x 512)
param([Parameter(Mandatory = $true)][string]$Render)
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class GreenKey {
    // Green-screen pixels become see-through; the edges lose their green tint
    public static Bitmap Key(Bitmap source, Rectangle crop) {
        Bitmap output = new Bitmap(crop.Width, crop.Height, PixelFormat.Format32bppArgb);
        BitmapData src = source.LockBits(crop, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        BitmapData dst = output.LockBits(new Rectangle(0, 0, crop.Width, crop.Height), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
        int bytes = Math.Abs(src.Stride) * crop.Height;
        byte[] a = new byte[bytes];
        byte[] b = new byte[Math.Abs(dst.Stride) * crop.Height];
        Marshal.Copy(src.Scan0, a, 0, bytes);
        for (int y = 0; y < crop.Height; y++) {
            for (int x = 0; x < crop.Width; x++) {
                int i = y * src.Stride + x * 4;
                int o = y * dst.Stride + x * 4;
                int blue = a[i], green = a[i + 1], red = a[i + 2];
                int spill = green - Math.Max(red, blue);
                double alpha = 1.0 - Math.Min(1.0, Math.Max(0.0, (spill - 90) / 120.0));
                int keptGreen = alpha < 1.0 ? Math.Min(green, Math.Max(red, blue) + 60) : green;
                b[o] = (byte)blue;
                b[o + 1] = (byte)keptGreen;
                b[o + 2] = (byte)red;
                b[o + 3] = (byte)(alpha * 255);
            }
        }
        Marshal.Copy(b, 0, dst.Scan0, b.Length);
        source.UnlockBits(src);
        output.UnlockBits(dst);
        return output;
    }
}
"@
$dir = Join-Path $PSScriptRoot "..\marketing"
$raw = [System.Drawing.Bitmap]::FromFile((Resolve-Path $Render))
# A square around the middle of the screen, where the crystal is
$side = [int]($raw.Height * 0.8)
$crop = New-Object System.Drawing.Rectangle ([int](($raw.Width - $side) / 2)), ([int](($raw.Height - $side) / 2)), $side, $side
$crystal = [GreenKey]::Key($raw, $crop)
$raw.Dispose()

$size = 512
$bmp = New-Object System.Drawing.Bitmap $size, $size
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
$g.InterpolationMode = 'HighQualityBicubic'
$g.Clear([System.Drawing.Color]::FromArgb(255, 9, 14, 30))
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$path.AddEllipse(-96, -110, 704, 704)
$glow = New-Object System.Drawing.Drawing2D.PathGradientBrush $path
$glow.CenterColor = [System.Drawing.Color]::FromArgb(235, 90, 225, 200)
$glow.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 90, 225, 200))
$g.FillRectangle($glow, 0, 0, $size, $size)
$g.DrawImage($crystal, 0, 0, $size, $size)
$crystal.Dispose()
$g.Dispose()
$out = Join-Path $dir "Product_BoostCrystal.png"
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
"wrote $out"
