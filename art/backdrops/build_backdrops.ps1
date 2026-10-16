# Makes the classic battle backdrops (assets/backdrops/<name>.png) from the
# full-detail art (art/backdrops/<name>_source.jpg) so they match the sprites:
#  - Shrunk to $height px tall. A sprite pixel block is about 2 sheet pixels,
#    which is about 1.5 screen pixels on a phone; at 540 tall the backdrop's
#    blocks come out about the same once the game scales it back up with
#    nearest neighbour (FilterQuality.none).
#  - Cut to $colors colors, each pulled onto the nearest sprite color when
#    within $snap, so the scene and the fighters share paints.
# Run with the PowerShell tool: powershell -ExecutionPolicy Bypass -File ...
param([int]$height = 540, [int]$colors = 40, [int]$snap = 18)
$root = Split-Path (Split-Path (Split-Path $MyInvocation.MyCommand.Path))
Add-Type -Path "$root\art\backdrops\Pixelate.cs" -ReferencedAssemblies System.Drawing
Add-Type -AssemblyName System.Drawing

$sheets = Get-ChildItem "$root\assets\sprites\*_pixel.png" | % { $_.FullName }
$spritePal = [Pixelate]::Palette([Pixelate]::SpritePixels($sheets), 96, 7)

foreach ($src in Get-ChildItem "$root\art\backdrops\*_source.jpg") {
  $name = $src.BaseName -replace '_source$', ''
  $b = [Pixelate]::Shrink($src.FullName, $height)
  $pal = [Pixelate]::Palette([Pixelate]::Pixels($b), $colors, 1)
  $moved = [Pixelate]::Snap($pal, $spritePal, $snap)
  [Pixelate]::Map($b, $pal)
  $b.Save("$root\assets\backdrops\$name.png", [System.Drawing.Imaging.ImageFormat]::Png)
  "$name  $($b.Width)x$($b.Height), $colors colors, $moved snapped to sprite colors"
  $b.Dispose()
}
