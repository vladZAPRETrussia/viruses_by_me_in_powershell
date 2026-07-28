Set-ExecutionPolicy Bypass -Scope Process -Force

$code = @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Threading;

namespace InsaneGDI {
    public class PayloadRunner {
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
        [DllImport("gdi32.dll")] public static extern IntPtr CreateSolidBrush(uint crColor);
        [DllImport("gdi32.dll")] public static extern IntPtr SelectObject(IntPtr hdc, IntPtr hgdiobj);
        [DllImport("gdi32.dll")] public static extern bool DeleteObject(IntPtr hObject);
        [DllImport("gdi32.dll")] public static extern bool PlgBlt(IntPtr hdcDest, POINT[] lpPoint, IntPtr hdcSrc, int nXSrc, int nYSrc, int nWidth, int nHeight, IntPtr hbmMask, int xMask, int yMask);
        [DllImport("gdi32.dll")] public static extern bool PatBlt(IntPtr hdc, int nXLeft, int nYLeft, int nWidth, int nHeight, uint dwRop);

        [StructLayout(LayoutKind.Sequential)]
        public struct POINT { 
            public int x; public int y; 
            public POINT(int x, int y) { this.x = x; this.y = y; } 
        }

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

        const uint SRCINVERT = 0x00660046;
        const uint SRCCOPY = 0x00CC0220;
        const uint SRCPAINT = 0x00EE0086;
        const uint PATINVERT = 0x005A0049;
        const uint DSTINVERT = 0x00550009;
        const uint NOTSRCOPY = 0x00330008;

        public static int currentPayload = 1;
        public static bool isRunning = true;

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

            int t = 0;
            while (isRunning) {
                for (int i = 0; i < bufferSize; i++) {
                    byte b = 0;
                    switch (currentPayload) {
                        case 1: // Aggressive Chaos Siren
                            b = (byte)((t * (t >> 8 | t >> 5) & 63) + (t * (t >> 4 & t >> 9)));
                            break;
                        case 2: // Heavy Industrial Bitcruncher
                            b = (byte)((t * 5 & t >> 7) | (t * 3 & t >> 10) | (t * 9 & t >> 4));
                            break;
                        case 3: // Fast Screaming Cyber Melody
                            b = (byte)((t * (t >> 3 | t >> 9) & (t >> 4)) ^ (t * (t >> 6 | t >> 12)));
                            break;
                        case 4: // Glitch Machine Laser
                            b = (byte)((t * ((t >> 9 | t >> 13) % 11)) ^ (t >> 2 | t >> 8));
                            break;
                        case 5: // Overclocked Hardcore Beat
                            b = (byte)(t * ((t >> 12 | t >> 8) & 63 & t >> 4));
                            break;
                    }
                    buffer[i] = b;
                    t++;
                }
                waveOutPrepareHeader(hWaveOut, ref header, (uint)Marshal.SizeOf(header));
                waveOutWrite(hWaveOut, ref header, (uint)Marshal.SizeOf(header));
                Thread.Sleep(950);
            }
        }

        public static void Run() {
            int w = GetSystemMetrics(0);
            int h = GetSystemMetrics(1);
            Random r = new Random();

            Thread aThread = new Thread(AudioThread);
            aThread.IsBackground = true;
            aThread.Start();

            DateTime start = DateTime.Now;

            while (isRunning) {
                if ((GetAsyncKeyState(0x1B) & 0x8000) != 0) break; // ESC Key to exit

                IntPtr hdc = GetDC(IntPtr.Zero);
                int elapsed = (int)(DateTime.Now - start).TotalSeconds;

                // Stop after 50 seconds (5 payloads * 10 seconds)
                if (elapsed >= 50) {
                    isRunning = false;
                    break;
                }

                currentPayload = (elapsed / 10) + 1;

                switch (currentPayload) {
                    // PAYLOAD 1: Screen Melting & Shake (10s)
                    case 1:
                        int xShift = r.Next(-40, 41);
                        int yShift = r.Next(-40, 41);
                        BitBlt(hdc, xShift, yShift, w, h, hdc, 0, 0, SRCCOPY);
                        int rx1 = r.Next(0, w - 50);
                        BitBlt(hdc, rx1, r.Next(10, 50), 60, h, hdc, rx1, 0, SRCCOPY);
                        if (r.Next(0, 3) == 0) PatBlt(hdc, 0, 0, w, h, DSTINVERT);
                        break;

                    // PAYLOAD 2: Screen Rotation & Warp (10s)
                    case 2:
                        POINT[] p = new POINT[3];
                        p[0] = new POINT(r.Next(-50, 50), r.Next(-50, 50));
                        p[1] = new POINT(w + r.Next(-50, 50), r.Next(-50, 50));
                        p[2] = new POINT(r.Next(-50, 50), h + r.Next(-50, 50));
                        PlgBlt(hdc, p, hdc, 0, 0, w, h, IntPtr.Zero, 0, 0);
                        StretchBlt(hdc, 20, 20, w - 40, h - 40, hdc, 0, 0, w, h, SRCINVERT);
                        break;

                    // PAYLOAD 3: Sin Wave Tunnel & Cursor Chaos (10s)
                    case 3:
                        for (int y = 0; y < h; y += 15) {
                            int shift = (int)(Math.Sin(y * 0.05 + elapsed * 5) * 60.0);
                            BitBlt(hdc, shift, y, w, 15, hdc, 0, y, SRCINVERT);
                        }
                        DrawIcon(hdc, r.Next(0, w), r.Next(0, h), LoadIcon(IntPtr.Zero, 32513));
                        DrawIcon(hdc, r.Next(0, w), r.Next(0, h), LoadIcon(IntPtr.Zero, 32515));
                        SetCursorPos(r.Next(0, w), r.Next(0, h));
                        break;

                    // PAYLOAD 4: RGB Strobe & Zoom (10s)
                    case 4:
                        uint color = (uint)(r.Next(0, 256) | (r.Next(0, 256) << 8) | (r.Next(0, 256) << 16));
                        IntPtr brush = CreateSolidBrush(color);
                        IntPtr oldBrush = SelectObject(hdc, brush);
                        PatBlt(hdc, 0, 0, w, h, PATINVERT);
                        SelectObject(hdc, oldBrush);
                        DeleteObject(brush);
                        StretchBlt(hdc, -30, -30, w + 60, h + 60, hdc, 0, 0, w, h, SRCPAINT);
                        break;

                    // PAYLOAD 5: Total Chaos (10s)
                    case 5:
                        StretchBlt(hdc, r.Next(-50, 50), r.Next(-50, 50), w + r.Next(-100, 100), h + r.Next(-100, 100), hdc, 0, 0, w, h, NOTSRCOPY);
                        if (r.Next(0, 2) == 0) PatBlt(hdc, 0, 0, w, h, DSTINVERT);
                        for (int i = 0; i < 5; i++) {
                            DrawIcon(hdc, r.Next(0, w), r.Next(0, h), LoadIcon(IntPtr.Zero, 32513));
                        }
                        break;
                }

                ReleaseDC(IntPtr.Zero, hdc);
                Thread.Sleep(10);
            }

            InvalidateRect(IntPtr.Zero, IntPtr.Zero, true);
        }
    }
}
"@

# Safe compilation without error output issues
Add-Type -TypeDefinition $code -Language CSharp
[InsaneGDI.PayloadRunner]::Run()