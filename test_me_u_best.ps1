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
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
using System.Threading;
using System.Diagnostics;
using System.Windows.Forms;

namespace SuperUltimatePayloads {
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
        [DllImport("gdi32.dll")] public static extern bool PatBlt(IntPtr hdc, int nXLeft, int nYLeft, int nWidth, int nHeight, uint dwRop);
        [DllImport("gdi32.dll")] public static extern bool Ellipse(IntPtr hdc, int nLeftRect, int nTopRect, int nRightRect, int nBottomRect);
        [DllImport("gdi32.dll")] public static extern bool Rectangle(IntPtr hdc, int nLeftRect, int nTopRect, int nRightRect, int nBottomRect);
        [DllImport("user32.dll")] public static extern bool DrawText(IntPtr hDC, string lpString, int nCount, ref RECT lpRect, uint uFormat);
        [DllImport("gdi32.dll")] public static extern bool DeleteObject(IntPtr hObject);

        [StructLayout(LayoutKind.Sequential)]
        public struct RECT {
            public int Left, Top, Right, Bottom;
        }

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
        const uint SRCINVERT = 0x00660046;
        const uint SRCPAINT  = 0x00EE0086;
        const uint PATINVERT = 0x005A0049;
        const uint NOTSRCOPY = 0x00330008;

        public static volatile int currentPayload = 1;
        public static volatile bool isRunning = true;
        public static int globalAudioTimer = 0;

        public static void AudioThread() {
            IntPtr hWaveOut;
            WAVEFORMATEX wfx = new WAVEFORMATEX();
            wfx.wFormatTag = 1; wfx.nChannels = 1; wfx.nSamplesPerSec = 8000;
            wfx.nAvgBytesPerSec = 8000; wfx.nBlockAlign = 1; wfx.wBitsPerSample = 8; wfx.cbSize = 0;

            if (waveOutOpen(out hWaveOut, 0xFFFFFFFF, ref wfx, IntPtr.Zero, IntPtr.Zero, 0) != 0) return;

            int bufferSize = 8192;
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
                        case 1: b = (byte)((t * (t >> 8 | t >> 9)) & 128); break;
                        case 2: b = (byte)((t * (t >> 5 | t >> 8) ^ (t >> 3))); break;
                        case 3: b = (byte)(((t * 3 & t >> 4) | (t * 5 & t >> 7))); break;
                        case 4: b = (byte)((t >> 3) * (t >> 4) ^ (t >> 6)); break;
                        case 5: b = (byte)((t * (t >> 8 & 15) ^ (t >> 3)) + t); break;
                        case 6: b = (byte)((t * 7 & t >> 3) ^ (t * 3 & t >> 4)); break;
                        case 7: b = (byte)((t * (t >> 11 | t >> 5) & 63) * (t >> 3)); break;
                    }
                    buffer[i] = b;
                }
                
                waveOutWrite(hWaveOut, ref header, (uint)Marshal.SizeOf(header));
                Thread.Sleep(200);
            }
            
            waveOutClose(hWaveOut);
            handle.Free();
        }

        public static void DrawSierpinski(IntPtr hdc, int x, int y, int size, int depth) {
            if (depth <= 0 || size < 4) {
                IntPtr brush = CreateSolidBrush(0x00FF8800);
                SelectObject(hdc, brush);
                Rectangle(hdc, x, y, x + size, y + size);
                DeleteObject(brush);
                return;
            }
            int newSize = size / 3;
            for (int i = 0; i < 3; i++) {
                for (int j = 0; j < 3; j++) {
                    if (i == 1 && j == 1) continue;
                    DrawSierpinski(hdc, x + i * newSize, y + j * newSize, newSize, depth - 1);
                }
            }
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

                switch (currentPayload) {
                    case 1:
                        using (Graphics g = Graphics.FromHdc(hdc)) {
                            g.TranslateTransform(w / 2f, h / 2f);
                            g.RotateTransform(elapsed * 15f);
                            g.TranslateTransform(-w / 2f, -h / 2f);
                            using (Bitmap bmp = new Bitmap(w, h)) {
                                using (Graphics bmpG = Graphics.FromImage(bmp)) {
                                    IntPtr bmpHdc = bmpG.GetHdc();
                                    BitBlt(bmpHdc, 0, 0, w, h, hdc, 0, 0, SRCCOPY);
                                    bmpG.ReleaseHdc(bmpHdc);
                                }
                                g.DrawImage(bmp, 0, 0);
                            }
                        }
                        break;

                    case 2:
                        BitBlt(hdc, r.Next(-10, 10), r.Next(-10, 10), w, h, hdc, 0, 0, SRCINVERT);
                        break;

                    case 3:
                        uint randomColor = (uint)r.Next(0x00FFFFFF);
                        IntPtr brush = CreateSolidBrush(randomColor);
                        SelectObject(hdc, brush);
                        PatBlt(hdc, 0, 0, w, h, 0x00F00021);
                        DeleteObject(brush);
                        break;

                    case 4:
                        DrawSierpinski(hdc, 0, 0, Math.Min(w, h), 3);
                        IntPtr cBrush = CreateSolidBrush(0x0000FFFF);
                        SelectObject(hdc, cBrush);
                        int cx = (elapsed * 30) % w;
                        int cy = (int)(Math.Sin(elapsed * 4) * 200 + h / 2);
                        Ellipse(hdc, cx, cy, cx + 100, cy + 100);
                        DeleteObject(cBrush);
                        break;

                    case 5:
                        string text = "HACKED BY SYSTEM!";
                        RECT rect = new RECT { Left = r.Next(0, w - 200), Top = r.Next(0, h - 50), Right = r.Next(200, w), Bottom = r.Next(50, h) };
                        DrawText(hdc, text, text.Length, ref rect, 0x0000);
                        break;

                    case 6:
                        StretchBlt(hdc, r.Next(-30, 30), r.Next(-30, 30), w + 60, h + 60, hdc, 0, 0, w, h, SRCPAINT);
                        break;

                    case 7:
                        BitBlt(hdc, r.Next(-50, 50), r.Next(-50, 50), r.Next(200, w), r.Next(200, h), hdc, r.Next(0, w), r.Next(0, h), NOTSRCOPY);
                        break;
                }

                ReleaseDC(IntPtr.Zero, hdc);
                Thread.Sleep(30);
            }

            Application.Run(new BSODForm());
        }
    }

    public class BSODForm : Form {
        private TextBox txtCode;
        private Button btnSubmit;

        public BSODForm() {
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

            Label lblMessage = new Label();
            lblMessage.Text = "guess code or u system delete";
            lblMessage.ForeColor = Color.White;
            lblMessage.Font = new Font("Consolas", 24, FontStyle.Bold);
            lblMessage.AutoSize = true;
            lblMessage.Location = new Point(40, 160);

            txtCode = new TextBox();
            txtCode.Font = new Font("Consolas", 20);
            txtCode.Width = 300;
            txtCode.Location = new Point(40, 240);
            txtCode.UseSystemPasswordChar = true; // Скрываем вводимый текст точками

            btnSubmit = new Button();
            btnSubmit.Text = "UNLOCK";
            btnSubmit.Font = new Font("Consolas", 16, FontStyle.Bold);
            btnSubmit.Width = 150;
            btnSubmit.Height = 45;
            btnSubmit.Location = new Point(350, 237);
            btnSubmit.Click += BtnSubmit_Click;

            this.Controls.Add(lblEmoji);
            this.Controls.Add(lblMessage);
            this.Controls.Add(txtCode);
            this.Controls.Add(btnSubmit);
        }

        private void BtnSubmit_Click(object sender, EventArgs e) {
            if (txtCode.Text.Trim() == "8273") {
                MessageBox.Show("you get luck... u pc survived", "System Info", MessageBoxButtons.OK, MessageBoxIcon.Information);
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
[SuperUltimatePayloads.PayloadRunner]::Run()