$code = @"
using System;
using System.Runtime.InteropServices;
using System.Threading;

public class GDICore {
    [DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern int ReleaseDC(IntPtr hwnd, IntPtr hdc);
    [DllImport("gdi32.dll")] public static extern bool BitBlt(IntPtr hdcDest, int nXDest, int nYDest, int nWidth, int nHeight, IntPtr hdcSrc, int nXSrc, int nYSrc, uint dwRop);
    [DllImport("gdi32.dll")] public static extern bool StretchBlt(IntPtr hdcDest, int nXDest, int nYDest, int nWidth, int nHeight, IntPtr hdcSrc, int nXSrc, int nYSrc, int nWidthSrc, int nHeightSrc, uint dwRop);
    [DllImport("user32.dll")] public static extern int GetSystemMetrics(int nIndex);
    [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int X, int Y);
    [DllImport("user32.dll")] public static extern IntPtr LoadIcon(IntPtr hInstance, int lpIconName);
    [DllImport("user32.dll")] public static extern bool DrawIcon(IntPtr hdc, int x, int y, IntPtr hIcon);
    [DllImport("user32.dll")] public static extern bool InvalidateRect(IntPtr hWnd, IntPtr lpRect, bool bErase);
    
    [DllImport("gdi32.dll")] public static extern IntPtr CreatePen(int fnPenStyle, int nWidth, uint crColor);
    [DllImport("gdi32.dll")] public static extern IntPtr SelectObject(IntPtr hdc, IntPtr hgdiobj);
    [DllImport("gdi32.dll")] public static extern bool DeleteObject(IntPtr hObject);
    [DllImport("gdi32.dll")] public static extern bool MoveToEx(IntPtr hdc, int x, int y, IntPtr lpPoint);
    [DllImport("gdi32.dll")] public static extern bool LineTo(IntPtr hdc, int x, int y);

    [StructLayout(LayoutKind.Sequential)]
    public struct WAVEFORMATEX {
        public ushort wFormatTag; public ushort nChannels; public uint nSamplesPerSec;
        public uint nAvgBytesPerSec; public ushort nBlockAlign; public ushort wBitsPerSample; public ushort cbSize;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct WAVEHDR {
        public IntPtr lpData; public uint dwBufferLength; public uint dwBytesRecorded;
        public IntPtr dwUser; public uint dwFlags; public uint dwLoops; public IntPtr lpNext; public IntPtr reserved;
    }

    [DllImport("winmm.dll")] public static extern int waveOutOpen(out IntPtr hWaveOut, uint uDeviceID, ref WAVEFORMATEX lpFormat, IntPtr dwCallback, IntPtr dwInstance, uint fdwOpen);
    [DllImport("winmm.dll")] public static extern int waveOutPrepareHeader(IntPtr hWaveOut, ref WAVEHDR lpWaveOutHdr, uint uSize);
    [DllImport("winmm.dll")] public static extern int waveOutWrite(IntPtr hWaveOut, ref WAVEHDR lpWaveOutHdr, uint uSize);

    const uint NOTSRCOPY = 0x00330008;
    const uint SRCINVERT = 0x00660046;
    const uint SRCCOPY = 0x00CC0220;
    const uint SRCPAINT = 0x00EE0086;
    const uint SRCAND = 0x008800C6;

    public static int currentPayload = 1;
    public static bool isRunning = true;

    // 7 DISTINCT BYTEBEAT FORMULAS
    public static void AudioThread() {
        IntPtr hWaveOut;
        WAVEFORMATEX wfx = new WAVEFORMATEX();
        wfx.wFormatTag = 1; wfx.nChannels = 1; wfx.nSamplesPerSec = 8000;
        wfx.nAvgBytesPerSec = 8000; wfx.nBlockAlign = 1; wfx.wBitsPerSample = 8; wfx.cbSize = 0;

        if (waveOutOpen(out hWaveOut, 0xFFFFFFFF, ref wfx, IntPtr.Zero, IntPtr.Zero, 0) != 0) return;

        int bufferSize = 8000;
        byte[] buffer = new byte[bufferSize];
        GCHandle handle = GCHandle.Alloc(buffer, GCHandleType.Pinned);

        WAVEHDR header = new WAVEHDR();
        header.lpData = handle.AddrOfPinnedObject();
        header.dwBufferLength = (uint)bufferSize;

        uint t = 0;
        while (isRunning) {
            for (int i = 0; i < bufferSize; i++) {
                byte b = 0;
                switch (currentPayload) {
                    case 1: b = (byte)((t * (t >> 8 | t >> 12)) ^ (t >> 4)); break; // Classic Chiptune
                    case 2: b = (byte)((t * 5 & t >> 7) | (t * 3 & t >> 10)); break; // Heavy Saw
                    case 3: b = (byte)((t * (t >> 5 | t >> 8) ^ (t >> 3)) * (t >> 10 & 15)); break; // Insane Metallic Noise
                    case 4: b = (byte)((t * ((t >> 9 | t >> 13) & 15)) & 0xFF); break; // Rhythm Glitch
                    case 5: b = (byte)((t >> 6 | t | t >> (t >> 16)) * 10 + ((t >> 11) & 7)); break; // Industrial Bass
                    case 6: b = (byte)(t * (t ^ (t >> 8 | t >> 12)) >> 4); break; // High Speed Arpeggio
                    case 7: b = (byte)((t * (t >> 4 | t >> 8) & (t >> 12)) ^ 0xFF); break; // Chaos Breakdown
                }
                buffer[i] = b;
                t++;
            }
            waveOutPrepareHeader(hWaveOut, ref header, (uint)Marshal.SizeOf(header));
            waveOutWrite(hWaveOut, ref header, (uint)Marshal.SizeOf(header));
            Thread.Sleep(950);
        }
    }

    // 3D Flying Cube Setup (Payload 3)
    static float angleX = 0, angleY = 0, angleZ = 0;
    static float cubeX = 0, cubeY = 0, vx = 12, vy = 8;
    static float[,] vertices = { {-1,-1,-1}, {1,-1,-1}, {1,1,-1}, {-1,1,-1}, {-1,-1,1}, {1,-1,1}, {1,1,1}, {-1,1,1} };
    static int[,] edges = { {0,1},{1,2},{2,3},{3,0},{4,5},{5,6},{6,7},{7,4},{0,4},{1,5},{2,6},{3,7} };

    public static void DrawCube(IntPtr hdc, int w, int h, Random r) {
        cubeX += vx; cubeY += vy;
        if (cubeX < 100 || cubeX > w - 100) vx = -vx;
        if (cubeY < 100 || cubeY > h - 100) vy = -vy;

        angleX += 0.08f; angleY += 0.06f; angleZ += 0.04f;
        float size = 110.0f;
        int[,] projected = new int[8, 2];

        for (int i = 0; i < 8; i++) {
            float x = vertices[i, 0], y = vertices[i, 1], z = vertices[i, 2];
            float y1 = y * (float)Math.Cos(angleX) - z * (float)Math.Sin(angleX);
            float z1 = y * (float)Math.Sin(angleX) + z * (float)Math.Cos(angleX);
            float x2 = x * (float)Math.Cos(angleY) + z1 * (float)Math.Sin(angleY);
            float z2 = -x * (float)Math.Sin(angleY) + z1 * (float)Math.Cos(angleY);
            float x3 = x2 * (float)Math.Cos(angleZ) - y1 * (float)Math.Sin(angleZ);
            float y3 = x2 * (float)Math.Sin(angleZ) + y1 * (float)Math.Cos(angleZ);
            projected[i, 0] = (int)(cubeX + x3 * size);
            projected[i, 1] = (int)(cubeY + y3 * size);
        }

        uint color = (uint)(r.Next(0, 256) | (r.Next(0, 256) << 8) | (r.Next(0, 256) << 16));
        IntPtr pen = CreatePen(0, 4, color);
        IntPtr oldPen = SelectObject(hdc, pen);

        for (int i = 0; i < 12; i++) {
            MoveToEx(hdc, projected[edges[i, 0], 0], projected[edges[i, 0], 1], IntPtr.Zero);
            LineTo(hdc, projected[edges[i, 1], 0], projected[edges[i, 1], 1]);
        }

        SelectObject(hdc, oldPen);
        DeleteObject(pen);
    }

    public static void Run() {
        int w = GetSystemMetrics(0);
        int h = GetSystemMetrics(1);
        Random r = new Random();
        cubeX = w / 2; cubeY = h / 2;

        Thread aThread = new Thread(AudioThread);
        aThread.IsBackground = true;
        aThread.Start();

        DateTime start = DateTime.Now;

        while (isRunning) {
            if ((GetAsyncKeyState(0x1B) & 0x8000) != 0) break; // ESC to stop manually

            IntPtr hdc = GetDC(IntPtr.Zero);
            int elapsed = (int)(DateTime.Now - start).TotalSeconds;

            // Auto-exit after 140 seconds (2 mins 20 secs)
            if (elapsed >= 140) {
                isRunning = false;
                break;
            }

            // Payloads switch every 20 seconds (7 total)
            currentPayload = (elapsed / 20) + 1;

            switch (currentPayload) {
                // 1. Shaking Screen Distortion
                case 1:
                    BitBlt(hdc, r.Next(-15, 16), r.Next(-15, 16), w, h, hdc, 0, 0, NOTSRCOPY);
                    StretchBlt(hdc, 15, 15, w - 30, h - 30, hdc, 0, 0, w, h, SRCINVERT);
                    break;

                // 2. Sine Wave Screen Melt
                case 2:
                    for (int y = 0; y < h; y += 12) {
                        int shift = (int)(Math.Sin(y * 0.05 + elapsed) * 30.0);
                        BitBlt(hdc, shift, y, w, 12, hdc, 0, y, SRCINVERT);
                    }
                    break;

                // 3. INSANE MELT + FLYING 3D CUBE
                case 3:
                    int rx = r.Next(0, w);
                    BitBlt(hdc, rx, r.Next(10, 30), r.Next(20, 80), h, hdc, rx, 0, SRCCOPY);
                    StretchBlt(hdc, 0, 0, w, h, hdc, r.Next(-8, 9), r.Next(-8, 9), w, h, SRCINVERT);
                    DrawCube(hdc, w, h, r);
                    break;

                // 4. Cursor Glitch & Icon Shower
                case 4:
                    DrawIcon(hdc, r.Next(0, w), r.Next(0, h), LoadIcon(IntPtr.Zero, 32513));
                    SetCursorPos(r.Next(0, w), r.Next(0, h));
                    break;

                // 5. Inverted Tunnel Zoom
                case 5:
                    StretchBlt(hdc, 25, 25, w - 50, h - 50, hdc, 0, 0, w, h, SRCPAINT);
                    break;

                // 6. Vertical Melting Cascade
                case 6:
                    for (int x = 0; x < w; x += 20) {
                        BitBlt(hdc, x, r.Next(5, 25), 20, h, hdc, x, 0, SRCCOPY);
                    }
                    break;

                // 7. Final Void Collapse (Exits after 20 secs)
                case 7:
                    StretchBlt(hdc, 40, 40, w - 80, h - 80, hdc, 0, 0, w, h, NOTSRCOPY);
                    DrawIcon(hdc, r.Next(0, w), r.Next(0, h), LoadIcon(IntPtr.Zero, 32513));
                    break;
            }

            ReleaseDC(IntPtr.Zero, hdc);
            Thread.Sleep(15);
        }

        InvalidateRect(IntPtr.Zero, IntPtr.Zero, true);
    }
}
"@

try {
    Add-Type -TypeDefinition $code -Language CSharp
    [GDICore]::Run()
} catch {
    Write-Host "Execution Error:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}