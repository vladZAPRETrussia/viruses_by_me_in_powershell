Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$msg1 = "u need hack pc?"
$title1 = "hackhackhackhackhack"
$result1 = [System.Windows.Forms.MessageBox]::Show($msg1, $title1, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)

if ($result1 -ne [System.Windows.Forms.DialogResult]::Yes) {
    Exit
}

$msg2 = "U ACCEPT OR NO???"
$title2 = "hackhackhackhack"
$result2 = [System.Windows.Forms.MessageBox]::Show($msg2, $title2, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Stop)

if ($result2 -ne [System.Windows.Forms.DialogResult]::Yes) {
    Exit
}

$code = @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Threading;
using System.Diagnostics;
using System.Windows.Forms;

namespace InsaneSimulationWithBSOD {
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
        [DllImport("gdi32.dll")] public static extern bool PatBlt(IntPtr hdc, int nXLeft, int nYLeft, int nWidth, int nHeight, uint dwRop);

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
        [DllImport("winmm.dll")] public static extern int waveOutClose(IntPtr hWaveOut);

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
            waveOutClose(hWaveOut);
            handle.Free();
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
                if ((GetAsyncKeyState(0x1B) & 0x8000) != 0) { isRunning = false; break; }

                IntPtr hdc = GetDC(IntPtr.Zero);
                int elapsed = (int)(DateTime.Now - start).TotalSeconds;

                if (elapsed >= 210) {
                    isRunning = false;
                    break;
                }

                currentPayload = (elapsed / 30) + 1;
                SetCursorPos(r.Next(0, w), r.Next(0, h));

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
                        BitBlt(hdc, r.Next(-200, 200), r.Next(-200, 200), w, h, hdc, 0, 0, SRCCOPY);
                        break;
                    case 7:
                        BitBlt(hdc, 0, 0, w, h, hdc, 0, 0, NOTSRCOPY);
                        StretchBlt(hdc, -100, -100, w + 200, h + 200, hdc, 0, 0, w, h, SRCINVERT);
                        PatBlt(hdc, 0, 0, w, h, DSTINVERT);
                        break;
                }

                ReleaseDC(IntPtr.Zero, hdc);
                Thread.Sleep(1);
            }

            Application.Run(new BSODForm());
        }
    }

    public class BSODForm : Form {
        private TextBox txtCode;
        private Button btnSubmit;
        private Label lblMessage;

        public BSODForm() {
            this.Text = "BSOD Simulation";
            this.WindowState = FormWindowState.Maximized;
            this.FormBorderStyle = FormBorderStyle.None;
            this.BackColor = Color.FromArgb(0, 120, 215);
            this.TopMost = true;

            Label lblEmoji = new Label();
            lblEmoji.Text = ":(";
            lblEmoji.ForeColor = Color.White;
            lblEmoji.Font = new Font("Segoe UI", 64, FontStyle.Bold);
            lblEmoji.Location = new Point(40, 40);
            lblEmoji.AutoSize = true;

            lblMessage = new Label();
            lblMessage.Text = "YOU PC HACKED\nRECOVERY? IMPOSSIBLE\nGUESS CODE: 8347";
            lblMessage.ForeColor = Color.White;
            lblMessage.Font = new Font("Consolas", 24, FontStyle.Bold);
            lblMessage.AutoSize = true;
            lblMessage.Location = new Point(40, 160);

            txtCode = new TextBox();
            txtCode.Font = new Font("Consolas", 20);
            txtCode.Width = 300;
            txtCode.Location = new Point(40, 360);

            btnSubmit = new Button();
            btnSubmit.Text = "UNLOCK";
            btnSubmit.Font = new Font("Consolas", 16, FontStyle.Bold);
            btnSubmit.Width = 150;
            btnSubmit.Height = 50;
            btnSubmit.Location = new Point(360, 355);
            btnSubmit.Click += BtnSubmit_Click;

            this.Controls.Add(lblEmoji);
            this.Controls.Add(lblMessage);
            this.Controls.Add(txtCode);
            this.Controls.Add(btnSubmit);
        }

        private void BtnSubmit_Click(object sender, EventArgs e) {
            if (txtCode.Text.Trim() == "8347") {
                MessageBox.Show("Correct Code! Unlocking system.", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                Application.Exit();
            } else {
                MessageBox.Show("Wrong Code!", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                txtCode.Clear();
            }
        }

        protected override void OnFormClosing(FormClosingEventArgs e) {
            if (e.CloseReason == CloseReason.UserClosing) {
                e.Cancel = true;
            }
        }
    }
}
"@

Add-Type -TypeDefinition $code -Language CSharp -ReferencedAssemblies "System.Windows.Forms", "System.Drawing"
[InsaneSimulationWithBSOD.PayloadRunner]::Run()