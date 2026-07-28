$code = @"
using System;
using System.Runtime.InteropServices;
using System.Threading;

public class INSANEGDI {
    // WinAPI GDI Functions
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

    // WinAPI Sound Engine (WaveOut for Bytebeat)
    [StructLayout(LayoutKind.Sequential)]
    public struct WAVEFORMATEX {
        public ushort wFormatTag;
        public ushort nChannels;
        public uint nSamplesPerSec;
        public uint nAvgBytesPerSec;
        public ushort nBlockAlign;
        public ushort wBitsPerSample;
        public ushort cbSize;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct WAVEHDR {
        public IntPtr lpData;
        public uint dwBufferLength;
        public uint dwBytesRecorded;
        public IntPtr dwUser;
        public uint dwFlags;
        public uint dwLoops;
        public IntPtr lpNext;
        public IntPtr reserved;
    }

    [DllImport("winmm.dll")] public static extern int waveOutOpen(out IntPtr hWaveOut, uint uDeviceID, ref WAVEFORMATEX lpFormat, IntPtr dwCallback, IntPtr dwInstance, uint fdwOpen);
    [DllImport("winmm.dll")] public static extern int waveOutPrepareHeader(IntPtr hWaveOut, ref WAVEHDR lpWaveOutHdr, uint uSize);
    [DllImport("winmm.dll")] public static extern int waveOutWrite(IntPtr hWaveOut, ref WAVEHDR lpWaveOutHdr, uint uSize);

    // Raster Operations
    const uint SRCCOPY = 0x00CC0220;
    const uint SRCINVERT = 0x00660046;
    const uint NOTSRCOPY = 0x00330008;
    const uint SRCPAINT = 0x00EE0086;

    // BYTEBEAT AUDIO THREAD
    public static void BytebeatAudioLoop() {
        IntPtr hWaveOut;
        WAVEFORMATEX wfx = new WAVEFORMATEX();
        wfx.wFormatTag = 1; // PCM
        wfx.nChannels = 1;
        wfx.nSamplesPerSec = 8000;
        wfx.nAvgBytesPerSec = 8000;
        wfx.nBlockAlign = 1;
        wfx.wBitsPerSample = 8;
        wfx.cbSize = 0;

        if (waveOutOpen(out hWaveOut, 0xFFFFFFFF, ref wfx, IntPtr.Zero, IntPtr.Zero, 0) != 0) return;

        int bufferSize = 8000;
        byte[] buffer = new byte[bufferSize];
        GCHandle handle = GCHandle.Alloc(buffer, GCHandleType.Pinned);

        WAVEHDR header = new WAVEHDR();
        header.lpData = handle.AddrOfPinnedObject();
        header.dwBufferLength = (uint)bufferSize;

        uint t = 0;
        while (true) {
            // Formula: Hardcore Bytebeat Chiptune
            for (int i = 0; i < bufferSize; i++) {
                byte layer1 = (byte)((t * (t >> 8 | t >> 12)) ^ (t >> 4));
                byte layer2 = (byte)((t * (t >> 7 | t >> 11) | t >> 2) & 0xFF);
                buffer[i] = (byte)(layer1 ^ layer2);
                t++;
            }

            waveOutPrepareHeader(hWaveOut, ref header, (uint)Marshal.SizeOf(header));
            waveOutWrite(hWaveOut, ref header, (uint)Marshal.SizeOf(header));
            Thread.Sleep(950);
        }
    }

    public static void Main() {
        int w = GetSystemMetrics(0);
        int h = GetSystemMetrics(1);
        Random r = new Random();

        // Запуск звукового потока Bytebeat
        Thread audioThread = new Thread(BytebeatAudioLoop);
        audioThread.IsBackground = true;
        audioThread.Start();

        DateTime startTime = DateTime.Now;

        // Главный цикл визуальных эффектов
        while (true) {
            // Для остановки удерживайте клавишу ESC 1 секунду
            if ((GetAsyncKeyState(0x1B) & 0x8000) != 0) break;

            IntPtr hdc = GetDC(IntPtr.Zero);
            
            // ПЕРЕКЛЮЧЕНИЕ РОВНО КАЖДЫЕ 10 СЕКУНД (1 - 5)
            int elapsed = (int)(DateTime.Now - startTime).TotalSeconds;
            int payload = (elapsed / 10) % 5 + 1;

            switch (payload) {
                // PAYLOAD 1 (0-10 сек): Встряска и сжатие экрана
                case 1:
                    int dx = r.Next(-15, 16);
                    int dy = r.Next(-15, 16);
                    BitBlt(hdc, dx, dy, w, h, hdc, 0, 0, NOTSRCOPY);
                    StretchBlt(hdc, 20, 20, w - 40, h - 40, hdc, 0, 0, w, h, SRCINVERT);
                    break;

                // PAYLOAD 2 (10-20 сек): Синусоидальные разрывы линий
                case 2:
                    for (int y = 0; y < h; y += 14) {
                        int shift = (int)(Math.Sin(y * 0.05 + elapsed) * 35.0);
                        BitBlt(hdc, shift, y, w, 14, hdc, 0, y, SRCINVERT);
                    }
                    break;

                // PAYLOAD 3 (20-30 сек): Эффект стекающего / тающего экрана
                case 3:
                    int rx = r.Next(0, w);
                    int sliceWidth = r.Next(20, 100);
                    int dropSpeed = r.Next(15, 35);
                    BitBlt(hdc, rx, dropSpeed, sliceWidth, h - dropSpeed, hdc, rx, 0, SRCCOPY);
                    StretchBlt(hdc, 0, 0, w, h, hdc, r.Next(-8, 9), r.Next(-8, 9), w, h, SRCPAINT);
                    break;

                // PAYLOAD 4 (30-40 сек): Спам иконками ошибок + Телепорт мыши
                case 4:
                    IntPtr hIcon = LoadIcon(IntPtr.Zero, 32513); // IDI_ERROR
                    DrawIcon(hdc, r.Next(0, w), r.Next(0, h), hIcon);
                    SetCursorPos(r.Next(0, w), r.Next(0, h));
                    break;

                // PAYLOAD 5 (40-50 сек): Зеркальный инвертированный стробоскоп
                case 5:
                    BitBlt(hdc, 0, 0, w, h, hdc, 0, 0, NOTSRCOPY);
                    StretchBlt(hdc, w, 0, -w, h, hdc, 0, 0, w, h, SRCINVERT);
                    break;
            }

            ReleaseDC(IntPtr.Zero, hdc);
            Thread.Sleep(15);
        }

        // Очистка экрана при завершении
        InvalidateRect(IntPtr.Zero, IntPtr.Zero, true);
    }
}
"@

Add-Type -TypeDefinition $code -Language CSharp
[INSANEGDI]::Main()