using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class Slicer {
    static int[] px; static int W, H;
    public static void Load(string path) {
        var b = new Bitmap(path);
        W = b.Width; H = b.Height;
        var d = b.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        px = new int[W * H];
        Marshal.Copy(d.Scan0, px, 0, px.Length);
        b.UnlockBits(d); b.Dispose();
    }
    static int Bright(int c) { return Math.Max((c >> 16) & 255, Math.Max((c >> 8) & 255, c & 255)); }

    // Start x of each lit run in a horizontal band (for finding frame anchors).
    public static string Runs(int x0, int x1, int y0, int y1, int thr) {
        var s = new List<string>(); bool inRun = false; int st = 0;
        for (int x = x0; x <= x1; x++) {
            bool lit = false;
            for (int y = y0; y < y1 && !lit; y++) if (Bright(px[y * W + x]) > thr) lit = true;
            if (lit && !inRun) { st = x; inRun = true; }
            else if (!lit && inRun) { s.Add(st + "-" + (x - 1)); inRun = false; }
        }
        if (inRun) s.Add(st + "-" + x1);
        return string.Join(" ", s);
    }

    // Splits one animation row into frames. The band's black background is keyed
    // out, the rest is split into 8-connected pieces, and each piece goes to the
    // frame with the largest anchor <= piece left edge + tol (effects trail to
    // the right of their fighter). Pieces starting at or past `end` are dropped.
    // Each frame is drawn into a cell x cell square, left edge at left (or
    // centered when left < 0), bottom at
    // cell - pad.
    public static Bitmap[] Row(int x0, int end, int y0, int y1, int[] anchors, int tol, int maxW, int cell, int left, int pad, int thr) {
        int w = end - x0, h = y1 - y0;
        var a = new int[w * h];
        for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) a[y * w + x] = px[(y + y0) * W + x + x0];
        var bg = new bool[w * h];
        var q = new Queue<int>();
        Action<int> push = i => { if (!bg[i] && Bright(a[i]) <= thr) { bg[i] = true; q.Enqueue(i); } };
        for (int x = 0; x < w; x++) { push(x); push((h - 1) * w + x); }
        for (int y = 0; y < h; y++) { push(y * w); push(y * w + w - 1); }
        while (q.Count > 0) {
            int i = q.Dequeue(), x = i % w, y = i / w;
            if (x > 0) push(i - 1);
            if (x < w - 1) push(i + 1);
            if (y > 0) push(i - w);
            if (y < h - 1) push(i + w);
        }
        var owner = new int[w * h];
        for (int i = 0; i < owner.Length; i++) owner[i] = -1;
        var seen = new bool[w * h];
        for (int s = 0; s < w * h; s++) {
            if (bg[s] || seen[s]) continue;
            var comp = new List<int>(); var cq = new Queue<int>(); cq.Enqueue(s); seen[s] = true;
            int minx = w, maxx = 0;
            while (cq.Count > 0) {
                int i = cq.Dequeue(); comp.Add(i); int x = i % w, y = i / w;
                if (x < minx) minx = x;
                if (x > maxx) maxx = x;
                for (int dy = -1; dy <= 1; dy++) for (int dx = -1; dx <= 1; dx++) {
                    int nx = x + dx, ny = y + dy;
                    if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                    int n = ny * w + nx;
                    if (!bg[n] && !seen[n]) { seen[n] = true; cq.Enqueue(n); }
                }
            }
            // A piece wider than maxW joins several frames (e.g. through ground
            // splashes), so split it pixel by pixel at the anchors instead.
            bool split = maxx - minx > maxW;
            foreach (int i in comp) {
                int px0 = split ? i % w : minx, f = 0;
                for (int k = 0; k < anchors.Length; k++) if (anchors[k] - x0 <= px0 + (split ? 0 : tol)) f = k;
                owner[i] = f;
            }
        }
        var frames = new Bitmap[anchors.Length];
        for (int f = 0; f < anchors.Length; f++) {
            int minx = w, maxx = -1, maxy = -1;
            for (int i = 0; i < owner.Length; i++) {
                if (owner[i] != f || Bright(a[i]) <= thr + 20) continue;
                int x = i % w, y = i / w;
                if (x < minx) minx = x; if (x > maxx) maxx = x; if (y > maxy) maxy = y;
            }
            var b = new Bitmap(cell, cell, PixelFormat.Format32bppArgb);
            int ox = left >= 0 ? left - minx : cell / 2 - (minx + maxx) / 2, oy = cell - pad - 1 - maxy;
            for (int i = 0; i < owner.Length; i++) {
                if (owner[i] != f) continue;
                int tx = i % w + ox, ty = i / w + oy;
                if (tx >= 0 && tx < cell && ty >= 0 && ty < cell) b.SetPixel(tx, ty, Color.FromArgb(a[i] | unchecked((int)0xFF000000)));
            }
            frames[f] = b;
        }
        return frames;
    }
}
