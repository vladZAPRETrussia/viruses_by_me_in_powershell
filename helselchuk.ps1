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

namespace SalineWinStyleSimulation {
    public class PayloadRunner {
        [DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hwnd);
        [DllImport("user32.dll")] public static extern int ReleaseDC(IntPtr hwnd, IntPtr hdc);
        [DllImport("gdi32.dll")] public static extern bool BitBlt(IntPtr hdcDest, int nXDest, int nYDest, int nWidth, int nHeight, IntPtr hdcSrc, int nXSrc, int nYSrc, uint dwRop);
        [DllImport("gdi32.dll")] public static extern bool StretchBlt(IntPtr hdcDest, int nXDest, int nYDest, int nWidth, int nHeight, IntPtr hdcSrc, int nXSrc, int nYSrc, int nWidthSrc, int nHeightSrc, uint dwRop);
        [DllImport("user32.dll")] public static extern int GetSystemMetrics(int nIndex);
        [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
        [DllImport("user32.dll")] public static extern bool SetCursorPos(int X, int Y);
        [DllImport("gdi32.dll")] public static extern IntPtr CreateSolidBrush(uint crColor);
        [DllImport("gdi32.dll")] public static extern IntPtr SelectObject(IntPtr hdc, IntPtr hgdiobj);
        [DllImport("gdi32.dll")] public static extern bool Rectangle(IntPtr hdc, int nLeftRect, int nTopRect, int nRightRect, int nBottomRect);
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
            public IntPtr lpUser; public uint dwFlags; public uint dwLoops; public IntPtr lpNext; public IntPtr reserved;
        }

        [DllImport("winmm.dll")] public static extern int waveOutOpen(out IntPtr hWaveOut, uint uDeviceID, ref WAVEFORMATEX lpFormat, IntPtr dwCallback, IntPtr dwInstance, uint fdwOpen);
        [DllImport("winmm.dll")] public static extern int waveOutPrepareHeader(IntPtr hWaveOut, ref WAVEHDR lpWaveOutHdr, uint uSize);
        [DllImport("winmm.dll")] public static extern int waveOutWrite(IntPtr hWaveOut, ref WAVEHDR lpWaveOutHdr, uint uSize);
        [DllImport("winmm.dll")] public static extern int waveOutClose(IntPtr hWaveOut);

        const uint SRCCOPY   = 0x00CC0220;
        const uint SRCPAINT  = 0x00EE0086;
        const uint SRCINVERT = 0x00660046;
        const uint NOTSRCOPY = 0x00330008;
        const uint PATINVERT = 0x005A0049;

        public static volatile int currentPayload = 1;
        public static volatile bool isRunning = true;
        public static int globalAudioTimer = 0;

        public static void AudioThread() {
            IntPtr hWaveOut;
            WAVEFORMATEX wfx = new WAVEFORMATEX();
            wfx.wFormatTag = 1; wfx.nChannels = 1; wfx.nSamplesPerSec = 11025;
            wfx.nAvgBytesPerSec = 11025; wfx.nBlockAlign = 1; wfx.wBitsPerSample = 8; wfx.cbSize = 0;

            if (waveOutOpen(out hWaveOut, 0xFFFFFFFF, ref wfx, IntPtr.Zero, IntPtr.Zero, 0) != 0) return;

            int bufferSize = 4096;
            byte[] buffer = new byte[bufferSize];
            GCHandle handle = GCHandle.Alloc(buffer, GCHandleType.Pinned);

            WAVEHDR header = new WAVEHDR();
            header.lpData = handle.AddrOfPinnedObject();
            header.dwBufferLength = (uint)bufferSize;

            waveOutPrepareHeader(hWaveOut, ref header, (uint)Marshal.SizeOf(header));

            while (isRunning) {
                for (int i = 0; i < bufferSize; i++) {
                    byte b = 0;
                    int t = Interlocked.Increment(ref globalAudioTimer);

                    switch (currentPayload) {
                        case 1: // SalineWin style rhythmic pulse
                            b = (byte)((t * 5 & t >> 7) | (t * 3 & t >> 10)); break;
                        case 2: // Fast glitchy arpeggio
                            b = (byte)((t * (t >> 9 | t >> 4)) ^ (t >> 3)); break;
                        case 3: // Deep ambient drone with bits
                            b = (byte)(((t >> 2) * (t >> 7 | t >> 5)) & 127); break;
                        case 4: // Robotic sawtooth sequence
                            b = (byte)((t * (t >> 3 & 15)) ^ (t >> 5)); break;
                        case 5: // Chaotic noise modulation
                            b = (byte)((t * 7 & t >> 4) + (t * 3 & t >> 8) ^ (t >> 2)); break;
                        case 6: // High frequency sine-like pulse
                            b = (byte)(((t * (t >> 6 | t >> 11)) & 63) * 3); break;
                        case 7: // Final destructive beep stream
                            b = (byte)((t >> 4) * (t >> 8) ^ (t * 13)); break;
                    }
                    buffer[i] = b;
                }
                
                waveOutWrite(hWaveOut, ref header, (uint)Marshal.SizeOf(header));
                Thread.Sleep(30);
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
            aThread.Priority = ThreadPriority.Highest;
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
                    case 1: // Effect 1: Screen Melting / Shifting lines (SalineWin Classic)
                        BitBlt(hdc, r.Next(-20, 20), r.Next(2, 10), w, h - 10, hdc, 0, 0, SRCCOPY);
                        break;
                    case 2: // Effect 2: Color Inversion Tunnel / Blocks
                        BitBlt(hdc, r.Next(0, w), r.Next(0, h), r.Next(100, 300), r.Next(100, 300), hdc, r.Next(0, w), r.Next(0, h), SRCINVERT);
                        break;
                    case 3: // Effect 3: Screen Zoom / Stretch Pulsation
                        StretchBlt(hdc, -20, -20, w + 40, h + 40, hdc, 0, 0, w, h, SRCPAINT);
                        break;
                    case 4: // Effect 4: Chaotic Grayscale/Pattern Inversion Blocks
                        PatBlt(hdc, r.Next(0, w), r.Next(0, h), r.Next(50, 200), r.Next(50, 200), PATINVERT);
                        break;
                    case 5: // Effect 5: Diagonal Shaking and Copying
                        BitBlt(hdc, r.Next(-30, 30), r.Next(-30, 30), w, h, hdc, 0, 0, NOTSRCOPY);
                        break;
                    case 6: // Effect 6: Random Colored Rectangles Overload
                        IntPtr brush = CreateSolidBrush((uint)r.Next(0x00FFFFFF));
                        SelectObject(hdc, brush);
                        Rectangle(hdc, r.Next(0, w), r.Next(0, h), r.Next(0, w), r.Next(0, h));
                        DeleteObject(brush);
                        break;
                    case 7: // Effect 7: Total Screen Collapse / Severe Glitch
                        StretchBlt(hdc, r.Next(-50, 50), r.Next(-50, 50), w + r.Next(-100, 100), h + r.Next(-100, 100), hdc, 0, 0, w, h, SRCINVERT);
                        BitBlt(hdc, 0, 0, w, h, hdc, 0, 0, NOTSRCOPY);
                        break;
                }

                ReleaseDC(IntPtr.Zero, hdc);
                Thread.Sleep(20);
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
[SalineWinStyleSimulation.PayloadRunner]::Run()