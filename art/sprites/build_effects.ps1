# Cuts each champion's attack effect (the beam, projectile or ground spikes
# drawn beside its attack frames) out of art/sprites/<name>_source.png into
# assets/effects/<name>.png, and prints the Dart map entries for
# lib/data/attack_effects.dart. Run with -Preview <dir> to also write each
# effect on gray.
param([string]$Preview = '')
$root = Split-Path (Split-Path (Split-Path $MyInvocation.MyCommand.Path))
Add-Type -Path "$root\art\sprites\AutoSlice.cs" -ReferencedAssemblies System.Drawing
Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force "$root\assets\effects" | Out-Null

# name = (kind, x0, x1, y0, y1): beam = flies from attacker to target,
# ground = erupts under the target.
$effects = [ordered]@{
  cardinal_ashworth   = @('beam', 1255, 1980, 205, 352)
  windhorn            = @('beam', 1432, 1980, 230, 402)
  tocho               = @('beam', 1236, 1760, 258, 445)
  nyx                 = @('beam', 1362, 1990, 240, 420)
  thalassar           = @('beam', 1385, 1980, 222, 345)
  mourn               = @('beam', 1272, 1765, 320, 565)
  friedrich_blitzberg = @('beam', 1312, 1995, 248, 445)
  demon_knight        = @('beam', 1302, 1990, 250, 450)
  voltgraven          = @('beam', 1412, 1985, 248, 415)
  ironbark            = @('ground', 1745, 1970, 255, 400)
  thundric            = @('beam', 1292, 1995, 248, 440)
  elowen              = @('ground', 1505, 1760, 255, 445)
  omnes               = @('beam', 1112, 1995, 190, 335)
  cosmic_eye          = @('beam', 905, 1995, 190, 340)
  hollow_shepherd     = @('beam', 1395, 1985, 185, 335)
  elder_shen          = @('beam', 1218, 1980, 205, 330)
  magmus              = @('beam', 1452, 1985, 235, 405)
  robotoman           = @('beam', 1152, 1985, 255, 425)
  riptide             = @('beam', 1188, 1965, 248, 418)
  forest_child        = @('beam', 1172, 1990, 195, 325)
  kaelvorn            = @('beam', 1268, 1995, 262, 445)
  nova                = @('beam', 1272, 1690, 195, 340)
  oorgath             = @('ground', 1790, 1990, 190, 305)
  vorkath             = @('beam', 1262, 1995, 205, 350)
  talonfire           = @('beam', 1197, 1995, 190, 345)
  doku                = @('ground', 1780, 1955, 210, 335)
  krogg               = @('beam', 1215, 1765, 388, 596)
}

foreach ($name in $effects.Keys) {
  $kind, $x0, $x1, $y0, $y1 = $effects[$name]
  [void][AutoSlice]::Load("$root\art\sprites\${name}_source.png")
  [void][AutoSlice]::EraseLabels()
  $e = [AutoSlice]::Effect($x0, $x1, $y0, $y1)
  $e.Save("$root\assets\effects\$name.png", [System.Drawing.Imaging.ImageFormat]::Png)
  if ($Preview) {
    $p = New-Object System.Drawing.Bitmap $e.Width, $e.Height
    $g = [System.Drawing.Graphics]::FromImage($p)
    $g.Clear([System.Drawing.Color]::FromArgb(70, 70, 80))
    $g.DrawImageUnscaled($e, 0, 0)
    $p.Save("$Preview\fx_$name.png"); $p.Dispose()
  }
  "  '$name': AttackEffect.$kind('assets/effects/$name.png', $($e.Width), $($e.Height)),"
  $e.Dispose()
}
