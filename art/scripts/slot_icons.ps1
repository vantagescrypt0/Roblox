# Makes the Bag's equipment slot pictures (art/textures/ui/slot_*.png, 256 px) and the soft glow
# the Night Glass look uses (glow.png). The helmet and
# chestplate start from ForgeGUI's flat white silhouettes (saved in art/textures/ui/source/);
# the leggings, boots, shield and paw are drawn here in the same style, as ForgeGUI ran out of
# credits. Every picture then gets the same finish: a chunky lit edge and a dark outline. They
# are mostly white so the game can tint them by armor tier (ImageColor3 multiplies, so the
# outline stays dark). Run with Windows PowerShell:
#   powershell -ExecutionPolicy Bypass -File art/scripts/slot_icons.ps1

$source = @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class SlotIcons {
    const int SIZE = 256;
    const int MARGIN = 14;
    const int OUTLINE = 8;
    const int BEVEL = 5;

    // A closed shape with rounded corners, from x,y pairs on a 1000 x 1000 page
    static void Poly(GraphicsPath path, float radius, params float[] xy) {
        int n = xy.Length / 2;
        path.StartFigure();
        for (int i = 0; i < n; i++) {
            PointF v = new PointF(xy[i * 2], xy[i * 2 + 1]);
            PointF p = new PointF(xy[((i + n - 1) % n) * 2], xy[((i + n - 1) % n) * 2 + 1]);
            PointF q = new PointF(xy[((i + 1) % n) * 2], xy[((i + 1) % n) * 2 + 1]);
            PointF a = Toward(v, p, radius);
            PointF b = Toward(v, q, radius);
            path.AddBezier(a, Mix(a, v, 0.6f), Mix(b, v, 0.6f), b);
        }
        path.CloseFigure();
    }

    static PointF Toward(PointF from, PointF to, float distance) {
        float dx = to.X - from.X, dy = to.Y - from.Y;
        float length = (float)Math.Sqrt(dx * dx + dy * dy);
        float step = Math.Min(distance, length / 2) / length;
        return new PointF(from.X + dx * step, from.Y + dy * step);
    }

    static PointF Mix(PointF a, PointF b, float t) {
        return new PointF(a.X + (b.X - a.X) * t, a.Y + (b.Y - a.Y) * t);
    }

    static Bitmap Page(params GraphicsPath[] shapes) {
        Bitmap page = new Bitmap(1024, 1024, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(page)) {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.ScaleTransform(1.024f, 1.024f);
            foreach (GraphicsPath shape in shapes) {
                g.FillPath(Brushes.White, shape);
            }
        }
        return page;
    }

    static Bitmap Legs() {
        GraphicsPath p = new GraphicsPath(FillMode.Alternate);
        // Waist, hips, two legs
        Poly(p, 34, 285,90, 715,90, 735,215, 785,350, 760,915, 560,915, 525,500, 475,500, 440,915, 240,915, 215,350, 265,215);
        // Belt line and buckle
        Poly(p, 12, 290,212, 710,212, 716,246, 284,246);
        Poly(p, 12, 450,118, 550,118, 550,190, 450,190);
        // Thigh ridges
        Poly(p, 12, 300,330, 425,330, 432,368, 296,368);
        Poly(p, 12, 575,330, 700,330, 704,368, 568,368);
        // Knee plates
        Poly(p, 14, 283,590, 358,632, 437,590, 441,632, 358,678, 281,632);
        Poly(p, 14, 559,590, 642,632, 717,590, 719,632, 642,678, 563,632);
        // Shin slits
        Poly(p, 12, 335,740, 380,740, 372,860, 342,860);
        Poly(p, 12, 620,740, 665,740, 658,860, 628,860);
        return Page(p);
    }

    static Bitmap Boots() {
        GraphicsPath p = new GraphicsPath(FillMode.Alternate);
        // A tall boot from the side, toe to the right
        Poly(p, 36, 225,80, 640,80, 665,190, 625,500, 800,610, 925,700, 945,905, 195,905, 170,690, 205,500, 195,190);
        // Cuff
        Poly(p, 12, 235,205, 625,205, 620,240, 240,240);
        // Shin straps
        Poly(p, 12, 240,310, 620,310, 616,342, 244,342);
        Poly(p, 12, 248,420, 606,420, 602,452, 252,452);
        // Ankle
        Poly(p, 14, 222,540, 600,540, 640,585, 590,600, 228,588);
        // Toe cap
        Poly(p, 14, 700,650, 740,676, 680,800, 640,800);
        // Sole
        Poly(p, 12, 212,800, 905,800, 910,835, 214,835);
        return Page(p);
    }

    static Bitmap Shield() {
        GraphicsPath p = new GraphicsPath(FillMode.Alternate);
        // A tall shield, wide at the top and coming to a point
        Poly(p, 40, 500,60, 850,150, 865,480, 780,720, 500,945, 220,720, 135,480, 150,150);
        // Round emblem
        p.StartFigure();
        p.AddEllipse(395, 240, 210, 210);
        // Chevron under it
        Poly(p, 14, 265,530, 500,700, 735,530, 730,590, 500,762, 270,590);
        // Top edge lines
        Poly(p, 12, 500,135, 770,205, 765,240, 500,172, 235,240, 230,205);
        return Page(p);
    }

    static Bitmap Paw() {
        GraphicsPath pad = new GraphicsPath(FillMode.Winding);
        pad.AddBezier(500f, 500f, 610f, 500f, 690f, 600f, 750f, 680f);
        pad.AddBezier(750f, 680f, 830f, 790f, 780f, 920f, 650f, 900f);
        pad.AddBezier(650f, 900f, 580f, 890f, 540f, 860f, 500f, 860f);
        pad.AddBezier(500f, 860f, 460f, 860f, 420f, 890f, 350f, 900f);
        pad.AddBezier(350f, 900f, 220f, 920f, 170f, 790f, 250f, 680f);
        pad.AddBezier(250f, 680f, 310f, 600f, 390f, 500f, 500f, 500f);
        pad.CloseFigure();
        return Page(pad, Toe(165, 435, 85, 120, -24), Toe(365, 250, 92, 135, -8), Toe(635, 250, 92, 135, 8), Toe(835, 435, 85, 120, 24));
    }

    static GraphicsPath Toe(float x, float y, float rx, float ry, float angle) {
        GraphicsPath toe = new GraphicsPath(FillMode.Winding);
        toe.AddEllipse(x - rx, y - ry, rx * 2, ry * 2);
        using (Matrix turn = new Matrix()) {
            turn.RotateAt(angle, new PointF(x, y));
            toe.Transform(turn);
        }
        return toe;
    }

    static byte[] Pixels(Bitmap image, out int stride) {
        BitmapData data = image.LockBits(new Rectangle(0, 0, image.Width, image.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        stride = data.Stride;
        byte[] pixels = new byte[stride * image.Height];
        Marshal.Copy(data.Scan0, pixels, 0, pixels.Length);
        image.UnlockBits(data);
        return pixels;
    }

    // Crops to the shape, scales it into the icon, drops any colour fringe and adds the finish
    static void Finish(Bitmap page, string output) {
        int stride;
        byte[] raw = Pixels(page, out stride);
        int left = page.Width, right = 0, top = page.Height, bottom = 0;
        for (int y = 0; y < page.Height; y++) {
            for (int x = 0; x < page.Width; x++) {
                if (raw[y * stride + x * 4 + 3] > 128) {
                    left = Math.Min(left, x); right = Math.Max(right, x);
                    top = Math.Min(top, y); bottom = Math.Max(bottom, y);
                }
            }
        }
        int shapeWidth = right - left + 1, shapeHeight = bottom - top + 1;
        float room = SIZE - 2 * MARGIN;
        float scale = Math.Min(room / shapeWidth, room / shapeHeight);
        int drawWidth = (int)(shapeWidth * scale), drawHeight = (int)(shapeHeight * scale);
        using (Bitmap fitted = new Bitmap(SIZE, SIZE, PixelFormat.Format32bppArgb)) {
            using (Graphics g = Graphics.FromImage(fitted)) {
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                g.DrawImage(page, new Rectangle((SIZE - drawWidth) / 2, (SIZE - drawHeight) / 2, drawWidth, drawHeight), new Rectangle(left, top, shapeWidth, shapeHeight), GraphicsUnit.Pixel);
            }
            int fittedStride;
            byte[] pixels = Pixels(fitted, out fittedStride);
            float[,] alpha = new float[SIZE, SIZE];
            for (int y = 0; y < SIZE; y++) {
                for (int x = 0; x < SIZE; x++) {
                    alpha[x, y] = pixels[y * fittedStride + x * 4 + 3] / 255f;
                }
            }
            List<int[]> disc = new List<int[]>();
            for (int dy = -OUTLINE; dy <= OUTLINE; dy++) {
                for (int dx = -OUTLINE; dx <= OUTLINE; dx++) {
                    if (dx * dx + dy * dy <= OUTLINE * OUTLINE) {
                        disc.Add(new int[] { dx, dy });
                    }
                }
            }
            using (Bitmap result = new Bitmap(SIZE, SIZE, PixelFormat.Format32bppArgb)) {
                BitmapData data = result.LockBits(new Rectangle(0, 0, SIZE, SIZE), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
                byte[] final = new byte[data.Stride * SIZE];
                for (int y = 0; y < SIZE; y++) {
                    for (int x = 0; x < SIZE; x++) {
                        float a = alpha[x, y];
                        float reach = a;
                        foreach (int[] d in disc) {
                            int nx = x + d[0], ny = y + d[1];
                            if (nx >= 0 && ny >= 0 && nx < SIZE && ny < SIZE && alpha[nx, ny] > reach) {
                                reach = alpha[nx, ny];
                            }
                        }
                        if (reach <= 0) {
                            continue;
                        }
                        float above = y >= BEVEL ? alpha[x, y - BEVEL] : 0;
                        float below = y + BEVEL < SIZE ? alpha[x, y + BEVEL] : 0;
                        float shade = 0.94f - 0.12f * y / SIZE;
                        if (above < 0.5f) {
                            shade = 1f;
                        } else if (below < 0.5f) {
                            shade = 0.66f;
                        }
                        float r = (shade * 255 * a + 30 * (reach - a)) / reach;
                        float g2 = (shade * 255 * a + 36 * (reach - a)) / reach;
                        float b = (shade * 255 * a + 58 * (reach - a)) / reach;
                        int at = y * data.Stride + x * 4;
                        final[at] = (byte)b;
                        final[at + 1] = (byte)g2;
                        final[at + 2] = (byte)r;
                        final[at + 3] = (byte)(reach * 255);
                    }
                }
                Marshal.Copy(final, 0, data.Scan0, final.Length);
                result.UnlockBits(data);
                result.Save(output, ImageFormat.Png);
            }
        }
    }

    static Bitmap Tint(Bitmap image, Color tint) {
        Bitmap tinted = new Bitmap(image.Width, image.Height, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(tinted)) {
            ColorMatrix matrix = new ColorMatrix();
            matrix.Matrix00 = tint.R / 255f;
            matrix.Matrix11 = tint.G / 255f;
            matrix.Matrix22 = tint.B / 255f;
            using (ImageAttributes attributes = new ImageAttributes()) {
                attributes.SetColorMatrix(matrix);
                g.DrawImage(image, new Rectangle(0, 0, image.Width, image.Height), 0, 0, image.Width, image.Height, GraphicsUnit.Pixel, attributes);
            }
        }
        return tinted;
    }

    // A soft round light: white, fading to nothing at the edge
    static void Glow(string output) {
        using (Bitmap glow = new Bitmap(SIZE, SIZE, PixelFormat.Format32bppArgb)) {
            for (int y = 0; y < SIZE; y++) {
                for (int x = 0; x < SIZE; x++) {
                    double dx = (x + 0.5 - SIZE / 2.0) / (SIZE / 2.0), dy = (y + 0.5 - SIZE / 2.0) / (SIZE / 2.0);
                    double t = Math.Max(0, 1 - Math.Sqrt(dx * dx + dy * dy));
                    glow.SetPixel(x, y, Color.FromArgb((int)(255 * t * t), 255, 255, 255));
                }
            }
            glow.Save(output, ImageFormat.Png);
        }
    }

    public static void Make(string folder, string preview) {
        Glow(folder + "\\glow.png");
        string[] names = { "Helmet", "Chest", "Legs", "Boots", "Shield", "Pet" };
        using (Bitmap helmet = new Bitmap(folder + "\\source\\Helmet.png")) { Finish(helmet, folder + "\\slot_Helmet.png"); }
        using (Bitmap chest = new Bitmap(folder + "\\source\\Chest.png")) { Finish(chest, folder + "\\slot_Chest.png"); }
        using (Bitmap legs = Legs()) { Finish(legs, folder + "\\slot_Legs.png"); }
        using (Bitmap boots = Boots()) { Finish(boots, folder + "\\slot_Boots.png"); }
        using (Bitmap shield = Shield()) { Finish(shield, folder + "\\slot_Shield.png"); }
        using (Bitmap paw = Paw()) { Finish(paw, folder + "\\slot_Pet.png"); }

        // A check sheet: each picture on the navy slot, empty and in tier colours, and on the pale grid
        Color navy = Color.FromArgb(42, 59, 94), pale = Color.FromArgb(238, 246, 255);
        Color[] tints = { Color.FromArgb(78, 100, 145), Color.FromArgb(205, 127, 50), Color.FromArgb(196, 200, 208), Color.FromArgb(120, 222, 244) };
        const int CELL = 128;
        using (Bitmap sheet = new Bitmap(CELL * names.Length, CELL * 4)) {
            using (Graphics g = Graphics.FromImage(sheet)) {
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                for (int i = 0; i < names.Length; i++) {
                    using (Bitmap icon = new Bitmap(folder + "\\slot_" + names[i] + ".png")) {
                        for (int row = 0; row < 4; row++) {
                            Rectangle cell = new Rectangle(i * CELL, row * CELL, CELL, CELL);
                            using (SolidBrush fill = new SolidBrush(row == 3 ? pale : navy)) { g.FillRectangle(fill, cell); }
                            using (Bitmap tinted = Tint(icon, tints[row])) {
                                g.DrawImage(tinted, new Rectangle(cell.X + 16, cell.Y + 16, 96, 96));
                            }
                        }
                    }
                }
            }
            sheet.Save(preview, ImageFormat.Png);
        }
    }
}
'@

Add-Type -TypeDefinition $source -ReferencedAssemblies System.Drawing
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
[SlotIcons]::Make("$root\art\textures\ui", "$root\art\renders\SlotIcons.png")
Write-Output "made slot icons"
