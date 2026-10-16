param([string]$Out = 'C:\Users\luisr\champion_draft_battle\assets\sprites\krogg_pixel.png', [string]$Preview = '')
$sp = Split-Path $MyInvocation.MyCommand.Path
Add-Type -Path "$sp\Slicer.cs" -ReferencedAssemblies System.Drawing
Add-Type -Path "$sp\Tween.cs" -ReferencedAssemblies System.Drawing
Add-Type -AssemblyName System.Drawing
[Slicer]::Load('C:\Users\luisr\champion_draft_battle\art\sprites\krogg_source.png')
$cell = 320; $left = 100; $pad = 6; $thr = 28

# Source frames per row (x anchors from the pasted sheet), then tweened to
# 16 per animation and laid out as two rows of 8 (as in build_sheets.ps1).
$idle = [Slicer]::Row(268, 915, 147, 308, [int[]](283, 368, 459, 551, 632, 732, 821), 12, 240, $cell, -1, $pad, $thr)
$atk  = [Slicer]::Row(266, 1213, 388, 594, [int[]](266, 382, 515, 668, 838, 1003), 0, 240, $cell, $left, $pad, $thr)
$hit  = [Slicer]::Row(38, 616, 662, 826, [int[]](38, 186, 322, 470), 0, 240, $cell, -1, $pad, $thr)
$die  = [Slicer]::Row(648, 1752, 662, 826, [int[]](648, 814, 974, 1177, 1360, 1557), 0, 240, $cell, -1, $pad, $thr)

$rows = @(
  [Tween]::Pick($idle[0..6], 16, $true),
  [Tween]::Pick([Tween]::Expand($atk, $false), 16, $false),
  [Tween]::Pick([Tween]::Expand($hit, $false), 16, $false),
  [Tween]::Pick([Tween]::Expand($die, $false), 16, $false)
)
$sheet = New-Object System.Drawing.Bitmap (8 * $cell), (8 * $cell), ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($sheet)
for ($r = 0; $r -lt 4; $r++) { for ($c = 0; $c -lt 16; $c++) { $g.DrawImageUnscaled($rows[$r][$c], ($c % 8) * $cell, ($r * 2 + [math]::Floor($c / 8)) * $cell) } }
$sheet.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
if ($Preview) {
  $p = New-Object System.Drawing.Bitmap $sheet.Width, $sheet.Height
  $pg = [System.Drawing.Graphics]::FromImage($p)
  $pg.Clear([System.Drawing.Color]::FromArgb(70, 70, 80))
  $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::Magenta), 1
  for ($c = 0; $c -le 8; $c++) { $pg.DrawLine($pen, $c * $cell, 0, $c * $cell, $p.Height) }
  for ($r = 0; $r -le 8; $r++) { $pg.DrawLine($pen, 0, $r * $cell, $p.Width, $r * $cell) }
  $pg.DrawImageUnscaled($sheet, 0, 0)
  $p.Save($Preview)
}
"$($sheet.Width)x$($sheet.Height) -> $Out"


