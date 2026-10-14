# Cuts the user's ChatGPT pixel art sheets (art/sprites/<name>_source.png)
# into game sprite sheets (assets/sprites/<name>_pixel.png): 320px frames,
# 8 per row, one row per animation in the order listed. Frame starts are found
# automatically (AutoSlice.Anchors) unless a row gives them. Run with
# -Only <name> to rebuild one, -Preview <dir> to also write previews on gray.
param([string]$Only = '', [string]$Preview = '')
$root = Split-Path (Split-Path (Split-Path $MyInvocation.MyCommand.Path))
Add-Type -Path "$root\art\sprites\AutoSlice.cs" -ReferencedAssemblies System.Drawing
Add-Type -AssemblyName System.Drawing
$cell = 320; $attackLeft = 100; $pad = 6

# Frame-count range per animation, and how much of the band (from the bottom)
# is used to find gaps between frames.
$kinds = @{
  idle   = @(6, 9, 1.0)
  attack = @(5, 9, 0.45)
  heal   = @(7, 11, 0.6)
  hurt   = @(3, 5, 1.0)
  death  = @(5, 7, 0.6)
}

# name = rows of (animation, y0, y1, x0, x1[, fixed frame starts])
$sheets = [ordered]@{
  cardinal_ashworth   = @(@('idle', 48, 175, 255, 1080, @(260,360,460,562,665,770,870,972)), @('attack', 218, 350, 255, 1255, @(262,375,497,628,778,920,1088)), @('heal', 370, 503, 250, 1975, @(255,395,540,695,830,995,1165,1325,1505,1740)), @('hurt', 510, 660, 250, 750), @('death', 510, 660, 780, 1975))
  windhorn            = @(@('idle', 55, 180, 290, 1090), @('attack', 240, 402, 290, 1430, @(293,428,578,752,905,1065,1232)), @('hurt', 470, 625, 290, 830), @('death', 470, 625, 850, 1960))
  tocho               = @(@('idle', 60, 207, 290, 950), @('attack', 270, 437, 290, 1235, @(293,398,530,700,868,1045)), @('heal', 495, 660, 290, 1755), @('hurt', 720, 855, 290, 800), @('death', 715, 855, 820, 1755))
  nyx                 = @(@('idle', 55, 195, 290, 1105), @('attack', 255, 415, 290, 1320, @(300,437,560,708,888,1060,1200)), @('hurt', 490, 632, 285, 830), @('death', 480, 632, 860, 1990))
  thalassar           = @(@('idle', 50, 166, 280, 1065), @('attack', 225, 340, 290, 1395, @(292,433,575,745,898,1050,1213)), @('heal', 375, 503, 295, 1965, @(295,415,540,668,800,975,1172,1392,1600,1790)), @('hurt', 550, 655, 280, 830), @('death', 545, 655, 830, 1960, @(840,972,1115,1298,1500,1780)))
  mourn               = @(@('idle', 110, 260, 295, 1000), @('attack', 335, 560, 295, 1270, @(297,425,560,705,905,1075)), @('hurt', 640, 810, 35, 640), @('death', 640, 810, 665, 1760))
  vaelric             = @(@('idle', 50, 180, 305, 1080), @('attack', 240, 400, 305, 1990, @(320,440,565,720,880,1095,1250,1455,1690)), @('hurt', 465, 605, 295, 890), @('death', 460, 605, 940, 1990))
  friedrich_blitzberg = @(@('idle', 60, 205, 310, 1080), @('attack', 265, 440, 310, 1310, @(322,452,588,728,898,1048,1198)), @('hurt', 485, 630, 305, 880), @('death', 480, 630, 900, 1980))
  demon_knight        = @(@('idle', 55, 210, 325, 1095), @('attack', 255, 440, 325, 1300, @(330,450,595,720,870,1003,1148)), @('hurt', 495, 650, 325, 880), @('death', 495, 650, 920, 1950))
  voltgraven          = @(@('idle', 55, 183, 300, 1105), @('attack', 255, 410, 300, 1410, @(302,443,588,725,888,1088,1238)), @('hurt', 485, 622, 300, 850), @('death', 485, 622, 870, 1980))
  ironbark            = @(@('idle', 55, 180, 290, 1080), @('attack', 255, 398, 290, 1565, @(300,437,585,722,890,1042,1202,1378)), @('hurt', 495, 630, 295, 830), @('death', 495, 630, 870, 1960))
  thundric            = @(@('idle', 65, 207, 320, 1130, @(322,432,530,632,732,830,928,1025)), @('attack', 255, 430, 315, 1290, @(318,462,585,718,858,1008,1158)), @('hurt', 490, 635, 315, 900), @('death', 495, 635, 930, 1990))
  elowen              = @(@('idle', 60, 207, 290, 945), @('attack', 260, 440, 290, 1500, @(293,418,552,690,880,1040,1222,1368)), @('heal', 480, 660, 290, 1760, @(293,438,558,682,802,938,1088,1238,1393,1568)), @('hurt', 720, 855, 290, 810), @('death', 720, 855, 830, 1760))
  omnes               = @(@('idle', 45, 165, 255, 1075), @('attack', 200, 330, 260, 1110, @(260,368,473,588,693,800,945)), @('heal', 360, 497, 255, 1990, @(258,385,510,638,800,995,1148,1298,1478,1648,1818)), @('hurt', 540, 648, 240, 800), @('death', 535, 648, 800, 1990))
  cosmic_eye          = @(@('idle', 45, 162, 250, 1080, @(255,360,465,562,665,765,868,970)), @('attack', 205, 335, 250, 905), @('heal', 375, 492, 250, 1990, @(255,372,505,650,810,995,1183,1488)), @('hurt', 540, 650, 245, 830), @('death', 535, 650, 850, 1990, @(855,1000,1185,1335,1495,1700)))
  hollow_shepherd     = @(@('idle', 45, 162, 280, 1080), @('attack', 195, 330, 290, 1395), @('heal', 384, 495, 280, 1940, @(283,415,570,730,900,1058,1230,1418,1675)), @('hurt', 540, 655, 245, 800), @('death', 515, 655, 840, 1960, @(845,995,1135,1300,1500,1725)))
  elder_shen          = @(@('idle', 48, 162, 255, 1070), @('attack', 205, 325, 255, 1215, @(258,370,478,598,738,878,1040)), @('heal', 360, 490, 255, 1800, @(255,388,532,680,815,962,1105,1272,1438,1605)), @('hurt', 535, 650, 235, 810, @(238,388,508,653)), @('death', 535, 650, 815, 1990))
  magmus              = @(@('idle', 50, 183, 295, 1090), @('attack', 245, 402, 295, 1450, @(300,430,562,688,868,1030,1225)), @('hurt', 475, 622, 285, 830), @('death', 480, 622, 860, 1990, @(873,1030,1200,1368,1545,1762)))
  robotoman           = @(@('idle', 55, 200, 345, 1105), @('attack', 260, 415, 345, 1150, @(350,478,598,718,858,1000)), @('hurt', 480, 625, 335, 880), @('death', 480, 625, 960, 1990, @(962,1100,1225,1390,1570,1765)))
  riptide             = @(@('idle', 60, 197, 275, 1030, @(275,368,460,550,642,735,830,925)), @('attack', 255, 412, 275, 1185, @(275,398,528,670,790,920,1050)), @('hurt', 485, 637, 260, 870, @(260,405,553,699)), @('death', 485, 637, 880, 1990))
}

# Picks 8 of n frames: idle loops, everything else spreads evenly and ends
# on the last frame.
function Pick8($frames, $kind) {
  $n = $frames.Count
  0..7 | % { if ($kind -eq 'idle' -and $n -lt 8) { $frames[$_ % $n] } else { $frames[[math]::Round($_ * ($n - 1) / 7)] } }
}

foreach ($name in $sheets.Keys) {
  if ($Only -and $name -ne $Only) { continue }
  [void][AutoSlice]::Load("$root\art\sprites\${name}_source.png")
  [void][AutoSlice]::EraseLabels()
  $rows = $sheets[$name]
  $sheet = New-Object System.Drawing.Bitmap (8 * $cell), ($rows.Count * $cell), ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($sheet)
  $log = @()
  for ($r = 0; $r -lt $rows.Count; $r++) {
    $kind, $y0, $y1, $x0, $x1 = $rows[$r][0..4]
    $k = $kinds[$kind]
    $anchors = if ($rows[$r].Count -gt 5) { [int[]]$rows[$r][5] } else { [AutoSlice]::Anchors($x0, $x1, $y0, $y1, $k[0], $k[1], $k[2]) }
    $anchors = [AutoSlice]::Refine($anchors, $y0, $y1, 25)
    $left = if ($kind -eq 'attack') { $attackLeft } else { -1 }
    $frames = [AutoSlice]::Row($anchors, $x1, $y0, $y1, $cell, $left, $pad)
    $log += "$kind $($anchors.Count): $($anchors -join ',') -> $x1"
    $c = 0
    foreach ($f in (Pick8 $frames $kind)) { $g.DrawImageUnscaled($f, $c * $cell, $r * $cell); $c++ }
  }
  $sheet.Save("$root\assets\sprites\${name}_pixel.png", [System.Drawing.Imaging.ImageFormat]::Png)
  if ($Preview) {
    $p = New-Object System.Drawing.Bitmap ($sheet.Width / 2), ($sheet.Height / 2)
    $pg = [System.Drawing.Graphics]::FromImage($p)
    $pg.Clear([System.Drawing.Color]::FromArgb(70, 70, 80))
    $pg.InterpolationMode = 'NearestNeighbor'
    $pg.DrawImage($sheet, 0, 0, $p.Width, $p.Height)
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::Magenta), 1
    for ($i = 0; $i -le 8; $i++) { $pg.DrawLine($pen, $i * $cell / 2, 0, $i * $cell / 2, $p.Height) }
    for ($i = 0; $i -le $rows.Count; $i++) { $pg.DrawLine($pen, 0, $i * $cell / 2, $p.Width, $i * $cell / 2) }
    $p.Save("$Preview\$name.png"); $p.Dispose()
  }
  "$name  " + ($log -join '  |  ')
  $sheet.Dispose()
}








