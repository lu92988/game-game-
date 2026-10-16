using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

// Turns the full-detail battle backdrops into chunky pixel art that matches
// the sprites: shrinks them (the game scales them back up with nearest
// neighbour), then cuts them to a small palette whose colors are pulled
// toward the sprites' own. See build_backdrops.ps1.
public static class Pixelate {
    public static int[] Read(Bitmap b) {
        var d = b.LockBits(new Rectangle(0, 0, b.Width, b.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        var px = new int[b.Width * b.Height];
        Marshal.Copy(d.Scan0, px, 0, px.Length);
        b.UnlockBits(d);
        return px;
    }

    // Area-averaged shrink to the given height.
    public static Bitmap Shrink(string path, int height) {
        using (var src = new Bitmap(path)) {
            int w = (int)Math.Round(src.Width * height / (double)src.Height);
            var b = new Bitmap(w, height, PixelFormat.Format32bppArgb);
            using (var g = Graphics.FromImage(b)) {
                g.InterpolationMode = InterpolationMode.HighQualityBilinear;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                g.DrawImage(src, new Rectangle(0, 0, w, height));
            }
            return b;
        }
    }

    // k-means over (a sample of) the opaque pixels.
    public static int[][] Palette(List<int> pixels, int k, int seed) {
        var rnd = new Random(seed);
        var pts = new List<int[]>();
        int step = Math.Max(1, pixels.Count / 60000);
        for (int i = 0; i < pixels.Count; i += step) {
            int c = pixels[i];
            pts.Add(new[] { (c >> 16) & 255, (c >> 8) & 255, c & 255 });
        }
        var cent = new int[k][];
        for (int j = 0; j < k; j++) cent[j] = (int[])pts[rnd.Next(pts.Count)].Clone();
        var asg = new int[pts.Count];
        for (int it = 0; it < 16; it++) {
            for (int i = 0; i < pts.Count; i++) asg[i] = Nearest(cent, pts[i]);
            var sum = new long[k, 3]; var n = new int[k];
            for (int i = 0; i < pts.Count; i++) {
                n[asg[i]]++;
                for (int ch = 0; ch < 3; ch++) sum[asg[i], ch] += pts[i][ch];
            }
            for (int j = 0; j < k; j++) {
                if (n[j] == 0) { cent[j] = (int[])pts[rnd.Next(pts.Count)].Clone(); continue; }
                for (int ch = 0; ch < 3; ch++) cent[j][ch] = (int)(sum[j, ch] / n[j]);
            }
        }
        return cent;
    }

    static int Nearest(int[][] pal, int[] p) {
        int best = 0, bd = int.MaxValue;
        for (int j = 0; j < pal.Length; j++) {
            int dr = pal[j][0] - p[0], dg = pal[j][1] - p[1], db = pal[j][2] - p[2];
            int d = 3 * dr * dr + 4 * dg * dg + 2 * db * db;
            if (d < bd) { bd = d; best = j; }
        }
        return best;
    }

    // Opaque pixels of every sprite sheet in a folder.
    public static List<int> SpritePixels(string[] files) {
        var all = new List<int>();
        foreach (var f in files) using (var b = new Bitmap(f)) {
            var px = Read(b);
            for (int i = 0; i < px.Length; i += 7) if (((px[i] >> 24) & 255) == 255) all.Add(px[i]);
        }
        return all;
    }

    // Moves each backdrop color onto the nearest sprite color when they are
    // close, so both come from one set of paints. Returns how many moved.
    public static int Snap(int[][] pal, int[][] spritePal, int maxDist) {
        int moved = 0;
        foreach (var c in pal) {
            var s = spritePal[Nearest(spritePal, c)];
            int dr = s[0] - c[0], dg = s[1] - c[1], db = s[2] - c[2];
            if (Math.Sqrt(dr * dr + dg * dg + db * db) <= maxDist) { c[0] = s[0]; c[1] = s[1]; c[2] = s[2]; moved++; }
        }
        return moved;
    }

    public static void Map(Bitmap b, int[][] pal) {
        var px = Read(b);
        var cache = new Dictionary<int, int>();
        for (int i = 0; i < px.Length; i++) {
            int c = px[i] & 0xFFFFFF;
            int o;
            if (!cache.TryGetValue(c, out o)) {
                var p = pal[Nearest(pal, new[] { (c >> 16) & 255, (c >> 8) & 255, c & 255 })];
                o = unchecked((int)0xFF000000) | (p[0] << 16) | (p[1] << 8) | p[2];
                cache[c] = o;
            }
            px[i] = o;
        }
        var d = b.LockBits(new Rectangle(0, 0, b.Width, b.Height), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
        Marshal.Copy(px, 0, d.Scan0, px.Length);
        b.UnlockBits(d);
    }

    public static List<int> Pixels(Bitmap b) { return new List<int>(Read(b)); }
}
