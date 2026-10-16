using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

// Doubles a move's frames by putting an in-between after each drawn frame (a
// 50/50 blend of its neighbours, pixel for pixel, so edges stay crisp), then
// spreads the result over a fixed number of frames. See build_sheets.ps1.
public static class Tween {
    static int[] Read(Bitmap b) {
        var d = b.LockBits(new Rectangle(0, 0, b.Width, b.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        var px = new int[b.Width * b.Height];
        Marshal.Copy(d.Scan0, px, 0, px.Length);
        b.UnlockBits(d);
        return px;
    }

    // Halfway between two frames: alpha is averaged and color is weighted by
    // alpha, so a pixel only one frame covers keeps its color at half alpha.
    public static Bitmap Mix(Bitmap a, Bitmap b) {
        int w = a.Width, h = a.Height;
        var pa = Read(a); var pb = Read(b); var o = new int[w * h];
        for (int i = 0; i < o.Length; i++) {
            int ca = pa[i], cb = pb[i];
            int aa = (ca >> 24) & 255, ab = (cb >> 24) & 255, s = aa + ab;
            if (s == 0) continue;
            int r = (((ca >> 16) & 255) * aa + ((cb >> 16) & 255) * ab) / s;
            int g = (((ca >> 8) & 255) * aa + ((cb >> 8) & 255) * ab) / s;
            int bl = ((ca & 255) * aa + (cb & 255) * ab) / s;
            o[i] = ((s / 2) << 24) | (r << 16) | (g << 8) | bl;
        }
        var outp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        var d = outp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
        Marshal.Copy(o, 0, d.Scan0, o.Length);
        outp.UnlockBits(d);
        return outp;
    }

    // Drawn frames with an in-between after each one; a looping move (idle)
    // also gets one from its last frame back to its first.
    public static Bitmap[] Expand(Bitmap[] frames, bool loop) {
        var outp = new List<Bitmap>();
        for (int i = 0; i < frames.Length; i++) {
            outp.Add(frames[i]);
            if (i + 1 < frames.Length) outp.Add(Mix(frames[i], frames[i + 1]));
            else if (loop && frames.Length > 1) outp.Add(Mix(frames[i], frames[0]));
        }
        return outp.ToArray();
    }

    // Exactly count frames: a loop is sampled evenly around the cycle; any
    // other move starts on its first frame and ends on its last.
    public static Bitmap[] Pick(Bitmap[] frames, int count, bool loop) {
        var outp = new Bitmap[count];
        int m = frames.Length;
        for (int i = 0; i < count; i++)
            outp[i] = frames[loop ? i * m / count : (int)Math.Round(i * (m - 1) / (double)(count - 1))];
        return outp;
    }
}
