using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Linq;
using System.Runtime.InteropServices;

// Cuts the user's ChatGPT pixel art sheets (labeled rows of frames on a flat
// background) into frames. See build_sheets.ps1.
public static class AutoSlice {
    static int[] px; static int W, H; static int bgR, bgG, bgB;
    public static int Thr = 12;
    // Trapped background pockets: how close to the background color, and how
    // many pixels a patch needs before it is cleared.
    public static int PocketThr = 4;
    public static int PocketMin = 60;

    public static string Load(string path) {
        var b = new Bitmap(path);
        W = b.Width; H = b.Height;
        var d = b.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        px = new int[W * H];
        Marshal.Copy(d.Scan0, px, 0, px.Length);
        b.UnlockBits(d); b.Dispose();
        // Sheets with a see-through background: mostly transparent pixels
        // (including the soft, tinted fringes) become plain black background.
        for (int i = 0; i < px.Length; i++) if (((px[i] >> 24) & 255) < 255) px[i] = unchecked((int)0xFF000000);
        int c = px[(H - 3) * W + W - 3];
        bgR = (c >> 16) & 255; bgG = (c >> 8) & 255; bgB = c & 255;
        return W + "x" + H + " bg " + bgR + "," + bgG + "," + bgB;
    }

    // Blanks the row labels ("IDLE (8 FRAMES)" etc.): boxes whose top and
    // bottom edges are long lit runs 22-60px apart with matching ends and
    // whose left and right sides are lit most of the way down.
    public static int EraseLabels() {
        var runs = new List<int[]>();
        for (int y = 0; y < H; y++) {
            int st = -1;
            for (int x = 0; x <= W; x++) {
                bool lit = x < W && Lit(x, y);
                if (lit && st < 0) st = x;
                else if (!lit && st >= 0) { if (x - st >= 120) runs.Add(new[] { y, st, x - 1 }); st = -1; }
            }
        }
        int erased = 0;
        var done = new List<int[]>();
        foreach (var a in runs) foreach (var b in runs) {
            int dy = b[0] - a[0];
            if (dy < 22 || dy > 60 || Math.Abs(a[1] - b[1]) > 6 || Math.Abs(a[2] - b[2]) > 6) continue;
            int x0 = Math.Min(a[1], b[1]), x1 = Math.Max(a[2], b[2]);
            if (done.Any(r => r[0] <= x0 + 8 && r[2] >= x1 - 8 && r[1] <= a[0] + 8 && r[3] >= b[0] - 8)) continue;
            int sides = 0;
            for (int y = a[0]; y <= b[0]; y++) if (Lit(x0 + 1, y) && Lit(x1 - 1, y)) sides++;
            if (sides < 0.8 * (dy + 1)) continue;
            // Labels sit on plain background; glowing effects don't.
            int above = 0, below = 0;
            for (int x = x0; x <= x1; x++) {
                if (a[0] >= 7 && Lit(x, a[0] - 7)) above++;
                if (b[0] + 7 < H && Lit(x, b[0] + 7)) below++;
            }
            if (above > 0.25 * (x1 - x0) || below > 0.25 * (x1 - x0)) continue;
            int ex0 = Math.Max(0, x0 - 4), ex1 = Math.Min(W - 1, x1 + 4), ey0 = Math.Max(0, a[0] - 4), ey1 = Math.Min(H - 1, b[0] + 4);
            for (int y = ey0; y <= ey1; y++) for (int x = ex0; x <= ex1; x++) px[y * W + x] = unchecked((int)0xFF000000) | (bgR << 16) | (bgG << 8) | bgB;
            done.Add(new[] { ex0, ey0, ex1, ey1 });
            erased++;
        }
        return erased;
    }

    // Frame start columns for a row segment: tries every frame count from
    // nMin to nMax, places cuts evenly and slides each to the emptiest column
    // nearby, and keeps the largest count whose cuts all land in (nearly)
    // empty columns, else the count with the emptiest worst cut. Occupancy is
    // measured over the bottom `frac` of the band (bodies, not effects).
    public static int[] Anchors(int x0, int x1, int y0, int y1, int nMin, int nMax, double frac) {
        int ys = y1 - (int)((y1 - y0) * frac);
        var occ = new int[x1 - x0];
        for (int x = x0; x < x1; x++) for (int y = ys; y < y1; y++) if (Lit(x, y)) occ[x - x0]++;
        int L = 0, R = occ.Length - 1;
        while (L < R && occ[L] == 0) L++;
        while (R > L && occ[R] == 0) R--;
        int[] best = null; int bestWorst = int.MaxValue; int[] bestClean = null;
        for (int n = nMin; n <= nMax; n++) {
            double s = (R - L + 1) / (double)n;
            var cuts = new int[n]; cuts[0] = L; int worst = 0; bool ok = true;
            for (int k = 1; k < n; k++) {
                int ideal = (int)(L + k * s), lo = Math.Max(cuts[k - 1] + (int)(0.5 * s), ideal - (int)(0.35 * s)), hi = Math.Min(R, ideal + (int)(0.35 * s));
                if (lo > hi) { ok = false; break; }
                int c = lo;
                for (int x = lo; x <= hi; x++) if (occ[x] < occ[c] || (occ[x] == occ[c] && Math.Abs(x - ideal) < Math.Abs(c - ideal))) c = x;
                cuts[k] = c; worst = Math.Max(worst, occ[c]);
            }
            if (!ok) continue;
            var abs = cuts.Select(c => c + x0).ToArray();
            if (worst <= 2) bestClean = abs;
            if (worst < bestWorst || (worst == bestWorst)) { bestWorst = worst; best = abs; }
        }
        return bestClean ?? best;
    }

    static int Dist(int c) {
        return Math.Max(Math.Abs(((c >> 16) & 255) - bgR), Math.Max(Math.Abs(((c >> 8) & 255) - bgG), Math.Abs((c & 255) - bgB)));
    }
    static bool Lit(int x, int y) { return Dist(px[y * W + x]) > Thr; }

    // Horizontal bands of lit rows within x0..x1: "y0-y1:litColumns".
    public static string Bands(int x0, int x1, int minPerRow, int gap) {
        var outp = new List<string>();
        int start = -1, last = -1;
        for (int y = 0; y < H; y++) {
            int n = 0;
            for (int x = x0; x < x1; x++) if (Lit(x, y)) n++;
            if (n >= minPerRow) { if (start < 0) start = y; last = y; }
            else if (start >= 0 && y - last > gap) { outp.Add(Describe(x0, x1, start, last)); start = -1; }
        }
        if (start >= 0) outp.Add(Describe(x0, x1, start, last));
        return string.Join("  ", outp);
    }
    static string Describe(int x0, int x1, int y0, int y1) {
        return y0 + "-" + y1 + "[" + Runs(x0, x1, y0, y1 + 1, 2, 4) + "]";
    }

    // Lit column runs in the band (a column counts when it has >= minLit lit
    // pixels; runs closer than gap are merged): "x0-x1 x0-x1 ...".
    public static string Runs(int x0, int x1, int y0, int y1, int minLit, int gap) {
        var s = new List<string>();
        int st = -1, last = -1;
        for (int x = x0; x < x1; x++) {
            int n = 0;
            for (int y = y0; y < y1; y++) if (Lit(x, y)) n++;
            if (n >= minLit) { if (st < 0) st = x; last = x; }
            else if (st >= 0 && x - last > gap) { s.Add(st + "-" + last); st = -1; }
        }
        if (st >= 0) s.Add(st + "-" + last);
        return string.Join(" ", s);
    }

    // Moves each cut (after the first) to the emptiest column within radius,
    // so frames split in the gaps between poses.
    public static int[] Refine(int[] cuts, int y0, int y1, int radius) {
        var outp = (int[])cuts.Clone();
        for (int k = 1; k < cuts.Length; k++) {
            int best = cuts[k], bestN = int.MaxValue;
            for (int x = cuts[k] - radius; x <= cuts[k] + radius; x++) {
                if (x <= outp[k - 1] + 10 || x < 0 || x >= W) continue;
                int n = 0;
                for (int y = y0; y < y1; y++) if (Lit(x, y)) n++;
                if (n < bestN || (n == bestN && Math.Abs(x - cuts[k]) < Math.Abs(best - cuts[k]))) { bestN = n; best = x; }
            }
            outp[k] = best;
        }
        return outp;
    }

    // Cuts a row into frames: frame k is the strip from cuts[k] to cuts[k+1]
    // (the last ends at end). The background is keyed out from the strip
    // edges; specks, thin label lines and small slivers of neighbouring
    // frames at the strip sides are dropped. Each frame is drawn into a
    // cell x cell square, bottom at cell - pad, left edge at left (centered
    // when left < 0).
    public static Bitmap[] Row(int[] cuts, int end, int y0, int y1, int cell, int left, int pad) {
        var frames = new Bitmap[cuts.Length];
        for (int f = 0; f < cuts.Length; f++) {
            int x0 = cuts[f], x1 = f + 1 < cuts.Length ? cuts[f + 1] : end;
            frames[f] = Strip(x0, x1, y0, y1, cell, left, pad);
        }
        return frames;
    }

    static Bitmap Strip(int x0, int x1, int y0, int y1, int cell, int left, int pad) {
        int w = x1 - x0, h = y1 - y0;
        var a = new int[w * h];
        for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) a[y * w + x] = px[(y + y0) * W + x + x0];
        var bg = new bool[w * h];
        var q = new Queue<int>();
        Action<int> push = i => { if (!bg[i] && Dist(a[i]) <= Thr) { bg[i] = true; q.Enqueue(i); } };
        for (int x = 0; x < w; x++) { push(x); push((h - 1) * w + x); }
        for (int y = 0; y < h; y++) { push(y * w); push(y * w + w - 1); }
        while (q.Count > 0) {
            int i = q.Dequeue(), x = i % w, y = i / w;
            if (x > 0) push(i - 1);
            if (x < w - 1) push(i + 1);
            if (y > 0) push(i - w);
            if (y < h - 1) push(i + w);
        }
        // Pockets of background trapped inside the drawing (between legs,
        // under arms): sizable patches of near-pure background color.
        var pocketSeen = new bool[w * h];
        for (int s = 0; s < w * h; s++) {
            if (bg[s] || pocketSeen[s] || Dist(a[s]) > PocketThr) continue;
            var pocket = new List<int>(); var pq = new Queue<int>(); pq.Enqueue(s); pocketSeen[s] = true;
            while (pq.Count > 0) {
                int i = pq.Dequeue(); pocket.Add(i); int x = i % w, y = i / w;
                foreach (int n in new[] { x > 0 ? i - 1 : -1, x < w - 1 ? i + 1 : -1, y > 0 ? i - w : -1, y < h - 1 ? i + w : -1 })
                    if (n >= 0 && !bg[n] && !pocketSeen[n] && Dist(a[n]) <= PocketThr) { pocketSeen[n] = true; pq.Enqueue(n); }
            }
            if (pocket.Count >= PocketMin) foreach (int i in pocket) bg[i] = true;
        }
        // 8-connected pieces with their size and bounds.
        var comps = new List<List<int>>(); var info = new List<int[]>();
        var seen = new bool[w * h];
        for (int s = 0; s < w * h; s++) {
            if (bg[s] || seen[s]) continue;
            var comp = new List<int>(); var cq = new Queue<int>(); cq.Enqueue(s); seen[s] = true;
            int mnx = w, mxx = 0, mny = h, mxy = 0;
            while (cq.Count > 0) {
                int i = cq.Dequeue(); comp.Add(i); int x = i % w, y = i / w;
                mnx = Math.Min(mnx, x); mxx = Math.Max(mxx, x); mny = Math.Min(mny, y); mxy = Math.Max(mxy, y);
                for (int dy = -1; dy <= 1; dy++) for (int dx = -1; dx <= 1; dx++) {
                    int nx = x + dx, ny = y + dy;
                    if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                    int n = ny * w + nx;
                    if (!bg[n] && !seen[n]) { seen[n] = true; cq.Enqueue(n); }
                }
            }
            comps.Add(comp); info.Add(new[] { comp.Count, mnx, mxx, mny, mxy });
        }
        int biggest = info.Count == 0 ? 0 : info.Max(v => v[0]);
        var keep = new bool[w * h];
        for (int c = 0; c < comps.Count; c++) {
            var v = info[c];
            bool speck = v[0] < 25;
            bool line = v[4] - v[3] <= 5 && v[2] - v[1] >= 15;
            bool sliver = (v[1] == 0 || v[2] == w - 1) && v[0] < 0.12 * biggest;
            if (speck || line || sliver) continue;
            foreach (int i in comps[c]) keep[i] = true;
        }
        int minx = w, maxx = -1, maxy = -1;
        for (int i = 0; i < keep.Length; i++) {
            if (!keep[i] || Dist(a[i]) <= Thr + 20) continue;
            int x = i % w, y = i / w;
            if (x < minx) minx = x; if (x > maxx) maxx = x; if (y > maxy) maxy = y;
        }
        var b = new Bitmap(cell, cell, PixelFormat.Format32bppArgb);
        if (maxx < 0) return b;
        int ox = left >= 0 ? left - minx : cell / 2 - (minx + maxx) / 2, oy = cell - pad - 1 - maxy;
        for (int i = 0; i < keep.Length; i++) {
            if (!keep[i]) continue;
            int tx = i % w + ox, ty = i / w + oy;
            if (tx >= 0 && tx < cell && ty >= 0 && ty < cell) b.SetPixel(tx, ty, Color.FromArgb(a[i] | unchecked((int)0xFF000000)));
        }
        return b;
    }
}


