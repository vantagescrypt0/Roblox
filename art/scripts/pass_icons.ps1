# Puts each armour kit's picture (armour.py -- <Kit> icon) on a dark background in its colour, for its game pass.
#   powershell -ExecutionPolicy Bypass -File art/scripts/pass_icons.ps1     writes art/marketing/Pass_<Kit>.png
Add-Type -AssemblyName System.Drawing
$dir = Join-Path $PSScriptRoot "..\marketing"
$kits = @{ Stormcaller = @(120, 222, 244); Sunforged = @(242, 193, 78); Emberguard = @(255, 120, 40); Frostwarden = @(170, 215, 245); Venomfang = @(80, 200, 120) }
foreach ($kit in $kits.Keys) {
    $c = $kits[$kit]
    $size = 512
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.InterpolationMode = 'HighQualityBicubic'
    $g.Clear([System.Drawing.Color]::FromArgb(255, 9, 14, 30))
    # A soft glow in the kit's colour behind the armour
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddEllipse(-96, -110, 704, 704)
    $glow = New-Object System.Drawing.Drawing2D.PathGradientBrush $path
    $glow.CenterColor = [System.Drawing.Color]::FromArgb(235, $c[0], $c[1], $c[2])
    $glow.SurroundColors = @([System.Drawing.Color]::FromArgb(0, $c[0], $c[1], $c[2]))
    $g.FillRectangle($glow, 0, 0, $size, $size)
    $picture = [System.Drawing.Image]::FromFile((Join-Path $dir "Pass_${kit}_icon.png"))
    $g.DrawImage($picture, 0, 0, $size, $size)
    $picture.Dispose()
    $g.Dispose()
    $bmp.Save((Join-Path $dir "Pass_$kit.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    "wrote Pass_$kit.png"
}
