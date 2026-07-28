$uniqueId = Get-Random -Minimum 10000 -Maximum 99999
$code = @"
using System;
using System.Runtime.InteropServices;
using System.Threading;

public class GDICore_$uniqueId {
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
    const uint PATINVERT = 0x005A0049;

    public static int currentPayload = 1;
    public static bool isRunning = true;

    // 5 INSANE BYTEBEATS
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
                    case 1: b = (byte)((t * (t >> 5 | t >> 8) ^ (t >> 3)) * (t >> 10 & 15)); break; // Insane Metallic Screamer
                    case 2: b = (byte)((t >> 6 | t | t >> (t >> 16)) * 10 + ((t >> 11) & 7)); break; // Heavy Industrial Sub-Bass
                    case 3: b = (byte)((t * (t >> 4 | t >> 8) & (t >> 12)) ^ 0xFF); break;         // Chaotic Glitch Machine
                    case 4: b = (byte)((t * 9 & t >> 4) | (t * 5 & t >> 7) | (t * 3 & t >> 10)); break; // Fast Saw Massacre
                    case 5: b = (byte)(t * (t ^ (t >> 8 | t >> 12)) >> 4); break;                   // Ultra Speed Noise Arp
                }
                buffer[i] = b;
                t++;
            }
            waveOutPrepareHeader(hWaveOut, ref header, (uint)Marshal.SizeOf(header));
            waveOutWrite(hWaveOut, ref header, (uint)Marshal.SizeOf(header));
            Thread.Sleep(950);
        }
    }

    // 3D Flying Cube Setup (For Payload 2)
    static float angleX = 0, angleY = 0, angleZ = 0;
    static float cubeX = 0, cubeY = 0, vx = 18, vy = 12;
    static float[,] vertices = { {-1,-1,-1}, {1,-1,-1}, {1,1,-1}, {-1,1,-1}, {-1,-1,1}, {1,-1,1}, {1,1,1}, {-1,1,1} };
    static int[,] edges = { {0,1},{1,2},{2,3},{3,0},{4,5},{5,6},{6,7},{7,4},{0,4},{1,5},{2,6},{3,7} };

    public static void DrawCube(IntPtr hdc, int w, int h, Random r) {
        cubeX += vx; cubeY += vy;
        if (cubeX < 120 || cubeX > w - 120) vx = -vx;
        if (cubeY < 120 || cubeY > h - 120) vy = -vy;

        angleX += 0.12f; angleY += 0.09f; angleZ += 0.06f;
        float size = 130.0f;
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
        IntPtr pen = CreatePen(0, 5, color);
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
            if ((GetAsyncKeyState(0x1B) & 0x8000) != 0) break; // ESC — моментальная остановка

            IntPtr hdc = GetDC(IntPtr.Zero);
            int elapsed = (int)(DateTime.Now - start).TotalSeconds;

            // Завершение через 50 секунд (5 пэйлоадов по 10 секунд)
            if (elapsed >= 50) {
                isRunning = false;
                break;
            }

            // Переключение ровно каждые 10 секунд
            currentPayload = (elapsed / 10) + 1;

            switch (currentPayload) {
                // INSANE 1: Aggressive Invert Tunnel + Random Stretch Distortion
                case 1:
                    StretchBlt(hdc, 20, 20, w - 40, h - 40, hdc, 0, 0, w, h, SRCINVERT);
                    BitBlt(hdc, r.Next(-25, 26), r.Next(-25, 26), w, h, hdc, 0, 0, NOTSRCOPY);
                    break;

                // INSANE 2: Flying 3D Cube + Screen Melting Glitch
                case 2:
                    int rx = r.Next(0, w);
                    BitBlt(hdc, rx, r.Next(10, 40), r.Next(30, 100), h, hdc, rx, 0, SRCCOPY);
                    StretchBlt(hdc, 0, 0, w, h, hdc, r.Next(-10, 11), r.Next(-10, 11), w, h, SRCINVERT);
                    DrawCube(hdc, w, h, r);
                    break;

                // INSANE 3: Sine Wave Distort + Rapid Cursor Jitter + Icon Rain
                case 3:
                    for (int y = 0; y < h; y += 10) {
                        int shift = (int)(Math.Sin(y * 0.08 + elapsed) * 45.0);
                        BitBlt(hdc, shift, y, w, 10, hdc, 0, y, SRCINVERT);
                    }
                    DrawIcon(hdc, r.Next(0, w), r.Next(0, h), LoadIcon(IntPtr.Zero, 32513)); // Error
                    DrawIcon(hdc, r.Next(0, w), r.Next(0, h), LoadIcon(IntPtr.Zero, 32515)); // Warning
                    SetCursorPos(r.Next(0, w), r.Next(0, h));
                    break;

                // INSANE 4: Vertical Pixel Melt + Inverted Tunnel Zoom
                case 4:
                    for (int x = 0; x < w; x += 15) {
                        BitBlt(hdc, x, r.Next(8, 30), 15, h, hdc, x, 0, SRCCOPY);
                    }
                    StretchBlt(hdc, 30, 30, w - 60, h - 60, hdc, 0, 0, w, h, SRCPAINT);
                    break;

                // INSANE 5: Total Screen Collapse & Color Inversion Spiral
                case 5:
                    StretchBlt(hdc, 50, 50, w - 100, h - 100, hdc, 0, 0, w, h, NOTSRCOPY);
                    BitBlt(hdc, r.Next(-30, 31), r.Next(-30, 31), w, h, hdc, 0, 0, PATINVERT);
                    DrawIcon(hdc, r.Next(0, w), r.Next(0, h), LoadIcon(IntPtr.Zero, 32513));
                    break;
            }

            ReleaseDC(IntPtr.Zero, hdc);
            Thread.Sleep(10);
        }

        // Автоматическая очистка рабочего стола
        InvalidateRect(IntPtr.Zero, IntPtr.Zero, true);
    }
}
"@

try {
    $type = Add-Type -TypeDefinition $code -Language CSharp -PassThru
    $type[0]::GetMethod("Run").Invoke($null, $null)
} catch {
    Write-Host "Execution Error:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}