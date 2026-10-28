# Calistirma: irm https://raw.githubusercontent.com/mero123bw123/DoomsdayBulucu/refs/heads/main/HileKiran.ps1 | iex
# (param() blogu iex ile calismadigi icin kullanilmaz; -Av bayragi $args ile, iex modunda ise soru ile secilir)
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
try {
    # Turkce kulturde buyuk/kucuk harf 'I' eslesmesi bozulur (C:\WINDOWS yollari sistem DLL yerine sahte bulgu uretir); sabit kultur kullan
    $hkInv = [System.Globalization.CultureInfo]::InvariantCulture
    [System.Threading.Thread]::CurrentThread.CurrentCulture = $hkInv
    [System.Threading.Thread]::CurrentThread.CurrentUICulture = $hkInv
    [System.Globalization.CultureInfo]::DefaultThreadCurrentCulture = $hkInv
    [System.Globalization.CultureInfo]::DefaultThreadCurrentUICulture = $hkInv
} catch {}
$script:SelfUrl = 'https://raw.githubusercontent.com/mero123bw123/DoomsdayBulucu/refs/heads/main/HileKiran.ps1'
$Av = (@($args) -contains '-Av')
$hkModeSet = $Av
if (-not $hkModeSet -and $env:HK_AV -eq '1') { $Av = $true; $hkModeSet = $true }
if (-not $hkModeSet -and $env:HK_AV -eq '0') { $hkModeSet = $true }
if (-not $hkModeSet -and -not $PSCommandPath) {
    Write-Host ''
    Write-Host 'HileKiran - mod sec:' -ForegroundColor Cyan
    Write-Host '  [1] Normal tarama (iz/prefetch/kayit defteri/bellek + sonunda tum disk avi sorusu)' -ForegroundColor Gray
    Write-Host '  [2] Sadece HILE AVI (tum disk, sure siniri yok)' -ForegroundColor Gray
    $mAns = Read-Host 'Secim (1/2, bos birakirsan 1)'
    if ($mAns -match '^\s*2') { $Av = $true }
}
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $elevated = $false
    if ($PSCommandPath) {
        try {
            Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -NoExit -File "' + $PSCommandPath + '"' + $(if ($Av) { ' -Av' } else { '' }))
            $elevated = $true
        } catch {}
    } else {
        try {
            $flag = '0'
            if ($Av) { $flag = '1' }
            $ecmd = '$env:HK_AV=''' + $flag + '''; try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}; irm ''' + $script:SelfUrl + ''' | iex'
            Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -NoExit -Command "' + $ecmd + '"')
            $elevated = $true
        } catch {}
    }
    if ($elevated) { return }
    Write-Host 'HATA: Bu script YONETICI olarak calistirilmali. PowerShell i sag tik > Yonetici olarak calistir ile acip komutu tekrar yapistir.' -ForegroundColor Red
    if ($PSCommandPath) { Read-Host 'Kapatmak icin Enter a bas' | Out-Null }
    return
}
# Konsolda yanlislikla tiklayinca/secince scriptin DONMASINI onle (QuickEdit kapatilir) + islem onceligi
try {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class HkCon {
    [DllImport("kernel32.dll")] static extern IntPtr GetStdHandle(int n);
    [DllImport("kernel32.dll")] static extern bool GetConsoleMode(IntPtr h, out uint m);
    [DllImport("kernel32.dll")] static extern bool SetConsoleMode(IntPtr h, uint m);
    public static void NoQuickEdit() {
        IntPtr h = GetStdHandle(-10);
        uint m;
        if (GetConsoleMode(h, out m)) { m = (m & ~0x40u) | 0x80u; SetConsoleMode(h, m); }
    }
}
'@ -Language CSharp -ErrorAction Stop
    [HkCon]::NoQuickEdit()
} catch {}
if (-not ('HkCon' -as [type])) {
    try {
        Start-Sleep -Milliseconds 500
        Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class HkCon { [DllImport("kernel32.dll")] static extern IntPtr GetStdHandle(int n); [DllImport("kernel32.dll")] static extern bool GetConsoleMode(IntPtr h, out uint m); [DllImport("kernel32.dll")] static extern bool SetConsoleMode(IntPtr h, uint m); public static void NoQuickEdit() { IntPtr h = GetStdHandle(-10); uint m; if (GetConsoleMode(h, out m)) { m = (m & ~0x40u) | 0x80u; SetConsoleMode(h, m); } } }' -Language CSharp -ErrorAction Stop
        [HkCon]::NoQuickEdit()
    } catch {}
}
$MaximumErrorCount = 32767
$script:HkThr = [Math]::Min(8, [Math]::Max(2, [int]([Environment]::ProcessorCount - 2)))
$hkPrio = [Diagnostics.ProcessPriorityClass]::Normal
if ($env:HK_YAVAS -eq '1') { $script:HkThr = [Math]::Min(4, [Math]::Max(2, [int]([Environment]::ProcessorCount / 2))); $hkPrio = [Diagnostics.ProcessPriorityClass]::BelowNormal }
if ($env:HK_HIZLI -eq '1') { $script:HkThr = [Math]::Min(8, [Environment]::ProcessorCount); $hkPrio = [Diagnostics.ProcessPriorityClass]::AboveNormal }
try { [Diagnostics.Process]::GetCurrentProcess().PriorityClass = $hkPrio } catch {}
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
try { $Host.UI.RawUI.WindowTitle = 'HileKiran' } catch {}
Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.IO.Compression -ErrorAction SilentlyContinue

# =====================================================================
# HileKiran - bu bilgisayardaki hile izlerini arar. Hicbir dosya icerigi disari gonderilmez (mod hash sorgusu haric, bkz. asagi),
# hicbir dosya silinmez/degistirilmez. Sadece okur ve rapor yazar (process bellegi de sadece OKUNUR).
# Tek istisna: 10. adimda mod dosyalarinin SHA1 hash i Modrinth/Megabase te sorgulanir (icerik gonderilmez; kapatmak icin HK_NONET=1).
# =====================================================================

$script:Rep = New-Object System.Collections.Generic.List[string]
$MaximumErrorRecordCount = 4096
$script:HkT0 = Get-Date
$script:HkSw = [Diagnostics.Stopwatch]::StartNew()
$script:HkFnd = New-Object System.Collections.Generic.List[object]
$script:ScriptCand = New-Object System.Collections.Generic.List[object]
$script:Sys = New-Object System.Collections.Generic.List[object]
$script:UsnDel = @{}
$script:UsnRecent = New-Object System.Collections.Generic.List[object]
$script:DeletedPf = New-Object System.Collections.Generic.List[object]
$script:BinItems = New-Object System.Collections.Generic.List[object]
$script:BinEmptied = @{}
$script:BinState = New-Object System.Collections.Generic.List[string]
$script:UsbList = New-Object System.Collections.Generic.List[object]
$script:GameDirs = New-Object System.Collections.Generic.List[string]
$script:ScanRoots = New-Object System.Collections.Generic.List[string]
$script:LogCand = New-Object System.Collections.Generic.List[object]
$script:ProfileJsonCand = New-Object System.Collections.Generic.List[object]
$script:JsonCand2 = New-Object System.Collections.Generic.List[object]
$script:JavaInfo = New-Object System.Collections.Generic.List[string]
$script:fileCount = 0
$script:PfExecs = New-Object System.Collections.Generic.List[object]
$script:BamLeaves = @{}
$script:Bt = New-Object System.Collections.Generic.List[object]
$script:JarCand = New-Object System.Collections.Generic.List[object]
$script:Runs = New-Object System.Collections.Generic.List[object]
$script:ArcOther = New-Object System.Collections.Generic.List[string]
$script:BinCand = New-Object System.Collections.Generic.List[object]
$script:CfgCand = New-Object System.Collections.Generic.List[object]
$script:HkOk = $false
$Started = Get-Date
$UP = $env:USERPROFILE

function Log([string]$t, [string]$c = 'Gray', [bool]$fileOnly = $false) {
    Write-Host $t -ForegroundColor $c
    [void]$script:Rep.Add($t)
}
$script:StepTimes = New-Object System.Collections.Generic.List[object]
$script:StepName = ''
$script:StepT0 = Get-Date
$script:ErrMark = 0
# ---- Canli ilerleme: pencere basligi (gorev cubugunda da gorunur) her saniye guncellenir ----
$script:TitleOk = $false
$titleCs = @'
using System;
using System.Threading;
public static class HkTitle {
    public static int Idx = 0;
    public static int Total = 54;
    public static double Frac = 0;
    public static string Name = "";
    public static string Sub = "";
    public static bool Done = false;
    public static DateTime T0 = DateTime.Now;
    static Timer tm;
    public static void Start() {
        T0 = DateTime.Now;
        tm = new Timer(delegate(object o) { Tick(); }, null, 0, 1000);
    }
    public static void Tick() {
        try {
            if (Done) { Console.Title = "HileKiran - BITTI (%100)"; return; }
            double f = Frac; if (f < 0) f = 0; if (f > 1) f = 1;
            double p = ((Idx > 0 ? Idx - 1 : 0) + f) / Total * 100.0;
            if (p > 99) p = 99;
            TimeSpan e = DateTime.Now - T0;
            string nm = Name == null ? "" : Name;
            int b = nm.IndexOf(']');
            if (b > 0 && b < nm.Length - 1) nm = nm.Substring(b + 1).Trim();
            if (nm.Length > 45) nm = nm.Substring(0, 45);
            string sub = string.IsNullOrEmpty(Sub) ? "" : " | " + Sub;
            Console.Title = "HileKiran %" + ((int)p) + " | adim " + Idx + "/" + Total + " | " + ((int)e.TotalMinutes) + ":" + e.Seconds.ToString("00") + " gecti | " + nm + sub;
        } catch { }
    }
}
'@
try {
    Add-Type -TypeDefinition $titleCs -Language CSharp -ErrorAction Stop
    if ($Av) { [HkTitle]::Total = 5 }
    [HkTitle]::Start()
    $script:TitleOk = $true
} catch {}
# ---- Konsol ilerleme cubugu (Write-Progress): ust satirda adim ici %, altinda genel % ----
$script:BarLast = [DateTime]::MinValue
$script:BarPrinted = -10
$script:BarPrintT = [DateTime]::MinValue
function Get-BarText([int]$pct) {
    $n = [int]($pct / 5)
    if ($n -gt 20) { $n = 20 }
    return '[' + ('#' * $n) + ('-' * (20 - $n)) + '] %' + $pct
}
function Update-Bar([double]$frac, [string]$sub = '', [bool]$force = $false) {
    $ProgressPreference = 'Continue'
    if (-not $script:TitleOk) { return }
    $now = Get-Date
    if (-not $force -and ($now - $script:BarLast).TotalMilliseconds -lt 300) { return }
    $script:BarLast = $now
    if ($frac -lt 0) { $frac = 0 }
    if ($frac -gt 1) { $frac = 1 }
    $idx = [HkTitle]::Idx
    $tot = [HkTitle]::Total
    $all = [int]((([Math]::Max(0, $idx - 1)) + $frac) / $tot * 100)
    if ($all -gt 99) { $all = 99 }
    $stp = [int]($frac * 100)
    $nm = [string][HkTitle]::Name
    $b = $nm.IndexOf(']')
    if ($b -gt 0 -and $b -lt $nm.Length - 1) { $nm = $nm.Substring($b + 1).Trim() }
    if ($nm.Length -gt 60) { $nm = $nm.Substring(0, 60) }
    $st = '%' + $stp
    if ($sub) { $st = '[' + $sub + ']  %' + $stp }
    # Sabit (kaydirilinca kapatan) Write-Progress paneli kaldirildi: ilerleme satiri normal cikti gibi akar, pencere basliginda da gorunur.
    $due = ($all -ge ($script:BarPrinted + 2)) -or ($all -lt $script:BarPrinted) -or (($now - $script:BarPrintT).TotalSeconds -ge 10)
    if (-not $force -and $due) {
        $script:BarPrinted = $all
        $script:BarPrintT = $now
    }
}
function Close-Bar {
    $ProgressPreference = 'Continue'
    Write-Progress -Id 1 -Activity ' ' -Completed
    Write-Progress -Id 0 -Activity ' ' -Completed
}
function Set-Frac([double]$f, [string]$sub = '') {
    if ($script:TitleOk) { [HkTitle]::Frac = $f; if ($sub) { [HkTitle]::Sub = $sub }; Update-Bar $f $sub }
}
function Test-BenignErr($er) {
    # Dosya/yol/process/olay yok, dosya baska islemde kilitli gibi beklenen ve zararsiz hatalar
    try {
        $m = [string]$er.Exception.Message
        if ($m -match '(?i)Cannot find path .+ because it does not exist|Cannot find a process with|No events were found|does not exist at path|^File .+ was not found|Could not find (a part of the path|file)|Cannot find the path|The system cannot find|being used by another process|Access to the path .+ is denied|0x800106ba') { return $true }
        if ($m -match '(?i)ba.ka bir i.lem taraf.ndan kullan|eri.im reddedildi|Eri.im engellendi|Parametre hatal') { return $true }
    } catch {}
    return $false
}
$script:Cov = @{}
$script:CapDrop = @{}
$script:Perf = New-Object System.Collections.Generic.List[object]
$script:LapSw = [Diagnostics.Stopwatch]::StartNew()
function Add-Cov([string]$Kat, [string]$Yol = '', [string]$Neden = '') {
    # Taranmayan / atlanan / kismi taranan seyleri tani dosyasi icin kaydeder
    try {
        if (-not $script:Cov.ContainsKey($Kat)) { $script:Cov[$Kat] = [pscustomobject]@{ N = 0; Adim = [string]$script:StepName; Ornek = (New-Object System.Collections.Generic.List[string]) } }
        $c = $script:Cov[$Kat]
        $c.N = $c.N + 1
        if ($c.Ornek.Count -lt 12) { $o = $Yol; if ($Neden) { $o = $o + ' | ' + $Neden }; [void]$c.Ornek.Add($o) }
    } catch {}
}
function Test-Cap([string]$Ad, [int]$Cnt, [int]$Cap) {
    # Sinira ulasan listeler: sinirin altindaysa $true, degilse dusurulen adayi sayar ve $false doner
    if ($Cnt -lt $Cap) { return $true }
    try { $script:CapDrop[$Ad] = 1 + [int]$script:CapDrop[$Ad] } catch {}
    return $false
}
function Add-Perf([string]$Ad, [double]$Sn, [string]$Not = '') {
    try { [void]$script:Perf.Add([pscustomobject]@{ Adim = [string]$script:StepName; Ad = $Ad; Sn = [Math]::Round($Sn, 1); Not = $Not }) } catch {}
}
function Perf-Lap([string]$Ad, [string]$Not = '') {
    try { $sn = $script:LapSw.Elapsed.TotalSeconds; $script:LapSw.Restart(); Add-Perf $Ad $sn $Not } catch {}
}
function Step([string]$t) {
    $now = Get-Date
    if ($script:StepName) {
        $secPrev = [int]($now - $script:StepT0).TotalSeconds
        [void]$script:StepTimes.Add([pscustomobject]@{ Ad = $script:StepName; Sn = $secPrev })
        Log ('   [onceki adim: ' + $secPrev + ' sn]') 'DarkGray'
        $newErr = $Error.Count - $script:ErrMark
        if ($newErr -gt 0) {
            $grp = @($Error | Select-Object -First $newErr | Where-Object { -not (Test-BenignErr $_) } | Group-Object { ([string]$_.Exception.Message) } | Sort-Object Count -Descending | Select-Object -First 3)
            # (gizli hata satirlari kapatildi)
        }
    }
    $script:ErrMark = $Error.Count
    $script:StepName = $t
    $script:StepT0 = $now
    try { $script:LapSw.Restart() } catch {}
    $pct = 0
    if ($script:TitleOk) {
        [HkTitle]::Idx = [HkTitle]::Idx + 1
        [HkTitle]::Frac = 0
        [HkTitle]::Sub = ''
        [HkTitle]::Name = $t
        $pct = [int](([HkTitle]::Idx - 1) / [HkTitle]::Total * 100)
        if ($pct -gt 99) { $pct = 99 }
        Update-Bar 0 '' $true
    }
    Log '' 'Gray'
    Log ($t + '   [genel %' + $pct + ']') 'Cyan'
    $script:BarPrinted = $pct
    $script:BarPrintT = Get-Date
}
function Fmt($d) {
    if ($d) { try { return ([datetime]$d).ToString('dd.MM.yyyy HH:mm:ss') } catch { return [string]$d } }
    return '-'
}
function Hk-Ft([long]$v) {
    if ($v -le 0) { return $null }
    try {
        $d = [datetime]::FromFileTime($v)
        if ($d.Year -lt 2000) { return $null }
        return $d
    } catch { return $null }
}

# ---------------- C# yardimcilari (registry zamani, sikistirma, pencere, surucu haritasi) ----------------
$cs = @'
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
public static class HkNative {
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
    public static extern uint QueryDosDevice(string lpDeviceName, StringBuilder lpTargetPath, int ucchMax);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h, int i);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("advapi32.dll", CharSet = CharSet.Unicode)]
    public static extern int RegQueryInfoKey(Microsoft.Win32.SafeHandles.SafeRegistryHandle hKey, StringBuilder lpClass, IntPtr lpcbClass, IntPtr lpReserved, IntPtr lpcSubKeys, IntPtr lpcbMaxSubKeyLen, IntPtr lpcbMaxClassLen, IntPtr lpcValues, IntPtr lpcbMaxValueNameLen, IntPtr lpcbMaxValueLen, IntPtr lpcbSecurityDescriptor, out long lpftLastWriteTime);
    [DllImport("ntdll.dll")] public static extern uint RtlGetCompressionWorkSpaceSize(ushort fmt, out uint ws, out uint fw);
    [DllImport("ntdll.dll")] public static extern uint RtlDecompressBufferEx(ushort fmt, byte[] ub, uint ubs, byte[] cb, uint cbs, out uint fin, byte[] ws);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct FIND_STREAM_DATA { public long StreamSize; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 296)] public string StreamName; }
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern IntPtr FindFirstStreamW(string f, int lvl, out FIND_STREAM_DATA d, uint flags);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern bool FindNextStreamW(IntPtr h, out FIND_STREAM_DATA d);
    [DllImport("kernel32.dll")] static extern bool FindClose(IntPtr h);
    [DllImport("kernel32.dll", SetLastError = true)] static extern IntPtr OpenProcess(uint acc, bool inh, int pid);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool ReadProcessMemory(IntPtr h, IntPtr addr, byte[] buf, IntPtr size, out IntPtr read);
    [StructLayout(LayoutKind.Sequential)] public struct MBI { public IntPtr BaseAddress; public IntPtr AllocationBase; public uint AllocationProtect; public IntPtr RegionSize; public uint State; public uint Protect; public uint Type; }
    [DllImport("kernel32.dll")] static extern IntPtr VirtualQueryEx(IntPtr h, IntPtr a, out MBI m, IntPtr len);
    [DllImport("kernel32.dll")] static extern IntPtr GetCurrentProcess();
    [DllImport("advapi32.dll", SetLastError = true)] static extern bool OpenProcessToken(IntPtr p, uint acc, out IntPtr tok);
    [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern bool LookupPrivilegeValue(string sys, string name, out long luid);
    [StructLayout(LayoutKind.Sequential, Pack = 1)] struct TokPriv { public int Count; public long Luid; public int Attr; }
    [DllImport("advapi32.dll", SetLastError = true)] static extern bool AdjustTokenPrivileges(IntPtr tok, bool dis, ref TokPriv np, int len, IntPtr prev, IntPtr ret);

    // NTFS ADS (alternate data stream) listesi: "ad|boyut"
    public static List<string> Streams(string path) {
        List<string> res = new List<string>();
        FIND_STREAM_DATA d;
        IntPtr h = FindFirstStreamW(path, 0, out d, 0);
        if (h == new IntPtr(-1)) return res;
        do { res.Add(d.StreamName + "|" + d.StreamSize.ToString()); } while (FindNextStreamW(h, out d));
        FindClose(h);
        return res;
    }
    // Process bellegini okumak icin SeDebugPrivilege (sadece okuma)
    public static bool EnableDebug() {
        IntPtr tok;
        if (!OpenProcessToken(GetCurrentProcess(), 0x28, out tok)) return false;
        long luid;
        if (!LookupPrivilegeValue(null, "SeDebugPrivilege", out luid)) { CloseHandle(tok); return false; }
        TokPriv tp = new TokPriv();
        tp.Count = 1; tp.Luid = luid; tp.Attr = 2;
        bool ok = AdjustTokenPrivileges(tok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
        CloseHandle(tok);
        return ok;
    }
    static bool PrintA(char c) { return c >= (char)0x20 && c < (char)0x7F; }
    static bool PrintU(char c) { return (c >= (char)0x20 && c < (char)0x7F) || (c >= (char)0xC0 && c <= (char)0x17F); }
    static void Harvest(string text, bool uni, Regex r, int minLen, Dictionary<string, bool> seen, List<string> res) {
        foreach (Match m in r.Matches(text)) {
            int a = m.Index;
            int lim = m.Index - 300; if (lim < 0) lim = 0;
            while (a > lim && (uni ? PrintU(text[a - 1]) : PrintA(text[a - 1]))) a--;
            int e = m.Index + m.Length;
            int lim2 = e + 200; if (lim2 > text.Length) lim2 = text.Length;
            while (e < lim2 && (uni ? PrintU(text[e]) : PrintA(text[e]))) e++;
            if (e - a < minLen) continue;
            string s = text.Substring(a, e - a);
            if (!seen.ContainsKey(s)) { seen[s] = true; res.Add(s); if (res.Count >= 150000) return; }
        }
    }
    // Bir process'in (Private/Mapped/Image) bellegindeki ASCII + UTF-16 stringleri tarar, rx ile eslesenleri dondurur. Sadece okur.
    static Dictionary<string, Regex> RxCache = new Dictionary<string, Regex>();
    public static List<string> MemStrings(int pid, string rx, int minLen, bool mapped, bool priv, bool image, long maxBytes) {
        IntPtr h = OpenProcess(0x0410, false, pid);
        if (h == IntPtr.Zero) h = OpenProcess(0x1010, false, pid);
        if (h == IntPtr.Zero) return null;
        List<string> res = new List<string>();
        Dictionary<string, bool> seen = new Dictionary<string, bool>();
        Regex r;
        lock (RxCache) { if (!RxCache.TryGetValue(rx, out r)) { r = new Regex(rx, RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled); RxCache[rx] = r; } }
        Encoding lat = Encoding.GetEncoding(28591);
        byte[] buf = new byte[4 * 1024 * 1024];
        int mbiSize = Marshal.SizeOf(typeof(MBI));
        long addr = 0; long total = 0;
        while (total < maxBytes && res.Count < 150000) {
            MBI m;
            if (VirtualQueryEx(h, new IntPtr(addr), out m, new IntPtr(mbiSize)) == IntPtr.Zero) break;
            long size = m.RegionSize.ToInt64();
            long baseA = m.BaseAddress.ToInt64();
            if (size <= 0) break;
            bool ok = (m.State == 0x1000) && ((m.Protect & 0x101) == 0) && (m.Protect != 0);
            if (ok) {
                bool take = (m.Type == 0x20000 && priv) || (m.Type == 0x40000 && mapped) || (m.Type == 0x1000000 && image);
                if (take) {
                    long off = 0;
                    while (off < size && total < maxBytes) {
                        int cnt = (int)Math.Min((long)buf.Length, size - off);
                        IntPtr rd;
                        if (!ReadProcessMemory(h, new IntPtr(baseA + off), buf, new IntPtr(cnt), out rd)) break;
                        int n = rd.ToInt32();
                        if (n <= 0) break;
                        total += n;
                        Harvest(lat.GetString(buf, 0, n), false, r, minLen, seen, res);
                        if (n > 2) {
                            Harvest(Encoding.Unicode.GetString(buf, 0, n & ~1), true, r, minLen, seen, res);
                            Harvest(Encoding.Unicode.GetString(buf, 1, (n - 1) & ~1), true, r, minLen, seen, res);
                        }
                        if (off + n < size && n > 1024) off += n - 512; else off += n;
                    }
                }
            }
            addr = baseA + size;
            if (addr < 0) break;
        }
        CloseHandle(h);
        return res;
    }

    public static List<string> Overlays() {
        List<string> res = new List<string>();
        EnumWindows(delegate(IntPtr h, IntPtr l) {
            if (!IsWindowVisible(h)) return true;
            int ex = GetWindowLong(h, -20);
            bool layered = (ex & 0x80000) != 0;
            bool transp = (ex & 0x20) != 0;
            bool top = (ex & 0x8) != 0;
            if (layered && transp && top) {
                uint pid = 0;
                GetWindowThreadProcessId(h, out pid);
                StringBuilder sb = new StringBuilder(256);
                GetWindowText(h, sb, 256);
                RECT r;
                GetWindowRect(h, out r);
                res.Add(pid.ToString() + "|" + sb.ToString() + "|" + (r.Right - r.Left).ToString() + "x" + (r.Bottom - r.Top).ToString());
            }
            return true;
        }, IntPtr.Zero);
        return res;
    }
    public static uint LastStatus = 0;
    public static string LastErr = "";
    public static byte[] Xpress(byte[] comp, uint usize) {
        try {
            LastStatus = 0; LastErr = "";
            uint ws = 0; uint fw = 0;
            uint r0 = RtlGetCompressionWorkSpaceSize(4, out ws, out fw);
            if (r0 != 0) { LastStatus = r0; LastErr = "workspace boyutu alinamadi"; return null; }
            byte[] work = new byte[Math.Max(ws, fw)];
            byte[] outb = new byte[usize];
            uint fin = 0;
            uint st = RtlDecompressBufferEx(4, outb, usize, comp, (uint)comp.Length, out fin, work);
            if (st != 0) { LastStatus = st; LastErr = "RtlDecompressBufferEx hata verdi"; return null; }
            return outb;
        } catch (Exception ex) { LastErr = ex.GetType().Name + ": " + ex.Message; return null; }
    }
    public static long KeyTime(Microsoft.Win32.SafeHandles.SafeRegistryHandle h) {
        long ft = 0;
        int r = RegQueryInfoKey(h, null, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, out ft);
        if (r != 0) return 0;
        return ft;
    }
}
'@
try {
    Add-Type -TypeDefinition $cs -Language CSharp -ErrorAction Stop
    $script:HkOk = $true
} catch { $script:HkOk = $false }

# ---------------- isim listeleri ----------------
$StrongNames = @(
    'wurst','aristois','meteor','mathax','doomsday','haruka','nursultan','dimosik','liquidbounce','minced','arbuz',
    'newcode','vanadium','catlean','nightware','wexside','mythra','oyvey','interia','iternia','inertia','catlavan',
    'zenora','vape','rusher','shoreline','slinky','augustus','boze','cutthrough','invmove','danqclient','baritone',
    'monoton','fdpclient','deadcode','radon','churka','koshka','litka','genclient','fluger','dettex','evaware',
    'moonproject','miraclous','nexgen','nightdlc','nextdlc','rogalik','ratka','spectra','shitpaste','wissend','amoral',
    'excellentomni','relake','deko','desteny','vredux','kimadlc','nixware','hachclient','neverlose','wiksi',
    'seasonreloadd','vegaline','voil','multiware','verist','foxclient','nurik','zovchik','hynix','zaharov','nuckerdlc',
    'nucker','komarudlc','komaru','waileent','astralisbeta','astralis','liorclient','mantance','lunoclient',
    'awesomeproject','zexis','wirent','hitdelay','hitsune','wingclient','aka_tweaks','potionrefill','visible-barriers',
    'jumpoverfences','attack_through_grass','pingbypass','astolfo','novoware','entrophy','zeroday','tenacity','hellion',
    'jigsaw','huzuni','7clicker','bape','cheatbreaker','goki','koid','cheatengine','extremeinjector','processhacker',
    'systeminformer','opautoclicker','gsautoclicker','tinytask','jitbit','phantomclient',
    'astralux','astraulex','nyrex','noxx','alycone','luminex','zoomies','rebron','vapev4','vapelite','glazedclient','kryptonclient',
    'thunderhack','astraware','exosware','dimasx','noxium','voidstrike','zyron','dqrkis','gooba','salarixi','horion','borion','krismilex','vxrgin','trashh','waterclient','releon',
    'bleachhack','futureclient','sigmaclient','riseclient','novoline','konasclient','phobosclient','3arthh4ck','gamesense','salhack','kamiblue',
    'lambdaclient','pyroclient','hanabiclient','ravenb4','ravenbs','dortware','crystalware','slothclient','nodusclient','coffeeclient','trollhack',
    'forgehax','aobaclient','wolfram','impactclient','aristoisclient','huzuniclient','zeroday','remixclient','intentclient','ghostclient','abyssclient',
    'rustclient','sparkclient','exhibitionclient','moonclient','fluxclient','azuraclient','pandaware','skilledclient','nodus',
    'xenoncl','zenithclient','argonclient','asteriaclient','virginclient','prestigeclient','gypsyclient','catleanclient','grimclient','krypton-client',
    'meteorclient','meteor-client','rusherhack','rusher-hack','wurstclient','wurst-client','liquidbounce','fdpclient','alienclient','cosmosclient',
    'nightix','blade-reload','bladereload','velka','aethereal','dimasik','dimasik-client','wild-client','wildclient','delta-client','deltaclient',
    'flow-client','flowclient','system-dlc','systemdlc','phobia-client','punch-client','doomsdayclient','doomsday-client'
)
$WeakNames = @(
    'collapse','expensive','excellent','delta','grim','venus','arcade','zenith','essence','adjust','centric','future',
    'phantom','nix','moon','ares','wild','grace','damage','opal','dream','grape','reach','velocity','aimbot','esp','fly',
    'explicit','exclusive','flux','rise','sigma','thunder','impact','rocket','virgin','prestige','exhibition','ethereal',
    'preacher','deluxe','sparta','winner','kami','raven','ventura','argon','vapor','krypton','celestial',
    'helsing','marlow','xenon','calcium','astral','radium','achilles','gypsy','osmium','zorin','vril','mist','silk','combo','fusion','aero','mace','helion','glazed','phobia','punch','flow'
)
function New-Rx([string[]]$names) {
    $sorted = $names | Sort-Object -Property { $_.Length } -Descending
    $alt = ($sorted | ForEach-Object { [regex]::Escape($_) }) -join '|'
    return New-Object System.Text.RegularExpressions.Regex ('(?i)(?<![a-z0-9])(' + $alt + ')(?![a-z0-9])')
}
$script:StrongRx = New-Rx $StrongNames
# '<isim> client' kalibi: sik kelimeler (water, star, system...) tek basina degil, sadece 'client/hack/ghost/dlc' ekiyle hile sayilir
$script:ClientRx = New-Object System.Text.RegularExpressions.Regex ('(?i)(?<![a-z0-9])(helsing|marlow|nyrex|noxx|xenon|calcium|astral|astralux|radium|helion|hellion|achilles|alycone|luminex|gypsy|osmium|zorin|zoomies|zenith|prestige|phantom|krypton|glazed|vril|rebron|catlean|3qi|4e|vape|doomsday|shoreline|vanadium|phobia|punch|nightix|velka|aethereal|wild|delta|flow|deluxe|blade[ _\-]?reload|dimasik|dimosik|wexside|nursultan|evaware|neverlose|catlavan|doomsday)[ _\-\.]?(client|hack|hacked[ _\-]?client|ghost|dlc)(?![a-z0-9])|(?<![a-z0-9])(system|shell|water|star|rich|air|combo|mist|silk|mace|mio|bt|fusion|aero)[ _\-](client|hack|ghost|dlc)(?![a-z0-9])')
$script:CamelRx = New-Object System.Text.RegularExpressions.Regex ('(?<![A-Za-z])(System|Shell|Water|Star|Rich|Air|Combo|Mist|Silk|Mace|Fusion|Aero|Echo|Pulse|Fake|Nature|Clarity|Matcha|Venom|Saber|Expensive|Rockstar|Celestial|Sakura|Leet|Mochi|Phobia|Orchard|Rubidium|Lumine|Selene|Epitaph|Arsenic|Cataclysm|Boze|Krispy|Corz|Zeph|Myau|Voil|Xiu|Primordial|Francium)Client(?![A-Za-z0-9])')
$script:WeakRx = New-Rx $WeakNames
$script:SubRx = New-Object System.Text.RegularExpressions.Regex ('(?i)(kill[ _\-]?aura|trigger[ _\-]?bot|aim[ _\-]?assist|aim[ _\-]?bot|auto[ _\-]?clicker|cheat[ _\-]?engine|elytra[ _\-]?target|jump[ _\-]?reset|scaffoldwalk|nofall|freecam|xray|antikb|autototem|autoarmor|chestesp|hitboxexpand)')
$script:StrongRx = New-Object System.Text.RegularExpressions.Regex ($script:StrongRx.ToString(), [System.Text.RegularExpressions.RegexOptions]::Compiled)
$script:WeakRx = New-Object System.Text.RegularExpressions.Regex ($script:WeakRx.ToString(), [System.Text.RegularExpressions.RegexOptions]::Compiled)
$script:SubRx = New-Object System.Text.RegularExpressions.Regex ($script:SubRx.ToString(), [System.Text.RegularExpressions.RegexOptions]::Compiled)
$script:ClientRx = New-Object System.Text.RegularExpressions.Regex ($script:ClientRx.ToString(), [System.Text.RegularExpressions.RegexOptions]::Compiled)
$script:CamelRx = New-Object System.Text.RegularExpressions.Regex ($script:CamelRx.ToString(), [System.Text.RegularExpressions.RegexOptions]::Compiled)
# Jar icindeki .class dosya adi (tam ad, buyuk/kucuk harf duyarli): LiquidBounce / Flight / Disabler / STap
$script:ClassNameRx = New-Object System.Text.RegularExpressions.Regex ('(?:^|/)(LiquidBounce|Flight|Disabler|STap|Stap|AutoSTap|AutoStap)(?:\$[^/]*)?\.class$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
# Cok kelimeli/ayracli isimler ve ekli isimler (arsenic-client, click-crystal-ghost, hwid-spoofer, echo-client, corz-clienttt ...)
$script:ExtraRx = New-Object System.Text.RegularExpressions.Regex ('(?<![a-z0-9])(?:liquid[ _\-\.]?bounce|click[ _\-\.]?crystal[ _\-\.]?(?:ghost|script)|hwid[ _\-\.]?spoofer|fate[ _\-\.]?injector|mei[ _\-\.]?laa|discord[ _\-\.]?orbs[ _\-\.]?farm|198[ _\-\.]?macros|cw[ _\-\.]?client[ _\-\.]?plus|zenith[ _\-\.]?macro|francium[ _\-\.]?reborn|argon[ _\-\.]?library|67[ _\-\.]?client|orchard[ _\-\.]?nitro|system[ _\-]1[ _\-]21(?:[ _\-]\d+)?|(?:arsenic|cataclysm|boze|krispy|corz|zeph|myau|voil|xiu|primordial|francium)[ _\-\.]?(?:clientt{0,3}|clients|hack|ghost|dlc|srcc?|macros?|injector|spoofer|proxy|reborn|remake|recode|nitro|plus)|(?:echo|pulse|fake|nature|clarity|matcha|venom|saber|expensive|rockstar|celestial|sakura|leet|mochi|phobia|rubidium|lumine|selene|epitaph)[ _\-](?:clientt{0,3}|clients|hack|ghost|dlc|srcc?|macros?|injector|proxy))(?![a-z0-9])', ([System.Text.RegularExpressions.RegexOptions]'IgnoreCase, Compiled'))
$script:BenignRx = '(?i)^(setup|install|installer|update|updater|unins\d*|uninstall|vc_?redist|vcredist|dxwebsetup|dotnet|windowsupdate|msedge|chrome|googleupdate|onedrive|teams|zoom|discord|spotify|steam|epicgames|riot|valorant|battle|nvidia|amd|radeon|intel|driver|java|jre|jdk|python|node|git|code|vscode|7z|winrar|vlc|obs|notepad|firefox|opera|brave|whatsapp|telegram|skype|anydesk|teamviewer|malwarebytes|avast|kaspersky|tlauncher|lunar|badlion|modrinth|prism|curseforge|overwolf|minecraft)'
$script:LauncherRx = '(?i)minecraft|launcher|lunar|badlion|modrinth|prism|multimc|feather|curseforge|tlauncher|labymod|salwyrr|atlauncher|technic|ftb|overwolf|ichor|sklauncher'
$IntExt = @('.exe','.dll','.jar','.zip','.rar','.7z','.bat','.cmd','.ps1','.vbs','.scr','.msi','.com')
$DisguiseExt = @('.png','.jpg','.jpeg','.gif','.bmp','.txt','.dat','.bin','.log','.pdf','.mp3','.mp4','.wav','.ico','.db','.ttf','.cfg','.ini','.json','.xml','.lang','.mcmeta','.nbt','.bak','.old','.mod','.disabled','.html','.htm','.css','.csv','.md','.rtf','.webp','.svg','.tga','.ogg','.m4a','.avi','.mkv','.mov','.wmv','.webm','.cache','.temp','.sav','.save','.backup','.bkp','.orig','.res','.data')
$HeavyRx = '(?i)\\(node_modules|Cache|Code Cache|GPUCache|CacheStorage|Service Worker|IndexedDB|Local Storage|Session Storage|Crashpad|blob_storage|libraries|assets|runtime|\.git)(\\|$)'
$SigRx = '(?i)\\(Downloads|Desktop|Documents|Temp|Public)\\'

$script:NhCache = New-Object 'System.Collections.Generic.Dictionary[string,object]' ([StringComparer]::Ordinal)
function Get-NameHit([string]$text, [bool]$weak = $true) {
    if ([string]::IsNullOrEmpty($text)) { return $null }
    $ck = $null
    if ($text.Length -le 260) {
        $ck = $(if ($weak) { 'w|' } else { 's|' }) + $text
        if ($script:NhCache.ContainsKey($ck)) { return $script:NhCache[$ck] }
    }
    $res = Get-NameHitRaw $text $weak
    if ($ck -and $script:NhCache.Count -lt 60000) { $script:NhCache[$ck] = $res }
    return $res
}
function Get-NameHitRaw([string]$text, [bool]$weak = $true) {
    if ([string]::IsNullOrEmpty($text)) { return $null }
    $m = $script:SubRx.Match($text)
    if ($m.Success) { return [pscustomobject]@{ Name = $m.Groups[1].Value.ToLower(); Weak = $false } }
    $m = $script:StrongRx.Match($text)
    if ($m.Success) { return [pscustomobject]@{ Name = $m.Groups[1].Value.ToLower(); Weak = $false } }
    $m = $script:ClientRx.Match($text)
    if ($m.Success) { return [pscustomobject]@{ Name = ($m.Value.ToLower().Trim()); Weak = $false } }
    $m = $script:ExtraRx.Match($text)
    if ($m.Success) { return [pscustomobject]@{ Name = ($m.Value.ToLower().Trim()); Weak = $false } }
    $m = $script:CamelRx.Match($text)
    if ($m.Success) { return [pscustomobject]@{ Name = ($m.Value.ToLower().Trim()); Weak = $false } }
    if ($weak) {
        $m = $script:WeakRx.Match($text)
        if ($m.Success) { return [pscustomobject]@{ Name = $m.Groups[1].Value.ToLower(); Weak = $true } }
    }
    return $null
}
function Get-HitLines([string]$text, [int]$max) {
    # Metindeki ilk eslesmelerin satirlarini dondurur; [CHAT] (oyuncu mesaji) satirlari atlanir. Tek gecis, satir satir tarama yok.
    $found = New-Object System.Collections.Generic.List[object]
    $seenS = @{}
    foreach ($rx in @($script:SubRx, $script:StrongRx, $script:ClientRx, $script:ExtraRx, $script:CamelRx)) {
        $m = $rx.Match($text)
        $got = 0
        $tries = 0
        while ($m.Success -and $got -lt $max -and $tries -lt 300) {
            $tries++
            $i = [int]$m.Index
            $a = 0
            if ($i -gt 0) { $a = $text.LastIndexOf("`n", $i - 1) + 1 }
            if (-not $seenS.ContainsKey($a)) {
                $seenS[$a] = 1
                $b = $text.IndexOf("`n", $i)
                if ($b -lt 0) { $b = $text.Length }
                $ln = $text.Substring($a, [Math]::Min(400, $b - $a))
                if ($ln.IndexOf('[CHAT]') -lt 0) { [void]$found.Add([pscustomobject]@{ Pos = $a; Line = $ln }); $got++ }
            }
            $m = $m.NextMatch()
        }
    }
    $res = New-Object System.Collections.Generic.List[string]
    foreach ($f in @($found | Sort-Object -Property Pos)) { [void]$res.Add([string]$f.Line); if ($res.Count -ge $max) { break } }
    return $res.ToArray()
}
function Name-Score($hit, [bool]$leaf) {
    if (-not $hit) { return 0 }
    if (-not $hit.Weak) { if ($leaf) { return 60 } else { return 40 } }
    if ($leaf) { return 25 }
    return 0
}

# Klavyeye rastgele basilarak uretilmis gibi gorunen dosya adi mi? (ornek: asdhjsa, hasdih, xzvkqpw)
function Test-Gibberish([string]$base) {
    if ([string]::IsNullOrWhiteSpace($base)) { return $false }
    $b = $base.ToLower()
    if ($b -match '^[0-9a-f\-_\{\}\.]{8,}$') { return $false }
    $letters = ($b -replace '[^a-z\u00e7\u011f\u0131\u00f6\u015f\u00fc]', '')
    if ($letters.Length -lt 5) { return $false }
    if ($letters -match '(asd|sdf|dfg|fgh|ghj|hjk|jkl|qwe|zxc|xcv|cvb)') { return $true }
    $vow = ([regex]::Matches($letters, '[aeiou\u0131\u00f6\u00fc]')).Count
    $ratio = $vow / [double]$letters.Length
    if ($letters.Length -ge 6 -and $ratio -lt 0.15) { return $true }
    if ($letters.Length -ge 6 -and $ratio -lt 0.25 -and $letters -match '[^aeiou\u0131\u00f6\u00fc]{5,}') { return $true }
    return $false
}

# id83lls.exe gibi harf-rakam karisik rastgele isimler (hile dosyalari sik boyle adlandirilir)
function Test-MixedRandom([string]$base) {
    if ([string]::IsNullOrWhiteSpace($base)) { return $false }
    $b = $base.ToLower()
    if ($b -notmatch '^[a-z0-9]{6,14}$') { return $false }
    if ($b -match '^[0-9a-f]{8,}$') { return $false }
    if ($b -match '(x64|x86|win32|win64|mp3|mp4|utf8|sha\d|md5|h264|h265|k2|3d|v\d)') { return $false }
    if ($b -notmatch '[a-z]\d+[a-z]') { return $false }
    $letters = ($b -replace '[^a-z]', '')
    if ($letters.Length -lt 3) { return $false }
    $vow = ([regex]::Matches($letters, '[aeiou]')).Count
    return (($vow / [double]$letters.Length) -lt 0.34)
}

# ---------------- yardimci fonksiyonlar ----------------
$script:Drives = @()
foreach ($d in [IO.DriveInfo]::GetDrives()) { if ($d.IsReady) { $script:Drives += $d.Name.Substring(0, 2).ToUpper() } }
$script:VolMap = @{}
if ($script:HkOk) {
    foreach ($dl in $script:Drives) {
        $sb = New-Object System.Text.StringBuilder 512
        if ([HkNative]::QueryDosDevice($dl, $sb, 512) -gt 0) { $script:VolMap[$sb.ToString()] = $dl }
    }
}
$script:SerialMap = @{}
foreach ($ld in @(Get-CimInstance Win32_LogicalDisk)) {
    if ($ld.VolumeSerialNumber) { $script:SerialMap[$ld.VolumeSerialNumber.ToUpper()] = $ld.DeviceID.ToUpper() }
}
$script:FixedNtfs = @()
foreach ($d in [IO.DriveInfo]::GetDrives()) {
    if ($d.IsReady -and $d.DriveType -eq 'Fixed' -and $d.DriveFormat -eq 'NTFS') { $script:FixedNtfs += $d.Name.Substring(0, 2).ToUpper() }
}

function Test-SysPathOk([string]$p) {
    # C:\Windows, C:\Program Files, C:\Program Files (x86) altinda mi? (kulturden ve buyuk/kucuk harften bagimsiz)
    if ([string]::IsNullOrEmpty($p)) { return $false }
    $u = $p.ToUpperInvariant()
    if ($u.StartsWith('\\?\')) { $u = $u.Substring(4) }
    if ($u.Length -lt 4) { return $false }
    if ($u[1] -ne ':' -or $u[2] -ne '\') { return $false }
    $rest = $u.Substring(3)
    return ($rest.StartsWith('WINDOWS\') -or $rest.StartsWith('PROGRAM FILES\') -or $rest.StartsWith('PROGRAM FILES (X86)\'))
}
function Get-Zone([string]$p) {
    if ($p -match '(?i)\\Users\\[^\\]+\\(Downloads|Desktop|Documents|Music|Videos|Pictures|OneDrive[^\\]*)\\') { return 'user' }
    if ($p -match '(?i)\\AppData\\Local\\Temp\\|\\Windows\\Temp\\|\\Temp\\') { return 'temp' }
    if ($p -match '(?i)\\AppData\\') { return 'appdata' }
    if ($p -match '(?i)\\Users\\Public\\|\\ProgramData\\') { return 'shared' }
    if ((Test-SysPathOk $p) -or $p -match '(?i)\\Program Files( \(x86\))?\\|\\WindowsApps\\') { return 'system' }
    return 'other'
}
$script:SigCache = @{}
function Test-HasEmbeddedSig([string]$p) {
    # PE dosyasinda gomulu imza (Certificate Table) var mi? Hizli okuma; emin degilse $true doner (tam kontrol yapilir)
    $fs = $null
    try {
        $fs = [IO.File]::Open($p, 'Open', 'Read', 'ReadWrite')
        $b = New-Object byte[] 1024
        $n = $fs.Read($b, 0, 1024)
        if ($n -lt 256 -or $b[0] -ne 0x4D -or $b[1] -ne 0x5A) { return $true }
        $pe = [BitConverter]::ToInt32($b, 0x3C)
        if ($pe -lt 64 -or ($pe + 200) -gt $n) { return $true }
        if ($b[$pe] -ne 0x50 -or $b[$pe + 1] -ne 0x45) { return $true }
        $mg = [BitConverter]::ToUInt16($b, $pe + 24)
        $dd = $pe + 24 + 96
        if ($mg -eq 0x20B) { $dd = $pe + 24 + 112 }
        $secSize = [BitConverter]::ToUInt32($b, $dd + 4 * 8 + 4)
        return ($secSize -gt 0)
    } catch { return $true } finally { if ($fs) { $fs.Dispose() } }
}
$script:PfSign = [long]0
$script:PfSignN = 0
$script:PfSignFast = 0
function Test-Signed([string]$p) {
    $k = $p.ToLowerInvariant()
    if ($script:SigCache.ContainsKey($k)) { return $script:SigCache[$k] }
    $r = $false
    $t0 = [Diagnostics.Stopwatch]::GetTimestamp()
    $needFull = $true
    if (-not (Test-SysPathOk $p)) {
        if (-not (Test-HasEmbeddedSig $p)) { $needFull = $false; $script:PfSignFast = $script:PfSignFast + 1 }
    }
    if ($needFull) {
        try {
            $sg = Get-AuthenticodeSignature -LiteralPath $p -ErrorAction Stop
            $r = ($sg.Status -eq 'Valid')
        } catch { $r = $false }
    }
    $script:PfSign = $script:PfSign + ([Diagnostics.Stopwatch]::GetTimestamp() - $t0)
    $script:PfSignN = $script:PfSignN + 1
    $script:SigCache[$k] = $r
    return $r
}
$script:NameDeep = New-Object System.Collections.Generic.List[string]
$script:NameDeepSeen = @{}
function Add-NameDeep([string]$p) {
    if (-not $p -or $p -notmatch '^[A-Za-z]:\\') { return }
    $k = $p.ToLower()
    if ($script:NameDeepSeen.ContainsKey($k)) { return }
    if (-not (Test-Cap 'ozel tarama (isim eslesen dosya) listesi (sinir 300)' $script:NameDeep.Count 300)) { return }
    $script:NameDeepSeen[$k] = 1
    [void]$script:NameDeep.Add($p)
}
function Get-ZoneInfo([string]$p) {
    try {
        if ($script:HkOk) { $hkZ = $false; foreach ($hkS in @([HkNative]::Streams($p))) { if ([string]$hkS -like ':Zone.Identifier*') { $hkZ = $true } }; if (-not $hkZ) { return '' } }
        $z = Get-Content -LiteralPath $p -Stream Zone.Identifier -ErrorAction Stop
        $h = $z | Where-Object { $_ -match '^HostUrl=' } | Select-Object -First 1
        $r = $z | Where-Object { $_ -match '^ReferrerUrl=' } | Select-Object -First 1
        $o = @()
        if ($h) { $o += ($h -replace '^HostUrl=', '') }
        if ($r) { $o += ('ref: ' + ($r -replace '^ReferrerUrl=', '')) }
        return ($o -join ' | ')
    } catch { return '' }
}
# =====================================================================
# INDIRME KAYNAGI + HILE SITESI KONTROLU
# 10. ve 11. adimlarda supheli dosyanin nereden indirildigi (Zone.Identifier + tarayici indirme gecmisi) yazilir.
# Indirme adresi bilinen bir hile sitesi/istemcisiyle eslesirse dosya KESIN hile sayilir.
# =====================================================================
$script:DlIdx = $null
$script:DlIdxLeaf = $null
$script:DlLastUrl = ''
function Copy-DlDb([string]$src, [string]$dst) {
    foreach ($sfx in @('', '-wal', '-shm')) {
        $sp = $src + $sfx
        if (-not (Test-Path -LiteralPath $sp)) { continue }
        $fin = $null
        $fout = $null
        try {
            $fin = [IO.File]::Open($sp, 'Open', 'Read', 'ReadWrite')
            $fout = [IO.File]::Create($dst + $sfx)
            $fin.CopyTo($fout)
        } catch {
            if ($sfx -eq '') { throw }
        } finally {
            if ($fin) { $fin.Dispose() }
            if ($fout) { $fout.Dispose() }
        }
    }
}
function Initialize-DlIndex {
    # Tarayici indirme gecmisi (Chrome/Edge/Brave/Opera/Firefox) bir kere okunur: dosya yolu -> indirildigi adres
    if ($null -ne $script:DlIdx) { return }
    $script:DlIdx = @{}
    $script:DlIdxLeaf = @{}
    $dlSqlCs = @'
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class HkSqlDl {
    const string D = "winsqlite3.dll";
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] static extern int sqlite3_open_v2(byte[] f, out IntPtr db, int flags, IntPtr vfs);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] static extern int sqlite3_close(IntPtr db);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] static extern int sqlite3_prepare_v2(IntPtr db, byte[] sql, int n, out IntPtr st, IntPtr tail);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] static extern int sqlite3_step(IntPtr st);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] static extern int sqlite3_finalize(IntPtr st);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] static extern int sqlite3_column_count(IntPtr st);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] static extern IntPtr sqlite3_column_text(IntPtr st, int i);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] static extern int sqlite3_column_bytes(IntPtr st, int i);
    public static List<string[]> Query(string path, string sql, int max) {
        List<string[]> rows = new List<string[]>();
        IntPtr db;
        byte[] fb = Encoding.UTF8.GetBytes(path + "\0");
        if (sqlite3_open_v2(fb, out db, 2, IntPtr.Zero) != 0) { if (db != IntPtr.Zero) sqlite3_close(db); return null; }
        IntPtr st;
        byte[] sb = Encoding.UTF8.GetBytes(sql + "\0");
        if (sqlite3_prepare_v2(db, sb, -1, out st, IntPtr.Zero) != 0) { sqlite3_close(db); return null; }
        int cc = sqlite3_column_count(st);
        while (rows.Count < max && sqlite3_step(st) == 100) {
            string[] r = new string[cc];
            for (int i = 0; i < cc; i++) {
                IntPtr p = sqlite3_column_text(st, i);
                if (p == IntPtr.Zero) { r[i] = ""; continue; }
                int n = sqlite3_column_bytes(st, i);
                byte[] b = new byte[n];
                Marshal.Copy(p, b, 0, n);
                r[i] = Encoding.UTF8.GetString(b);
            }
            rows.Add(r);
        }
        sqlite3_finalize(st);
        sqlite3_close(db);
        return rows;
    }
}
'@
    $ok = $false
    try { Add-Type -TypeDefinition $dlSqlCs -Language CSharp -ErrorAction Stop; $ok = $true } catch { if ('HkSqlDl' -as [type]) { $ok = $true } }
    if (-not $ok) { return }
    $dbs = New-Object System.Collections.Generic.List[object]
    $bases = @(
        @('Chrome', ($env:LOCALAPPDATA + '\Google\Chrome\User Data')),
        @('Edge', ($env:LOCALAPPDATA + '\Microsoft\Edge\User Data')),
        @('Brave', ($env:LOCALAPPDATA + '\BraveSoftware\Brave-Browser\User Data')),
        @('Opera', ($env:APPDATA + '\Opera Software\Opera Stable')),
        @('Opera GX', ($env:APPDATA + '\Opera Software\Opera GX Stable'))
    )
    foreach ($bs in $bases) {
        if (-not (Test-Path -LiteralPath $bs[1])) { continue }
        $cands = New-Object System.Collections.Generic.List[string]
        $f0 = Join-Path $bs[1] 'History'
        if (Test-Path -LiteralPath $f0) { [void]$cands.Add($f0) }
        foreach ($pd in @(Get-ChildItem -LiteralPath $bs[1] -Directory -Force -ErrorAction SilentlyContinue)) {
            if ($pd.Name -eq 'Default' -or $pd.Name -like 'Profile *') {
                $f1 = Join-Path $pd.FullName 'History'
                if (Test-Path -LiteralPath $f1) { [void]$cands.Add($f1) }
            }
        }
        foreach ($cf in $cands) { [void]$dbs.Add([pscustomobject]@{ Tarayici = $bs[0]; Dosya = $cf; Firefox = $false }) }
    }
    foreach ($fd in @(Get-ChildItem -Path ($env:APPDATA + '\Mozilla\Firefox\Profiles') -Directory -Force -ErrorAction SilentlyContinue)) {
        $pf = Join-Path $fd.FullName 'places.sqlite'
        if (Test-Path -LiteralPath $pf) { [void]$dbs.Add([pscustomobject]@{ Tarayici = 'Firefox'; Dosya = $pf; Firefox = $true }) }
    }
    foreach ($db in $dbs) {
        $tmp = Join-Path $env:TEMP ('hk_dl_' + [guid]::NewGuid().ToString('N') + '.db')
        try {
            Copy-DlDb $db.Dosya $tmp
            $rows = $null
            if ($db.Firefox) {
                try { $rows = [HkSqlDl]::Query($tmp, "SELECT a.content, p.url, '', a.dateAdded FROM moz_annos a JOIN moz_anno_attributes n ON n.id = a.anno_attribute_id JOIN moz_places p ON p.id = a.place_id WHERE n.name = 'downloads/destinationFileURI'", 20000) } catch {}
            } else {
                try { $rows = [HkSqlDl]::Query($tmp, 'SELECT d.target_path, (SELECT c.url FROM downloads_url_chains c WHERE c.id = d.id ORDER BY c.chain_index DESC LIMIT 1), d.tab_url, d.start_time FROM downloads d ORDER BY d.start_time DESC', 20000) } catch {}
            }
            if ($null -ne $rows) {
                foreach ($rw in $rows) {
                    $tp = [string]$rw[0]
                    if (-not $tp) { continue }
                    $durl = [string]$rw[1]
                    $tab = [string]$rw[2]
                    if ($db.Firefox) {
                        try { $tp = ([Uri]::UnescapeDataString(($tp -replace '^file:///', ''))) -replace '/', '\' } catch {}
                    }
                    $tm = ''
                    try {
                        $tv = [long]$rw[3]
                        if ($tv -gt 0) {
                            if ($db.Firefox) { $tm = [DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc).AddMilliseconds($tv / 1000.0).ToLocalTime().ToString('yyyy-MM-dd HH:mm') }
                            else { $tm = [DateTime]::FromFileTimeUtc($tv * 10).ToLocalTime().ToString('yyyy-MM-dd HH:mm') }
                        }
                    } catch {}
                    $info = $db.Tarayici + ' indirme kaydi: ' + $durl
                    if ($tab) { $info = $info + ' (sayfa: ' + $tab + ')' }
                    if ($tm) { $info = $info + ' | ' + $tm }
                    $kk = $tp.ToLowerInvariant()
                    if (-not $script:DlIdx.ContainsKey($kk)) { $script:DlIdx[$kk] = $info }
                    $lf = ''
                    try { $lf = [IO.Path]::GetFileName($tp).ToLowerInvariant() } catch {}
                    if ($lf -and -not $script:DlIdxLeaf.ContainsKey($lf)) { $script:DlIdxLeaf[$lf] = $info }
                }
            }
        } catch {
        } finally {
            foreach ($sfx in @('', '-wal', '-shm')) { try { Remove-Item -LiteralPath ($tmp + $sfx) -Force -ErrorAction SilentlyContinue } catch {} }
        }
    }
}
# Bilinen hile istemcisi / hile satis-paylasim siteleri (etiket, regex). Indirme adresi (HostUrl, ReferrerUrl, tarayici kaydi)
# bunlardan biriyle eslesirse KESIN hile sayilir. Adres alan-adi uzantisindan bagimsiz (.net/.com/.cc/.xyz) aranir; GitHub/Discord yolundaki dosya/repo adlari da eslesir.
# Yeni site eklemek icin listeye @('Etiket', 'regex') satiri ekle.
$script:CheatSites = @(
    @('Meteor Client', 'meteor-?client|meteordevelopment'),
    @('Wurst', 'wurstclient|wurst-?imperium|wurst-?client|wurst7'),
    @('LiquidBounce', 'liquid-?bounce|ccblueX'),
    @('RusherHack', 'rusher-?hack'),
    @('Vape', 'vape\.gg|vape-?client|vape-?v4|vape-?lite|manthe\.today'),
    @('Future Client', 'future-?client'),
    @('Impact Client', 'impact-?client'),
    @('Aristois', 'aristois'),
    @('BleachHack', 'bleach-?hack'),
    @('ForgeHax', 'forge-?hax'),
    @('Boze', 'boze\.dev|boze-?client'),
    @('Bloody Client', 'bloody-?client'),
    @('Jex Client', 'jex-?client'),
    @('Mio Client', 'mio-?client'),
    @('MatHax', 'mathax'),
    @('Shoreline', 'shoreline-?client|shoreline\.(dev|wtf|cc|lol)'),
    @('Ares Client', 'ares-?client'),
    @('Inertia Client', 'inertia-?client'),
    @('Salhack', 'salhack'),
    @('KAMI Blue', 'kami-?blue'),
    @('Phobos/3arth', '3arth(h4ck|qu4ke)|phobos-?(hack|client)'),
    @('Konas', 'konas-?client|konasclient'),
    @('Thunderhack', 'thunder-?hack'),
    @('Huzuni', 'huzuni'),
    @('Intent', 'intent\.store|intent-?client'),
    @('Rise', 'rise-?client'),
    @('Novoline', 'novoline'),
    @('Sigma', 'sigma-?client'),
    @('Astolfo', 'astolfo'),
    @('Moon Client', 'moon-?client'),
    @('Drip Client', 'drip-?client|drip-?lite'),
    @('Raven', 'raven-?client|raven-?b\+|raven-?bplus'),
    @('Tenacity', 'tenacity-?client'),
    @('Exhibition', 'exhibition-?client'),
    @('Doomsday Client', 'doomsday-?client|doomsday\.(wtf|cc|club|pw|fun|lol|gg)'),
    @('diger istemciler (-client)', '(opai|dortware|pandaware|zeroday|slinky|entropy|azura|myau|koid|expensive|celestial|akrien|excellent|eternity|rockstar|hitware|deadcode|arbuz|fluger|catware|mushroom)-?client'),
    @('Nursultan', 'nursultan'),
    @('Neverlose', 'neverlose'),
    @('Evaware', 'evaware'),
    @('Wexside', 'wexside'),
    @('Catlavan', 'catlavan'),
    @('Nightix / NightX', 'nightix|night-?x-?client'),
    @('Aethereal', 'aethereal'),
    @('Velka', 'velka'),
    @('Dimasik', 'dimasik|dimosik'),
    @('Blade Reload', 'blade-?reload'),
    @('Wild Client', 'wild-?client'),
    @('Delta Client', 'delta-?client'),
    @('Flow Client', 'flow-?client'),
    @('System DLC', 'system-?dlc'),
    @('Zenith Client', 'zenith-?client'),
    @('Phobia Client', 'phobia-?client'),
    @('Punch Client', 'punch-?client'),
    @('Deluxe Client', 'deluxe-?client'),
    @('UnknownCheats', 'unknowncheats'),
    @('MPGH', 'mpgh\.net'),
    @('ElitePVPers', 'elitepvpers'),
    @('OwnedCore', 'ownedcore'),
    @('HackForums', 'hackforums'),
    @('MCHacks', 'mchacks'),
    @('Cracked.io', 'cracked\.io'),
    @('Nulled', 'nulled\.to'),
    @('BreachForums', 'breachforums|breached\.(vc|to|co|cc)'),
    @('hile/ghost client sitesi', '(minecraft|mc)[-.]?(hacks?|cheats?)|hacked[-.]?clients?|ghost[-.]?clients?|cheat[-.]?(client|store|shop)')
)
function Get-CheatSite([string]$u) {
    if (-not $u) { return '' }
    foreach ($cs in $script:CheatSites) {
        if ($u -match ('(?i)(?<![a-z0-9])(?:' + $cs[1] + ')')) { return [string]$cs[0] }
    }
    return ''
}
function Get-DlSite([string]$u) {
    if ($u -match 'discord(app)?\.(com|net)') { return 'Discord' }
    if ($u -match 'mediafire\.com') { return 'MediaFire' }
    if ($u -match 'mega\.nz|mega\.co\.nz') { return 'MEGA' }
    if ($u -match 'dropbox\.com') { return 'Dropbox' }
    if ($u -match 'drive\.google\.com|docs\.google\.com') { return 'Google Drive' }
    if ($u -match 'github\.com|githubusercontent\.com') { return 'GitHub' }
    if ($u -match 'modrinth\.com') { return 'Modrinth' }
    if ($u -match 'curseforge\.com') { return 'CurseForge' }
    if ($u -match 'gofile\.io|pixeldrain\.com|anonfiles|transfer\.sh|workupload\.com|file\.io|catbox\.moe|sendspace\.com|1fichier\.com') { return 'dosya paylasim sitesi' }
    if ($u -match 'https?://(?:www\.)?([^/?#:]+)') { return $Matches[1] }
    return ''
}
function Get-DlSource([string]$p, [bool]$ZoneOnly = $false) {
    $script:DlLastUrl = ''
    # Nereden indirildi: once Zone.Identifier (HostUrl/ReferrerUrl), yoksa tarayici indirme gecmisi
    $hostU = ''
    $refU = ''
    $zid = ''
    $pkg = ''
    $hasZ = $false
    try {
        $zs = $true
        if ($script:HkOk) { $zs = $false; foreach ($st in @([HkNative]::Streams($p))) { if ([string]$st -like ':Zone.Identifier*') { $zs = $true } } }
        if ($zs) {
            $zl = @(Get-Content -LiteralPath $p -Stream Zone.Identifier -ErrorAction Stop)
            $hasZ = $true
            foreach ($ln in $zl) {
                if ($ln -match '^HostUrl=(.+)$') { $hostU = $Matches[1].Trim() }
                elseif ($ln -match '^ReferrerUrl=(.+)$') { $refU = $Matches[1].Trim() }
                elseif ($ln -match '^ZoneId=(\d+)') { $zid = $Matches[1] }
                elseif ($ln -match '^LastWriterPackageFamilyName=(.+)$') { $pkg = $Matches[1].Trim() }
            }
        }
    } catch {}
    if ($hostU -or $refU) {
        $script:DlLastUrl = ($hostU + ' ' + $refU)
        $site = Get-DlSite ($hostU + ' ' + $refU)
        $t = 'NEREDEN INDIRILDI: '
        if ($site) { $t = $t + '[' + $site + '] ' }
        if ($hostU) { $t = $t + $hostU }
        if ($refU) { $t = $t + ' | sayfa (ReferrerUrl): ' + $refU }
        if ($zid) { $t = $t + ' | ZoneId=' + $zid }
        if ($pkg) { $t = $t + ' | indiren uygulama: ' + $pkg }
        return $t + ' (kaynak: Zone.Identifier)'
    }
    if ($ZoneOnly) { return '' }
    $br = ''
    try {
        Initialize-DlIndex
        $kk = $p.ToLowerInvariant()
        if ($script:DlIdx -and $script:DlIdx.ContainsKey($kk)) { $br = $script:DlIdx[$kk] }
        else {
            $lf = ''
            try { $lf = [IO.Path]::GetFileName($p).ToLowerInvariant() } catch {}
            if ($lf -and $script:DlIdxLeaf -and $script:DlIdxLeaf.ContainsKey($lf)) { $br = $script:DlIdxLeaf[$lf] + ' [AYNI ISIMLI kayit: dosya tasinmis/yeniden adlandirilmis olabilir]' }
        }
    } catch {}
    if ($br) {
        $script:DlLastUrl = $br
        $site2 = Get-DlSite $br
        $t2 = 'NEREDEN INDIRILDI: '
        if ($site2) { $t2 = $t2 + '[' + $site2 + '] ' }
        $t2 = $t2 + $br
        if ($hasZ) { $t2 = $t2 + ' | Zone.Identifier var ama adres yok (ZoneId=' + $zid + ')' }
        return $t2
    }
    $why0 = 'Zone.Identifier yok'
    if ($hasZ) { $why0 = 'Zone.Identifier var (ZoneId=' + $zid + ') ama adres yazilmamis' }
    return 'NEREDEN INDIRILDI: BULUNAMADI (' + $why0 + ' ve tarayici indirme gecmisinde kaydi yok: arsivden cikarilmis, USB/baska bilgisayardan kopyalanmis, baska tarayici/profilden inmis ya da kayitlar silinmis olabilir)'
}
function Get-Magic([string]$p) {
    try {
        $fs = [IO.File]::Open($p, 'Open', 'Read', 'ReadWrite')
        $n = 0
        $buf = New-Object byte[] 4
        try { $n = $fs.Read($buf, 0, 4) } finally { $fs.Dispose() }
        if ($n -ge 2 -and $buf[0] -eq 0x4D -and $buf[1] -eq 0x5A) { return 'MZ' }
        if ($n -ge 4 -and $buf[0] -eq 0x50 -and $buf[1] -eq 0x4B -and $buf[2] -eq 3 -and $buf[3] -eq 4) { return 'PK' }
        if ($n -ge 2) { return 'OTHER' }
    } catch {}
    return ''
}
function Get-KeyTime($k) {
    if ($script:HkOk) { try { return (Hk-Ft ([HkNative]::KeyTime($k.Handle))) } catch {} }
    return $null
}
function Test-PathInfo([string]$p) {
    $r = @{ Exists = $false; Removed = $false }
    if ($p -match '^([A-Za-z]:)\\') {
        $dl = $Matches[1].ToUpper()
        if ($script:Drives -contains $dl) { $r.Exists = [bool](Test-Path -LiteralPath $p) } else { $r.Removed = $true }
    } elseif ($p -match '^\(') {
        $r.Removed = $true
    } else {
        $r.Exists = [bool](Test-Path -LiteralPath $p)
    }
    return $r
}
function Resolve-NtPath([string]$p) {
    $r = @{ Path = $p; Exists = $false; Removed = $false }
    if ($p -match '^(\\Device\\HarddiskVolume\d+)(\\.*)$') {
        $dev = $Matches[1]
        $rest = $Matches[2]
        if ($script:VolMap.ContainsKey($dev)) {
            $r.Path = $script:VolMap[$dev] + $rest
            $r.Exists = [bool](Test-Path -LiteralPath $r.Path)
        } else {
            $found = $false
            if (-not $script:HkOk) {
                foreach ($dl in $script:Drives) {
                    if (Test-Path -LiteralPath ($dl + $rest)) { $r.Path = $dl + $rest; $r.Exists = $true; $found = $true; break }
                }
            }
            if (-not $found -and -not $r.Exists) { $r.Path = '(cikarilmis/eski surucu)' + $rest; $r.Removed = $true }
        }
    } else {
        $pi = Test-PathInfo $p
        $r.Exists = $pi.Exists
        $r.Removed = $pi.Removed
    }
    return $r
}
function Resolve-PfPath([string]$p) {
    $r = @{ Path = $p; Exists = $false; Removed = $false }
    if ($p -match '^\\VOLUME\{[0-9a-fA-F]+-([0-9a-fA-F]{8})\}(\\.*)$') {
        $ser = $Matches[1].ToUpper()
        $rest = $Matches[2]
        if ($script:SerialMap.ContainsKey($ser)) {
            $r.Path = $script:SerialMap[$ser] + $rest
            try { $r.Exists = [bool](Test-Path -LiteralPath $r.Path -ErrorAction Stop) } catch { $r.Exists = $false }
        } else {
            $r.Path = '(cikarilmis/eski surucu)' + $rest
            $r.Removed = $true
        }
    }
    return $r
}
function Rot13([string]$s) {
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $s.ToCharArray()) {
        $c = [int]$ch
        if ($c -ge 65 -and $c -le 90) { $c = ((($c - 65 + 13) % 26) + 65) } elseif ($c -ge 97 -and $c -le 122) { $c = ((($c - 97 + 13) % 26) + 97) }
        [void]$sb.Append([char]$c)
    }
    return $sb.ToString()
}
function Get-DownloadsPath {
    try {
        $v = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction Stop).'{374DE290-123F-4565-9164-39C4925E467B}'
        if ($v) { return [Environment]::ExpandEnvironmentVariables($v) }
    } catch {}
    return (Join-Path $env:USERPROFILE 'Downloads')
}

function Add-Sys([string]$Baslik, [int]$Skor, [string]$Aciklama, $Zaman = $null, [string]$Durum = '', $Degisim = $null) {
    [void]$script:Sys.Add([pscustomobject]@{ Baslik = $Baslik; Skor = $Skor; Aciklama = $Aciklama; Zaman = $Zaman; Durum = $Durum; Degisim = $Degisim })
}
# Bir servisin durumunu (baslatma modu + calisip calismadigi) ve kayit defteri anahtarinin
# en son ne zaman elle degistirildigini (Degisim) birlikte raporlar.
function Get-SvcHist {
    if ($null -ne $script:SvcHist) { return }
    $script:SvcHist = @{}
    $t0 = (Get-Date).AddDays(-90)
    try {
        foreach ($ev in @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Service Control Manager'; Id = 7036, 7040; StartTime = $t0 } -MaxEvents 8000 -ErrorAction SilentlyContinue)) {
            $dn = ''; $st = ''; $nw = ''
            try { $dn = [string]$ev.Properties[0].Value } catch {}
            if (-not $dn) { continue }
            if (-not $script:SvcHist.ContainsKey($dn)) { $script:SvcHist[$dn] = @{ Stop = $null; Cfg = $null; CfgMsg = '' } }
            $h = $script:SvcHist[$dn]
            if ($ev.Id -eq 7036) {
                try { $st = [string]$ev.Properties[1].Value } catch {}
                if ($st -match '(?i)stopp|durdu' -and (-not $h.Stop -or $ev.TimeCreated -gt $h.Stop)) { $h.Stop = $ev.TimeCreated }
            } elseif ($ev.Id -eq 7040) {
                if (-not $h.Cfg -or $ev.TimeCreated -gt $h.Cfg) { $h.Cfg = $ev.TimeCreated; $h.CfgMsg = (([string]$ev.Message) -replace '\s+', ' ').Trim() }
            }
        }
    } catch {}
}
function Check-Service([string]$sv, [string]$aciklama, [int]$devreDisiSkor = 40, [int]$durdurulmusSkor = 30) {
    if ($null -eq $script:SvcAll) { $script:SvcAll = @{}; foreach ($hkSv in @(Get-CimInstance Win32_Service)) { $script:SvcAll[[string]$hkSv.Name] = $hkSv } }
    $s = $script:SvcAll[$sv]
    if (-not $s) { return }
    $kt = $null
    try {
        $k = (Get-Item -LiteralPath ('HKLM:\SYSTEM\CurrentControlSet\Services\' + $sv))
        $kt = Get-KeyTime $k
    } catch {}
    $durum = $sv + ': baslatma=' + $s.StartMode + ', durum=' + $s.State
    $cfgT = $null
    if ($s.StartMode -eq 'Disabled' -or ($s.State -ne 'Running' -and $s.StartMode -eq 'Auto') -or ($kt -and $kt -gt (Get-Date).AddDays(-14))) {
        Get-SvcHist
        $hh = $script:SvcHist[[string]$s.DisplayName]
        if ($hh) {
            if ($hh.Cfg) { $durum = $durum + ' | SON ELLE AYAR DEGISIKLIGI (olay 7040): ' + (Fmt $hh.Cfg); $cfgT = $hh.Cfg; if ($hh.CfgMsg) { $durum = $durum + ' [' + $hh.CfgMsg + ']' } }
            if ($hh.Stop) { $durum = $durum + ' | SON DURDURULMA (olay 7036): ' + (Fmt $hh.Stop); if (-not $cfgT -or $hh.Stop -gt $cfgT) { $cfgT = $hh.Stop } }
        } else { $durum = $durum + ' | olay gunlugunda (90 gun) durdurma/ayar degisikligi kaydi yok' }
        if ($cfgT -and $kt -and $kt -gt $cfgT) { $cfgT = $kt }
        if (-not $cfgT) { $cfgT = $kt }
        if ($kt) { $durum = $durum + ' | kayit defteri anahtari son yazilma: ' + (Fmt $kt) }
        if ($cfgT) { $kt = $cfgT }
    }
    if ($s.StartMode -eq 'Disabled') {
        Add-Sys ('Servis DEVRE DISI: ' + $sv) $devreDisiSkor $aciklama $null $durum $kt
    } elseif ($s.State -ne 'Running' -and $s.StartMode -eq 'Auto') {
        Add-Sys ('Servis durdurulmus: ' + $sv) $durdurulmusSkor $aciklama $null $durum $kt
    } elseif ($kt -and $kt -gt (Get-Date).AddDays(-14)) {
        Add-Sys ('Servis ayari yakin zamanda degistirilmis: ' + $sv) 15 ($aciklama + ' (ayar 14 gun icinde degismis, normal olabilir)') $null $durum $kt
    }
}
# Bir kayit defteri DWORD degerini okur; beklenen (guvenli) degerden farkliysa uyari ekler,
# anahtarin en son ne zaman elle degistirildigini de raporlar.
function Check-RegFlag([string]$path, [string]$name, $beklenen, [string]$baslik, [string]$aciklama, [int]$skor) {
    try {
        $item = Get-Item -LiteralPath $path -ErrorAction Stop
        $val = $item.GetValue($name)
        $kt = Get-KeyTime $item
        if ($null -eq $val) { return }
        if ($val -ne $beklenen) {
            Add-Sys $baslik $skor $aciklama $null ($name + '=' + $val + ' (beklenen: ' + $beklenen + ')') $kt
        } elseif ($kt -and $kt -gt (Get-Date).AddDays(-14)) {
            Add-Sys ($baslik + ' - ayar yakin zamanda degistirilmis') 12 ($aciklama + ' (deger guvenli ama anahtar 14 gun icinde degismis)') $null ($name + '=' + $val) $kt
        }
    } catch {}
}
function Add-F {
    param([string]$Kaynak, [string]$Ad, [string]$Yol, [int]$Skor, $Son = $null, $Ilk = $null, [string]$Var = 'Bilinmiyor', $Silinme = $null, [string]$Not = '', [bool]$Benign = $false)
    # Guvence: Windows'un kendi klasorlerindeki (System32/SysWOW64/WinSxS) gecerli imzali dosyalar hicbir modulde bulgu sayilmaz
    if ($Yol -match '^[A-Za-z]:\\' -and $Kaynak -notmatch 'Kernel surucusu|Servis/surucu|Defender|ADS') {
        $swd = [string]$env:SystemRoot
        if ($swd -and $Yol.StartsWith(($swd.TrimEnd('\') + '\'), [StringComparison]::OrdinalIgnoreCase) -and $Yol -match '(?i)\\(System32|SysWOW64|WinSxS|SystemApps|servicing)\\') {
            if (Test-Signed $Yol) { return }
        }
    }
    if ($Ad -match '^hilekiran[^\\]*\.(ps1|txt)$') { return }
    # Indirme adresi bilinen bir hile sitesiyse (Jump List, RecentDocs, Prefetch, tarayici kaydi, Zone.Identifier... her kaynaktan) bulgu KESIN hile olur
    if ((-not $Benign) -and $Skor -lt 100 -and $Not -and ($Not -notmatch 'KESIN: hile sitesinden')) {
        $dlm = [regex]::Match($Not, '(indirildigi adres:|NEREDEN INDIRILDI:).*$')
        if ($dlm.Success) {
            $csn = ''
            try { $csn = Get-CheatSite $dlm.Value } catch {}
            if ($csn) { $Skor = 100; $Not = $Not + ' | KESIN: hile sitesinden indirilmis (' + $csn + ')' }
        }
    }
    [void]$script:HkFnd.Add([pscustomobject]@{ Kaynak = $Kaynak; Ad = $Ad; Yol = $Yol; Skor = $Skor; Son = $Son; Ilk = $Ilk; Var = $Var; Silinme = $Silinme; Not = $Not; Benign = $Benign })
}

# Calistirilmis bir program kaydini (Prefetch/BAM/UserAssist/Amcache/Shimcache/Recent) degerlendirir
$script:ExecExtSet = @('.exe','.dll','.scr','.com','.msi')
$script:CodeExtSet = @('.exe','.dll','.scr','.com','.msi','.jar','.bat','.cmd','.ps1','.vbs')
function Eval-Exec {
    param([string]$Kaynak, [string]$Path, [bool]$Exists = $false, [bool]$Removed = $false, $Last = $null, $First = $null, [string]$Note = '', [switch]$NoLoc)
    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    $leaf = $Path
    try { $leaf = Split-Path -Leaf $Path } catch {}
    if ([string]::IsNullOrWhiteSpace($leaf)) { return }
    if ($Last -and $Path -match '^[A-Za-z]:\\' -and (Test-Cap 'calistirma kaydi listesi (sinir 30000)' $script:Runs.Count 30000)) { [void]$script:Runs.Add([pscustomobject]@{ Yol = $Path; Zaman = $Last; Kaynak = $Kaynak }) }
    $zone = 'other'
    if (-not $NoLoc) { $zone = Get-Zone $Path }
    $hit = Get-NameHit $leaf $true
    $extL = ''
    try { $extL = [IO.Path]::GetExtension($leaf).ToLower() } catch {}
    $isCode = ($script:CodeExtSet -contains $extL)
    $sc = 0
    $why = New-Object System.Collections.Generic.List[string]
    if ($hit) {
        $ns = Name-Score $hit $true
        if ($ns -gt 0) { $sc += $ns; [void]$why.Add('isim eslesmesi: ' + $hit.Name) }
    }
    # ONEMLI: isim eslesmesi YOKSA ve dosya calistirilabilir bir kod dosyasi (exe/dll/jar/bat/ps1 vs.) DEGILSE
    # (yani sadece bir arsiv/veri dosyasi ise: .zip/.rar/.7z/resource pack vb.) hicbir konum/imza puani verme.
    # Sirf "indirilenler klasorunde" veya "imzasiz" olmak (zip'lerin zaten imzasi olmaz) tek basina supheli degildir.
    if ($hit -and -not $hit.Weak -and $Exists) { Add-NameDeep $Path }
    if (-not $hit -and -not $isCode) { return }
    if ($isCode -and -not $NoLoc -and $zone -ne 'system') {
        $rbn = ''
        try { $rbn = [IO.Path]::GetFileNameWithoutExtension($leaf) } catch {}
        if ((Test-MixedRandom $rbn) -or (Test-Gibberish $rbn)) { $sc += 25; [void]$why.Add('rastgele/anlamsiz karakterli dosya adi') }
    }
    if (-not $NoLoc) {
        if ($zone -eq 'system' -and $sc -eq 0) { return }
        if ($Removed) {
            $sc += 30
            [void]$why.Add('cikarilmis/eski surucuden calistirilmis')
        } elseif ($zone -eq 'user' -or $zone -eq 'temp') {
            if (-not $Exists) {
                $sc += 30
                [void]$why.Add('kullanici/temp klasorunden calistirilmis, su an SILINMIS')
            } else {
                $sc += 12
                [void]$why.Add('kullanici/temp klasorunden calistirilmis')
                if (($script:ExecExtSet -contains $extL) -and -not (Test-Signed $Path)) { $sc += 20; [void]$why.Add('imzasiz calistirilabilir dosya') }
            }
        } elseif ($zone -eq 'shared') {
            if (-not $Exists) { $sc += 20; [void]$why.Add('ortak klasorden calistirilmis, SILINMIS') } elseif (($script:ExecExtSet -contains $extL) -and -not (Test-Signed $Path)) { $sc += 15; [void]$why.Add('ortak klasorde imzasiz program') }
        } elseif ($zone -eq 'appdata') {
            if (-not $Exists) { $sc += 12; [void]$why.Add('AppData programi, su an yok') }
        } elseif ($zone -eq 'other') {
            if (-not $Exists) { $sc += 12; [void]$why.Add('calistirilmis, su an bulunamiyor') }
        }
    }
    $benign = $false
    if (($leaf -match $script:BenignRx) -and $sc -lt 40) { $benign = $true; $sc -= 15 }
    # Windows DISM Host Servicing Process: Windows Update/DISM her calistiginda Temp\{GUID}\dismhost.exe olusturup siler (normal)
    if ($leaf -ieq 'dismhost.exe' -and $Path -match '(?i)\\Temp\\\{?[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}\}?\\dismhost\.exe$') {
        if ((-not $Exists) -or (Test-Signed $Path)) { $benign = $true; $sc = [Math]::Min($sc, 10) }
    }
    if ($sc -lt 10) { return }
    $var = 'Bilinmiyor'
    if (-not $NoLoc) { if ($Exists) { $var = 'Evet' } else { $var = 'Hayir' } }
    $nt = ($why -join '; ')
    if ($Note) { $nt = $nt + ' | ' + $Note }
    if ($Exists -and $sc -ge 20) {
        $zi = Get-ZoneInfo $Path
        if ($zi) { $nt = $nt + ' | indirildigi adres: ' + $zi }
    }
    Add-F -Kaynak $Kaynak -Ad $leaf.ToLower() -Yol $Path -Skor ([Math]::Min(100, $sc)) -Son $Last -Ilk $First -Var $var -Not $nt -Benign $benign
}

function Inspect-Jar([string]$p) {
    $r = @{ Hit = $null; CHit = $null; Agent = $false; AgentClass = '' }
    try {
        $zip = [IO.Compression.ZipFile]::OpenRead($p)
        try {
            foreach ($e in $zip.Entries) {
                $n = $e.FullName
                if (-not $r.Hit -and $n.EndsWith('.class')) {
                    $h = Get-NameHit $n $false
                    if ($h) { $r.Hit = $h.Name }
                }
                if (-not $r.CHit -and $n.EndsWith('.class')) {
                    $cm = $script:ClassNameRx.Match($n)
                    if ($cm.Success) { $r.CHit = $cm.Groups[1].Value }
                }
                if ($n -eq 'META-INF/MANIFEST.MF') {
                    $sr = New-Object IO.StreamReader($e.Open())
                    $txt = $sr.ReadToEnd()
                    $sr.Dispose()
                    if ($txt -match '(?im)^(Premain-Class|Agent-Class|Launcher-Agent-Class):\s*(\S+)') { $r.Agent = $true; $r.AgentClass = $Matches[2] }
                }
            }
        } finally { $zip.Dispose() }
    } catch {}
    return $r
}

function Inspect-File($f) {
    $script:fileCount++
    if (($script:fileCount % 3000) -eq 0) { Write-Host -NoNewline '.' -ForegroundColor DarkGray }
    if (($script:fileCount % 500) -eq 0 -and $script:TitleOk) { [HkTitle]::Sub = ($script:fileCount.ToString() + ' dosya'); if ([HkTitle]::Frac -lt 0.9) { [HkTitle]::Frac = [Math]::Min(0.9, $script:fileCount / 200000.0) }; Update-Bar ([HkTitle]::Frac) ($script:fileCount.ToString() + ' dosya') }
    $name = $f.Name
    $ext = $f.Extension.ToLower()
    $path = $f.FullName
    if ($name -match '[^\u0000-\u024F\u1E00-\u1EFF]') {
        $uSc = 0
        $uWhy = ''
        if ($name -match '[\u202A-\u202E\u2066-\u2069]') { $uSc = 65; $uWhy = 'sag-sol yon degistirici karakter (uzanti gizleme hilesi)' }
        elseif ($name -match '[\u200B-\u200F\u2060-\u2064\uFEFF]') { $uSc = 45; $uWhy = 'gorunmeyen (sifir genislikli) karakter' }
        elseif ($name -match '[A-Za-z]' -and $name -match '[\u0370-\u03FF\u0400-\u04FF]') { $uSc = 40; $uWhy = 'Latin harflerle karisik Kiril/Yunan benzer karakter' }
        elseif ($name -match '[\uFF00-\uFFEF]') { $uSc = 35; $uWhy = 'tam genislikli (fullwidth) karakter' }
        if ($uSc -gt 0) { Add-F -Kaynak 'Dosya adinda gizli/benzer unicode karakter' -Ad $name -Yol $path -Skor $uSc -Son $f.LastWriteTime -Ilk $f.CreationTime -Var 'Evet' -Not ('dosya adinda ' + $uWhy) }
    }
    if (($ext -eq '.jar' -or ($ext -eq '.zip' -and $path -match $SigRx)) -and $f.Length -lt 104857600 -and $path -notmatch $HeavyRx -and (Test-Cap 'jar/zip aday listesi (sinir 4000)' $script:JarCand.Count 4000)) { [void]$script:JarCand.Add($f) }
    if (($ext -eq '.rar' -or $ext -eq '.7z') -and $f.Length -lt 4294967296 -and (Test-Cap 'rar/7z aday listesi (sinir 800)' $script:ArcOther.Count 800)) { [void]$script:ArcOther.Add($path) }
    if (($ext -eq '.exe' -or $ext -eq '.dll') -and $f.Length -gt 4096 -and $f.Length -lt 41943040 -and $path -notmatch $HeavyRx -and (Test-Cap 'exe/dll aday listesi (sinir 800)' $script:BinCand.Count 800)) { [void]$script:BinCand.Add($f) }
    if (@('.json', '.cfg', '.toml', '.txt', '.properties', '.yml', '.yaml', '.ini', '.conf') -contains $ext -and $f.Length -gt 100 -and $f.Length -lt 3145728 -and $path -match '(?i)\\(\.minecraft|AppData\\Roaming|AppData\\Local|Documents|Downloads|Desktop)\\' -and $path -notmatch $HeavyRx -and $path -notmatch '(?i)\\(logs|crash-reports)\\' -and $name -notlike 'launcher_profiles*' -and (Test-Cap 'ayar/metin dosyasi aday listesi (sinir 4000)' $script:CfgCand.Count 4000)) { [void]$script:CfgCand.Add($f) }
    $isInt = ($IntExt -contains $ext)
    $sc = 0
    $why = New-Object System.Collections.Generic.List[string]

    if (($ext -eq '.log' -or $ext -eq '.gz' -or $ext -eq '.txt') -and ($path -match '(?i)\\(logs|crash-reports)\\') -and ($path -match $script:LauncherRx)) {
        [void]$script:LogCand.Add($f)
    }
    if ($name -like 'launcher_profiles*.json') { [void]$script:ProfileJsonCand.Add($f) }
    if (($ext -eq '.bat' -or $ext -eq '.cmd' -or $ext -eq '.vbs' -or $ext -eq '.ps1' -or $ext -eq '.hta' -or $ext -eq '.wsf') -and $f.Length -lt 1048576 -and $path -notmatch $HeavyRx -and (Test-Cap 'script dosyasi aday listesi (sinir 800)' $script:ScriptCand.Count 800)) { [void]$script:ScriptCand.Add($f) }
    if ($ext -eq '.json' -and $f.Length -lt 3145728 -and ($path -match '(?i)\\\.minecraft\\versions\\|feather')) { [void]$script:JsonCand2.Add($f) }
    if ($isInt -or $ext -eq '') {
        $hit = Get-NameHit $name $true
        if ($hit) {
            if (-not $hit.Weak) { Add-NameDeep $path }
            $ns = Name-Score $hit $true
            if ($ns -gt 0) { $sc += $ns; [void]$why.Add('dosya adi: ' + $hit.Name) }
        }
    }
    if ($name -match '(?i)\.(png|jpe?g|gif|txt|pdf|docx?|xlsx?|mp3|mp4|zip|rar|lnk)\.(exe|scr|bat|cmd|jar|com|vbs|ps1|dll)$') {
        $sc += 55; [void]$why.Add('cift uzanti (gizlenmis calistirilabilir dosya)')
    }
    if ($name.IndexOf([char]0x202E) -ge 0) { $sc += 60; [void]$why.Add('RTLO (ters yazdirma) uzanti hilesi') }
    if ((@('.exe', '.jar', '.dll', '.bat', '.ps1', '.scr') -contains $ext) -and ($path -match '(?i)\\Users\\[^\\]+\\(Downloads|Desktop|Documents)\\') -and (Test-Gibberish ([IO.Path]::GetFileNameWithoutExtension($name)))) {
        $sc += 30; [void]$why.Add('rastgele/anlamsiz karakterli dosya adi')
    }

    $heavy = ($path -notmatch $HeavyRx)
    if (-not $heavy -and ($ext -eq '.jar' -or $ext -eq '.exe' -or $ext -eq '.dll')) { Add-Cov 'libraries/assets/runtime/cache klasorundeki jar-exe-dll: derin taranmadi' $path }
    $magic = ''
    $disg = ($DisguiseExt -contains $ext)
    # .tmp: Temp/installer/updater artiklari normalde MZ/PK icerir, bu yuzden sadece mod/surum klasorlerinde supheli say
    if ($ext -eq '.tmp' -and ($path -match '(?i)\\\.minecraft\\(mods|versions)\\')) { $disg = $true }
    if ($f.Length -ge 4 -and $heavy) {
        if (($disg -and $f.Length -ge 20480) -or ($ext -eq '' -and $f.Length -ge 20480) -or $ext -eq '.jar' -or $ext -eq '.exe' -or $ext -eq '.dll') { $pt0 = [Diagnostics.Stopwatch]::GetTimestamp(); $magic = Get-Magic $path; $script:PfMagic = [long]$script:PfMagic + ([Diagnostics.Stopwatch]::GetTimestamp() - $pt0); $script:PfMagicN = [int]$script:PfMagicN + 1 }
    }
    if ($magic -eq 'MZ' -and ($disg -or $ext -eq '')) {
        $extTxt = $ext
        if (-not $extTxt) { $extTxt = '(uzantisiz)' }
        $sc += 60; [void]$why.Add('uzanti ' + $extTxt + ' ama icerik EXE/DLL (MZ) - uzanti degistirilmis/silinmis')
    } elseif ($magic -eq 'PK' -and ($disg -or $ext -eq '.exe' -or $ext -eq '.dll')) {
        $sc += 45; [void]$why.Add('uzanti ' + $ext + ' ama icerik ZIP/JAR (PK) - uzanti degistirilmis')
    } elseif ($magic -eq 'OTHER' -and $ext -eq '.jar') {
        $sc += 35; [void]$why.Add('.jar uzantili ama gercek jar/zip degil (sifreli/bozuk olabilir)')
    } elseif ($magic -eq 'OTHER' -and ($ext -eq '.exe' -or $ext -eq '.dll')) {
        $sc += 40; [void]$why.Add($ext + ' uzantili ama gercek program degil')
    }
    if ($magic -eq 'PK' -and ($disg -or $ext -eq '.exe' -or $ext -eq '.dll') -and $f.Length -lt 104857600 -and (Test-Cap 'jar/zip aday listesi (sinir 4000)' $script:JarCand.Count 4000)) { [void]$script:JarCand.Add($f) }
    if ($magic -eq 'MZ' -and ($disg -or $ext -eq '') -and $f.Length -lt 41943040 -and (Test-Cap 'exe/dll aday listesi (sinir 800)' $script:BinCand.Count 800)) { [void]$script:BinCand.Add($f) }
    if ($heavy -and ($ext -eq '.jar' -or ($magic -eq 'PK' -and ($disg -or $ext -eq '.exe' -or $ext -eq '.dll'))) -and $f.Length -lt 157286400) {
        $pt0 = [Diagnostics.Stopwatch]::GetTimestamp()
        $jr = Inspect-Jar $path
        $script:PfInsJar = [long]$script:PfInsJar + ([Diagnostics.Stopwatch]::GetTimestamp() - $pt0); $script:PfInsJarN = [int]$script:PfInsJarN + 1
        if ($jr.Hit) { $sc += 40; [void]$why.Add('jar ICINDE hile modulu/istemci ismi: ' + $jr.Hit) }
        if ($jr.CHit) { $sc += 25; [void]$why.Add('jar ICINDE supheli class adi: ' + $jr.CHit + ' (LiquidBounce/Flight/Disabler/STap)') }
        if ($jr.Agent) { $sc += 30; [void]$why.Add('jar bir Java agent (' + $jr.AgentClass + ') - oyuna kod enjekte edebilir') }
    }
    if ($script:HkOk -and $heavy) {
        $adsList = $null
        $pt0 = [Diagnostics.Stopwatch]::GetTimestamp()
        try { $adsList = [HkNative]::Streams($path) } catch {}
        $script:PfAds = [long]$script:PfAds + ([Diagnostics.Stopwatch]::GetTimestamp() - $pt0); $script:PfAdsN = [int]$script:PfAdsN + 1
        foreach ($stx in @($adsList)) {
            if (-not $stx) { continue }
            $sp = ([string]$stx).Split('|')
            $sn = $sp[0]
            if ($sn -eq '::$DATA') { continue }
            $nm = ($sn -replace '^:', '') -replace ':\$DATA$', ''
            if ($nm -match '^(Zone\.Identifier|Win32App_\d+|SmartScreen|encryptable|com\.dropbox\.attrs|com\.dropbox\.attributes|AFP_AfpInfo|OECustomProperty)$') { continue }
            $ssz = [long]0
            [void][long]::TryParse($sp[1], [ref]$ssz)
            $adsSc = 30
            $adsWhy = 'gizli veri akisi (ADS): ' + $nm + ' (' + $ssz + ' bayt)'
            if ($ssz -ge 1024) { $adsSc = 45 }
            if ($nm -match '(?i)\.(exe|dll|jar|bat|ps1|cmd|vbs)$') { $adsSc = [Math]::Max($adsSc, 60); $adsWhy += ' - kod uzantili' }
            if ($ssz -ge 2) {
                try {
                    $hb = @(Get-Content -LiteralPath $path -Stream $nm -Encoding Byte -TotalCount 2 -ErrorAction Stop)
                    if ($hb.Count -ge 2 -and $hb[0] -eq 0x4D -and $hb[1] -eq 0x5A) { $adsSc = 80; $adsWhy += ' - icerik EXE/DLL (MZ)' }
                } catch {}
            }
            Add-F -Kaynak 'ADS (gizli veri akisi)' -Ad ($name.ToLower() + ':' + $nm.ToLower()) -Yol ($path + ':' + $nm) -Skor $adsSc -Son $f.LastWriteTime -Ilk $f.CreationTime -Var 'Evet' -Not $adsWhy
        }
    }
    if ($ext -eq '.exe' -and ($path -match $SigRx)) {
        if (-not (Test-Signed $path)) { $sc += 20; [void]$why.Add('imzasiz exe') }
    }
    if ($isInt) {
        # hile sitesi kontrolu: sadece Zone.Identifier (hizli); adres bilinen bir hile sitesiyse KESIN hile
        $dlz = Get-DlSource $path $true
        if ($dlz) {
            $csx = Get-CheatSite $script:DlLastUrl
            if ($csx) { $sc = 100; [void]$why.Add('KESIN: hile sitesinden indirilmis (' + $csx + ')') }
        }
    }
    if ($sc -ge 10) {
        [void]$why.Add((Get-DlSource $path))
        $nt = ($why -join '; ')
        Add-F -Kaynak 'Dosya taramasi' -Ad $name.ToLower() -Yol $path -Skor ([Math]::Min(100, $sc)) -Son $f.LastWriteTime -Ilk $f.CreationTime -Var 'Evet' -Not $nt
    }
}

function Read-Prefetch([string]$file) {
    $res = @{ Runs = @(); Paths = @(); Exe = '' }
    $script:PfDiag = ''
    try {
        $raw = [IO.File]::ReadAllBytes($file)
        $data = $raw
        if ($raw.Length -gt 8 -and $raw[0] -eq 0x4D -and $raw[1] -eq 0x41 -and $raw[2] -eq 0x4D) {
            if (-not $script:HkOk) { $script:PfDiag = 'yardimci modul (HkNative) derlenmemis, sikistirilmis Prefetch acilamaz'; return $res }
            $usize = [BitConverter]::ToUInt32($raw, 4)
            $comp = New-Object byte[] ($raw.Length - 8)
            [Array]::Copy($raw, 8, $comp, 0, $comp.Length)
            $data = [HkNative]::Xpress($comp, $usize)
            if ($null -eq $data) { $script:PfDiag = 'sikistirma acilamadi: ' + [HkNative]::LastErr + ' (durum 0x' + ([HkNative]::LastStatus).ToString('X8') + ')' }
        }
        if ($null -eq $data -or $data.Length -lt 200) { if (-not $script:PfDiag) { $script:PfDiag = 'dosya cok kisa/bos (' + @($data).Length + ' bayt)' }; return $res }
        if ([Text.Encoding]::ASCII.GetString($data, 4, 4) -ne 'SCCA') { $script:PfDiag = 'SCCA imzasi yok (acilan veri Prefetch degil)'; return $res }
        $ver = [BitConverter]::ToUInt32($data, 0)
        $res.Exe = [Text.Encoding]::Unicode.GetString($data, 16, 60).Split([char]0)[0]
        $runs = @()
        if ($ver -ge 26) {
            for ($i = 0; $i -lt 8; $i++) {
                $t = Hk-Ft ([BitConverter]::ToInt64($data, 128 + 8 * $i))
                if ($t) { $runs += $t }
            }
        } elseif ($ver -eq 23) {
            $t = Hk-Ft ([BitConverter]::ToInt64($data, 128))
            if ($t) { $runs += $t }
        } elseif ($ver -eq 17) {
            $t = Hk-Ft ([BitConverter]::ToInt64($data, 120))
            if ($t) { $runs += $t }
        }
        $res.Runs = $runs
        $so = [BitConverter]::ToUInt32($data, 100)
        $sl = [BitConverter]::ToUInt32($data, 104)
        if ($so -gt 0 -and $sl -gt 0 -and ($so + $sl) -le $data.Length) {
            $s = [Text.Encoding]::Unicode.GetString($data, $so, $sl)
            $res.Paths = @($s.Split([char]0) | Where-Object { $_ })
        } else { $script:PfDiag = 'dosya adlari bolumu bos/gecersiz (surum ' + $ver + ')' }
    } catch { $script:PfDiag = 'istisna: ' + $_.Exception.GetType().Name + ': ' + $_.Exception.Message + ' | satir: ' + ([string]$_.InvocationInfo.Line).Trim() }
    return $res
}

function Read-LogText([string]$p) {
    try {
        if ($p -like '*.gz') {
            $fs = [IO.File]::OpenRead($p)
            $gz = New-Object IO.Compression.GZipStream($fs, [IO.Compression.CompressionMode]::Decompress)
            $sr = New-Object IO.StreamReader($gz)
            $t = $sr.ReadToEnd()
            $sr.Dispose(); $gz.Dispose(); $fs.Dispose()
            return $t
        }
        $fs2 = [IO.File]::Open($p, 'Open', 'Read', 'ReadWrite')
        $sr2 = New-Object IO.StreamReader($fs2)
        $t2 = $sr2.ReadToEnd()
        $sr2.Dispose(); $fs2.Dispose()
        return $t2
    } catch { return '' }
}

function Get-UsnTime([string]$ln) {
    $m = [regex]::Match($ln, '(\d{1,4}[-/.]\d{1,2}[-/.]\d{1,4})[ T,]+(\d{1,2}:\d{2}:\d{2}(?:\s?[AaPp][Mm])?)')
    if (-not $m.Success) { return $null }
    $s = $m.Groups[1].Value + ' ' + $m.Groups[2].Value
    $d = [datetime]::MinValue
    if ([datetime]::TryParse($s, [Globalization.CultureInfo]::CurrentCulture, [Globalization.DateTimeStyles]::None, [ref]$d)) { return $d }
    if ([datetime]::TryParse($s, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$d)) { return $d }
    return $null
}
function Get-UsnName([string]$ln) {
    foreach ($tok in $ln.Split(',')) {
        $t = $tok.Trim().Trim('"').Trim()
        if (-not $t) { continue }
        if ($t -match '^0x[0-9A-Fa-f]+$') { continue }
        if ($t -match '^\d+$') { continue }
        if ($t -match '[\\/:*?<>|]') { continue }
        if ($t -match '^\$I[A-Za-z0-9]{6}(\.|$)' -or $t -match '\.[A-Za-z0-9]{1,5}$') { return $t }
    }
    return $null
}
function Test-UsnDelete([string]$ln) {
    if ($ln -match '(?i)file delete') { return $true }
    foreach ($mm in [regex]::Matches($ln, '0x[0-9A-Fa-f]{8}(?![0-9A-Fa-f])')) {
        $val = [Convert]::ToUInt32($mm.Value.Substring(2), 16)
        if (($val -band 0x200) -ne 0) { return $true }
    }
    return $false
}
# USN gunlugu her surucu icin sadece BIR kez okunur (eskiden 3 ayri tam gecis vardi); sonuc bellekte tutulur
$script:UsnRawCache = @{}
$script:UsnBg = @{}
function Stop-UsnBg([string]$dl) {
    $k = $dl.ToUpper()
    if (-not $script:UsnBg.ContainsKey($k)) { return }
    $bg = $script:UsnBg[$k]
    $script:UsnBg.Remove($k)
    try { if (-not $bg.Proc.HasExited) { $bg.Proc.Kill() } } catch {}
    Start-Sleep -Milliseconds 200
    Remove-Item -LiteralPath $bg.Cmd -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $bg.Out -Force -ErrorAction SilentlyContinue
}
# USN gunlugu okumasi (fsutil, dakikalar surebilir) diger adimlarla ayni anda arka planda baslatilir; sonuc Get-UsnRaw ile beklenip okunur
function Start-UsnBg([string]$dl) {
    $k = $dl.ToUpper()
    if ($script:UsnBg.ContainsKey($k) -or $script:UsnRawCache.ContainsKey($k)) { return }
    $id = [guid]::NewGuid().ToString('N')
    $tmpCmd = Join-Path $env:TEMP ('hk_usn_' + $id + '.cmd')
    $tmpOut = Join-Path $env:TEMP ('hk_usn_' + $id + '.txt')
    $cmdText = "@echo off`r`nfsutil usn readjournal " + $dl + " csv | findstr /i /c:`".exe`" /c:`".jar`" /c:`".rar`" /c:`".zip`" /c:`".7z`" /c:`".dll`" /c:`".bat`" /c:`".ps1`" /c:`".pf`" /c:`"`$I`" /c:`"ConsoleHost_history`" /c:`"JavaLauncher`" > `"" + $tmpOut + "`"`r`n"
    try {
        Set-Content -LiteralPath $tmpCmd -Value $cmdText -Encoding ASCII
        $pr = Start-Process -FilePath 'cmd.exe' -ArgumentList ('/c "' + $tmpCmd + '"') -WindowStyle Hidden -PassThru -ErrorAction Stop
        if ($pr) { $script:UsnBg[$k] = @{ Proc = $pr; Cmd = $tmpCmd; Out = $tmpOut } }
    } catch { Remove-Item -LiteralPath $tmpCmd -Force -ErrorAction SilentlyContinue }
}
function Get-UsnRaw([string]$dl) {
    $k = $dl.ToUpper()
    if ($script:UsnRawCache.ContainsKey($k)) { return ,$script:UsnRawCache[$k] }
    $tmpCmd = $null
    $tmpOut = $null
    if ($script:UsnBg.ContainsKey($k)) {
        $bg = $script:UsnBg[$k]
        $script:UsnBg.Remove($k)
        try { $bg.Proc.WaitForExit() } catch {}
        $tmpCmd = $bg.Cmd
        $tmpOut = $bg.Out
    } else {
        $id = [guid]::NewGuid().ToString('N')
        $tmpCmd = Join-Path $env:TEMP ('hk_usn_' + $id + '.cmd')
        $tmpOut = Join-Path $env:TEMP ('hk_usn_' + $id + '.txt')
        $cmdText = "@echo off`r`nfsutil usn readjournal " + $dl + " csv | findstr /i /c:`".exe`" /c:`".jar`" /c:`".rar`" /c:`".zip`" /c:`".7z`" /c:`".dll`" /c:`".bat`" /c:`".ps1`" /c:`".pf`" /c:`"`$I`" /c:`"ConsoleHost_history`" /c:`"JavaLauncher`" > `"" + $tmpOut + "`"`r`n"
        try {
            Set-Content -LiteralPath $tmpCmd -Value $cmdText -Encoding ASCII
            & $tmpCmd | Out-Null
        } catch {}
    }
    $lines = @()
    if (Test-Path -LiteralPath $tmpOut) { try { $lines = [IO.File]::ReadAllLines($tmpOut, [Text.Encoding]::Default) } catch { $lines = @(Get-Content -LiteralPath $tmpOut -ErrorAction SilentlyContinue) } }
    Remove-Item -LiteralPath $tmpCmd -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tmpOut -Force -ErrorAction SilentlyContinue
    $script:UsnRawCache[$k] = $lines
    return ,$lines
}
function Select-UsnLines([string]$dl, [string[]]$needles) {
    $raw = Get-UsnRaw $dl
    $parts = @()
    foreach ($nd in $needles) { $parts += [regex]::Escape($nd) }
    $urx = New-Object System.Text.RegularExpressions.Regex (($parts -join '|'), [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $res = New-Object System.Collections.Generic.List[string]
    foreach ($ln in $raw) { if ($urx.IsMatch($ln)) { [void]$res.Add($ln) } }
    return $res.ToArray()
}
function Read-Usn([string]$dl) {
    $lines = @(Select-UsnLines $dl @('.exe', '.jar', '.rar', '.zip', '.7z', '.dll', '.bat', '.ps1', '.pf', '$I'))
    $cnt = 0
    $cut = (Get-Date).AddDays(-30)
    foreach ($ln in $lines) {
        if (-not (Test-UsnDelete $ln)) { continue }
        $nm = Get-UsnName $ln
        if (-not $nm) { continue }
        $tm = Get-UsnTime $ln
        $key = $nm.ToLower()
        if ($nm -match '^\$I[A-Za-z0-9]{6}(\.|$)') {
            if ($tm) {
                if (-not $script:BinEmptied.ContainsKey($dl) -or $tm -gt $script:BinEmptied[$dl]) { $script:BinEmptied[$dl] = $tm }
            }
            continue
        }
        if ($nm -match '^\$R') { continue }
        $cnt++
        if ($tm) {
            if (-not $script:UsnDel.ContainsKey($key) -or $tm -gt $script:UsnDel[$key]) { $script:UsnDel[$key] = $tm }
        }
        $ext = ''
        try { $ext = [IO.Path]::GetExtension($nm).ToLower() } catch {}
        if ($ext -eq '.pf') { [void]$script:DeletedPf.Add([pscustomobject]@{ Ad = $nm; Zaman = $tm; Surucu = $dl }) }
        $hit = Get-NameHit $nm $true
        $ns = 0
        if ($hit) { $ns = Name-Score $hit $true }
        if ($ns -gt 0) {
            Add-F -Kaynak 'USN silinme kaydi' -Ad $key -Yol $nm -Skor ($ns + 5) -Var 'Hayir' -Silinme $tm -Not ('dosya silinmis (USN gunlugu): ' + $hit.Name)
        }
        if ($tm -and $tm -ge $cut -and @('.exe', '.jar', '.rar', '.zip', '.7z', '.bat', '.ps1') -contains $ext) {
            [void]$script:UsnRecent.Add([pscustomobject]@{ Ad = $nm; Zaman = $tm; Surucu = $dl })
        }
    }
    return $cnt
}

function Add-Root([string]$r) {
    if ([string]::IsNullOrWhiteSpace($r)) { return }
    if (-not (Test-Path -LiteralPath $r)) { return }
    $r = $r.TrimEnd('\')
    foreach ($e in $script:ScanRoots) {
        if ($r -ieq $e -or $r.StartsWith($e + '\', [StringComparison]::OrdinalIgnoreCase)) { return }
    }
    [void]$script:ScanRoots.Add($r)
}

$script:SecF0 = 0
$script:SecS0 = 0

function Find-Paths([string]$text, [string]$exts) {
    $res = New-Object System.Collections.Generic.List[string]
    $pat = '[A-Za-z]:\\[^\x00-\x1f"<>|*?:]{3,260}?\.(?:' + $exts + ')(?![A-Za-z0-9])'
    try {
        $rx = New-Object System.Text.RegularExpressions.Regex ($pat, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase, [TimeSpan]::FromSeconds(25))
        foreach ($m in $rx.Matches($text)) { [void]$res.Add($m.Value) }
    } catch {}
    return $res
}
# Fileless / script kalibi: Invoke-*, Reflection.Assembly, base64, gizli pencere vb. (tek basina BAN sebebi degil, supheli)
$script:FlRx2 = '(?i)Invoke-Expression|Invoke-RestMethod|Invoke-WebRequest|Invoke-Command|Invoke-Shellcode|\bIEX\b|System\.Reflection\.Assembly|\[Reflection\.Assembly\]|DownloadString|DownloadFile|FromBase64String|-enc(odedcommand)?\s|-w(indowstyle)?\s+hidden|-ExecutionPolicy\s+Bypass|\bmshta\b|certutil.*-urlcache|bitsadmin.*transfer|wmic\s+.*process\s+call\s+create'

# Byte dizisinden (registry binary / XML / PIDL) dosya yolu ve dosya adi cikarir (hem UTF-16 hem ASCII okunur)
function Get-PathsFromBytes([byte[]]$b, [bool]$namesToo = $false) {
    $res = New-Object System.Collections.Generic.List[string]
    if ($null -eq $b -or $b.Length -lt 8) { return $res }
    $seen = @{}
    $texts = New-Object System.Collections.Generic.List[string]
    foreach ($off in @(0, 1)) {
        $len = $b.Length - $off
        if ($len -lt 4) { continue }
        $sub = New-Object byte[] $len
        [Array]::Copy($b, $off, $sub, 0, $len)
        [void]$texts.Add([Text.Encoding]::Unicode.GetString($sub))
    }
    [void]$texts.Add([Text.Encoding]::GetEncoding(28591).GetString($b))
    foreach ($t in $texts) {
        foreach ($p in (Find-Paths $t 'exe|dll|jar|bat|ps1|scr|cmd|vbs|com')) {
            $k = $p.ToLower()
            if (-not $seen.ContainsKey($k)) { $seen[$k] = 1; [void]$res.Add($p) }
        }
        if ($namesToo) {
            foreach ($m in [regex]::Matches($t, '(?i)(?<![\w.\-\\/])[\w\-.]{2,80}\.(?:exe|dll|jar|bat|ps1|scr|cmd|vbs)(?![\w])')) {
                $k = $m.Value.ToLower()
                if (-not $seen.ContainsKey($k)) { $seen[$k] = 1; [void]$res.Add($m.Value) }
            }
        }
    }
    return $res
}

$script:PiCache = @{}
function Get-PiCached([string]$p) {
    $k = $p.ToLower()
    if (-not $script:PiCache.ContainsKey($k)) { $script:PiCache[$k] = Test-PathInfo $p }
    return $script:PiCache[$k]
}

# ---------------- process bellegi (RAM) string analizi ----------------
# .exe/.dll/.jar... yolu ve dosya adi iceren stringler: bilinen hile isimleri, silinmis/olagan disi yerden calisanlar
function Analyze-MemExe([string]$label, $strings, [int]$procId) {
    if ($null -eq $strings -or $strings.Count -eq 0) { return }
    $text = [string]::Join("`n", $strings)
    $seenP = @{}
    $cnt = 0
    foreach ($pm in (Find-Paths $text 'exe|dll|jar|bat|ps1|scr|cmd|vbs|com')) {
        $lk = $pm.ToLower()
        if ($seenP.ContainsKey($lk)) { continue }
        $seenP[$lk] = 1
        $leaf = ''
        try { $leaf = Split-Path -Leaf $pm } catch {}
        if (-not $leaf) { continue }
        $zone = Get-Zone $pm
        $hit = Get-NameHit $leaf $false
        if ($zone -eq 'system' -and -not $hit) { continue }
        $cnt++
        if ($cnt -gt 3000) { break }
        $pi = Get-PiCached $pm
        Eval-Exec -Kaynak ('Bellek stringi: ' + $label) -Path $pm -Exists $pi.Exists -Removed $pi.Removed -Note ('process bellegindeki yol (PID ' + $procId + ')')
    }
    $seenN = @{}
    foreach ($m in [regex]::Matches($text, '(?i)(?<![\w.\-\\/])([\w\-]{2,60})\.(?:exe|dll|jar)(?![\w])')) {
        $leaf = $m.Value
        $lk = $leaf.ToLower()
        if ($seenN.ContainsKey($lk)) { continue }
        $seenN[$lk] = 1
        $hit = Get-NameHit $leaf $false
        if (-not $hit) { continue }
        Add-F -Kaynak ('Bellek stringi: ' + $label) -Ad $lk -Yol $leaf -Skor 45 -Var 'Bilinmiyor' -Not ('process bellegindeki dosya adi, hile ismi: ' + $hit.Name + ' (PID ' + $procId + ')')
    }
}
# DPS servisinin bellegindeki !!program.exe!yyyy/MM/dd:HH:mm:ss! kayitlari (calistirma zamani)
function Analyze-MemDps([string]$label, $strings, [int]$procId) {
    if ($null -eq $strings -or $strings.Count -eq 0) { return }
    $text = [string]::Join("`n", $strings)
    $seen = @{}
    foreach ($m in [regex]::Matches($text, '!!([^!\\/\r\n]{2,80}\.(?:exe|dll))!(\d{4}/\d{2}/\d{2}:\d{2}:\d{2}:\d{2})!')) {
        $n = $m.Groups[1].Value
        $hit = Get-NameHit $n $false
        if (-not $hit) { continue }
        $key = $n.ToLower() + '|' + $m.Groups[2].Value
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = 1
        $tm = $null
        try { $tm = [datetime]::ParseExact($m.Groups[2].Value, 'yyyy/MM/dd:HH:mm:ss', [Globalization.CultureInfo]::InvariantCulture) } catch {}
        Add-F -Kaynak ('Bellek stringi: ' + $label + ' (DPS kaydi)') -Ad $n.ToLower() -Yol $n -Skor 50 -Son $tm -Var 'Bilinmiyor' -Not ('DPS bellek kaydi: calistirilmis program, hile ismi: ' + $hit.Name)
    }
}
# Dnscache bellegindeki alan adlari: hile site/istemci isimleri
function Analyze-MemDns([string]$label, $strings, [int]$procId) {
    if ($null -eq $strings -or $strings.Count -eq 0) { return }
    $text = [string]::Join("`n", $strings)
    $seen = @{}
    foreach ($m in [regex]::Matches($text, '(?i)(?<![a-z0-9\-])[a-z0-9][a-z0-9\-]{1,40}(?:\.[a-z0-9\-]{1,30})*\.(?:com|net|org|gg|io|xyz|ru|to|cc|club|pw|dev|me|app|su|cloud|shop|store|lol|fun|top|info|site|online|space|tech|cx|ws)(?![a-z0-9])')) {
        $d = $m.Value.ToLower()
        if ($seen.ContainsKey($d)) { continue }
        $seen[$d] = 1
        if ($seen.Count -gt 20000) { Add-Cov 'Bellek DNS/alan adi listesi 20000 sinirinda kesildi' '' ''; break }
        $hit = Get-NameHit $d $false
        if (-not $hit) { continue }
        Add-F -Kaynak ('Bellek stringi: ' + $label + ' (DNS)') -Ad ('alan adi: ' + $d) -Yol $d -Skor 45 -Var 'Bilinmiyor' -Not ('DNS onbellegi/bellek: bu alan adina baglanilmis olabilir, hile ismi: ' + $hit.Name)
    }
}
# wmic ile program baslatma komutlari (wmic ... process call create)
function Analyze-MemWmic([string]$label, $strings, [int]$procId) {
    if ($null -eq $strings -or $strings.Count -eq 0) { return }
    $seen = @{}
    foreach ($s in $strings) {
        if ($s.IndexOf('wmic', [StringComparison]::OrdinalIgnoreCase) -lt 0) { continue }
        $sc = 0
        if ($s -match '(?i)wmic(\.exe)?\s+.*process\s+call\s+create') { $sc = 60 }
        elseif ($s -match '(?i)wmic(\.exe)?\s+\S.*\.(exe|dll|bat|ps1|jar)') { $sc = 40 }
        if ($sc -eq 0) { continue }
        $k = $s.ToLower()
        if ($seen.ContainsKey($k)) { continue }
        $seen[$k] = 1
        if ($seen.Count -gt 10) { break }
        $snip = $s
        if ($snip.Length -gt 220) { $snip = $snip.Substring(0, 220) + '...' }
        Add-F -Kaynak ('Bellek stringi: ' + $label + ' (wmic)') -Ad 'wmic ile program baslatma' -Yol $snip -Skor $sc -Var 'Bilinmiyor' -Not ('komut: ' + $snip + ' (PID ' + $procId + ') - exe/uzantisiz dosya/ADS baslatmak icin kullanilir')
    }
}
function Scan-MemProcess([string]$label, [int]$procId, [string]$rx, [string]$mode) {
    Log ('   bellek taraniyor: ' + $label + ' (PID ' + $procId + ')') 'DarkGray'
    $list = $null
    try { $list = [HkNative]::MemStrings($procId, $rx, 5, $true, $true, $false, [long]734003200) } catch { $list = $null }
    if ($null -eq $list) { $script:MemFail++; [void]$script:MemFailNames.Add($label); Add-Cov 'Process bellegi okunamadi (korumali/AV engeli?)' $label; return }
    $script:MemOk++
    if ($mode -eq 'dns') { Analyze-MemDns $label $list $procId; return }
    Analyze-MemExe $label $list $procId
    if ($mode -eq 'dps') { Analyze-MemDps $label $list $procId }
    if ($mode -eq 'wmic') { Analyze-MemWmic $label $list $procId }
}

function Get-DelTime($x) {
    if ($x.Silinme) { return $x.Silinme }
    if ($x.Var -eq 'Hayir') {
        $k = ([string]$x.Ad).ToLower()
        if ($script:UsnDel.ContainsKey($k)) { return $script:UsnDel[$k] }
        foreach ($b in $script:BinItems) { if ($b.Orijinal -ieq $x.Yol) { return $b.Silinme } }
    }
    return $null
}
$script:ClassHitMap = @{}
function Show-ClassHits([string]$yol, [bool]$fileOnly = $false) {
    # 10. adim: hile izi bulunan jar icin, hangi class/dosyada hangi isim bulundu (tek tek)
    try {
        $k = $yol.ToLower()
        if (-not $script:ClassHitMap.ContainsKey($k)) { return }
        $lines = @($script:ClassHitMap[$k])
        Log ('      HILE BULUNAN CLASS/DOSYALAR (' + $lines.Count + '):') 'Red' $fileOnly
        foreach ($cl in $lines) { Log ('         - ' + $cl) 'Yellow' $fileOnly }
    } catch {}
}
function Show-Finding($x) {
    $col = 'Yellow'
    if ($x.Skor -ge 60) { $col = 'Red' }
    Log '' 'Gray'
    $vtxt = ''
    if ($x.Skor -lt 60) { $vtxt = ' - tek basina kanit degil, DOGRULA' }
    Log ('   [%' + $x.Skor + ' hile ihtimali' + $vtxt + '] ' + $x.Ad) $col
    Log ('      Konum            : ' + $x.Yol) 'Gray'
    $durum = 'DURUYOR'
    if ($x.Var -eq 'Hayir') {
        $dt = Get-DelTime $x
        if ($dt) { $durum = 'SILINMIS - silinme zamani: ' + (Fmt $dt) } else { $durum = 'SILINMIS - silinme zamani kayitlarda bulunamadi' }
    } elseif ($x.Var -eq 'Bilinmiyor') {
        $durum = 'bilinmiyor (yol kaydi yok)'
    }
    Log ('      Durum            : ' + $durum) 'Gray'
    Log ('      En son calistirma: ' + (Fmt $x.Son)) 'Gray'
    Log ('      Ilk gorulme/indirme: ' + (Fmt $x.Ilk)) 'Gray'
    Log ('      Bulundugu yer    : ' + $x.Kaynak) 'DarkGray'
    if ($x.Not) { Log ('      Detay            : ' + $x.Not) 'DarkGray' }
    Show-ClassHits ([string]$x.Yol) $false
}
function Start-Sec {
    $script:SecF0 = $script:HkFnd.Count
    $script:SecS0 = $script:Sys.Count
}
function Show-Section {
    $secA = 0
    $secN = 0
    try { $secA = [int]$script:SecS0; $secN = [int]$script:Sys.Count } catch { $secA = 0; $secN = 0 }
    for ($i = $secA; $i -lt $secN; $i++) {
        $s = $script:Sys[$i]
        if ($null -eq $s) { continue }
        if ($s.Skor -lt 15 -and $s.Baslik -like 'Gorev kayit*') { continue }
        $zt = ''
        if ($s.Zaman) { $zt = ' [' + (Fmt $s.Zaman) + ']' }
        Log ('   ! [%' + $s.Skor + '] ' + $s.Baslik + $zt) 'Yellow'
        Log ('        ' + $s.Aciklama) 'DarkGray'
        if ($s.Durum) { Log ('        Durum          : ' + $s.Durum) 'DarkGray' }
        if ($s.Degisim) { Log ('        SON ELLE DEGISIM: ' + (Fmt $s.Degisim)) 'Cyan' }
    }
    $items = @()
    for ($i = $script:SecF0; $i -lt $script:HkFnd.Count; $i++) { $items += $script:HkFnd[$i] }
    $sel = @($items | Where-Object { $_.Skor -ge 30 -and -not $_.Benign } | Sort-Object -Property @{ Expression = 'Skor'; Descending = $true }, @{ Expression = 'Son'; Descending = $true })
    $rest = $items.Count - $sel.Count
    if ($sel.Count -eq 0 -and $script:Sys.Count -le $script:SecS0) { Log '   -> supheli bulgu yok' 'Green' }
    $shownKeys = @{}
    $dupN = 0
    foreach ($x in $sel) {
        $dk = (([string]$x.Ad) + '|' + ([string]$x.Yol)).ToLower()
        if ($shownKeys.ContainsKey($dk)) { $dupN++; continue }
        $shownKeys[$dk] = 1
        Show-Finding $x
    }
    if ($dupN -gt 0) { Log ('   (' + $dupN + ' ayni bulgu tekrar kaydi gizlendi)') 'DarkGray' }
    if ($rest -gt 0) { Log ('   (' + $rest + ' dusuk guvenli kayit daha - sonda TAM LISTE bolumunde)') 'DarkGray' }
}

function Show-Item($m, [string]$color, [bool]$fileOnly = $false) {
    Log '' 'Gray' $fileOnly
    Log ('[%' + $m.Skor + '] ' + $m.Ad) $color $fileOnly
    Log ('   Yer            : ' + $m.Yol) 'Gray' $fileOnly
    $durum = 'DURUYOR'
    if ($m.Var -eq 'Hayir') {
        if ($m.Silinme) { $durum = 'SILINMIS - silinme zamani: ' + (Fmt $m.Silinme) } else { $durum = 'SILINMIS (silinme zamani kayitlarda bulunamadi)' }
    } elseif ($m.Var -eq 'Bilinmiyor') {
        $durum = 'bilinmiyor (yol kaydi yok)'
    }
    Log ('   Durum          : ' + $durum) 'Gray' $fileOnly
    Log ('   Son kullanim   : ' + (Fmt $m.Son) + '     Ilk gorulme/indirme: ' + (Fmt $m.Ilk)) 'Gray' $fileOnly
    Log ('   Kaynaklar      : ' + $m.Kaynaklar) 'Gray' $fileOnly
    if ($m.Not) { Log ('   Detay          : ' + $m.Not) 'DarkGray' $fileOnly }
    Show-ClassHits ([string]$m.Yol) $fileOnly
}

# =====================================================================
Log '===================================================================' 'Green'
Log '  HileKiran - Minecraft hile / iz analizi' 'Green'
Log ('  Baslangic: ' + (Get-Date)) 'Green'
Log '  Not: Sadece bu bilgisayarda calisir, veri gondermez, hicbir seyi silmez.' 'DarkGray'
Log '===================================================================' 'Green'
if ($PSVersionTable.PSVersion.Major -lt 5) { Log 'UYARI: PowerShell 5+ gerekli, bazi kontroller calismayabilir.' 'Yellow' }
if (-not $script:HkOk) { Log 'UYARI: yardimci modul derlenemedi; Prefetch saatleri/USB/BAM yol cozumu kisitli olabilir.' 'Yellow' } else { Log 'Yardimci modul (Prefetch/USN/ADS cozumleyici): hazir.' 'DarkGray' }

# =====================================================================
# HILE AVI MODU ve paylasilan yardimcilar (adimlardan once tanimlanir)
# =====================================================================
$jarCs = @'
using System;
using System.IO;
using System.IO.Compression;
using System.Text;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using System.Threading.Tasks;
public class HkJarRes {
    public HashSet<string> Terms = new HashSet<string>();
    public HashSet<string> Brands = new HashSet<string>();
    public StringBuilder MetaSb = new StringBuilder();
    public bool Plugin;
    public string Pkg = "";
    public int Classes;
    public int Short;
    public int Scanned;
    public int Nested;
    public int TextScanned;
    public bool TimedOut;
    public bool Error;
    public string EncReason = "";
    public int BadMagic;
    public HashSet<string> ObfMarks = new HashSet<string>();
    public List<string> NativeLibs = new List<string>();
    public List<string> HiEnt = new List<string>();
    public string Meta { get { return MetaSb.ToString(); } }
}
public static class HkJar {
    static Encoding Lat = Encoding.GetEncoding(28591);
    static Dictionary<string, Regex> Cache = new Dictionary<string, Regex>();
    static Regex RxPlugin = new Regex(@"^(plugin\.yml|bungee\.yml|paper-plugin\.yml|velocity-plugin\.json)$", RegexOptions.IgnoreCase);
    static Regex RxMeta = new Regex(@"^(fabric\.mod\.json|quilt\.mod\.json|mcmod\.info|META-INF/mods\.toml|META-INF/neoforge\.mods\.toml)$", RegexOptions.IgnoreCase);
    static Regex RxText = new Regex(@"\.(json|txt|cfg|toml|properties|yml|yaml)$", RegexOptions.IgnoreCase);
    static Regex Get(string pat) {
        lock (Cache) {
            Regex r;
            if (!Cache.TryGetValue(pat, out r)) {
                r = new Regex(pat, RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled);
                Cache[pat] = r;
            }
            return r;
        }
    }
    static Regex RxObf = new Regex(@"ALLATORIxDEMO|Allatori|Zelix KlassMaster|Stringer Java|DashO|Paramorphism|Skidfuscator|qProtect|Branchlock|Binscure|JNIC|Superblaze|obfuscated by", RegexOptions.None);
    static Regex RxNative = new Regex(@"\.(dll|so|dylib|jnilib)$", RegexOptions.IgnoreCase);
    static Regex RxBlob = new Regex(@"\.(bin|dat|enc|data|pak|res|cache|key)$", RegexOptions.IgnoreCase);
    public static double Entropy(byte[] b, int max) {
        if (b == null || b.Length == 0) { return 0.0; }
        int n = Math.Min(b.Length, max);
        long[] cnt = new long[256];
        for (int i = 0; i < n; i++) { cnt[b[i]]++; }
        double h = 0.0;
        for (int i = 0; i < 256; i++) {
            if (cnt[i] == 0) { continue; }
            double p = (double)cnt[i] / n;
            h -= p * Math.Log(p, 2.0);
        }
        return h;
    }
    public static string[] PeSections(byte[] b) {
        List<string> r = new List<string>();
        try {
            if (b == null || b.Length < 256 || b[0] != 0x4D || b[1] != 0x5A) { return r.ToArray(); }
            int pe = BitConverter.ToInt32(b, 0x3C);
            if (pe < 0 || pe + 24 > b.Length) { return r.ToArray(); }
            if (b[pe] != 0x50 || b[pe + 1] != 0x45) { return r.ToArray(); }
            int nsec = BitConverter.ToUInt16(b, pe + 6);
            int optSize = BitConverter.ToUInt16(b, pe + 20);
            int sec = pe + 24 + optSize;
            for (int i = 0; i < nsec && i < 40; i++) {
                int o = sec + i * 40;
                if (o + 8 > b.Length) { break; }
                r.Add(System.Text.Encoding.ASCII.GetString(b, o, 8).TrimEnd('\0'));
            }
        } catch { }
        return r.ToArray();
    }
    static string ZipEnc(FileStream fs, long len) {
        int tail = (int)Math.Min(len, 65557L);
        byte[] t = new byte[tail];
        fs.Seek(len - tail, SeekOrigin.Begin);
        int got = 0;
        while (got < tail) { int c = fs.Read(t, got, tail - got); if (c <= 0) { break; } got += c; }
        int eocd = -1;
        for (int i = got - 22; i >= 0; i--) {
            if (t[i] == 0x50 && t[i + 1] == 0x4B && t[i + 2] == 0x05 && t[i + 3] == 0x06) { eocd = i; break; }
        }
        if (eocd < 0) { return ""; }
        int total = BitConverter.ToUInt16(t, eocd + 10);
        uint cdSize = BitConverter.ToUInt32(t, eocd + 12);
        uint cdOff = BitConverter.ToUInt32(t, eocd + 16);
        if (cdSize == 0xFFFFFFFFu || cdOff == 0xFFFFFFFFu || total == 0xFFFF) { return ""; }
        if (cdSize > 33554432u || (long)cdOff + (long)cdSize > len) { return ""; }
        byte[] cd = new byte[cdSize];
        fs.Seek((long)cdOff, SeekOrigin.Begin);
        got = 0;
        while (got < cd.Length) { int c2 = fs.Read(cd, got, cd.Length - got); if (c2 <= 0) { break; } got += c2; }
        int pos = 0;
        int n = 0;
        int enc = 0;
        int aes = 0;
        while (pos + 46 <= got && cd[pos] == 0x50 && cd[pos + 1] == 0x4B && cd[pos + 2] == 0x01 && cd[pos + 3] == 0x02) {
            int flags = BitConverter.ToUInt16(cd, pos + 8);
            int method = BitConverter.ToUInt16(cd, pos + 10);
            int nl = BitConverter.ToUInt16(cd, pos + 28);
            int el = BitConverter.ToUInt16(cd, pos + 30);
            int cl = BitConverter.ToUInt16(cd, pos + 32);
            n++;
            if ((flags & 1) != 0) { enc++; }
            if (method == 99) { aes++; }
            pos += 46 + nl + el + cl;
            if (n > 200000) { break; }
        }
        if (enc > 0 || aes > 0) {
            string a = "";
            if (aes > 0) { a = " (AES)"; }
            return "sifreli zip: " + Math.Max(enc, aes) + "/" + n + " dosya sifreli" + a;
        }
        return "";
    }
    static string RarEnc(FileStream fs, long len) {
        byte[] b = new byte[64];
        fs.Seek(0, SeekOrigin.Begin);
        int got = fs.Read(b, 0, 64);
        if (got < 20) { return ""; }
        if (b[4] == 0x1A && b[5] == 0x07 && b[6] == 0x01 && b[7] == 0x00) {
            int p = 12;
            int shift = 0;
            while (p < got) { byte x = b[p]; p++; shift += 7; if ((x & 0x80) == 0) { break; } if (shift > 28) { break; } }
            if (p < got) {
                int type = 0;
                shift = 0;
                while (p < got) { byte y = b[p]; p++; type |= (y & 0x7F) << shift; shift += 7; if ((y & 0x80) == 0) { break; } if (shift > 28) { break; } }
                if (type == 4) { return "sifreli rar: basliklar sifreli (icerik listesi bile gorunmuyor)"; }
            }
        } else if (b[4] == 0x1A && b[5] == 0x07 && b[6] == 0x00) {
            int flags = b[10] | (b[11] << 8);
            if (b[9] == 0x73 && (flags & 0x0080) != 0) { return "sifreli rar: basliklar sifreli"; }
        }
        return "";
    }
    static string SevenEnc(FileStream fs, long len) {
        int tail = (int)Math.Min(len, 65536L);
        byte[] t = new byte[tail];
        fs.Seek(len - tail, SeekOrigin.Begin);
        int got = 0;
        while (got < tail) { int c = fs.Read(t, got, tail - got); if (c <= 0) { break; } got += c; }
        for (int i = 0; i + 3 < got; i++) {
            if (t[i] == 0x06 && t[i + 1] == 0xF1 && t[i + 2] == 0x07 && t[i + 3] == 0x01) { return "sifreli 7z (AES kodlayici bulundu)"; }
        }
        return "";
    }
    public static string EncInfo(string path) {
        try {
            using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete)) {
                long len = fs.Length;
                if (len < 32) { return ""; }
                byte[] head = new byte[8];
                int hn = fs.Read(head, 0, 8);
                if (hn < 8) { return ""; }
                if (head[0] == 0x50 && head[1] == 0x4B) { return ZipEnc(fs, len); }
                if (head[0] == 0x52 && head[1] == 0x61 && head[2] == 0x72 && head[3] == 0x21) { return RarEnc(fs, len); }
                if (head[0] == 0x37 && head[1] == 0x7A && head[2] == 0xBC && head[3] == 0xAF) { return SevenEnc(fs, len); }
            }
        } catch { }
        return "";
    }
    static byte[] ReadAll(ZipArchiveEntry e, int len) {
        try {
            using (Stream s = e.Open()) {
                byte[] b = new byte[len];
                int off = 0;
                while (off < len) {
                    int c = s.Read(b, off, len - off);
                    if (c <= 0) break;
                    off += c;
                }
                if (off != len) Array.Resize(ref b, off);
                return b;
            }
        } catch { return null; }
    }
    static string ReadText(ZipArchiveEntry e) {
        try {
            using (StreamReader sr = new StreamReader(e.Open(), Encoding.UTF8)) { return sr.ReadToEnd(); }
        } catch { return null; }
    }
    static void AddMatches(Regex rx, string t, HashSet<string> set) {
        foreach (Match m in rx.Matches(t)) { set.Add(m.Value.ToLowerInvariant().Replace(" ", "")); }
    }
    static void Walk(ZipArchive z, HkJarRes r, Regex term, Regex brand, Regex pkg, System.Diagnostics.Stopwatch sw, int maxSec, int depth) {
        foreach (ZipArchiveEntry e in z.Entries) {
            if (sw.Elapsed.TotalSeconds > maxSec) { r.TimedOut = true; return; }
            string n = e.FullName;
            if (RxPlugin.IsMatch(n)) r.Plugin = true;
            if (r.NativeLibs.Count < 5 && RxNative.IsMatch(n)) { r.NativeLibs.Add(n); }
            if (r.Pkg.Length == 0) {
                Match pm = pkg.Match(n);
                if (pm.Success) r.Pkg = pm.Groups[1].Value;
            }
            if (n.EndsWith(".class", StringComparison.Ordinal)) {
                r.Classes++;
                string bn = Path.GetFileNameWithoutExtension(n);
                if (bn.Length <= 2) r.Short++;
                long len = e.Length;
                if (r.Scanned < 2500 && len > 0 && len < 1048576) {
                    r.Scanned++;
                    byte[] buf = ReadAll(e, (int)len);
                    if (buf != null) {
                        if (buf.Length >= 4 && !(buf[0] == 0xCA && buf[1] == 0xFE && buf[2] == 0xBA && buf[3] == 0xBE)) { r.BadMagic++; }
                        string t = Lat.GetString(buf);
                        AddMatches(term, t, r.Terms);
                        AddMatches(brand, t, r.Brands);
                        foreach (Match om in RxObf.Matches(t)) { r.ObfMarks.Add(om.Value); }
                    }
                }
            } else if (RxBlob.IsMatch(n) && e.Length > 20000 && e.Length < 4194304 && r.HiEnt.Count < 3) {
                byte[] bb = ReadAll(e, (int)e.Length);
                if (bb != null && Entropy(bb, bb.Length) > 7.9) { r.HiEnt.Add(n + " (" + e.Length + " bayt)"); }
            } else if (RxMeta.IsMatch(n) && e.Length < 65536) {
                string tx = ReadText(e);
                if (tx != null) r.MetaSb.Append(' ').Append(tx);
            } else if (depth < 2 && n.EndsWith(".jar", StringComparison.OrdinalIgnoreCase) && e.Length > 0 && e.Length < 31457280 && r.Nested < 25) {
                r.Nested++;
                try {
                    byte[] ib = ReadAll(e, (int)e.Length);
                    if (ib != null) {
                        using (MemoryStream ms = new MemoryStream(ib)) {
                            using (ZipArchive inner = new ZipArchive(ms, ZipArchiveMode.Read)) {
                                Walk(inner, r, term, brand, pkg, sw, maxSec, depth + 1);
                            }
                        }
                    }
                } catch { }
            } else if (RxText.IsMatch(n) && e.Length > 20 && e.Length < 262144 && r.TextScanned < 150) {
                r.TextScanned++;
                string tx2 = ReadText(e);
                if (tx2 != null) {
                    AddMatches(term, tx2, r.Terms);
                    AddMatches(brand, tx2, r.Brands);
                }
            }
        }
    }
    public static HkJarRes Scan(string path, string termPat, string brandPat, string pkgPat, int maxSeconds) {
        HkJarRes r = new HkJarRes();
        r.EncReason = EncInfo(path);
        try {
            Regex term = Get(termPat);
            Regex brand = Get(brandPat);
            Regex pkg = Get(pkgPat);
            System.Diagnostics.Stopwatch sw = System.Diagnostics.Stopwatch.StartNew();
            using (ZipArchive z = ZipFile.OpenRead(path)) {
                Walk(z, r, term, brand, pkg, sw, maxSeconds, 0);
            }
        } catch { r.Error = true; }
        return r;
    }
    public static HkJarRes[] ScanMany(string[] paths, string termPat, string brandPat, string pkgPat, int maxSeconds, int threads) {
        HkJarRes[] res = new HkJarRes[paths.Length];
        ParallelOptions po = new ParallelOptions();
        po.MaxDegreeOfParallelism = threads;
        Parallel.For(0, paths.Length, po, delegate(int i) {
            res[i] = Scan(paths[i], termPat, brandPat, pkgPat, maxSeconds);
        });
        return res;
    }
}
'@
$script:ModTermPat = 'kill ?aura|aim ?assist|trigger ?bot|auto ?clicker|click ?gui|self ?destruct|scaffold(?!ing)|auto ?totem|auto ?inv ?totem|chest ?esp|chest ?stealer|anti ?knockback|anti ?kb|jump ?reset|wtap|block ?hit(?!result)|auto ?pot(?!ion)|no ?slow ?down|auto ?crystal|crystal ?aura|anchor ?(?:macro|aura)|auto ?anchor|shield ?breaker|auto ?d ?tap|stun ?slam|mace ?swap|silent ?aim|target ?strafe|elytra ?target|hitbox ?expand|pearl ?catch'
$script:BrandRx = New-Object System.Text.RegularExpressions.Regex ('astralux|astraulex|helsing ?client|shoreline ?client|vanadium ?client|nyrex|noxx ?client|alycone|luminex ?(?:beta|client)|marlow ?client|zoomies ?client|catlean|wurst ?client|doomsday ?client|liquidbounce|meteor ?client|rusherhack|vape ?v4|achilles ?client|calcium ?client|xenon ?client|krypton ?client|glazed ?client|hellion ?client|prestige ?client|phantom ?client|aristois|huzuni|impact ?client|future ?client|sigma ?client|rise ?client|tenacity|astolfo|novoline|remix ?client|exhibition ?client|bleach ?hack|salhack|kami ?blue|phobos ?client|3arthh4ck|gamesense|konas ?client|pyro ?client|dortware|crystalware|sloth ?client|coffee ?client|trollhack|forgehax|thunder ?hack|hanabi ?client|azura ?client|pandaware|moon ?client|flux ?client|tenacity ?client|zeroday ?client|fdp ?client|alien ?client|cosmos ?client|nightix|blade ?reload|velka|aethereal|dimasik ?client|wild ?client|delta ?client|flow ?client|system ?dlc|phobia ?client|nursultan|evaware|neverlose|catlavan|wexside|zenith ?client|punch ?client|deluxe ?client|doomsday ?client', ([System.Text.RegularExpressions.RegexOptions]'IgnoreCase, Compiled'))
$script:PkgRx = '(?i)^(meteordevelopment/meteorclient|net/wurstclient|net/ccbluex/liquidbounce|me/zeroeightsix/kami)'
function Get-Brands([string]$text, $dict) {
    foreach ($m in $script:BrandRx.Matches($text)) { $dict[($m.Value.ToLower() -replace ' ', '')] = 1 }
}
$script:ModTermRx = New-Object System.Text.RegularExpressions.Regex ($script:ModTermPat, ([System.Text.RegularExpressions.RegexOptions]'IgnoreCase, Compiled'))
function Get-Terms([string]$text, $dict) {
    foreach ($m in $script:ModTermRx.Matches($text)) { $dict[($m.Value.ToLower() -replace ' ', '')] = 1 }
}

$knownNat = '(?i)^(lwjgl|glfw|openal|jemalloc|stb|tinyfd|nanovg|nfd|jna|sqlite|libusb|vcruntime|msvcp|concrt|ucrtbase|api-ms)'
function Has-Any([string]$t, [string[]]$needles, [bool]$ic = $false) {
    $cmp = [StringComparison]::Ordinal
    if ($ic) { $cmp = [StringComparison]::OrdinalIgnoreCase }
    foreach ($nd in $needles) { if ($t.IndexOf($nd, $cmp) -ge 0) { return $true } }
    return $false
}
$script:ObfList = New-Object System.Collections.Generic.List[object]
$script:ObfSeen = @{}
function Add-ObfNote([string]$path, [string]$reason) {
    if (-not $reason) { return }
    $k = ($path + '|' + $reason).ToLower()
    if ($script:ObfSeen.ContainsKey($k)) { return }
    $script:ObfSeen[$k] = 1
    [void]$script:ObfList.Add([pscustomobject]@{ Yol = $path; Neden = $reason })
}
function Get-PackInfo($b) {
    $res = @{ Reason = ''; Bonus = 0 }
    if ($null -eq $b -or $b.Length -lt 4096) { return $res }
    $secs = @()
    try { $secs = @([HkJar]::PeSections($b)) } catch {}
    $pk = @()
    foreach ($sn in $secs) { if ($sn -match '(?i)^\.?(upx\d|vmp\d|themida|winlice|enigma\d?|aspack|adata|petite|mpress\d|nsp\d|boom|perplex|pec\d?|yoda|rlpack|kkrunchy|neolite|molebox|obsidium|armadillo|svkp|ezip)') { $pk += $sn } }
    $ent = 0.0
    try { $ent = [HkJar]::Entropy($b, 8388608) } catch {}
    $parts = @()
    if ($pk.Count -gt 0) { $parts += ('paketleyici/koruyucu bolum adlari: ' + ($pk -join ', ')); $res.Bonus = 25 }
    if ($ent -gt 7.4 -and $b.Length -gt 200000) { $parts += ('yuksek entropi ' + [Math]::Round($ent, 2) + ' (paketlenmis/sifreli icerik olabilir)'); $res.Bonus = $res.Bonus + 15 }
    if ($parts.Count -gt 0) { $res.Reason = ($parts -join '; ') }
    return $res
}
function Show-ObfSummary {
    $items = @()
    try { $items = @($script:ObfList.ToArray()) } catch { $items = @() }
    Log '' 'Gray'
    Log '=================== SIFRELI / OBFUSCATE / PAKETLI DOSYALAR ===================' 'Magenta'
    if ($items.Count -eq 0) {
        Log '   Bu taramada sifreli arsiv, sifreli class, obfuscator imzasi veya paketli exe bulunmadi.' 'Green'
        return
    }
    Log ('   ' + $items.Count + ' kayit. Icerigi gizlendigi/okunamadigi icin elle bakman gerekebilir:') 'Yellow'
    foreach ($it in @($items | Select-Object -First 60)) {
        Log ('   ' + $it.Yol) 'Yellow'
        Log ('        -> ' + $it.Neden) 'DarkYellow'
    }
    if ($items.Count -gt 60) { Log ('   ... ve ' + ($items.Count - 60) + ' kayit daha.') 'DarkGray' }
}
function Add-HistVals($val, $list) {
    foreach ($v in @($val)) {
        if ($v -is [byte[]]) {
            foreach ($z in ([Text.Encoding]::Unicode.GetString($v) -split "`0")) { if ($z) { [void]$list.Add($z) } }
        } elseif ($v) {
            [void]$list.Add([string]$v)
        }
    }
}
function Invoke-NameDeep {
Step '[17+/17] V) OZEL TARAMA: adi bilinen bir hile istemcisiyle eslesen dosyalarin icerigi (sure siniri yok)...'
Start-Sec
$vList = @($script:NameDeep)
Log ('   isim eslesen ' + $vList.Count + ' dosya ozel taramaya alindi.') 'DarkGray'
foreach ($vp in $vList) {
    if (-not (Test-Path -LiteralPath $vp)) { continue }
    $vf = $null
    try { $vf = Get-Item -LiteralPath $vp -Force -ErrorAction Stop } catch { continue }
    if (-not $vf -or $vf.PSIsContainer) { continue }
    $vext = $vf.Extension.ToLower()
    $vh = Get-NameHit $vf.Name $false
    $vhn = ''
    if ($vh) { $vhn = $vh.Name }
    Write-Host ('   [ozel tarama] ' + $vp) -ForegroundColor DarkGray
    $tk = @()
    $bk = @()
    $why = New-Object System.Collections.Generic.List[string]
    $sc = 40
    $info = ''
    [void]$why.Add('dosya adi bilinen hile istemcisiyle eslesti: ' + $vhn)
    if ($vext -eq '.jar' -or $vext -eq '.zip') {
        $classes = 0
        $short = 0
        $pkg = ''
        $plug = $false
        $nested = 0
        $meta = ''
        $got = $false
        if ($jarCsOk) {
            $vx = $null
            try { $vx = [HkJar]::Scan($vp, $script:ModTermPat, $script:BrandRx.ToString(), $script:PkgRx, 86400) } catch {}
            if ($vx -and -not $vx.Error) {
                $got = $true
                $tk = @($vx.Terms)
                $bk = @($vx.Brands)
                $classes = $vx.Classes
                $short = $vx.Short
                $pkg = $vx.Pkg
                $plug = $vx.Plugin
                $nested = $vx.Nested
                $meta = $vx.Meta
            }
        } else {
            $vd = Deep-Jar $vp
            $got = $true
            $tk = @($vd.Terms.Keys)
            $bk = @($vd.Brands.Keys)
            $classes = $vd.Classes
            $short = $vd.Short
            $pkg = $vd.Pkg
            $plug = $vd.Plugin
            $nested = $vd.Nested
            $meta = $vd.Meta
        }
        if (-not $got) {
            [void]$why.Add('icerik OKUNAMADI (bozuk/sifreli arsiv olabilir)')
        } else {
            if ($pkg) { $sc += 30; [void]$why.Add('bilinen hile istemcisi paket yolu: ' + $pkg) }
            $mh = Get-NameHit $meta $false
            if ($mh) { $sc += 15; [void]$why.Add('mod bilgisinde hile ismi: ' + $mh.Name) }
            if ($classes -ge 20 -and ($short / [double]$classes) -ge 0.6) { $sc += 20; [void]$why.Add('obfuscate edilmis gorunuyor (' + $short + '/' + $classes + ' sinif adi 1-2 harf)') }
            if ($plug) { [void]$why.Add('plugin.yml var: sunucu eklentisi olabilir') }
            if ($vx) {
                if ($vx.EncReason) { $sc += 25; [void]$why.Add($vx.EncReason); Add-ObfNote $vp $vx.EncReason }
                if ($vx.BadMagic -gt 0) { $sc += 40; [void]$why.Add('class dosyalarinin ' + $vx.BadMagic + ' tanesi gecersiz (sifreli olabilir)'); Add-ObfNote $vp ('sifreli/bozuk class dosyasi: ' + $vx.BadMagic) }
                if ($vx.ObfMarks.Count -gt 0) { $sc += 15; $omv = (@($vx.ObfMarks) -join ', '); [void]$why.Add('obfuscator imzasi: ' + $omv); Add-ObfNote $vp ('obfuscator imzasi: ' + $omv) }
                if ($vx.NativeLibs.Count -gt 0) { $sc += 10; $nlv = (@($vx.NativeLibs) -join ', '); [void]$why.Add('jar icinde yerel kutuphane: ' + $nlv); Add-ObfNote $vp ('jar icinde yerel kutuphane (dll/so): ' + $nlv) }
                if ($vx.HiEnt.Count -gt 0) { $sc += 15; $hev = (@($vx.HiEnt) -join ', '); [void]$why.Add('yuksek entropili veri dosyasi: ' + $hev); Add-ObfNote $vp ('yuksek entropili veri dosyasi: ' + $hev) }
            }
            if ($classes -ge 20 -and ($short / [double]$classes) -ge 0.6) { Add-ObfNote $vp ('obfuscate edilmis (' + $short + '/' + $classes + ' sinif adi 1-2 harf)') }
            $info = ' | ' + $classes + ' class, ic ice jar: ' + $nested
        }
    } elseif (@('.exe', '.dll', '.scr', '.com') -contains $vext) {
        if ($vf.Length -gt 125829120) {
            [void]$why.Add('dosya 120 MB ustu, icerik taramasi atlandi'); Add-Cov 'Dosya >120 MB: icerik taranmadi (ozel tarama)' $vp
        } else {
            $vb = $null
            try { $vb = [IO.File]::ReadAllBytes($vp) } catch {}
            if ($null -eq $vb) {
                [void]$why.Add('icerik OKUNAMADI')
            } else {
                $vt = [Text.Encoding]::GetEncoding(28591).GetString($vb)
                $tkh = @{}
                $bkh = @{}
                Get-Terms $vt $tkh
                Get-Brands $vt $bkh
                if ($vb.Length -lt 20971520) {
                    $vu = [Text.Encoding]::Unicode.GetString($vb)
                    Get-Terms $vu $tkh
                    Get-Brands $vu $bkh
                }
                $tk = @($tkh.Keys)
                $bk = @($bkh.Keys)
                $vJni = Has-Any $vt @('JNI_GetCreatedJavaVMs', 'GetCreatedJavaVMs', 'jvmtiEnv', 'AttachCurrentThread')
                $vMc = Has-Any $vt @('net/minecraft/client', 'net.minecraft.client', 'class_310', 'class_746', 'Lnet/minecraft/', 'net/minecraft/class_', 'com/mojang/blaze3d')
                $vInj = ((Has-Any $vt @('WriteProcessMemory')) -and (Has-Any $vt @('CreateRemoteThread', 'NtCreateThreadEx', 'RtlCreateUserThread', 'QueueUserAPC', 'SetWindowsHookEx')) -and (Has-Any $vt @('javaw', 'java.exe', 'Minecraft') $true))
                if ($vJni -and $vMc) { $sc += 40; [void]$why.Add('Minecraft sinif adlari + JNI/JVMTI: Java disindan oyuna baglanan program/DLL') }
                if ($vInj) { $sc += 45; [void]$why.Add('enjektor belirtileri (WriteProcessMemory + uzak thread + javaw/Minecraft)') }
                $pkV = Get-PackInfo $vb
                if ($pkV.Reason) { $sc += $pkV.Bonus; [void]$why.Add($pkV.Reason); Add-ObfNote $vp $pkV.Reason }
                $vsg = 'imzasiz'
                if (Test-Signed $vp) { $vsg = 'imzali' }
                $info = ' | ' + $vsg
            }
        }
    } elseif (@('.bat', '.cmd', '.ps1', '.vbs', '.txt', '.json', '.cfg', '.toml', '.yml', '.yaml', '.ini', '.conf', '.properties') -contains $vext) {
        $vtx = $null
        if ($vf.Length -le 5242880) { try { $vtx = [IO.File]::ReadAllText($vp) } catch {} }
        if ($vtx) {
            $tkh = @{}
            $bkh = @{}
            Get-Terms $vtx $tkh
            Get-Brands $vtx $bkh
            $tk = @($tkh.Keys)
            $bk = @($bkh.Keys)
        } else {
            [void]$why.Add('icerik okunamadi veya 5 MB ustu')
        }
    } else {
        [void]$why.Add('dosya turu (' + $vext + ') icerigi okunamiyor; elle ac ve bak')
    }
    if ($tk.Count -ge 3) { $sc += 40 } elseif ($tk.Count -eq 2) { $sc += 30 } elseif ($tk.Count -eq 1) { $sc += 15 }
    if ($tk.Count -gt 0) { [void]$why.Add('icerikte hile modulu stringleri (' + $tk.Count + ' adet): ' + ($tk -join ', ')) }
    if ($bk.Count -gt 0) { $sc += 20; [void]$why.Add('icerikte bilinen hile istemcisi ismi: ' + ($bk -join ', ')) }
    if ($tk.Count -gt 0 -or $bk.Count -gt 0) {
        Write-Host ('      -> ICERIK KANITI VAR: ' + $tk.Count + ' modul ismi, ' + $bk.Count + ' istemci ismi') -ForegroundColor Red
    } else {
        Write-Host '      -> isim eslesti ama icerikte modul/istemci ismi bulunamadi (obfuscate/sifreli olabilir, ya da yanlis eslesme)' -ForegroundColor Yellow
    }
    Add-F -Kaynak 'Ozel tarama (isim eslesen dosya)' -Ad ('ozel: ' + $vf.Name.ToLower()) -Yol $vp -Skor ([Math]::Min(100, $sc)) -Son $vf.LastWriteTime -Ilk $vf.CreationTime -Var 'Evet' -Not (($why -join '; ') + $info)
}
Show-Section
}
function Scan-BinHunt($bf) {
    $pth = $bf.FullName
    if ((Get-Zone $pth) -eq 'system') { return }
    if ($bf.Name.ToLower() -match $knownNat) { return }
    if ($bf.Length -gt 12582912 -and (Test-Signed $pth)) { Add-Cov 'Imzali buyuk (>12 MB) exe/dll: icerik taranmadi' $bf.FullName; return }
    $b = $null
    try { $b = [IO.File]::ReadAllBytes($pth) } catch { return }
    if ($null -eq $b) { return }
    $t = [Text.Encoding]::GetEncoding(28591).GetString($b)
    $isJni = Has-Any $t @('JNI_GetCreatedJavaVMs', 'GetCreatedJavaVMs', 'jvmtiEnv', 'AttachCurrentThread')
    $isMc = Has-Any $t @('net/minecraft/client', 'net.minecraft.client', 'class_310', 'class_746', 'Lnet/minecraft/', 'net/minecraft/class_', 'com/mojang/blaze3d')
    $isInj = ((Has-Any $t @('WriteProcessMemory')) -and (Has-Any $t @('CreateRemoteThread', 'NtCreateThreadEx', 'RtlCreateUserThread', 'QueueUserAPC', 'SetWindowsHookEx')) -and (Has-Any $t @('javaw', 'java.exe', 'Minecraft') $true))
    $terms = @{}
    $brands = @{}
    $mcRel = ($isJni -or $isMc -or (Has-Any $t @('minecraft', 'javaw', 'lwjgl', 'glfw', 'jvmti') $true))
    if ($b.Length -lt 4194304 -or $mcRel) {
        Get-Terms $t $terms
        Get-Brands $t $brands
        if ($b.Length -lt 8388608) {
            $tu = [Text.Encoding]::Unicode.GetString($b)
            Get-Terms $tu $terms
            Get-Brands $tu $brands
        }
    }
    $tk = @($terms.Keys)
    $bk = @($brands.Keys)
    $sc = 0
    $why = New-Object System.Collections.Generic.List[string]
    if ($tk.Count -ge 3) { $sc += 70 } elseif ($tk.Count -eq 2) { $sc += 50 } elseif ($tk.Count -eq 1) { $sc += 25 }
    if ($tk.Count -gt 0) { [void]$why.Add('icerikte hile modulu stringleri: ' + ($tk -join ', ')) }
    if ($bk.Count -gt 0) { $sc += 35; [void]$why.Add('icerikte bilinen hile istemcisi ismi: ' + ($bk -join ', ')) }
    if ($isJni -and $isMc) { $sc += 40; [void]$why.Add('Minecraft sinif adlari + JNI/JVMTI: Java disindan oyuna baglanan program/DLL') }
    if ($isInj) { $sc += 45; [void]$why.Add('enjektor belirtileri (WriteProcessMemory + uzak thread + javaw/Minecraft)') }
    $pk = Get-PackInfo $b
    if ($pk.Reason) { $sc += $pk.Bonus; [void]$why.Add($pk.Reason) }
    if ($sc -lt 25) { return }
    $sig = Test-Signed $pth
    if ($pk.Reason -and -not $sig) { Add-ObfNote $pth $pk.Reason }
    if ($sig -and $tk.Count -lt 3) { return }
    $sg = 'imzasiz'
    if ($sig) { $sg = 'imzali' }
    Add-F -Kaynak 'Hile avi: exe/dll icerigi' -Ad $bf.Name.ToLower() -Yol $pth -Skor ([Math]::Min(100, $sc)) -Son $bf.LastWriteTime -Ilk $bf.CreationTime -Var 'Evet' -Not (($why -join '; ') + ' | ' + $sg)
}
function Invoke-Hunt {
    Step '[AV] HILE AVI: tum sabit disklerde isim, icerik, indirme izi ve yakin zamanda gelen dosyalar (calistirilmamis dosyalar dahil)...'
    Start-Sec
    $hSw = [Diagnostics.Stopwatch]::StartNew()
    $huntCs = @'
using System;
using System.IO;
using System.Collections.Generic;
using System.Text.RegularExpressions;
public static class HkHunt {
    public static List<string> Sweep(string root, string[] ciPats, string[] csPats, string skipDirRx, string candSkipRx, string[] exts, int maxOut) {
        List<string> res = new List<string>();
        List<Regex> ci = new List<Regex>();
        foreach (string p in ciPats) { ci.Add(new Regex(p, RegexOptions.IgnoreCase | RegexOptions.CultureInvariant)); }
        List<Regex> cs = new List<Regex>();
        foreach (string q in csPats) { cs.Add(new Regex(q, RegexOptions.CultureInvariant)); }
        Regex skip = new Regex(skipDirRx, RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
        Regex candSkip = new Regex(candSkipRx, RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
        HashSet<string> ext = new HashSet<string>(exts, StringComparer.OrdinalIgnoreCase);
        Stack<string> st = new Stack<string>();
        st.Push(root);
        while (st.Count > 0 && res.Count < maxOut) {
            string d = st.Pop();
            string[] files = null;
            string[] dirs = null;
            try { files = Directory.GetFiles(d); } catch { }
            try { dirs = Directory.GetDirectories(d); } catch { }
            if (files != null) {
                foreach (string f in files) {
                    string n = Path.GetFileName(f);
                    bool hit = false;
                    foreach (Regex r1 in ci) { if (r1.IsMatch(n)) { hit = true; break; } }
                    if (!hit) { foreach (Regex r2 in cs) { if (r2.IsMatch(n)) { hit = true; break; } } }
                    if (hit) { res.Add("N|" + f); continue; }
                    string e = Path.GetExtension(f);
                    if (e.Length > 0 && ext.Contains(e)) {
                        if (!candSkip.IsMatch(f) || f.IndexOf("\\Windows\\Temp\\", StringComparison.OrdinalIgnoreCase) >= 0) { res.Add("C|" + f); }
                    }
                }
            }
            if (dirs != null) {
                foreach (string sd in dirs) {
                    try { if ((File.GetAttributes(sd) & FileAttributes.ReparsePoint) != 0) { continue; } } catch { continue; }
                    if (skip.IsMatch(sd)) { continue; }
                    string dn = Path.GetFileName(sd);
                    bool dh = false;
                    foreach (Regex r3 in ci) { if (r3.IsMatch(dn)) { dh = true; break; } }
                    if (!dh) { foreach (Regex r4 in cs) { if (r4.IsMatch(dn)) { dh = true; break; } } }
                    if (dh) { res.Add("D|" + sd); }
                    st.Push(sd);
                }
            }
        }
        return res;
    }
}
'@
    $hOk = $false
    if ('HkHunt' -as [type]) { $hOk = $true } else {
        try { Add-Type -TypeDefinition $huntCs -Language CSharp -ErrorAction Stop; $hOk = $true } catch {}
    }
    if (-not $hOk) { Log '   HATA: hile avi tarayicisi derlenemedi.' 'Red'; return }
    if (-not ('HkJar' -as [type])) {
        try { Add-Type -TypeDefinition $jarCs -Language CSharp -ReferencedAssemblies @('System.IO.Compression', 'System.IO.Compression.FileSystem') -ErrorAction Stop } catch {}
    }
    $script:jarCsOk = [bool]('HkJar' -as [type])

    $drv = @()
    try { $drv = @(Get-CimInstance Win32_LogicalDisk -ErrorAction Stop | Where-Object { $_.DriveType -eq 3 } | ForEach-Object { [string]$_.DeviceID }) } catch {}
    if ($drv.Count -eq 0) { $drv = @([string]$env:SystemDrive) }
    $ciP = [string[]]@($script:StrongRx.ToString(), $script:ClientRx.ToString(), $script:ExtraRx.ToString(), $script:SubRx.ToString())
    $csP = [string[]]@($script:CamelRx.ToString())
    $skipDir = '(?i)\\(Windows\\(WinSxS|System32|SysWOW64|assembly|servicing|Installer|Microsoft\.NET|Fonts|Logs|Boot|Panther|diagnostics|SoftwareDistribution|Speech|InputMethod|Cursors)|\$Recycle\.Bin|System Volume Information|\$WinREAgent|Recovery|MSOCache|Config\.Msi)$'
    $candSkip = '(?i)\\(Windows|Program Files|Program Files \(x86\)|ProgramData\\Microsoft|\$Recycle\.Bin)(\\|$)'
    $exts = [string[]]@('.jar', '.zip', '.rar', '.7z', '.exe', '.dll', '.scr', '.msi', '.bat', '.cmd', '.ps1', '.vbs')
    $allLines = New-Object System.Collections.Generic.List[string]
    foreach ($dv in $drv) {
        Write-Host ('   disk taraniyor: ' + $dv + '\ (tum klasorler gezilir, birkac dakika surebilir)...') -ForegroundColor DarkGray
        $dl = $null
        try { $dl = [HkHunt]::Sweep(($dv + '\'), $ciP, $csP, $skipDir, $candSkip, $exts, 400000) } catch {}
        if ($dl) { foreach ($x in $dl) { [void]$allLines.Add($x) } }
        Write-Host ('   ' + $dv + ' bitti (' + [int]$hSw.Elapsed.TotalSeconds + ' sn, toplam ' + $allLines.Count + ' kayit)') -ForegroundColor DarkGray
    }
    $nFiles = New-Object System.Collections.Generic.List[string]
    $dDirs = New-Object System.Collections.Generic.List[string]
    $cand = New-Object System.Collections.Generic.List[string]
    foreach ($ln in $allLines) {
        if ($ln.Length -lt 3) { continue }
        $tag = $ln.Substring(0, 1)
        $pp = $ln.Substring(2)
        if ($tag -eq 'N') { [void]$nFiles.Add($pp) } elseif ($tag -eq 'D') { [void]$dDirs.Add($pp) } elseif ($tag -eq 'C') { [void]$cand.Add($pp) }
    }
    Log ('   adi hile istemcisiyle eslesen dosya: ' + $nFiles.Count + ', klasor: ' + $dDirs.Count + ', icerik/iz adayi dosya: ' + $cand.Count) 'DarkGray'

    # --- Klasor adi eslesmeleri ---
    $dN = 0
    foreach ($dp in $dDirs) {
        $dN++
        if ($dN -gt 60) { break }
        $cntTxt = ''
        try {
            $fl = [IO.Directory]::GetFiles($dp, '*', [IO.SearchOption]::AllDirectories)
            $cntTxt = ' | icinde ' + $fl.Length + ' dosya: ' + ((@($fl | Select-Object -First 4 | ForEach-Object { Split-Path -Leaf $_ })) -join ', ')
        } catch {}
        $dLeaf = Split-Path -Leaf $dp
        $dh = Get-NameHit $dLeaf $false
        $dhn = ''
        if ($dh) { $dhn = $dh.Name }
        Add-F -Kaynak 'Hile avi: klasor adi' -Ad ('klasor: ' + $dLeaf.ToLower()) -Yol $dp -Skor 55 -Var 'Evet' -Not ('klasor adi bilinen hile istemcisiyle eslesti: ' + $dhn + $cntTxt)
    }
    # --- Dosya adi eslesmeleri ---
    foreach ($np in $nFiles) {
        $nf = $null
        try { $nf = New-Object IO.FileInfo $np } catch { continue }
        $nh = Get-NameHit $nf.Name $false
        $nhn = ''
        if ($nh) { $nhn = $nh.Name }
        Add-NameDeep $np
        Add-F -Kaynak 'Hile avi: dosya adi' -Ad $nf.Name.ToLower() -Yol $np -Skor 55 -Son $nf.LastWriteTime -Ilk $nf.CreationTime -Var 'Evet' -Not ('dosya adi bilinen hile istemcisiyle eslesti: ' + $nhn)
    }
    Show-Section
    Invoke-NameDeep

    # --- Jar/zip icerik taramasi (tum diskte) ---
    Step '[AV] jar/zip icerik taramasi (tum disk, kullanici klasorleri once)...'
    Start-Sec
    $arcAll = New-Object System.Collections.Generic.List[object]
    foreach ($cp in $cand) {
        if ($cp -notmatch '(?i)\.(jar|zip)$') { continue }
        try {
            $fi = New-Object IO.FileInfo $cp
            if ($fi.Length -gt 0 -and $fi.Length -lt 157286400 -and (([int]$fi.Attributes -band 4460544) -eq 0)) { [void]$arcAll.Add($fi) }
        } catch {}
    }
    $arcSorted = @($arcAll | Sort-Object @{ Expression = { if ($_.FullName -match '(?i)\\Users\\') { 0 } else { 1 } } }, Length | Select-Object -First 1000000)
    Log ('   ' + $arcAll.Count + ' jar/zip bulundu, ' + $arcSorted.Count + ' tanesi taranacak.') 'DarkGray'
    if ($script:jarCsOk) {
        $thr = [Math]::Max(2, $script:HkThr)
        $chN = 0
        for ($ci = 0; $ci -lt $arcSorted.Count; $ci += 24) {
            Set-Frac ($ci / [Math]::Max(1, $arcSorted.Count)) ('jar/zip ' + $ci + '/' + $arcSorted.Count)
            $hi = [Math]::Min($ci + 23, $arcSorted.Count - 1)
            $chunk = @($arcSorted[$ci..$hi])
            $paths = [string[]]@($chunk | ForEach-Object { $_.FullName })
            $res = $null
            try { $res = [HkJar]::ScanMany($paths, $script:ModTermPat, $script:BrandRx.ToString(), $script:PkgRx, 86400, $thr) } catch {}
            if ($res) {
                for ($k = 0; $k -lt $paths.Count; $k++) {
                    $x = $res[$k]
                    if (-not $x -or $x.Error -or $x.Plugin) { continue }
                    $tl = @($x.Terms)
                    $bl = @($x.Brands)
                    $sc = 0
                    $why = New-Object System.Collections.Generic.List[string]
                    if ($tl.Count -ge 3) { $sc += 70 } elseif ($tl.Count -eq 2) { $sc += 55 } elseif ($tl.Count -eq 1) { $sc += 30 }
                    if ($tl.Count -gt 0) { [void]$why.Add('icerikte hile modulu stringleri (' + $tl.Count + ' adet): ' + ($tl -join ', ')) }
                    if ($bl.Count -gt 0) { $sc += 35; [void]$why.Add('icerikte bilinen hile istemcisi ismi: ' + ($bl -join ', ')) }
                    if ($x.Pkg) { $sc += 40; [void]$why.Add('bilinen hile istemcisi paket yolu: ' + $x.Pkg) }
                    if ($x.Classes -ge 20 -and ($x.Short / [double]$x.Classes) -ge 0.6) { $sc += 25; [void]$why.Add('obfuscate edilmis gorunuyor (' + $x.Short + '/' + $x.Classes + ' sinif adi 1-2 harf)') }
                    $mh = Get-NameHit $x.Meta $false
                    if ($mh) { $sc += 40; [void]$why.Add('mod bilgisinde hile ismi: ' + $mh.Name) }
                    $cfp = $chunk[$k].FullName
                    if ($x.EncReason) { $sc += 25; [void]$why.Add($x.EncReason); Add-ObfNote $cfp $x.EncReason }
                    if ($x.BadMagic -gt 0) { $sc += 40; [void]$why.Add('class dosyalarinin ' + $x.BadMagic + ' tanesi gecersiz (sifreli olabilir)'); Add-ObfNote $cfp ('sifreli/bozuk class dosyasi: ' + $x.BadMagic) }
                    if ($x.ObfMarks.Count -gt 0) { $sc += 15; $omh = (@($x.ObfMarks) -join ', '); [void]$why.Add('obfuscator imzasi: ' + $omh); Add-ObfNote $cfp ('obfuscator imzasi: ' + $omh) }
                    if ($x.NativeLibs.Count -gt 0) { $sc += 10; $nlh = (@($x.NativeLibs) -join ', '); [void]$why.Add('jar icinde yerel kutuphane: ' + $nlh); Add-ObfNote $cfp ('jar icinde yerel kutuphane (dll/so): ' + $nlh) }
                    if ($x.HiEnt.Count -gt 0) { $sc += 15; $heh = (@($x.HiEnt) -join ', '); [void]$why.Add('yuksek entropili veri dosyasi: ' + $heh); Add-ObfNote $cfp ('yuksek entropili veri dosyasi: ' + $heh) }
                    if ($x.Classes -ge 20 -and ($x.Short / [double]$x.Classes) -ge 0.6) { Add-ObfNote $cfp ('obfuscate edilmis (' + $x.Short + '/' + $x.Classes + ' sinif adi 1-2 harf)') }
                    if ($sc -ge 25) {
                        $cf = $chunk[$k]
                        Add-F -Kaynak 'Hile avi: jar/zip icerigi' -Ad ('jar: ' + $cf.Name.ToLower()) -Yol $cf.FullName -Skor ([Math]::Min(100, $sc)) -Son $cf.LastWriteTime -Ilk $cf.CreationTime -Var 'Evet' -Not (($why -join '; ') + ' | NOT: sifreli/agir obfuscation kullanan hilelerde class stringleri gorunmez')
                    }
                }
            }
            $chN++
            if (($chN % 10) -eq 0) { Write-Host ('   jar/zip ilerleme: ' + [Math]::Min($ci + 24, $arcSorted.Count) + '/' + $arcSorted.Count + ' (' + [int]$hSw.Elapsed.TotalSeconds + ' sn)') -ForegroundColor DarkGray }
        }
    } else {
        Log '   jar tarayici derlenemedi, jar/zip icerik taramasi atlandi.' 'DarkYellow'; Add-Cov 'Jar tarayici derlenemedi: jar/zip icerik taramasi YAPILMADI' ''
    }
    foreach ($cp in $cand) {
        if ($cp -notmatch '(?i)\.(rar|7z)$') { continue }
        $er = ''
        try { $er = [HkJar]::EncInfo($cp) } catch {}
        if ($er) {
            Add-ObfNote $cp $er
            Add-F -Kaynak 'Hile avi: sifreli arsiv' -Ad ('arsiv: ' + (Split-Path -Leaf $cp).ToLower()) -Yol $cp -Skor 35 -Var 'Evet' -Not ($er + ' | icerigi okunamadi, elle ac ve bak')
        }
    }
    Show-Section

    # --- exe/dll icerik taramasi (kullanici klasorleri once, kucuk dosyalar once) ---
    Step '[AV] exe/dll icerik taramasi (tum disk, sistem klasorleri haric)...'
    Start-Sec
    $binAll = New-Object System.Collections.Generic.List[object]
    foreach ($cp in $cand) {
        if ($cp -notmatch '(?i)\.(exe|dll|scr)$') { continue }
        try {
            $fi = New-Object IO.FileInfo $cp
            if ($fi.Length -gt 4096 -and $fi.Length -lt 31457280) { [void]$binAll.Add($fi) }
        } catch {}
    }
    $binSorted = @($binAll | Sort-Object @{ Expression = { if ($_.FullName -match '(?i)\\Users\\') { 0 } else { 1 } } }, Length)
    Log ('   ' + $binSorted.Count + ' exe/dll adayi (sure siniri yok, hepsi taranir).') 'DarkGray'
    $bSw = [Diagnostics.Stopwatch]::StartNew()
    $bI = 0
    foreach ($bf in $binSorted) {
        $bI++
        if (($bI % 50) -eq 0) { Set-Frac ($bI / [Math]::Max(1, $binSorted.Count)) ('exe/dll ' + $bI + '/' + $binSorted.Count) }
        if (($bI % 200) -eq 0) { Write-Host ('   exe/dll ilerleme: ' + $bI + '/' + $binSorted.Count + ' (' + [int]$bSw.Elapsed.TotalSeconds + ' sn)') -ForegroundColor DarkGray }
        try { Scan-BinHunt $bf } catch {}
    }
    Show-Section

    # --- Indirme izi (Zone.Identifier), yakin zamanda gelen dosyalar, arsiv programi gecmisi ---
    Step '[AV] indirme izi (Zone.Identifier), son 60 gunde gelen dosyalar ve WinRAR/7-Zip gecmisi...'
    Start-Sec
    $dlHostRx = '(?i)cdn\.discordapp\.com/attachments|media\.discordapp\.net/attachments|mega\.nz|mediafire\.com|gofile\.io|pixeldrain\.com|anonfiles|transfer\.sh|workupload\.com|file\.io|catbox\.moe|dropbox\.com|drive\.google\.com|sendspace\.com|1fichier\.com|t\.me|telegram'
    $recentRows = New-Object System.Collections.Generic.List[object]
    $zChecked = 0
    $cutoff = (Get-Date).AddDays(-60)
    foreach ($cp in $cand) {
        if ($cp -notmatch '(?i)\\Users\\') { continue }
        if ($cp -notmatch '(?i)\.(jar|zip|rar|7z|exe|dll|msi|bat|cmd|ps1|vbs|scr)$') { continue }
        $fi = $null
        try { $fi = New-Object IO.FileInfo $cp } catch { continue }
        $newest = $fi.CreationTime
        if ($fi.LastWriteTime -gt $newest) { $newest = $fi.LastWriteTime }
        $srcUrl = ''
        if ($zChecked -lt 5000) {
            $zChecked++
            $zi = $null
            try { $zi = @(Get-Content -LiteralPath $cp -Stream Zone.Identifier -ErrorAction Stop) } catch {}
            foreach ($zl in @($zi)) { if ($zl -and ($zl -match '^(HostUrl|ReferrerUrl)=(.+)$')) { $srcUrl = $srcUrl + ' ' + $Matches[2] } }
        }
        $srcUrl = $srcUrl.Trim()
        if ($srcUrl) {
            $zh = Get-NameHit ($srcUrl + ' ' + $fi.Name) $false
            if ($zh) {
                Add-F -Kaynak 'Hile avi: indirme kaynagi (Zone.Identifier)' -Ad $fi.Name.ToLower() -Yol $cp -Skor 50 -Son $fi.LastWriteTime -Ilk $fi.CreationTime -Var 'Evet' -Not ('indirildigi adres: ' + $srcUrl + ' | hile ismi: ' + $zh.Name)
            } elseif ($srcUrl -match $dlHostRx -and ($IntExt -contains $fi.Extension.ToLower())) {
                Add-F -Kaynak 'Hile avi: indirme kaynagi (Zone.Identifier)' -Ad $fi.Name.ToLower() -Yol $cp -Skor 30 -Son $fi.LastWriteTime -Ilk $fi.CreationTime -Var 'Evet' -Not ('dosya paylasim/sohbet sitesinden indirilmis kod/arsiv dosyasi: ' + $srcUrl + ' (hile dagitiminda sik kullanilir ama mesru dosyalar da olabilir)')
            }
        }
        if ($newest -gt $cutoff) { [void]$recentRows.Add([pscustomobject]@{ T = $newest; Yol = $cp; Boyut = $fi.Length; Kaynak = $srcUrl }) }
    }
    $hist = New-Object System.Collections.Generic.List[string]
    foreach ($rk in @('HKCU:\Software\WinRAR\ArcHistory', 'HKCU:\Software\WinRAR\DialogEditHistory\ExtrPath')) {
        try {
            $k = Get-Item -LiteralPath $rk -ErrorAction Stop
            foreach ($vn in $k.GetValueNames()) { Add-HistVals ($k.GetValue($vn)) $hist }
        } catch {}
    }
    foreach ($rv in @(@('HKCU:\Software\7-Zip\FM', 'FolderHistory'), @('HKCU:\Software\7-Zip\FM', 'PanelPath0'), @('HKCU:\Software\7-Zip\FM', 'PanelPath1'), @('HKCU:\Software\7-Zip\Extraction', 'PathHistory'), @('HKCU:\Software\7-Zip\Compression', 'ArcHistory'))) {
        try {
            $pr = Get-ItemProperty -LiteralPath $rv[0] -Name $rv[1] -ErrorAction Stop
            Add-HistVals ($pr.($rv[1])) $hist
        } catch {}
    }
    $hSeen = @{}
    $hShown = 0
    Log '' 'Gray'
    Log 'WinRAR/7-Zip gecmisinde gecen yollar (arsiv acilmis/cikarilmis olabilir):' 'Cyan'
    foreach ($hp in $hist) {
        $hk = $hp.ToLower()
        if ($hSeen.ContainsKey($hk)) { continue }
        $hSeen[$hk] = 1
        $hEx = $true
        if ($hp -match '^[A-Za-z]:\\') { $hEx = [bool](Test-Path -LiteralPath $hp) }
        $hh = Get-NameHit $hp $false
        $hTxt = ''
        if (-not $hEx) { $hTxt = '   (ARTIK YOK)' }
        if ($hShown -lt 40) { Log ('   ' + $hp + $hTxt) 'Gray'; $hShown++ }
        if ($hh) {
            Add-F -Kaynak 'Hile avi: arsiv programi gecmisi' -Ad ('gecmis: ' + $hp.ToLower()) -Yol $hp -Skor 50 -Var 'Evet' -Not ('WinRAR/7-Zip gecmisinde hile ismi: ' + $hh.Name)
        }
    }
    if ($hShown -eq 0) { Log '   (kayit yok)' 'DarkGray' }
    $recSorted = @($recentRows | Sort-Object T -Descending | Select-Object -First 80)
    Log '' 'Gray'
    Log ('SON 60 GUNDE kullanici klasorlerine gelen/degisen kod ve arsiv dosyalari (' + $recentRows.Count + ' adet, en yenisinden ilk ' + $recSorted.Count + ') - tanidik bir dosya var mi bak:') 'Cyan'
    foreach ($rr in $recSorted) {
        $szMb = [Math]::Round($rr.Boyut / 1048576, 1)
        $ln2 = '   ' + (Fmt $rr.T) + '  ' + $szMb + ' MB  ' + $rr.Yol
        if ($rr.Kaynak) { $ln2 = $ln2 + '   <- ' + $rr.Kaynak }
        Log $ln2 'Gray'
    }
    Show-Section
    Log '' 'Gray'
    Show-ObfSummary
    Log ('HILE AVI bitti: ' + [int]$hSw.Elapsed.TotalSeconds + ' sn.') 'Cyan'
    Close-Bar
    if ($script:TitleOk -and $Av) { [HkTitle]::Done = $true; [HkTitle]::Tick() }
}
if ($Av) {
    Invoke-Hunt
    Log '' 'Gray'
    if ($PSCommandPath) { Read-Host 'Kapatmak icin Enter a bas' | Out-Null }
    return
}

# USN gunlugu okumalari simdi arka planda baslar (adim 2 sonucu bekler)
foreach ($ubDl in $script:FixedNtfs) { Start-UsnBg $ubDl }

# ---------------------------------------------------------------------
Step '[1/17] BYPASS TESPITI - iz saklama/temizleme, servis ve ayar durumlari...'
Start-Sec
$pfDir = $env:WINDIR + '\Prefetch'
$pfFiles = @()
try { $pfFiles = @(Get-ChildItem -LiteralPath $pfDir -Filter '*.pf' -Force -ErrorAction Stop) } catch {}
$pfReg = $null
try { $pfReg = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' -ErrorAction Stop).EnablePrefetcher } catch {}
if ($pfReg -eq 0) { Add-Sys 'Prefetch KAPATILMIS' 45 'EnablePrefetcher=0: Windows program calistirma kaydi tutmuyor (iz saklama girisimi olabilir).' }
if ($pfFiles.Count -eq 0) {
    Add-Sys 'Prefetch klasoru bos veya okunamadi' 40 'Normalde yuzlerce .pf dosyasi olur. Bos ise temizlenmis olabilir.'
} elseif ($pfFiles.Count -lt 20) {
    Add-Sys ('Prefetch klasorunde sadece ' + $pfFiles.Count + ' kayit var') 35 'Normalde cok daha fazla olur; yakin zamanda temizlenmis olabilir.'
} else {
    $oldest = ($pfFiles | Sort-Object CreationTime | Select-Object -First 1).CreationTime
    Log ('   Prefetch: ' + $pfFiles.Count + ' kayit, en eskisi: ' + (Fmt $oldest)) 'DarkGray'
}
Check-Service 'SysMain' 'Bu servis (eski adiyla Superfetch) Prefetch verisiyle iliskilidir; kapatilmasi iz saklama girisimi olabilir.' 40 30
Check-Service 'PcaSvc' 'Program Compatibility Assistant, calistirilan programlarla ilgili ek kayit tutar.' 35 15
Check-Service 'DPS' 'Diagnostic Policy Service - tanilama ve bazi kayit mekanizmalari buna baglidir.' 35 20
Check-Service 'EventLog' 'Windows Olay Gunlugu servisinin kendisi; kapaliysa hicbir olay kaydedilmez.' 60 50
Check-Service 'bam' 'BAM (Background Activity Moderator) - programlarin son calistirma zamanini tutar.' 45 30
Check-Service 'WinDefend' 'Windows Defender antivirus motoru.' 45 35
Check-Service 'WdNisSvc' 'Windows Defender ag denetimi.' 25 15
Check-Service 'Sense' 'Windows Defender gelismis tehdit koruma servisi.' 20 10
Check-Service 'wscsvc' 'Windows Guvenlik Merkezi servisi; antivirus/guvenlik duvarinin durumunu bildirir.' 30 20
Check-Service 'Appinfo' 'Uygulama Bilgisi servisi; yonetici izni isteyen programlarla ilgili kayit tutar.' 25 15
Check-Service 'mpssvc' 'Windows Guvenlik Duvari servisi.' 35 25
Check-Service 'Dnscache' 'DNS Istemci (Dnscache) servisi; hangi sitelere baglanildigina dair DNS onbellegini tutar.' 25 15
Check-Service 'BFE' 'Taban Filtre Motoru (BFE); guvenlik duvari kurallarini uygular, kapatilmasi tehlikeli.' 40 30
Check-Service 'DiagTrack' 'Baglanti Kullanici Deneyimleri ve Telemetri servisi.' 15 10
Check-Service 'WSearch' 'Windows Arama (SearchIndexer) servisi; dosya indeksleme ve arama gecmisini tutar.' 20 12

# --- Prefetch/Superfetch parametreleri (acik/kapali + en son elle degistirilme zamani) ---
Check-RegFlag 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' 'EnablePrefetcher' 3 'Prefetch (EnablePrefetcher) beklenenden farkli' 'Program calistirma onbellegi ayari degistirilmis (normal: 2 veya 3).' 40
Check-RegFlag 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' 'EnableSuperfetch' 3 'Superfetch ayari beklenenden farkli' 'Superfetch/SysMain onbellek ayari degistirilmis.' 25

# --- USN gunlugu / degisiklik gunlugu izleme ayari ---
try {
    $nlu = (Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name NtfsDisableLastAccessUpdate -ErrorAction Stop).NtfsDisableLastAccessUpdate
    if ($nlu -eq 1) { Add-Sys 'Dosya erisim zamani guncellemesi elle KAPATILMIS' 20 'NtfsDisableLastAccessUpdate=1 (kullanici yonetimli). Windows varsayilani (sistem yonetimli) bu degildir ama performans icin kapatan cok kisi vardir; tek basina suphe degil.' }
} catch {}

# --- PowerShell komut/script kaydi (loglama) ---
Check-RegFlag 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' 'EnableScriptBlockLogging' 1 'PowerShell ScriptBlock loglama KAPALI' 'PowerShell komutlarinin kaydi tutulmuyor; script tabanli islemler iz birakmaz.' 20

# --- Windows Defender kapatma bayraklari (grup ilkesi seviyesinde) ---
Check-RegFlag 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' 'DisableAntiSpyware' 0 'Windows Defender grup ilkesiyle KAPATILMIS' 'Antivirus grup ilkesi (registry) uzerinden devre disi birakilmis.' 55
Check-RegFlag 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection' 'DisableRealtimeMonitoring' 0 'Windows Defender aninda koruma KAPALI (registry)' 'Gercek zamanli tarama registry uzerinden kapatilmis.' 45

# --- Denetim (audit) ilkesi: nesne erisimi/sistem olaylari izleniyor mu ---
try {
    $apOut = & auditpol.exe /get /subcategory:'{0CCE921D-69AE-11D9-BED3-505054503030}' 2>$null | Out-String
    if ($apOut -match '(?i)No Auditing|Denetim yok|Denetleme yok|Denetlenmiyor') { Add-Sys 'Dosya sistemi denetimi (audit) KAPALI' 15 'Dosya erisim/degisiklik olaylari Olay Gunlugune yazilmiyor (varsayilan zaten kapali olabilir).' }
} catch {}

# --- Zamanlanmis gorevler: log/prefetch/iz temizleyen komutlar iceren gorev var mi ---
$taskRoot = $env:WINDIR + '\System32\Tasks'
$cleanRx = '(?i)wevtutil\s+(cl|clear-log)|fsutil\s+usn\s+deletejournal|cipher\s*/w|del\s+/f.*prefetch|Clear-EventLog|Remove-Item.*Prefetch'
if (Test-Path -LiteralPath $taskRoot) {
    foreach ($tf in @(Get-ChildItem -LiteralPath $taskRoot -Recurse -File -Force -ErrorAction SilentlyContinue)) {
        $ttxt = ''
        try { $ttxt = Get-Content -LiteralPath $tf.FullName -Raw -ErrorAction Stop } catch {}
        if ($ttxt -and ($ttxt -match $cleanRx)) {
            Add-Sys ('Zamanlanmis gorev iz temizliyor: ' + $tf.Name) 45 'Bu gorev calistiginda log/prefetch/USN temizleme komutu iceriyor.' $tf.LastWriteTime ('gorev dosyasi: ' + $tf.FullName) $tf.LastWriteTime
        }
    }
}

# --- hosts dosyasi: yakin zamanda elle degistirilmis mi (anticheat/telemetri engelleme icin kullanilabilir) ---
$hostsPath = $env:WINDIR + '\System32\drivers\etc\hosts'
if (Test-Path -LiteralPath $hostsPath) {
    $hf = Get-Item -LiteralPath $hostsPath
    $hlines = @(Get-Content -LiteralPath $hostsPath -ErrorAction SilentlyContinue | Where-Object { $_ -and ($_.TrimStart() -notmatch '^#') })
    if ($hlines.Count -gt 5 -or ($hf.LastWriteTime -gt (Get-Date).AddDays(-30) -and $hlines.Count -gt 0)) {
        Add-Sys 'hosts dosyasi degistirilmis' 20 'Sistemin hosts dosyasinda ozel yonlendirme/engelleme kayitlari var (bazi hileler/anticheat atlatma araclari bunu kullanir).' $null ($hlines.Count.ToString() + ' ozel satir') $hf.LastWriteTime
    }
}
foreach ($e in @(Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 1102 } -MaxEvents 5 -ErrorAction SilentlyContinue)) {
    Add-Sys 'Guvenlik olay gunlugu TEMIZLENMIS' 50 'Windows olay kaydi (Event 1102) silinmis.' $e.TimeCreated 'temizlenme zamani asagida' $e.TimeCreated
}
foreach ($e in @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 104 } -MaxEvents 5 -ErrorAction SilentlyContinue)) {
    Add-Sys 'Sistem olay gunlugu TEMIZLENMIS' 50 'Windows olay kaydi (Event 104) silinmis.' $e.TimeCreated 'temizlenme zamani asagida' $e.TimeCreated
}
foreach ($e in @(Get-WinEvent -FilterHashtable @{ LogName = 'Application'; Id = 1102 } -MaxEvents 5 -ErrorAction SilentlyContinue)) {
    Add-Sys 'Uygulama olay gunlugu TEMIZLENMIS' 45 'Windows olay kaydi (Event 1102) Uygulama gunlugunde silinmis.' $e.TimeCreated 'temizlenme zamani asagida' $e.TimeCreated
}
foreach ($e in @(Get-WinEvent -FilterHashtable @{ LogName = 'Application'; Id = 3079 } -MaxEvents 5 -ErrorAction SilentlyContinue)) {
    Add-Sys 'Olay Gunlugu TEMIZLENMIS (3079)' 40 'Olay Goruntuleyicisi uzerinden bir log elle temizlenmis (Event 3079).' $e.TimeCreated 'temizlenme zamani asagida' $e.TimeCreated
}
# --- Servis durdurma gecmisi: SCM 7036 (durdu) / 7040 (baslatma tipi degisti). Durdurup tekrar acanlari da yakalar ---
try {
    $svWanted = @{}
    foreach ($svK in @('DPS', 'PcaSvc', 'SysMain', 'WinDefend', 'Appinfo', 'WSearch', 'Dnscache', 'BFE', 'mpssvc', 'DiagTrack', 'WdiServiceHost', 'WdiSystemHost')) {
        if ($script:SvcAll -and $script:SvcAll[$svK]) { $svWanted[[string]$script:SvcAll[$svK].DisplayName] = $svK }
    }
    $svT0 = (Get-Date).AddDays(-30)
    $svStops = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Service Control Manager'; Id = 7036; StartTime = $svT0 } -MaxEvents 5000 -ErrorAction SilentlyContinue)
    $svDown = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'EventLog'; Id = 6006; StartTime = $svT0 } -MaxEvents 300 -ErrorAction SilentlyContinue | ForEach-Object { $_.TimeCreated })
    $svSeen = @{}
    foreach ($ev in $svStops) {
        $dn = ''
        $stt = ''
        try { $dn = [string]$ev.Properties[0].Value; $stt = [string]$ev.Properties[1].Value } catch {}
        if (-not $svWanted.ContainsKey($dn)) { continue }
        if ($stt -notmatch '(?i)stopp|durdu') { continue }
        $evT = $ev.TimeCreated
        $nearDown = $false
        foreach ($dt in $svDown) { if ($evT -ge $dt.AddMinutes(-4) -and $evT -le $dt.AddMinutes(1)) { $nearDown = $true; break } }
        if ($nearDown) { continue }
        $svc = $svWanted[$dn]
        if (-not $svSeen.ContainsKey($svc)) { $svSeen[$svc] = @{ N = 0; T = $evT; Dn = $dn } }
        $svSeen[$svc].N++
    }
    foreach ($svc in $svSeen.Keys) {
        $sk = 30; if ($svc -in @('DPS', 'PcaSvc', 'SysMain')) { $sk = 40 }
        Add-Sys ('Servis ELLE durdurulmus (son 30 gun): ' + $svSeen[$svc].Dn + ' (' + $svc + ')') $sk ('Servis, bilgisayar kapanmadan durdu (' + $svSeen[$svc].N + ' kez); sonradan tekrar acilmis olsa bile durdurma-acma izi kalir (iz saklama yontemi).') $svSeen[$svc].T ('en son durma: ' + (Fmt $svSeen[$svc].T)) $svSeen[$svc].T
    }
    $cfgSeen = @{}
    foreach ($ev in @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Service Control Manager'; Id = 7040; StartTime = $svT0 } -MaxEvents 400 -ErrorAction SilentlyContinue)) {
        $dn = ''
        try { $dn = [string]$ev.Properties[0].Value } catch {}
        if (-not $svWanted.ContainsKey($dn)) { continue }
        if (-not $cfgSeen.ContainsKey($dn)) { $cfgSeen[$dn] = @{ N = 0; T = $ev.TimeCreated; M = (($ev.Message -replace '\s+', ' ')) } }
        $cfgSeen[$dn].N++
    }
    foreach ($dn in $cfgSeen.Keys) {
        Add-Sys ('Servis baslatma tipi degistirilmis: ' + $dn + ' (' + $cfgSeen[$dn].N + ' kez, son 30 gun)') 40 'Servis ayari (otomatik/elle/devre disi) degistirilmis; iz birakmamak icin kapatilmis olabilir.' $cfgSeen[$dn].T $cfgSeen[$dn].M $cfgSeen[$dn].T
    }
} catch {}
# --- Olay gunlugu neredeyse bos / cok yeni mi (dosya silinerek veya temizlenerek sifirlanmis olabilir) ---
try {
    $osI = $null
    try { $osI = [datetime](Get-CimInstance Win32_OperatingSystem).InstallDate } catch {}
    $evSes = New-Object System.Diagnostics.Eventing.Reader.EventLogSession
    foreach ($lgN in @('System', 'Application')) {
        $lgInf = $evSes.GetLogInformation($lgN, [System.Diagnostics.Eventing.Reader.PathType]::LogName)
        $lgCfg = New-Object System.Diagnostics.Eventing.Reader.EventLogConfiguration($lgN)
        $fillP = 0
        if ($lgCfg.MaximumSizeInBytes -gt 0) { $fillP = [double]$lgInf.FileSize / [double]$lgCfg.MaximumSizeInBytes }
        $lgOld = @(Get-WinEvent -LogName $lgN -Oldest -MaxEvents 1 -ErrorAction SilentlyContinue)
        if ($lgOld.Count -gt 0 -and $osI -and $osI -lt (Get-Date).AddDays(-20) -and $lgOld[0].TimeCreated -gt (Get-Date).AddDays(-5) -and $fillP -lt 0.8) {
            Add-Sys ($lgN + ' olay gunlugunun en eski kaydi cok yeni (' + (Fmt $lgOld[0].TimeCreated) + ')') 50 'Windows uzun suredir kurulu ama bu logda yakin zamandan eski kayit yok ve log dolmamis: log temizlenmis/silinmis olabilir (temizleme olayi da silinmis olabilir).' $lgOld[0].TimeCreated ('log doluluk: %' + [int]($fillP * 100))
        }
    }
} catch {}
# --- Prefetch klasorunun tamami cok yeni mi (toplu silme + yeniden olusma) ---
try {
    $osI2 = [datetime](Get-CimInstance Win32_OperatingSystem).InstallDate
    if ($pfFiles.Count -ge 20) {
        $pfOld = ($pfFiles | Sort-Object CreationTime | Select-Object -First 1).CreationTime
        if ($osI2 -lt (Get-Date).AddDays(-20) -and $pfOld -gt (Get-Date).AddDays(-3)) {
            Add-Sys 'Prefetch klasorundeki tum kayitlar son 3 gunden' 35 'Windows uzun suredir kurulu ama en eski Prefetch kaydi cok yeni: klasor yakin zamanda toplu silinmis olabilir.' $pfOld ('en eski kayit: ' + (Fmt $pfOld))
        }
    }
} catch {}
# --- NTFS Operational log: USN Journal silinip yeniden olusturulmus mu (Event 501 tekrarlari = journal bypass) ---
try {
    $ntfsOp = @(Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Ntfs/Operational'; Id = 501 } -MaxEvents 20 -ErrorAction Stop)
    if ($ntfsOp.Count -ge 2) {
        Add-Sys ('USN Journal olayi (501) birden fazla kayitli (' + $ntfsOp.Count + ' kayit)') 15 'NTFS Operational logunda 501 olayi tekrar ediyor. Journal silinip yeniden olusturulmus olabilir ama Windows guncellemeleri, disk araclari ve harici/sanal diskler de bunu uretebilir; TEK BASINA KANIT DEGIL, olay zamanini Olay Goruntuleyicisinde kontrol et.' $ntfsOp[0].TimeCreated ('en son: ' + (Fmt $ntfsOp[0].TimeCreated)) $ntfsOp[0].TimeCreated
    }
} catch {}

# --- Prefetch dosya nitelikleri: Salt Okunur/Gizli yapilmis mi (Prefetch'in kaydetmesini engelleme yontemi) ---
$pfAttrBad = 0
$pfAttrExample = ''
foreach ($pf in $pfFiles) {
    if (($pf.Attributes -band [IO.FileAttributes]::ReadOnly) -or ($pf.Attributes -band [IO.FileAttributes]::Hidden)) {
        $pfAttrBad++
        if (-not $pfAttrExample) { $pfAttrExample = $pf.Name + ' (' + $pf.Attributes + ')' }
    }
}
if ($pfAttrBad -gt 0) {
    Add-Sys ('Prefetch dosyalarinda Salt Okunur/Gizli nitelik bulundu (' + $pfAttrBad + ' dosya)') 45 'Prefetch dosyasi Salt Okunur/Gizli yapilarak Windows''in yeni kayit yazmasi engellenebilir.' $null $pfAttrExample
}

# --- CMD AutoRun: her CMD acilista otomatik calisan komut (ozellikle kendini kapatan) ---
foreach ($arPath in @('HKLM:\SOFTWARE\Microsoft\Command Processor', 'HKCU:\SOFTWARE\Microsoft\Command Processor')) {
    try {
        $ar = (Get-ItemProperty -LiteralPath $arPath -Name AutoRun -ErrorAction Stop).AutoRun
        if ($ar) {
            $sc2 = 25
            if ($ar -match '(?i)taskkill|cmd\.exe.*\/f|cmd\.exe.*kill') { $sc2 = 50 }
            Add-Sys ('CMD AutoRun tanimli (' + $arPath + ')') $sc2 'CMD her acildiginda otomatik calisan bir komut var; CMD''yi kapatmak icin kullanilmis olabilir.' $null $ar
        }
    } catch {}
}

# --- CMD renk gizleme: yazi rengi = arka plan rengi (yazilanlari gizleme yontemi) ---
try {
    $cons = Get-ItemProperty -LiteralPath 'HKCU:\Console' -ErrorAction Stop
    if ($null -ne $cons.ScreenColors -and $null -ne $cons.PopupColors) {
        $fg = $cons.ScreenColors -band 0x0F
        $bg = ($cons.ScreenColors -band 0xF0) -shr 4
        if ($fg -eq $bg) {
            Add-Sys 'CMD yazi rengi arka plan rengiyle AYNI' 40 'Komut isterinde yazilanlar gorunmuyor olabilir (renk gizleme yontemi).' $null ('ScreenColors=0x' + [Convert]::ToString($cons.ScreenColors, 16))
        }
    }
    if ($null -ne $cons.ForceV2 -and $cons.ForceV2 -eq 0) {
        Add-Sys 'CMD eski konsol modunda (Legacy Console)' 20 'Kopyala/yapistir ve bazi ozellikler kapatilmis olabilir (eski konsol moduna alinarak).' $null 'ForceV2=0'
    }
} catch {}

# --- Internet Secenekleri Yasakli Siteler: anticheat/ss-tool sitelerini engelleme (indirme bypass) ---
try {
    $zoneRoot = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains'
    if (Test-Path -LiteralPath $zoneRoot) {
        $domains = New-Object System.Collections.Generic.List[string]
        foreach ($d in @(Get-ChildItem -LiteralPath $zoneRoot -ErrorAction SilentlyContinue)) {
            $sub = Get-ItemProperty -LiteralPath $d.PSPath -ErrorAction SilentlyContinue
            $hasRestricted = $false
            foreach ($p in $sub.PSObject.Properties) { if ($p.Name -notmatch '^PS' -and $p.Value -eq 4) { $hasRestricted = $true } }
            if ($hasRestricted) { [void]$domains.Add($d.PSChildName) }
            foreach ($d2 in @(Get-ChildItem -LiteralPath $d.PSPath -ErrorAction SilentlyContinue)) {
                $sub2 = Get-ItemProperty -LiteralPath $d2.PSPath -ErrorAction SilentlyContinue
                foreach ($p in $sub2.PSObject.Properties) { if ($p.Name -notmatch '^PS' -and $p.Value -eq 4) { [void]$domains.Add($d2.PSChildName + '.' + $d.PSChildName) } }
            }
        }
        if ($domains.Count -gt 0) {
            Add-Sys ('Internet Secenekleri Yasakli Siteler listesinde ' + $domains.Count + ' adres var') 25 'Bazi web siteleri "Yasakli Siteler" bolgesine eklenerek erisimi/indirmeyi engellemek icin kullanilabilir (anticheat/takip sitelerini engellemek gibi); listeyi elle kontrol et.' $null (($domains | Select-Object -First 5) -join ', ')
        }
    }
} catch {}
try {
    $mp = Get-MpPreference -ErrorAction Stop
    foreach ($x in @($mp.ExclusionPath)) {
        if ($x) {
            $z = Get-Zone $x
            if ($z -eq 'user' -or $z -eq 'temp' -or $x -match $script:LauncherRx -or $x -match '(?i)mods') { Add-Sys ('Defender dislama (klasor): ' + $x) 45 'Antivirus bu klasoru taramiyor; hile dosyalarini saklamak icin kullanilabilir.' } else { Add-Sys ('Defender dislama (klasor): ' + $x) 20 'Antivirus bu klasoru taramiyor.' }
        }
    }
    foreach ($x in @($mp.ExclusionProcess)) { if ($x) { Add-Sys ('Defender dislama (process): ' + $x) 35 'Antivirus bu programi taramiyor.' } }
    foreach ($x in @($mp.ExclusionExtension)) { if ($x) { Add-Sys ('Defender dislama (uzanti): ' + $x) 40 'Bu uzantili dosyalar taranmiyor.' } }
} catch {}
foreach ($pair in @(@('LGHUB', ($env:LOCALAPPDATA + '\LGHUB')), @('Razer Synapse', ($env:LOCALAPPDATA + '\Razer')), @('Bloody7', ($env:APPDATA + '\Bloody7')), @('SteelSeries', ($env:PROGRAMDATA + '\SteelSeries')))) {
    if (Test-Path -LiteralPath $pair[1]) { Add-Sys ('Fare/klavye yazilimi var: ' + $pair[0]) 15 'Makro/autoclick profili tanimlanmis olabilir (bu script profil icerigini okuyamaz).' (Get-Item -LiteralPath $pair[1]).LastWriteTime }
}
Show-Section

# ---------------------------------------------------------------------
Step '[2/17] Geri donusum kutusu ve USN gunlugu (silinen dosyalar, silinme zamanlari)...'
Start-Sec
foreach ($dl in $script:Drives) {
    $bin = $dl + '\$Recycle.Bin'
    if (-not (Test-Path -LiteralPath $bin)) { continue }
    $total = 0
    $latestDirChange = $null
    foreach ($sd in @(Get-ChildItem -LiteralPath $bin -Force -Directory -ErrorAction SilentlyContinue)) {
        if (-not $latestDirChange -or $sd.LastWriteTime -gt $latestDirChange) { $latestDirChange = $sd.LastWriteTime }
        foreach ($fi in @(Get-ChildItem -LiteralPath $sd.FullName -Force -Filter '$I*' -File -ErrorAction SilentlyContinue)) {
            try {
                $b = [IO.File]::ReadAllBytes($fi.FullName)
                if ($b.Length -lt 28) { continue }
                $ver = [BitConverter]::ToInt64($b, 0)
                $del = Hk-Ft ([BitConverter]::ToInt64($b, 16))
                $orig = ''
                if ($ver -eq 2) {
                    $plen = [BitConverter]::ToInt32($b, 24)
                    $take = [Math]::Min($plen * 2, $b.Length - 28)
                    $orig = [Text.Encoding]::Unicode.GetString($b, 28, $take).TrimEnd([char]0)
                } else {
                    $orig = [Text.Encoding]::Unicode.GetString($b, 24, $b.Length - 24).TrimEnd([char]0)
                }
                $rname = '$R' + $fi.Name.Substring(2)
                $still = Test-Path -LiteralPath (Join-Path $sd.FullName $rname)
                $total++
                [void]$script:BinItems.Add([pscustomobject]@{ Surucu = $dl; Orijinal = $orig; Silinme = $del; Kutuda = $still })
                $leaf = ''
                try { $leaf = Split-Path -Leaf $orig } catch {}
                if ($leaf) {
                    $bext = ''
                    try { $bext = [IO.Path]::GetExtension($leaf).ToLower() } catch {}
                    $bh = Get-NameHit $leaf $true
                    $bsc = 0
                    if ($bh) { $bsc += (Name-Score $bh $true) }
                    if (@('.exe', '.jar', '.rar', '.zip', '.7z', '.bat', '.ps1', '.scr') -contains $bext) { $bsc += 30 }
                    if ($bsc -ge 20) {
                        $bpi = Test-PathInfo $orig
                        $bvar = 'Hayir'
                        if ($bpi.Exists) { $bvar = 'Evet' }
                        $bnote = 'geri donusum kutusunda'
                        if (-not $still) { $bnote = 'geri donusum kutusu kaydi var ama dosya artik yok (kutu bosaltilmis)' }
                        Add-F -Kaynak 'Geri donusum kutusu' -Ad $leaf.ToLower() -Yol $orig -Skor ([Math]::Min(100, $bsc)) -Var $bvar -Silinme $del -Not $bnote -Benign ($bh -eq $null -and $leaf -match $script:BenignRx)
                    }
                }
            } catch {}
        }
    }
    if ($total -gt 0) { [void]$script:BinState.Add($dl + ' geri donusum kutusunda su an ' + $total + ' kayit var.') } else { [void]$script:BinState.Add($dl + ' geri donusum kutusu su an BOS.') }
    if ($latestDirChange) { [void]$script:BinState.Add('   ' + $dl + ' kutu klasoru son degisiklik: ' + (Fmt $latestDirChange) + ' (kutu bossa: yaklasik en son bosaltma/silme zamani)') }
}
foreach ($dl in $script:FixedNtfs) {
    & fsutil usn queryjournal $dl 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Stop-UsnBg $dl
        Add-Sys ('USN gunlugu YOK/silinmis: ' + $dl) 45 'USN gunlugu dosya silme/degistirme kayitlarini tutar; silinmis olmasi iz temizleme girisimi olabilir (fsutil usn deletejournal).'
        continue
    }
    Log ('   USN gunlugu okunuyor: ' + $dl + ' (biraz surebilir)...') 'DarkGray'
    $n = Read-Usn $dl
    Log ('   ' + $dl + ' : ' + $n + ' ilgili silme kaydi bulundu.') 'DarkGray'
}

# --- Silinen Prefetch (.pf) dosyalari: Prefetch'in kendisi veya java/javaw calisma kaydi silinmis mi ---
if ($script:DeletedPf.Count -gt 0) {
    $javaPf = @($script:DeletedPf | Where-Object { $_.Ad -match '(?i)^JAVA(W)?\.EXE' })
    $otherPf = @($script:DeletedPf | Where-Object { $_.Ad -notmatch '(?i)^JAVA(W)?\.EXE' })
    if ($javaPf.Count -gt 0) {
        $jp = $javaPf | Sort-Object Zaman -Descending | Select-Object -First 1
        $jpList = (($javaPf | Sort-Object Zaman -Descending | Select-Object -First 5 | ForEach-Object { $_.Ad + ' (' + (Fmt $_.Zaman) + ')' }) -join '; ')
        Add-Sys ('JAVA/JAVAW Prefetch kaydi SILINMIS (' + $javaPf.Count + ' adet)') 55 'java.exe veya javaw.exe icin Windows''in tuttugu calisma kaydi (Prefetch) elle silinmis; Minecraft/java calistirma gecmisini gizlemek icin kullanilan bir yontemdir.' $jp.Zaman $jpList
    }
    if ($otherPf.Count -gt 0) {
        $op = $otherPf | Sort-Object Zaman -Descending | Select-Object -First 1
        $opList = (($otherPf | Sort-Object Zaman -Descending | Select-Object -First 5 | ForEach-Object { $_.Ad + ' (' + (Fmt $_.Zaman) + ')' }) -join '; ')
        Add-Sys ('Prefetch (.pf) dosyasi SILINMIS (' + $otherPf.Count + ' adet)') 35 'Bir programin calisma kaydi (Prefetch dosyasi) elle silinmis; o programin calistirildigi izi gizlemek icin kullanilabilir.' $op.Zaman $opList
    }
}
Show-Section

# ---------------------------------------------------------------------
Step '[3/17] Calisan process, Java komut satiri, overlay pencereleri...'
Start-Sec
$procs = @(Get-CimInstance Win32_Process)
$SysNames = @('svchost', 'csrss', 'lsass', 'winlogon', 'services', 'smss', 'wininit', 'explorer', 'dllhost', 'conhost', 'taskhostw', 'sihost', 'RuntimeBroker', 'fontdrvhost', 'spoolsv', 'ctfmon', 'audiodg', 'dwm')
$ToolRx = '(?i)^(cheatengine|processhacker|systeminformer|x64dbg|x32dbg|ollydbg|extremeinjector|xenos|injector|dnspy|reclass|autohotkey|autoclick|tinytask|jitbit)'
foreach ($pr in $procs) {
    $pn = $pr.Name
    if (-not $pn) { continue }
    $base = [IO.Path]::GetFileNameWithoutExtension($pn)
    $pp = [string]$pr.ExecutablePath
    $isJava = ($pn -ieq 'javaw.exe' -or $pn -ieq 'java.exe')
    if (-not $isJava -and $pp -match '(?i)^[A-Za-z]:\\Windows\\' -and -not ($SysNames -contains $base)) { continue }
    $sc = 0
    $why = New-Object System.Collections.Generic.List[string]
    if ($pp -and ($SysNames -contains $base)) {
        # Yol karsilastirmasi: \??\ oneki, / ayiraci, kisa 8.3 adlar ve buyuk/kucuk harf farklari duzeltilir
        $ppn = $pp.Trim().Trim('"') -replace '^\\\?\?\\', ''
        $ppn = $ppn -replace '/', '\'
        try { $ppn = [IO.Path]::GetFullPath($ppn) } catch {}
        $winDir = [string]$env:SystemRoot
        if (-not $winDir) { $winDir = 'C:\Windows' }
        $inWin = $ppn.StartsWith($winDir.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)
        if (-not $inWin) {
            # Windows klasorunde degil: Microsoft imzali degilse taklit say
            if (-not (Test-Signed $pp)) {
                $sc += 65; [void]$why.Add('sistem process ismi taklidi (Windows klasorunde degil ve imzasiz)')
            }
        }
    }
    $hit = Get-NameHit $pn $true
    if ($hit) { $ns = Name-Score $hit $true; if ($ns -gt 0) { $sc += $ns; [void]$why.Add('isim eslesmesi: ' + $hit.Name) } }
    if ($base -match $ToolRx) { $sc += 40; [void]$why.Add('hile/enjeksiyon/makro araci ismi') }
    if ($pp -and ($pp -match '(?i)\\Users\\[^\\]+\\(Downloads|Desktop|Documents)\\|\\Temp\\|\\Users\\Public\\')) {
        $sc += 25; [void]$why.Add('kullanici/temp klasorunden calisiyor')
        if (-not (Test-Signed $pp)) { $sc += 15; [void]$why.Add('imzasiz') }
    }
    if ($sc -ge 20) {
        Add-F -Kaynak 'Calisan process' -Ad $pn.ToLower() -Yol $pp -Skor ([Math]::Min(100, $sc)) -Son $pr.CreationDate -Var 'Evet' -Not (($why -join '; ') + ' | PID ' + $pr.ProcessId)
    }
    if ($isJava) {
        $cl = [string]$pr.CommandLine
        $gd = ''
        if ($cl -match '--gameDir\s+(?:"([^"]+)"|(\S+))') { $gd = $Matches[1]; if (-not $gd) { $gd = $Matches[2] } }
        if ($gd) { [void]$script:GameDirs.Add($gd) }
        [void]$script:JavaInfo.Add(('Java PID ' + $pr.ProcessId + ' (basladi: ' + (Fmt $pr.CreationDate) + ') oyun klasoru: ' + $(if ($gd) { $gd } else { 'bilinmiyor' })))
        foreach ($am in [regex]::Matches($cl, '-javaagent:(?:"([^"]+)"|([^\s"]+))')) {
            $ap = $am.Groups[1].Value
            if (-not $ap) { $ap = $am.Groups[2].Value }
            $eq = $ap.IndexOf('=')
            if ($eq -gt 0) { $ap = $ap.Substring(0, $eq) }
            $asc = 30
            $anote = '-javaagent ile yuklenmis (oyuna dis kod yukler; Lunar/Badlion gibi launcher''lar da kullanir)'
            $ah = Get-NameHit $ap $false
            if ($ah) { $asc += 35; $anote = $anote + ' | isim: ' + $ah.Name }
            $api = Test-PathInfo $ap
            $avar = 'Hayir'
            if ($api.Exists) { $avar = 'Evet' }
            Add-F -Kaynak 'Java komut satiri' -Ad ('javaagent: ' + (Split-Path -Leaf $ap).ToLower()) -Yol $ap -Skor $asc -Son $pr.CreationDate -Var $avar -Not $anote
        }
        foreach ($fl in @('-Xbootclasspath', '-agentpath', '-agentlib', '-noverify', '-Xverify:none', '-Djdk.attach.allowAttachSelf')) {
            if ($cl.IndexOf($fl, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                Add-F -Kaynak 'Java komut satiri' -Ad ('javaparam: ' + $fl) -Yol ('PID ' + $pr.ProcessId) -Skor 35 -Son $pr.CreationDate -Var 'Evet' -Not ('Java baslatma parametresi: ' + $fl + ' (dogrulamayi atlar / dis kod yukler)')
            }
        }
        try {
            $gp = Get-Process -Id $pr.ProcessId -ErrorAction Stop
            foreach ($mod in $gp.Modules) {
                $mp2 = $mod.FileName
                if ((Test-SysPathOk $mp2) -or $mp2 -match '(?i)\\Program Files') { continue }
                $mh = Get-NameHit $mod.ModuleName $false
                $mz = Get-Zone $mp2
                $bad = $false
                $why2 = ''
                if ($mh) {
                    $bad = $true; $why2 = 'isim: ' + $mh.Name
                } elseif (($mz -eq 'user' -or $mz -eq 'shared' -or $mz -eq 'other') -and ($mp2 -notmatch '(?i)\\\.minecraft\\|ModrinthApp|PrismLauncher|\.lunarclient|\\runtime\\|\\jre|\\jdk|\\java') -and -not (Test-Signed $mp2)) {
                    $bad = $true; $why2 = 'imzasiz modul, olagan disi yerde'
                }
                if ($bad) {
                    Add-F -Kaynak 'Java modulu (injection)' -Ad $mod.ModuleName.ToLower() -Yol $mp2 -Skor 65 -Son $pr.CreationDate -Var 'Evet' -Not ('calisan Java icine yuklenmis DLL: ' + $why2)
                }
            }
        } catch {}
    }
}
if ($script:HkOk) {
    $OverlayOk = @('explorer', 'dwm', 'TextInputHost', 'ShellExperienceHost', 'SearchHost', 'SearchApp', 'StartMenuExperienceHost', 'ApplicationFrameHost', 'NVIDIA Overlay', 'nvcontainer', 'NVIDIA Share', 'RTSS', 'MSIAfterburner', 'Discord', 'steamwebhelper', 'steam', 'GameBar', 'XboxGameBar', 'GameBarPresenceWriter', 'obs64', 'Medal', 'Overwolf', 'OverwolfBrowser', 'RadeonSoftware', 'AMDRSSrcExt', 'LockApp', 'ScreenClippingHost', 'SnippingTool', 'PowerToys', 'Lightshot', 'Rainmeter', 'ShareX')
    try {
        foreach ($o in [HkNative]::Overlays()) {
            $parts = $o.Split('|')
            $opid = [int]$parts[0]
            $pname = ''
            try { $pname = (Get-Process -Id $opid -ErrorAction Stop).ProcessName } catch {}
            if ($pname -and ($OverlayOk -notcontains $pname)) {
                $opath = ''
                try { $opath = (Get-Process -Id $opid -ErrorAction Stop).Path } catch {}
                Add-F -Kaynak 'Overlay penceresi' -Ad ('overlay: ' + $pname.ToLower()) -Yol $opath -Skor 40 -Var 'Evet' -Not ('saydam + hep ustte + tiklamayi gecirgen pencere (harici ESP/overlay olabilir). Baslik: ' + $parts[1] + ' boyut: ' + $parts[2])
            }
        }
    } catch {}
}
Show-Section

# ---------------------------------------------------------------------
Step '[4/17] Prefetch: calistirilan programlar ve calisma saatleri...'
Start-Sec
$pfCount = 0
foreach ($pf in $pfFiles) {
    try {
        $info = Read-Prefetch $pf.FullName
        $exe = $info.Exe
        if (-not $exe) { $exe = ($pf.BaseName -split '-')[0] }
        $pathFull = $null
        foreach ($sp in $info.Paths) { if ($sp -like ('*\' + $exe)) { $pathFull = $sp; break } }
        $last = $pf.LastWriteTime
        $runsTxt = ''
        if ($info.Runs.Count -gt 0) {
            $sorted = @($info.Runs | Sort-Object -Descending)
            $last = $sorted[0]
            $runsTxt = 'Prefetch calisma saatleri: ' + ((@($sorted | Select-Object -First 8) | ForEach-Object { Fmt $_ }) -join ', ')
        }
        $pfCount++
        if ($exe -ieq 'WMIC.EXE') {
            Add-Sys 'WMIC.EXE calistirilmis (Prefetch)' 10 'wmic ile exe/dosya baslatmak hilelerde kullanilabilir, ama bircok oyun/launcher/anticheat/donanim araci da donanim bilgisi okumak icin wmic calistirir; tek basina supheli degil.' $last $runsTxt $null
        }
        if ($pathFull) {
            $rr = Resolve-PfPath $pathFull
            [void]$script:PfExecs.Add([pscustomobject]@{ Exe = $exe; Path = $rr.Path; Exists = $rr.Exists; Last = $last })
            Eval-Exec -Kaynak 'Prefetch' -Path $rr.Path -Exists $rr.Exists -Removed $rr.Removed -Last $last -First $pf.CreationTime -Note $runsTxt
        } else {
            Eval-Exec -Kaynak 'Prefetch' -Path $exe -Last $last -First $pf.CreationTime -Note $runsTxt -NoLoc
        }
    } catch {}
}
Log ('   ' + $pfCount + ' Prefetch kaydi incelendi.') 'DarkGray'
Show-Section

# ---------------------------------------------------------------------
Step '[5/17] BAM: programlarin son calistirma zamani (kayit defteri)...'
Start-Sec
$bamCount = 0
foreach ($root in @('HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings', 'HKLM:\SYSTEM\CurrentControlSet\Services\bam\UserSettings')) {
    if (-not (Test-Path $root)) { continue }
    foreach ($sk in @(Get-ChildItem $root)) {
        foreach ($vn in $sk.GetValueNames()) {
            if ($vn -notmatch '^\\Device\\|^[A-Za-z]:\\') { continue }
            $bytes = $sk.GetValue($vn)
            $t = $null
            if ($bytes -is [byte[]] -and $bytes.Length -ge 8) { $t = Hk-Ft ([BitConverter]::ToInt64($bytes, 0)) }
            $rp = Resolve-NtPath $vn
            try { $script:BamLeaves[(Split-Path -Leaf $rp.Path).ToLower()] = 1 } catch {}
            Eval-Exec -Kaynak 'BAM' -Path $rp.Path -Exists $rp.Exists -Removed $rp.Removed -Last $t -Note 'BAM son calistirma kaydi'
            $bamCount++
        }
    }
}
Log ('   ' + $bamCount + ' BAM kaydi incelendi.') 'DarkGray'
Show-Section

# ---------------------------------------------------------------------
Step '[6/17] UserAssist: calistirma sayisi ve zamani...'
Start-Sec
$KnownFolders = @{
    '{374DE290-123F-4565-9164-39C4925E467B}' = ($UP + '\Downloads')
    '{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}' = ($UP + '\Desktop')
    '{FDD39AD0-238F-46AF-ADB4-6C85480369C7}' = ($UP + '\Documents')
    '{3EB685DB-65F9-4CF6-A03A-E3EF65729F3D}' = $env:APPDATA
    '{F1B32785-6FBA-4FCF-9D55-7B8E7F157091}' = $env:LOCALAPPDATA
    '{5E6C858F-0E22-4760-9AFE-EA3317B67173}' = $UP
    '{905E63B6-C1BF-494E-B29C-65B732D3D21A}' = 'C:\Program Files'
    '{6D809377-6AF0-444B-8957-A3773F02200E}' = 'C:\Program Files'
    '{7C5A40EF-A0FB-4BFC-874A-C0F2E0B9FA8E}' = 'C:\Program Files (x86)'
    '{F38BF404-1D43-42F2-9305-67DE0B28FC23}' = 'C:\Windows'
    '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}' = 'C:\Windows\System32'
}
$uaCount = 0
$uaRoot = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist'
foreach ($g in @(Get-ChildItem $uaRoot)) {
    $ck = $g.OpenSubKey('Count')
    if (-not $ck) { continue }
    foreach ($vn in $ck.GetValueNames()) {
        $dec = Rot13 $vn
        if ($dec -notmatch '(?i)\.exe$') { continue }
        foreach ($kf in $KnownFolders.Keys) { if ($dec.StartsWith($kf, [StringComparison]::OrdinalIgnoreCase)) { $dec = $KnownFolders[$kf] + $dec.Substring($kf.Length); break } }
        if ($dec -notmatch '^[A-Za-z]:\\') { continue }
        $bytes = $ck.GetValue($vn)
        $t = $null
        $cnt = ''
        if ($bytes -is [byte[]] -and $bytes.Length -ge 68) {
            $t = Hk-Ft ([BitConverter]::ToInt64($bytes, 60))
            $cnt = 'UserAssist calistirma sayisi: ' + [BitConverter]::ToUInt32($bytes, 4)
        }
        $pi = Test-PathInfo $dec
        Eval-Exec -Kaynak 'UserAssist' -Path $dec -Exists $pi.Exists -Removed $pi.Removed -Last $t -Note $cnt
        $uaCount++
    }
}
Log ('   ' + $uaCount + ' UserAssist kaydi incelendi.') 'DarkGray'
Show-Section

# ---------------------------------------------------------------------
Step '[7/17] Amcache: program envanteri (silinmis programlarin izi)...'
$amCount = 0
$amReason = ''
$amDir = Join-Path $env:TEMP ('hk_amc_' + [guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $amDir -Force -ErrorAction SilentlyContinue)
$amSrc = $env:WINDIR + '\appcompat\Programs\Amcache.hve'
$amTmp = Join-Path $amDir 'Amcache.hve'
$copied = $false
try {
    $eo = & esentutl.exe /y /vss $amSrc /d $amTmp 2>&1
    if (Test-Path -LiteralPath $amTmp) { $copied = $true } else { $amReason = 'esentutl: ' + ((($eo | Out-String).Trim()) -replace '\s+', ' ') }
} catch { $amReason = 'esentutl calistirilamadi: ' + $_.Exception.Message }
if (-not $copied) {
    try { Copy-Item -LiteralPath $amSrc -Destination $amTmp -Force -ErrorAction Stop; $copied = $true } catch { $amReason = $amReason + ' | dogrudan kopya: ' + $_.Exception.Message }
}
if ($copied) {
    foreach ($lgx in @('.LOG1', '.LOG2')) {
        if (-not (Test-Path -LiteralPath ($amTmp + $lgx))) {
            try { & esentutl.exe /y /vss ($amSrc + $lgx) /d ($amTmp + $lgx) 2>&1 | Out-Null } catch {}
            if (-not (Test-Path -LiteralPath ($amTmp + $lgx))) { try { Copy-Item -LiteralPath ($amSrc + $lgx) -Destination ($amTmp + $lgx) -Force -ErrorAction Stop } catch {} }
        }
    }
    $loaded = $false
    $hkn = 'HK_AMC_' + (Get-Random -Maximum 99999)
    $lo = & reg.exe load ('HKLM\' + $hkn) $amTmp 2>&1
    if ($LASTEXITCODE -eq 0) {
        $loaded = $true
    } else {
        Start-Sleep -Milliseconds 400
        $lo = & reg.exe load ('HKLM\' + $hkn) $amTmp 2>&1
        if ($LASTEXITCODE -eq 0) { $loaded = $true } else {
            $amReason = 'hive yuklenemedi: ' + ((($lo | Out-String).Trim()) -replace '\s+', ' ') + ' (ham tarama yapildi)'
            try {
                $amHb = [IO.File]::ReadAllBytes($amTmp)
                Start-Sec
                foreach ($ap in @(Get-PathsFromBytes $amHb $false)) {
                    if ($ap -match '(?i)^[a-z]:\\(windows|program files)') { continue }
                    $pi = Test-PathInfo $ap
                    Eval-Exec -Kaynak 'Amcache' -Path $ap -Exists $pi.Exists -Removed $pi.Removed -Note 'Amcache (ham tarama; hive yuklenemedi)'
                    $amCount++
                }
            } catch {}
        }
    }
    if ($loaded) {
        Start-Sec
        try {
            $rk = 'Registry::HKEY_LOCAL_MACHINE\' + $hkn + '\Root\InventoryApplicationFile'
            foreach ($k in @(Get-ChildItem -LiteralPath $rk -ErrorAction SilentlyContinue)) {
                $ap = [string]$k.GetValue('LowerCaseLongPath')
                if (-not $ap) { $k.Close(); continue }
                if ($ap -match '(?i)^[a-z]:\\(windows|program files)') { $k.Close(); continue }
                $kt = Get-KeyTime $k
                $pub = [string]$k.GetValue('Publisher')
                $sha = [string]$k.GetValue('FileId')
                $k.Close()
                $pi = Test-PathInfo $ap
                $nt = 'Amcache kaydi'
                if ($pub) { $nt = $nt + ' | yayinci: ' + $pub } else { $nt = $nt + ' | yayinci yok' }
                if ($sha.Length -gt 4) { $nt = $nt + ' | SHA1: ' + $sha.Substring(4) }
                Eval-Exec -Kaynak 'Amcache' -Path $ap -Exists $pi.Exists -Removed $pi.Removed -First $kt -Note $nt
                $amCount++
            }
        } catch {}
        [gc]::Collect()
        [gc]::WaitForPendingFinalizers()
        Start-Sleep -Milliseconds 300
        & reg.exe unload ('HKLM\' + $hkn) 2>&1 | Out-Null
    }
}
Remove-Item -LiteralPath $amDir -Recurse -Force -ErrorAction SilentlyContinue
if ($amCount -eq 0) {
    if ($amReason.Length -gt 300) { $amReason = $amReason.Substring(0, 300) + '...' }
    if (-not $amReason) { $amReason = 'kayit bulunamadi' }
    Log ('   Amcache okunamadi. Neden: ' + $amReason) 'DarkYellow'
} else {
    Perf-Lap '7: Amcache okuma + imza/yol kontrolu'
    Log ('   ' + $amCount + ' Amcache kaydi incelendi.') 'DarkGray'
    Show-Section
}

# ---------------------------------------------------------------------
Step '[8/17] Shimcache (AppCompatCache) yol taramasi...'
Start-Sec
$shCount = 0
try {
    $blob = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache' -ErrorAction Stop).AppCompatCache
    if ($blob -is [byte[]]) {
        $seenSh = @{}
        foreach ($off in @(0, 1)) {
            $len = $blob.Length - $off
            $sub = New-Object byte[] $len
            [Array]::Copy($blob, $off, $sub, 0, $len)
            $txt = [Text.Encoding]::Unicode.GetString($sub)
            foreach ($pm in (Find-Paths $txt 'exe|jar|bat|ps1|scr|cmd|vbs')) {
                $lk = $pm.ToLower()
                if ($seenSh.ContainsKey($lk)) { continue }
                $seenSh[$lk] = 1
                $pi = Test-PathInfo $pm
                Eval-Exec -Kaynak 'Shimcache' -Path $pm -Exists $pi.Exists -Removed $pi.Removed -Note 'Shimcache kaydi (zaman bilgisi yok)'
                $shCount++
            }
        }
    }
} catch {}
Perf-Lap '8: Shimcache okuma + yol kontrolu'
Log ('   ' + $shCount + ' Shimcache yolu incelendi.') 'DarkGray'
Show-Section

# ---------------------------------------------------------------------
Step '[9/17] Recent (shell:recent) / Jump List / RecentDocs / RunMRU kayitlari...'
Start-Sec
function Read-Lnk([string]$p) {
    $r = @{ Target = ''; Drive = -1; Serial = ''; Label = ''; Size = [long]0; Args = ''; Rel = '' }
    try {
        $b = [IO.File]::ReadAllBytes($p)
        if ($b.Length -lt 76 -or [BitConverter]::ToUInt32($b, 0) -ne 76) { return $r }
        $fl = [BitConverter]::ToUInt32($b, 20)
        $r.Size = [long][BitConverter]::ToUInt32($b, 52)
        $o = 76
        if ($fl -band 1) { $o += 2 + [int][BitConverter]::ToUInt16($b, $o) }
        if ($fl -band 2) {
            $li = $o
            $lsz = [int][BitConverter]::ToUInt32($b, $li)
            $lf = [BitConverter]::ToUInt32($b, $li + 8)
            if ($lf -band 1) {
                $vo = $li + [int][BitConverter]::ToUInt32($b, $li + 12)
                $r.Drive = [int][BitConverter]::ToUInt32($b, $vo + 4)
                $r.Serial = ([BitConverter]::ToUInt32($b, $vo + 8)).ToString('X8')
                $lo2 = $vo + [int][BitConverter]::ToUInt32($b, $vo + 12)
                $e = $lo2; while ($e -lt $b.Length -and $b[$e] -ne 0) { $e++ }
                $r.Label = [Text.Encoding]::Default.GetString($b, $lo2, $e - $lo2)
                $bo = $li + [int][BitConverter]::ToUInt32($b, $li + 16)
                $e = $bo; while ($e -lt $b.Length -and $b[$e] -ne 0) { $e++ }
                $r.Target = [Text.Encoding]::Default.GetString($b, $bo, $e - $bo)
            }
            $o = $li + $lsz
        }
        $uni = (($fl -band 128) -ne 0)
        foreach ($bit in @(4, 8, 16, 32)) {
            if (-not ($fl -band $bit)) { continue }
            if ($o + 2 -gt $b.Length) { break }
            $cnt = [int][BitConverter]::ToUInt16($b, $o); $o += 2
            $len = $cnt; if ($uni) { $len = $cnt * 2 }
            if ($o + $len -gt $b.Length) { break }
            if ($uni) { $s = [Text.Encoding]::Unicode.GetString($b, $o, $len) } else { $s = [Text.Encoding]::Default.GetString($b, $o, $len) }
            $o += $len
            if ($bit -eq 8) { $r.Rel = $s } elseif ($bit -eq 32) { $r.Args = $s }
        }
    } catch {}
    return $r
}
$recentDir = Join-Path $env:APPDATA 'Microsoft\Windows\Recent'
$lnks = @(Get-ChildItem -LiteralPath $recentDir -Filter '*.lnk' -Force -ErrorAction SilentlyContinue)
Log ('   Recent klasorunde ' + $lnks.Count + ' kisayol var.') 'DarkGray'
if ($lnks.Count -lt 5) { Add-Sys 'Recent (Son kullanilanlar) neredeyse bos' 30 'Temizlenmis olabilir (normalde onlarca kayit olur).' }
try {
    $rdi = Get-Item -LiteralPath $recentDir -Force
    if ($lnks.Count -gt 0 -and $lnks.Count -lt 100) {
        $newestC = ($lnks | Sort-Object CreationTime -Descending | Select-Object -First 1).CreationTime
        if ($rdi.LastWriteTime -gt $newestC.AddHours(1) -and $rdi.LastWriteTime -gt (Get-Date).AddDays(-30)) {
            Add-Sys 'Recent klasorunden kayit silinmis olabilir' 25 'Klasorun son degisim zamani en yeni kisayoldan cok sonra: kisayol(lar) silinmis olabilir (Windows 150 kayit sinirinda eskileri de siler).' $rdi.LastWriteTime ('klasor: ' + (Fmt $rdi.LastWriteTime) + ' | en yeni kisayol: ' + (Fmt $newestC))
        }
    }
} catch {}
$adDir = Join-Path $recentDir 'AutomaticDestinations'
if (-not (Test-Path -LiteralPath $adDir)) {
    Add-Sys 'Jump List klasoru (AutomaticDestinations) YOK' 35 'Normalde bulunur; silinmis olabilir.'
} elseif (@(Get-ChildItem -LiteralPath $adDir -File -Force -ErrorAction SilentlyContinue).Count -lt 3) {
    Add-Sys 'Jump List (AutomaticDestinations) neredeyse bos' 30 'Normalde onlarca dosya olur; temizlenmis olabilir.'
}
$wsh = $null
try { $wsh = New-Object -ComObject WScript.Shell } catch {}
$magCount = 0
foreach ($l in $lnks) {
    $target = ''
    try { if ($wsh) { $target = [string]$wsh.CreateShortcut($l.FullName).TargetPath } } catch {}
    $lk = Read-Lnk $l.FullName
    if ([string]::IsNullOrWhiteSpace($target)) { $target = [string]$lk.Target }
    if ([string]::IsNullOrWhiteSpace($target) -and $lk.Rel) { $target = [string]$lk.Rel }
    $tExt = ''
    try { $tExt = [IO.Path]::GetExtension($target).ToLower() } catch {}
    $lh = Get-NameHit $l.BaseName $true
    $bnL = $l.BaseName
    $bnExt = ''
    $bnStem = $bnL
    try { $bnExt = [IO.Path]::GetExtension($bnL).ToLower(); $bnStem = [IO.Path]::GetFileNameWithoutExtension($bnL) } catch {}
    if (($script:CodeExtSet -contains $bnExt) -and (Test-Gibberish $bnStem)) {
        $gv = 'Bilinmiyor'
        $gy = $bnL
        if ($target -match '^[A-Za-z]:\\') {
            $gp0 = Test-PathInfo $target
            $gy = $target
            if ($gp0.Exists) { $gv = 'Evet' } else { $gv = 'Hayir' }
        }
        Add-F -Kaynak 'Recent (anlamsiz dosya adi)' -Ad ($bnL.ToLower()) -Yol $gy -Skor 45 -Son $l.LastWriteTime -Ilk $l.CreationTime -Var $gv -Not 'Recent klasorunde rastgele/anlamsiz karakterli kod dosyasi (ornek: asdhjsa.jar, hasdih.exe); hile dosyalari sik boyle adlandirilir'
    }
    if ($lk.Args) {
        $ah = Get-NameHit $lk.Args $false
        if ($ah) { Add-F -Kaynak 'Recent (kisayol argumani)' -Ad ($l.BaseName.ToLower()) -Yol $target -Skor 50 -Son $l.LastWriteTime -Ilk $l.CreationTime -Not ('kisayol argumaninda hile ismi: ' + $ah.Name + ' | arguman: ' + $lk.Args) }
        elseif ($lk.Args -match '(?i)-javaagent') { Add-F -Kaynak 'Recent (kisayol argumani)' -Ad ($l.BaseName.ToLower()) -Yol $target -Skor 45 -Son $l.LastWriteTime -Ilk $l.CreationTime -Not ('kisayol javaagent ile calistiriyor: ' + $lk.Args) }
    }
    if ($target -match '^[A-Za-z]:\\' -and (($IntExt -contains $tExt) -or ($DisguiseExt -contains $tExt))) {
        $piT = Test-PathInfo $target
        $vT = 'Hayir'; if ($piT.Exists) { $vT = 'Evet' }
        if ($lk.Drive -eq 2 -or $lk.Drive -eq 4) {
            $dtx = 'cikarilabilir disk (USB)'; if ($lk.Drive -eq 4) { $dtx = 'ag surucusu' }
            Add-F -Kaynak 'Recent (USB/harici disk)' -Ad ($l.BaseName.ToLower()) -Yol $target -Skor 40 -Son $l.LastWriteTime -Ilk $l.CreationTime -Var $vT -Not ('dosya ' + $dtx + ' uzerinden acilmis (disk seri: ' + $lk.Serial + ', etiket: ' + $lk.Label + ')')
        }
        if ((-not $piT.Exists) -and (-not $piT.Removed) -and $lk.Size -ge 20480) {
            $dirT = ''
            try { $dirT = Split-Path -Parent $target } catch {}
            if ($dirT -and (Test-Path -LiteralPath $dirT)) {
                $mc = 0
                foreach ($cf in @(Get-ChildItem -LiteralPath $dirT -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.Length -eq $lk.Size })) {
                    if ($mc -ge 3) { break }
                    $mc++
                    Add-F -Kaynak 'Recent (yeniden adlandirilmis dosya)' -Ad ($cf.Name.ToLower()) -Yol $cf.FullName -Skor 60 -Son $l.LastWriteTime -Ilk $l.CreationTime -Var 'Evet' -Not ('kisayol ' + $l.Name + ' -> ' + $target + ' artik yok; ayni klasorde AYNI BOYUTTA (' + $lk.Size + ' bayt) dosya var: ' + $cf.Name + ' (yeniden adlandirilmis olabilir)')
                }
            }
        }
        if ($piT.Exists -and ($DisguiseExt -contains $tExt) -and $lk.Size -ge 20480 -and $magCount -lt 400) {
            $magCount++
            $mgR = Get-Magic $target
            if ($mgR -eq 'MZ' -or $mgR -eq 'PK') {
                Add-F -Kaynak 'Recent (uzanti degistirilmis)' -Ad ($l.BaseName.ToLower()) -Yol $target -Skor 55 -Son $l.LastWriteTime -Ilk $l.CreationTime -Var 'Evet' -Not ('acilmis dosyanin uzantisi ' + $tExt + ' ama icerigi ' + $mgR + ' (program/jar): uzanti degistirilmis')
            }
        }
    }
    if ([string]::IsNullOrWhiteSpace($target)) {
        if ($lh) { Eval-Exec -Kaynak 'Recent (kisayol)' -Path $l.BaseName -Last $l.LastWriteTime -First $l.CreationTime -Note ('kisayol: ' + $l.Name) -NoLoc }
    } elseif (($IntExt -contains $tExt) -or $lh) {
        $pi = Test-PathInfo $target
        Eval-Exec -Kaynak 'Recent (kisayol)' -Path $target -Exists $pi.Exists -Removed $pi.Removed -Last $l.LastWriteTime -First $l.CreationTime -Note ('kisayol: ' + $l.Name)
    }
}
$jlCount = 0
foreach ($jd in @((Join-Path $recentDir 'AutomaticDestinations'), (Join-Path $recentDir 'CustomDestinations'))) {
    foreach ($jf in @(Get-ChildItem -LiteralPath $jd -File -Force -ErrorAction SilentlyContinue)) {
        try {
            $jb = [IO.File]::ReadAllBytes($jf.FullName)
            $jp = @{}
            foreach ($enc in @([Text.Encoding]::Unicode, [Text.Encoding]::ASCII)) {
                $jt = $enc.GetString($jb)
                foreach ($pm in (Find-Paths $jt 'exe|dll|jar|bat|cmd|ps1|vbs|scr|msi|com|zip|rar|7z')) { $jp[$pm] = 1 }
            }
            foreach ($pth in $jp.Keys) {
                $pi = Test-PathInfo $pth
                Eval-Exec -Kaynak 'Jump List' -Path $pth -Exists $pi.Exists -Removed $pi.Removed -Last $jf.LastWriteTime -Note 'Jump List kaydi (zaman = uygulamanin liste dosyasi)'
                $jlCount++
            }
        } catch {}
    }
}
Log ('   ' + $jlCount + ' Jump List yolu incelendi.') 'DarkGray'
# --- Kayit defteri karsiliklari: RecentDocs (shell:recent), RunMRU (Win+R), TypedPaths (adres cubugu) ---
$rdCount = 0
try {
    $rdKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs'
    foreach ($rk in @(@(Get-Item -LiteralPath $rdKey -ErrorAction SilentlyContinue) + @(Get-ChildItem -LiteralPath $rdKey -ErrorAction SilentlyContinue))) {
        if (-not $rk) { continue }
        $rkt = Get-KeyTime $rk
        foreach ($vn in $rk.GetValueNames()) {
            if ($vn -notmatch '^\d+$') { continue }
            $vb = $rk.GetValue($vn)
            if ($vb -isnot [byte[]]) { continue }
            $e = 0
            while ($e + 1 -lt $vb.Length -and -not ($vb[$e] -eq 0 -and $vb[$e + 1] -eq 0)) { $e += 2 }
            $nm = [Text.Encoding]::Unicode.GetString($vb, 0, $e)
            if (-not $nm) { continue }
            $rdCount++
            $rdExt = ''; $rdStem = $nm
            try { $rdExt = [IO.Path]::GetExtension($nm).ToLower(); $rdStem = [IO.Path]::GetFileNameWithoutExtension($nm) } catch {}
            if (($script:CodeExtSet -contains $rdExt) -and (Test-Gibberish $rdStem)) {
                Add-F -Kaynak 'RecentDocs (anlamsiz dosya adi)' -Ad $nm.ToLower() -Yol $nm -Skor 35 -Son $rkt -Not 'Gezgin son kullanilanlar kaydinda rastgele adli kod dosyasi'
            }
            Eval-Exec -Kaynak 'RecentDocs (kayit defteri)' -Path $nm -Last $rkt -Note 'Gezgin RecentDocs kaydi (zaman = anahtar son yazma)' -NoLoc
        }
    }
} catch {}
try {
    $rmk = Get-Item -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU' -ErrorAction Stop
    $rmt = Get-KeyTime $rmk
    foreach ($vn in $rmk.GetValueNames()) {
        if ($vn -eq 'MRUList') { continue }
        $cmd = ([string]$rmk.GetValue($vn)) -replace '\\1$', ''
        if (-not $cmd) { continue }
        $rdCount++
        if ($cmd -match '(?i)wevtutil|fsutil\s+usn|Clear-EventLog|\b(sc|net)(\.exe)?\s+(stop|config)\s+\S*(eventlog|dps|sysmain|pcasvc|bam|windefend)|cipher\s*/w|Set-MpPreference|Add-MpPreference') {
            Add-Sys ('Calistir (Win+R) gecmisinde iz temizleme/servis komutu: ' + $cmd) 50 'Win+R ile iz silme, log temizleme veya servis durdurma komutu calistirilmis.' $rmt
        }
        $rh = Get-NameHit $cmd $false
        if ($rh) { Add-F -Kaynak 'RunMRU (Win+R)' -Ad $cmd.ToLower() -Yol $cmd -Skor 50 -Son $rmt -Not ('Win+R gecmisinde hile ismi: ' + $rh.Name) }
        foreach ($pm in (Find-Paths $cmd 'exe|jar|bat|cmd|ps1|vbs|dll|msi')) {
            $pi = Test-PathInfo $pm
            Eval-Exec -Kaynak 'RunMRU (Win+R)' -Path $pm -Exists $pi.Exists -Removed $pi.Removed -Last $rmt -Note 'Win+R ile calistirilmis'
        }
    }
} catch {}
try {
    $tpk = Get-Item -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths' -ErrorAction Stop
    $tpt = Get-KeyTime $tpk
    foreach ($vn in $tpk.GetValueNames()) {
        $tp = [string]$tpk.GetValue($vn)
        if (-not $tp) { continue }
        $th = Get-NameHit $tp $false
        if ($th) { Add-F -Kaynak 'TypedPaths (adres cubugu)' -Ad $tp.ToLower() -Yol $tp -Skor 40 -Son $tpt -Not ('Gezgin adres cubuguna yazilan yolda hile ismi: ' + $th.Name) }
    }
} catch {}
Log ('   ' + $rdCount + ' RecentDocs/RunMRU kaydi incelendi.') 'DarkGray'
Show-Section

# =====================================================================
# MOD KLASORU ANALIZI (Meow Mod Analyzer mantigi, HileKiran yapisina uyarlandi)
# Sadece OKUR. Tek ag kullanimi: mod dosyasinin SHA1 hash i Modrinth/Megabase te aranir (HK_NONET=1 ile kapatilir).
# =====================================================================
Step '[10/17] MOD KLASORU ANALIZI: .jar modlarin hash dogrulamasi, hile stringleri, bypass/enjeksiyon, obfuscation, JVM agent...'
Start-Sec

function ConvertTo-Fw([string]$s) {
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $s.ToCharArray()) {
        $c = [int]$ch
        if (($c -ge 48 -and $c -le 57) -or ($c -ge 65 -and $c -le 90) -or ($c -ge 97 -and $c -le 122)) { [void]$sb.Append([char]($c + 0xFEE0)) }
        elseif ($c -eq 45) { [void]$sb.Append([char]0xFF0D) }
        elseif ($c -eq 44) { [void]$sb.Append([char]0xFF0C) }
        else { [void]$sb.Append($ch) }
    }
    return $sb.ToString()
}

$script:MmNet = ($env:HK_NONET -ne '1')
$script:MmFails = 0
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}

# ---- desen listesi (entry adlari + class icerigi; regex, buyuk/kucuk harf duyarli) ----
$mmPatList = @(
    'AimAssist','AnchorTweaks','AutoAnchor','AutoCrystal','AutoDoubleHand','JDWP.VirtualMachine.AllModules',
    'AutoHitCrystal','AutoPot','AutoTotem','AutoArmor','InventoryTotem','LegitTotem','PingSpoof','SelfDestruct',
    'ShieldBreaker','TriggerBot','AxeSpam','WebMacro','FastPlace','WalskyOptimizer','WalksyOptimizer','walsky.optimizer',
    'WalksyCrystalOptimizerMod','Donut','Replace Mod','ShieldDisabler','SilentAim','Totem Hit','Wtap','FakeLag','dev.virel','orchard',
    'BlockESP','dev.krypton','dev/krypton','skid.krypton','skid/krypton','AntiMissClick','LagReach','PopSwitch','SprintReset',
    'ChestSteal','AntiBot','ElytraSwap','FastXP','FastExp','Refill','AirAnchor','jnativehook','FakeInv','HoverTotem',
    'AutoClicker','AutoFirework','PackSpoof','Antiknockback','catlean','AuthBypass','Asteria','Prestige','AutoEat','AutoMine',
    'MaceSwap','Macro198','StunSlam','SafeAnchor','DoubleAnchor','AutoTPA','BaseFinder','Xenon','gypsy','AutoPotRefill',
    'KeyPearl','AutoNethPot','AutoDtap','AutoWeb','AnchorAction',
    'org.chainlibs.module.impl.modules.Crystal.Y','org.chainlibs.module.impl.modules.Crystal.bF','org.chainlibs.module.impl.modules.Crystal.bM',
    'org.chainlibs.module.impl.modules.Crystal.bY','org.chainlibs.module.impl.modules.Crystal.bq','org.chainlibs.module.impl.modules.Crystal.cv',
    'org.chainlibs.module.impl.modules.Crystal.o','org.chainlibs.module.impl.modules.Blatant.I','org.chainlibs.module.impl.modules.Blatant.bR',
    'org.chainlibs.module.impl.modules.Blatant.bx','org.chainlibs.module.impl.modules.Blatant.cj','org.chainlibs.module.impl.modules.Blatant.dk',
    'imgui.gl3','imgui.glfw','BowAim','Criticals','Fakenick','FakeItem','invsee','ItemExploit','Hellion','hellion',
    'LicenseCheckMixin','ClientPlayerInteractionManagerAccessor','ClientPlayerEntityMixim','dev.gambleclient','obfuscatedAuth',
    'phantom-refmap.json','xyz.greaj',
    'HighStep','WaterWalk','LiquidWalk','LavaWalk','NoSlow','NoSlowdown','NoWeb','NoSoulSand','WallHack','ElytraSpeed','InstantElytra',
    'ScaffoldWalk','FastBridge','BuildHelper','AutoBridge','Nuker','NukerLegit','InstantBreak',
    'GhostHand','NoSwing','PlaceAssist','AirPlace','AutoPlace','InstantPlace',
    'PlayerESP','MobESP','ItemESP','StorageESP','ChestESP','Tracers','NameTagsHack','XRayHack','OreFinder','CaveFinder','OreESP',
    'NewChunks','ChunkBorders','TunnelFinder','TargetHUD','ReachDisplay','DoubleClicker','JitterClick','ButterflyClick','CPSBoost',
    'ChestStealer','InvManager','InvMovebypass','AutoSprint','AntiAFK','AutoRespawn',
    'FakeLatency','FakePing','SpoofRotation','PositionSpoof','GameSpeed','SpeedTimer','GrimBypass','VulcanBypass','MatrixBypass',
    'AACBypass','VerusDisabler','IntaveBypass','WatchdogBypass',
    'PacketMine','PacketWalk','PacketSneak','PacketCancel','PacketDupe','PacketSpam',
    'HideClient','SessionStealer','TokenLogger','TokenGrabber','DiscordToken','RemoteAccess','ReverseShell','C2Server','Backdoor','KeyLogger',
    'StashFinder','TrailFinder','imgui.binding','JNativeHook','GlobalScreen','NativeKeyListener','client-refmap.json','cheat-refmap.json',
    'aHR0cDovL2FwaS5ub3ZhY2xpZW50LmxvbC93ZWJob29rLnR4dA==',
    'meteordevelopment','cc/novoline','com/alan/clients','club/maxstats','wtf/moonlight','me/zeroeightsix/kami','net/ccbluex','today/opai',
    'net/minecraft/injection','org/chainlibs/module/impl/modules','xyz/greaj','com/cheatbreaker','com/moonsworth',
    'doomsdayclient','DoomsdayClient','doomsday.jar','novaclient','api.novaclient.lol','LWFH Crystal',
    'vape.gg','vapeclient','VapeClient','VapeLite','intent.store','IntentClient','rise.today','riseclient.com',
    'meteor-client','meteorclient','meteordevelopment.meteorclient','liquidbounce','fdp-client','net.ccbluex','novoware','novoclient',
    'aristois','impactclient','azura','pandaware','skilled','moonClient','astolfo','futureClient','konas','rusherhack','inertia','exhibition',
    'VirginClient','virgin client','CatleanClient','catlean client','ArgonClient','argon client','AsteriaClient','asteria client',
    'PrestigeClient','prestige client','prestigeclient.vip','GypsyClient','gypsy client','XenonClient','xenon client',
    'GrimClient','grim client','dqrkis.xyz','Dqrkis Client',
    'phobia','Phobia','nightix','Nightix','blade-reload','BladeReload','velka','Velka','aethereal','Aethereal','dimasik','Dimasik','dimasik-client',
    'wild-client','delta-client','flow-client','system-dlc','SystemDLC','nursultan','Nursultan','wexside','Wexside','evaware','Evaware',
    'neverlose','Neverlose','catlavan','Catlavan','zenith-client','ZenithClient','punch-client','deluxe-client','DoomsdayClient','doomsdayclient','doomsday-client',
    'LiquidBounce','Disabler','STap','Stap','AutoSTap','AutoStap','Flight','FlightHack'
)
# Japonca sinif adi obfuscation izleri (script ASCII kalsin diye kod noktasindan uretilir)
foreach ($cp in @(0x3058,0x3075,0x3076,0x3077,0x305F,0x306D,0x305D,0x306A,0x3069,0x3050,0x305A,0x3067,0x3064,0x3079,0x305B,0x3068,0x307F,0x3073,0x3059,0x306E)) {
    $mmPatList += (([string][char]$cp) + '.class')
}
$mmPatSet = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
foreach ($p in $mmPatList) { if ($p) { [void]$mmPatSet.Add($p) } }
$mmPatSorted = @($mmPatSet | Sort-Object -Property { $_.Length } -Descending)
$mmPatAlt = ($mmPatSorted | ForEach-Object { [regex]::Escape($_) }) -join '|'
$script:MmPatRx = New-Object System.Text.RegularExpressions.Regex -ArgumentList ('(?<![A-Za-z])(' + $mmPatAlt + ')(?![A-Za-z])'), ([System.Text.RegularExpressions.RegexOptions]::Compiled)

# ---- class icerigi stringleri: hem duz hem tam genislikli (fullwidth) halleri aranir ----
$mmBoth = @(
    'AutoCrystal','Auto Crystal','AutoHitCrystal','AutoAnchor','Auto Anchor','DoubleAnchor','Double Anchor','SafeAnchor','Safe Anchor','Anchor Macro',
    'AutoTotem','Auto Totem','HoverTotem','Hover Totem','InventoryTotem','Auto Inventory Totem','Auto Totem Hit','AutoPot','Auto Pot','Auto Pot Refill',
    'AutoArmor','Auto Armor','ShieldDisabler','Shield Disabler','AutoDoubleHand','Auto Double Hand','AutoClicker','AutoMace','Auto Mace',
    'MaceSwap','Mace Swap','Spear Swap','Stun Slam','AimAssist','Aim Assist','TriggerBot','Trigger Bot','Silent Rotations','FakeLag','Fake Lag',
    'Fake Punch','Anti Web','AutoWeb','Walksy Optimizer','ElytraSwap','Elytra Swap','KeyPearl','Key Pearl','Loot Yeeter','Fast Place','Auto Breach',
    'Freecam','No Clip','Freeze Player','LWFH Crystal'
)
# Cok genel ayar adlari: sadece tam genislikli (obfuscate/gizlenmis) halleri aranir, duz halleri mesru modlarda cok gectigi icin atlanir
$mmFwOnly = @(
    'Click Simulation','On RMB','No Count Glitch','No Bounce','NoBounce','Place Delay','Break Delay','Fast Mode','Place Chance','Break Chance',
    'Stop On Kill','Damage Tick','Anti Weakness','Particle Chance','Trigger Key','Switch Delay','Totem Slot','Smooth Rotations','Rotation Speed',
    'Use Easing','Easing Strength','While Use','Glowstone Delay','Glowstone Chance','Explode Delay','Explode Chance','Explode Slot','Only Charge',
    'Reach Distance','Min Height','Min Fall Speed','Attack Delay','Breach Delay','Require Elytra','Auto Switch Back','Check Line of Sight',
    'Only When Falling','Require Crit','Show Status Display','Stop On Crystal','Check Shield','On Pop','Predict Damage','On Ground','Check Players',
    'Predict Crystals','Check Aim','Check Items','Activates Above','Blatant','Force Totem','Stay Open For','Only On Pop','Vertical Speed','Swap Speed',
    'Strict One-Tick','Mace Priority','Min Totems','Min Pearls','Totem First','Drop Interval','Random Pattern','Horizontal Aim Speed',
    'Vertical Aim Speed','Include Head','Web Delay','Holding Web','Not When Affects Player','Hit Delay','Switch Back','Require Hold Axe',
    'Activate Key','Macro Key','Places Webs On Enemies','Move freely through walls','Refills your hotbar with potions','Keeps you sprinting at all times',
    'placeInterval','breakInterval','stopOnKill','activateOnRightClick','damagetick','holdCrystal','fakePunch'
)
$mmPlainExtra = @(
    'JDWP.VirtualMachine.AllModules','dontPlaceCrystal','dontBreakCrystal','dev.virel','orchard','autocrystal','cw crystal','autohitcrystal',
    'canPlaceCrystalServer','healPotSlot','autoanchor','HasAnchor','anchortweaks','anchor macro','safe anchor','AirAnchor','anchorMacro','autototem',
    'inventorytotem','legittotem','hover totem','speedPotSlot','strengthPotSlot','autopot','auto pot','autoarmor','auto armor',
    'preventSwordBlockBreaking','preventSwordBlockAttack','ShieldBreaker','Breaking shield with axe...','autodoublehand','Failed to switch to mace after axe!',
    'SpearSwap','Donut','JumpReset','axespam','axe spam','findKnockbackSword','attackRegisteredThisClick','aimassist','triggerbot','trigger bot',
    'FakeInv','swapBackToOriginalSlot','pingspoof','ping spoof','mace_swap','quick_strike','macro_198','stun_slam','safe_anchor','double_anchor',
    'auto_pot_refill','walksy_optimizer','key_pearl','aim_assist','auto_neth_pot','auto_dtap','trigger_bot','auto_web','DOUBLE_ESCAPE',
    'DOUBLE_RIGHTCLICK_FIRST','DOUBLE_RIGHTCLICK_SECOND','POST_CYCLE_DELAY','PLACE_OBI','WAIT_OBI','PLACE_CRYSTAL','BREAK_CRYSTAL','ROTATING_DOWN',
    'ROTATING_BACK','REFILLING','PLANTING','BONEMEALING','AnchorAction','Places two anchors for massive damage','REOFFHAND_TOTEM','webmacro','web macro',
    'AntiWeb','lvstrng','dqrkis','selfdestruct','self destruct','WalksyCrystalOptimizerMod','WalksyOptimizer','WalskyOptimizer','autoCrystalPlaceClock',
    'AutoFirework','FastXP','FastExp','NoJumpDelay','PackSpoof','Antiknockback','catlean','AuthBypass','obfuscatedAuth','LicenseCheckMixin','BaseFinder',
    'invsee','ItemExploit','FreezePlayer','LootYeeter','setBlockBreakingCooldown','getBlockBreakingCooldown','blockBreakingCooldown','onBlockBreaking',
    'setItemUseCooldown','invokeDoAttack','invokeDoItemUse','invokeOnMouseButton','onPushOutOfBlocks','onIsGlowing',
    'Automatically switches to sword when hitting with totem','arrayOfString','POT_CHEATS','Dqrkis Client','Entity.isGlowing',
    'KillAura','ClickAura','MultiAura','ForceField','LegitAura','AimBot','AutoAim','SilentAim','AimLock','HeadSnap','CrystalAura','AnchorAura','AnchorFill',
    'AnchorPlace','BedAura','AutoBed','BedBomb','BedPlace','BowAimbot','BowSpam','AutoBow','AutoCrit','CritBypass','AlwaysCrit','CriticalHit','ReachHack',
    'ExtendReach','LongReach','HitboxExpand','AntiKB','NoKnockback','GrimVelocity','GrimDisabler','VelocitySpoof','KBReduce','OffhandTotem','TotemSwitch',
    'AutoWeapon','AutoSword','AutoCity','Burrow','SelfTrap','HoleFiller','AntiSurround','AntiBurrow','WTap','TargetStrafe','AutoGap','AutoPearl',
    'FlyHack','CreativeFlight','BoatFly','PacketFly','AirJump','SpeedHack','BHop','BunnyHop','AntiFall','NoFallDamage','SafeFall','StepHack','FastClimb','AutoStep'
)
# ---- KESIN LISTE: bu stringlerden BIRI BILE bir modun class/json icinde gecerse %100 hile bulgusu (aninda ekrana yazilir) ----
# Sadece ayirt edici kelimeler: onTick/onRender/inject/HUD/toggle/key/Hit gibi genel kelimeler HER modda gectigi icin bilerek yok.
$mmCertain = @(
    # hile enjektoru (injector) arayuz/site yazilari: jar bir yukleyici/enjektor ise mod degildir
    'doomsdayclient.com','Found minecraft processes','Advanced inject','Doomsday Client','DoomsdayInjector','doomsdayinjector',
    # BetterHitreg / hitreg istemcisi izleri
    'BetterHitreg','HitType','TOO_EARLY','tooEarlyForDamage','tooEarlyForSpecial','FULL_PICK','HALF_PICK','wasBlocked','wasHoldingSword',
    'swordHadSharpness','sprintWasReset','hadShield','HIDE_ANIMATIONS','HIDE_ALL_PARTICLES','HIDE_OTHER_PARTICLES','PARTICLES_EVERY_HIT',
    'SILENCE_SELF','LEGACY_SOUNDS','total_fights','fight_playtime_(seconds)','/hitreg','hitreg set','hitreg toggled','getUIKey',
    # hile istemcisi ayar/degisken/fonksiyon adlari
    'killauraRange','antiSS','hideInModList','silentAim','randomizeCPS','selfDestruct','rainbowESP','boxESP','tracerLine','xrayOpacity',
    
    'autoClicker','expandHitbox','uninject',
    # hile istemcisi mesajlari / menu adlari
    'Successfully Injected','Self Destruct Completed','[Client] Module Enabled','[Client] Module Disabled','ClickGUI','TargetHUD','.friend add',
    # bilinen hile modul adlari (mesru modlarda gecmez)
    'KillAura','TriggerBot','CrystalAura','AnchorAura','ChestStealer','ScaffoldWalk','PacketFly','BoatFly','AutoCrystal','AutoHitCrystal',
    'AutoAnchor','HitboxExpand','AntiKnockback','JitterClick','ButterflyClick','SelfDestructMixin','HideClient',
    # bilinen hile istemcisi paket yollari / marka izleri
    'net/wurstclient','net/ccbluex','me/zeroeightsix/kami','meteordevelopment/meteorclient','org/chainlibs','xyz/greaj','dev/gambleclient',
    'dev/krypton','dev.krypton','doomsdayclient','DoomsdayClient','rusherhack','LiquidBounce','novoware','Novoware',
    'bleachhack','BleachHack','org/bleachhack','salhack','com/gamesense','me/earth/phobos','me/earth/earthhack',
    'com/konasclient','dev/tigr/forgehax','today/opai','wtf/moonlight','cc/novoline','club/maxstats','com/alan/clients',
    # cheat modul sinif adlari (yaygin hile istemcisi isimlendirmesi)
    'Criticals','AntiBot','InvManager','AutoLeave','HitSelect','LegitScaffold','FastBridge','AutoBridge','ReachHack','NoSlowdown','Aimbot','AimBot'
)
$mmCertainSet = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
foreach ($s in $mmCertain) { [void]$mmCertainSet.Add($s) }
# --- MODUL KUMESI: tek basina genel (meshru modlarda da var) ama bir jar'da birlikte cok geciyorsa hile ---
# Yalnizca jar icindeki .class DOSYA ADLARINA bakilir (tam eslesme, buyuk/kucuk harf duyarli); icerik icinde alt-string aranmaz.
$mmClusterNames = @(
    'Velocity','Speed','Fly','Xray','Freecam','ESP','NoFall','Backtrack',
    'Reach','Sprint','Step','Jesus','Phase','Spider','NoSlow','Blink','Timer','Nuker','Tracers','Chams','Nametags',
    'FastPlace','FastBreak','AutoClicker','AutoTotem','AutoArmor','AutoSprint','AutoWalk','AutoEat','AutoFish','AutoTool',
    'Scaffold','Strafe','Teleport','AirJump','HighJump','LongJump','Glide','Bhop','Parkour','NoClip','Flight','ElytraFly',
    'AntiKnockback','AntiHunger','AntiAFK','Fullbright','Criticals','KillAura','TriggerBot','AimAssist','AutoCrystal',
    'CrystalAura','AnchorAura','BedAura','Surround','HoleFiller','Offhand','PlayerESP','StorageESP','ItemESP','BlockESP',
    'NoRender','NoSlowdown','Disabler','Clip','Hitboxes','Hitbox','Wallhack','Radar','Waypoints','Breadcrumbs','Aimbot'
)
$mmClusterSet = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
foreach ($s in $mmClusterNames) { [void]$mmClusterSet.Add($s) }
function Get-MmModuleCluster([string]$path) {
    $res = @{ Names = @(); Struct = $false }
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
        $z = [System.IO.Compression.ZipFile]::OpenRead($path)
        try {
            $names = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
            foreach ($e in $z.Entries) {
                $fn = $e.FullName
                if ($fn -notmatch '\.class$') { continue }
                # klasik hile istemcisi dizilimi: .../modules/combat/..., .../hacks/movement/... gibi
                if ($fn -match '(?i)(^|/)(modules?|features?|hacks?|cheats?)/(combat|movement|render|player|misc|world|exploit|visual|ghost|legit|rage)/') { $res.Struct = $true }
                $b = $fn.Substring($fn.LastIndexOf('/') + 1)
                $b = $b -replace '\.class$', ''
                $b = ($b -split '\$')[0]
                if ($mmClusterSet.Contains($b)) { [void]$names.Add($b) }
            }
            $res.Names = @($names)
        } finally { $z.Dispose() }
    } catch {}
    return $res
}
$mmStrSet =New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
foreach ($s in $mmCertain) { [void]$mmStrSet.Add($s) }
foreach ($s in $mmBoth) { [void]$mmStrSet.Add($s); [void]$mmStrSet.Add((ConvertTo-Fw $s)) }
foreach ($s in $mmFwOnly) { [void]$mmStrSet.Add((ConvertTo-Fw $s)) }
foreach ($s in $mmPlainExtra) { [void]$mmStrSet.Add($s) }
$mmStrSorted = @($mmStrSet | Sort-Object -Property { $_.Length } -Descending)
$mmStrAlt = ($mmStrSorted | ForEach-Object { [regex]::Escape($_) }) -join '|'
$script:MmStrRx = New-Object System.Text.RegularExpressions.Regex -ArgumentList $mmStrAlt, ([System.Text.RegularExpressions.RegexOptions]::Compiled)
$script:MmFwRx = New-Object System.Text.RegularExpressions.Regex -ArgumentList '[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]{2,}', ([System.Text.RegularExpressions.RegexOptions]::Compiled)
$script:MmFwPool = @($mmStrSet | Where-Object { $_ -cmatch '[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]' })

# ---- arsiv yardimcilari ----
function Open-MmArchive([string]$path) {
    $zip = $null
    try { $zip = [System.IO.Compression.ZipFile]::OpenRead($path) } catch { return $null }
    if (-not $zip) { return $null }
    $entries = New-Object System.Collections.Generic.List[object]
    $inner = New-Object System.Collections.Generic.List[object]
    $nested = New-Object System.Collections.Generic.List[object]
    foreach ($e in @($zip.Entries)) { [void]$entries.Add($e) }
    foreach ($e in @($zip.Entries)) {
        if ($e.FullName -match '^META-INF/jars/.+\.jar$') {
            [void]$nested.Add($e)
            if ($e.Length -gt 0 -and $e.Length -lt 31457280) {
                try {
                    $ns = $e.Open()
                    $ms = New-Object System.IO.MemoryStream
                    $ns.CopyTo($ms); $ns.Dispose()
                    $ms.Position = 0
                    $iz = New-Object System.IO.Compression.ZipArchive($ms, [System.IO.Compression.ZipArchiveMode]::Read)
                    [void]$inner.Add($iz)
                    foreach ($ie in @($iz.Entries)) { [void]$entries.Add($ie) }
                } catch {}
            }
        }
    }
    return @{ Zip = $zip; Entries = $entries; Inner = $inner; Nested = $nested }
}
function Close-MmArchive($a) {
    if (-not $a) { return }
    foreach ($i in $a.Inner) { try { $i.Dispose() } catch {} }
    try { $a.Zip.Dispose() } catch {}
}
function Read-MmEntry($entry, [int]$max) {
    try {
        if ($entry.Length -gt $max) { return $null }
        $st = $entry.Open()
        $ms = New-Object System.IO.MemoryStream
        $st.CopyTo($ms); $st.Dispose()
        $b = $ms.ToArray(); $ms.Dispose()
        return ,$b
    } catch { return $null }
}

# ---- 1) hile string taramasi ----
function Invoke-ModScan([string]$FilePath) {
    $foundPatterns = New-Object 'System.Collections.Generic.HashSet[string]'
    $foundStrings = New-Object 'System.Collections.Generic.HashSet[string]'
    $foundFw = New-Object 'System.Collections.Generic.HashSet[string]'
    $classHits = New-Object System.Collections.Generic.List[string]
    $arc = Open-MmArchive $FilePath
    if ($arc) {
        foreach ($e in $arc.Entries) {
            $enh = @{}
            foreach ($m in $script:MmPatRx.Matches($e.FullName)) { [void]$foundPatterns.Add($m.Value); $enh[$m.Value] = 1 }
            if ($enh.Count -gt 0 -and $classHits.Count -lt 80) { [void]$classHits.Add($e.FullName + '  <- DOSYA ADINDA: ' + (@($enh.Keys) -join ', ')) }
        }
        foreach ($e in $arc.Entries) {
            $n = $e.FullName
            if ($n -match '\.(class|json)$' -or $n -match 'MANIFEST\.MF') {
                $bytes = Read-MmEntry $e 3145728
                if ($null -eq $bytes) { continue }
                $txt = [System.Text.Encoding]::UTF8.GetString($bytes)
                $enc = @{}
                foreach ($m in $script:MmPatRx.Matches($txt)) { [void]$foundPatterns.Add($m.Value); $enc[$m.Value] = 1 }
                foreach ($m in $script:MmStrRx.Matches($txt)) { [void]$foundStrings.Add($m.Value); $enc[$m.Value] = 1 }
                foreach ($m in $script:MmFwRx.Matches($txt)) { [void]$foundFw.Add($m.Value) }
                if ($enc.Count -gt 0 -and $classHits.Count -lt 80) { [void]$classHits.Add($n + '  <- ICERIKTE: ' + ((@($enc.Keys) | Select-Object -First 12) -join ', ')) }
            }
        }
        Close-MmArchive $arc
    }
    $resolved = New-Object System.Collections.Generic.List[string]
    $resSet = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($fw in @($foundFw)) {
        if ($fw.Length -lt 3) { continue }
        $best = $null
        foreach ($cs in $script:MmFwPool) {
            if ($cs.Contains($fw)) { if ($null -eq $best -or $cs.Length -lt $best.Length) { $best = $cs } }
        }
        if ($null -ne $best) { if ($resSet.Add($best)) { [void]$resolved.Add($best) } }
        elseif ($fw.Length -ge 6) { if ($resSet.Add($fw)) { [void]$resolved.Add($fw) } }
    }
    $finalFw = New-Object System.Collections.Generic.List[string]
    foreach ($fw in $resolved) {
        $red = $false
        foreach ($o in $resolved) { if ($fw.Length -lt $o.Length -and $o.Contains($fw)) { $red = $true; break } }
        if (-not $red) { [void]$finalFw.Add($fw) }
    }
    return @{ Patterns = @($foundPatterns); Strings = @($foundStrings); Fullwidth = @($finalFw); ClassHits = @($classHits.ToArray()) }
}

# ---- 2) bypass / enjeksiyon taramasi ----
function Test-MmJarName([string]$JarName) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($JarName)
    if ($base -match '\d') { return $false }
    foreach ($pfx in @('com_','org_','net_','io_','dev_','gs_','xyz_','app_','me_','tv_','uk_','be_','fr_','de_')) {
        if ($base.ToLower().StartsWith($pfx)) { return $false }
    }
    if ($base.Length -gt 20) { return $false }
    return $true
}
function Invoke-MmBypassScan([string]$FilePath) {
    $flags = New-Object System.Collections.Generic.List[string]
    $arc = Open-MmArchive $FilePath
    if (-not $arc) { return ,$flags }
    $outerClasses = @($arc.Zip.Entries | Where-Object { $_.FullName -match '\.class$' })
    foreach ($nj in $arc.Nested) {
        $njBase = [System.IO.Path]::GetFileName($nj.FullName)
        if (Test-MmJarName $njBase) { [void]$flags.Add('Suspicious nested JAR - no version, unknown dependency: ' + $njBase) }
    }
    if ($arc.Nested.Count -eq 1 -and $outerClasses.Count -lt 3) {
        $njName = [System.IO.Path]::GetFileName($arc.Nested[0].FullName)
        [void]$flags.Add('Hollow shell - only ' + $outerClasses.Count + ' own class(es), wraps: ' + $njName)
    }
    $outerModId = ''
    $fmje = @($arc.Zip.Entries | Where-Object { $_.FullName -eq 'fabric.mod.json' } | Select-Object -First 1)
    if ($fmje.Count -gt 0) {
        $fb = Read-MmEntry $fmje[0] 262144
        if ($null -ne $fb) {
            $ft = [System.Text.Encoding]::UTF8.GetString($fb)
            if ($ft -match '"id"\s*:\s*"([^"]+)"') { $outerModId = $Matches[1] }
        }
    }
    $rtExec = $false; $httpDl = $false; $httpExfil = $false
    $obfN = 0; $numN = 0; $uniN = 0; $totN = 0
    foreach ($entry in $arc.Entries) {
        $name = $entry.FullName
        if ($name -notmatch '\.class$') { continue }
        $totN++
        $className = [System.IO.Path]::GetFileNameWithoutExtension(($name -split '/')[-1])
        if ($className -match '^\d+$') { $numN++ }
        if ($className -match '[^\x00-\x7F]') { $uniN++ }
        $segs = ($name -replace '\.class$', '') -split '/'
        $cons = 0; $maxC = 0
        foreach ($seg in $segs) {
            if ($seg.Length -eq 1) { $cons++; if ($cons -gt $maxC) { $maxC = $cons } } else { $cons = 0 }
        }
        if ($maxC -ge 3) { $obfN++ }
        $rb = Read-MmEntry $entry 2097152
        if ($null -eq $rb) { continue }
        $ct = [System.Text.Encoding]::ASCII.GetString($rb)
        if (-not $rtExec -and $ct.Contains('java/lang/Runtime') -and $ct.Contains('getRuntime') -and $ct.Contains('exec')) { $rtExec = $true }
        if (-not $httpDl -and $ct.Contains('openConnection') -and $ct.Contains('HttpURLConnection') -and $ct.Contains('FileOutputStream')) { $httpDl = $true }
        if (-not $httpExfil -and $ct.Contains('openConnection') -and $ct.Contains('setDoOutput') -and $ct.Contains('getOutputStream') -and $ct.Contains('getProperty')) { $httpExfil = $true }
    }
    Close-MmArchive $arc
    $obfPct = 0; $numPct = 0; $uniPct = 0
    if ($totN -ge 10) { $obfPct = [math]::Round(($obfN / $totN) * 100) }
    if ($totN -ge 5) { $numPct = [math]::Round(($numN / $totN) * 100); $uniPct = [math]::Round(($uniN / $totN) * 100) }
    if ($rtExec -and $obfPct -ge 25) { [void]$flags.Add('Runtime.exec() in obfuscated code - can run arbitrary OS commands') }
    if ($httpDl) { [void]$flags.Add('HTTP file download - fetches and writes files from a remote server at runtime') }
    if ($httpExfil) { [void]$flags.Add('HTTP POST exfiltration - sends system data to an external server') }
    if ($totN -ge 10 -and $obfPct -ge 25) { [void]$flags.Add('Heavy obfuscation - ' + $obfPct + '% of classes use single-letter path segments (a/b/c style)') }
    if ($numPct -ge 20) { [void]$flags.Add('Numeric class names - ' + $numPct + '% of classes have numeric-only names') }
    if ($uniPct -ge 10) { [void]$flags.Add('Unicode class names - ' + $uniPct + '% of classes use non-ASCII characters') }
    $legitIds = @('vmp-fabric','vmp','lithium','sodium','iris','fabric-api','modmenu','ferrite-core','lazydfu','starlight','entityculling','memoryleakfix','krypton','c2me-fabric','smoothboot-fabric','immediatelyfast','noisium','threadtweak')
    $danger = @($flags | Where-Object { $_ -match 'Runtime\.exec|HTTP file download|HTTP POST|Heavy obfuscation|Suspicious nested JAR' }).Count
    if ($outerModId -and ($legitIds -contains $outerModId) -and $danger -gt 0) {
        [void]$flags.Add("Fake mod identity - claims to be '" + $outerModId + "' but contains dangerous code")
    }
    return ,$flags
}

# ---- 3) obfuscation analizi ----
function Invoke-MmObfScan([string]$FilePath) {
    $flags = New-Object System.Collections.Generic.List[string]
    $arc = $null
    try { $arc = [System.IO.Compression.ZipFile]::OpenRead($FilePath) } catch { return ,$flags }
    $totalClass = 0; $numeric = 0; $unicode = 0; $fullw = 0; $jp = 0; $s1 = 0; $s2 = 0; $gib = 0; $nov = 0; $conf = 0; $singlePkg = 0
    $sample = New-Object System.Text.StringBuilder
    $sampleSize = 0
    $cheatObf = [ordered]@{
        'Skidfuscator' = @('dev/skidfuscator', 'Skidfuscator', 'skidfuscator.dev')
        'Paramorphism' = @('Paramorphism', 'paramorphism-', 'dev/paramorphism')
        'Radon' = @('ItzSomebody/Radon', 'me/itzsomebody/radon', 'Radon Obfuscator')
        'Caesium' = @('sim0n/Caesium', 'Caesium Obfuscator', 'dev/sim0n/caesium')
        'Bozar' = @('vimasig/Bozar', 'Bozar Obfuscator', 'com/bozar')
        'Branchlock' = @('Branchlock', 'branchlock.dev')
        'Binscure' = @('Binscure', 'com/binscure')
        'SuperBlaubeere' = @('superblaubeere', 'superblaubeere27')
        'Qprotect' = @('Qprotect', 'QProtect', 'mdma.dev/qprotect')
        'Zelix' = @('ZKMFLOW', 'ZelixKlassMaster', 'com/zelix')
        'Stringer' = @('StringerJavaObfuscator', 'com/licel/stringer')
        'JNIC' = @('jnic.obf', 'jnic-obfuscator')
        'Scuti' = @('ScutiObf', 'scuti.obf')
        'Smoke' = @('SmokeObf', 'smoke.obf')
    }
    try {
        foreach ($entry in $arc.Entries) {
            $name = $entry.FullName
            if ($name -notmatch '\.class$') { continue }
            $totalClass++
            $className = [System.IO.Path]::GetFileNameWithoutExtension(($name -split '/')[-1])
            if ($className -match '^\d+$') { $numeric++ }
            if ($className -match '[^\x00-\x7F]') { $unicode++ }
            if ($className -match '[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]') { $fullw++ }
            if ($className -match '[\u3040-\u309F\u30A0-\u30FF]') { $jp++ }
            if ($className -match '^[a-zA-Z]$') { $s1++ }
            if ($className -match '^[a-zA-Z]{2}$') { $s2++ }
            if ($className -match '^[Il1O0]+$' -or $className -match '^_+$') { $conf++ }
            if ($className.Length -ge 3 -and $className.Length -le 8 -and $className -match '^[a-zA-Z]+$') {
                $vow = ([regex]::Matches($className, '[aeiouAEIOU]')).Count
                if ($vow -eq 0) { $nov++ }
                if (($className -match '[bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ]{3,}') -and (($vow / $className.Length) -lt 0.3)) { $gib++ }
            }
            $segs = ($name -replace '\.class$', '') -split '/'
            if ($segs.Count -gt 1) { foreach ($seg in $segs[0..($segs.Count - 2)]) { if ($seg.Length -eq 1) { $singlePkg++ } } }
            if ($sampleSize -lt 150000 -and $entry.Length -lt 100000 -and $entry.Length -gt 100) {
                $sb2 = Read-MmEntry $entry 100000
                if ($null -ne $sb2) {
                    $as = [System.Text.Encoding]::ASCII.GetString($sb2)
                    [void]$sample.Append($as)
                    $sampleSize += $as.Length
                }
            }
        }
    } catch {}
    try { $arc.Dispose() } catch {}
    if ($totalClass -lt 5) { return ,$flags }
    $pct = { param($n) [math]::Round(($n / $totalClass) * 100) }
    $numPct = & $pct $numeric; $uniPct = & $pct $unicode; $fwPct = & $pct $fullw; $jpPct = & $pct $jp
    $s1Pct = & $pct $s1; $s2Pct = & $pct $s2; $gibPct = & $pct $gib; $novPct = & $pct $nov; $confPct = & $pct $conf
    if ($numPct -ge 20) { [void]$flags.Add('Numeric class names - ' + $numPct + '% of classes have numeric-only names') }
    if ($uniPct -ge 10) { [void]$flags.Add('Unicode class names - ' + $uniPct + '% of classes use non-ASCII characters') }
    if ($fwPct -gt 0) { [void]$flags.Add('Fullwidth Unicode class names - ' + $fwPct + '% use fullwidth chars (' + $fullw + ' classes)') }
    if ($jpPct -gt 0) { [void]$flags.Add('Japanese obfuscation - ' + $jpPct + '% use hiragana/katakana class names (' + $jp + ' classes)') }
    if ($s1Pct -ge 15) { [void]$flags.Add('Single-letter class names - ' + $s1Pct + '% (' + $s1 + ' classes)') }
    if ($s2Pct -ge 20) { [void]$flags.Add('Two-letter class names - ' + $s2Pct + '% (' + $s2 + ' classes)') }
    if ($gibPct -ge 5) { [void]$flags.Add('Gibberish class names - ' + $gibPct + '% have no vowels / consonant clusters (' + $gib + ' classes)') }
    if ($novPct -ge 8) { [void]$flags.Add('No-vowel class names - ' + $novPct + '% (' + $nov + ' classes)') }
    if ($confPct -ge 3) { [void]$flags.Add('Confusion-char names (Il1O0/_) - ' + $confPct + '% (' + $conf + ' classes)') }
    if ($singlePkg -ge 6) { [void]$flags.Add('Single-char package paths - ' + $singlePkg + ' path segments like a/b/c') }
    $sampleStr = $sample.ToString()
    $fwM = $script:MmFwRx.Matches($sampleStr)
    if ($fwM.Count -gt 0) {
        $ex = (@($fwM | Select-Object -First 3 | ForEach-Object { $_.Value }) -join ', ')
        [void]$flags.Add('Fullwidth strings in class content - ' + $fwM.Count + ' occurrences (e.g. ' + $ex + ')')
    }
    foreach ($on in $cheatObf.Keys) {
        foreach ($pt in $cheatObf[$on]) {
            if ($sampleStr.Contains($pt)) { [void]$flags.Add('Known cheat obfuscator detected - ' + $on + ' (matched: ' + $pt + ')'); break }
        }
    }
    return ,$flags
}

# ---- hash dogrulama (Modrinth / Megabase) ----
function Invoke-MmWeb([string]$uri) {
    if (-not $script:MmNet) { return $null }
    try {
        $r = Invoke-RestMethod -Uri $uri -Method Get -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop
        $script:MmFails = 0
        return $r
    } catch {
        $code = 0
        try { $code = [int]$_.Exception.Response.StatusCode } catch {}
        if ($code -ne 404 -and $code -ne 400) {
            $script:MmFails++
            if ($script:MmFails -ge 4) { $script:MmNet = $false }
        }
        return $null
    }
}
function Get-MmVerify([string]$hash) {
    $res = @{ Name = ''; Slug = ''; By = '' }
    if (-not $hash) { return $res }
    $vi = Invoke-MmWeb ('https://api.modrinth.com/v2/version_file/' + $hash)
    if ($vi -and $vi.project_id) {
        $pj = Invoke-MmWeb ('https://api.modrinth.com/v2/project/' + $vi.project_id)
        if ($pj -and $pj.slug) { $res.Name = [string]$pj.title; $res.Slug = [string]$pj.slug; $res.By = 'Modrinth'; return $res }
    }
    $mb = Invoke-MmWeb ('https://megabase.vercel.app/api/query?hash=' + $hash)
    if ($mb -and -not $mb.error -and $mb.data -and $mb.data.name) { $res.Name = [string]$mb.data.name; $res.By = 'Megabase' }
    return $res
}
function Get-MmSource([string]$path) {
    $zd = $null
    try { $hkHas = $true; if ($script:HkOk) { $hkHas = $false; foreach ($hkS in @([HkNative]::Streams($path))) { if ([string]$hkS -like ':Zone.Identifier*') { $hkHas = $true } } }; if ($hkHas) { $zd = Get-Content -Raw -Stream Zone.Identifier -LiteralPath $path -ErrorAction Stop } } catch {}
    if ($zd -and $zd -match 'HostUrl=(.+)') {
        $url = $Matches[1].Trim()
        if ($url -match 'mediafire\.com') { return 'MediaFire' }
        if ($url -match 'discord(app)?\.(com|net)') { return 'Discord' }
        if ($url -match 'dropbox\.com') { return 'Dropbox' }
        if ($url -match 'drive\.google\.com') { return 'Google Drive' }
        if ($url -match 'mega\.nz|mega\.co\.nz') { return 'MEGA' }
        if ($url -match 'github\.com') { return 'GitHub' }
        if ($url -match 'modrinth\.com') { return 'Modrinth' }
        if ($url -match 'curseforge\.com') { return 'CurseForge' }
        if ($url -match 'anydesk\.com') { return 'AnyDesk' }
        if ($url -match 'https?://(?:www\.)?([^/]+)') { return $Matches[1] }
        return $url
    }
    return ''
}
function Get-MmFlagScore([string]$f) {
    if ($f -match '^Fake mod identity') { return 70 }
    if ($f -match '^Runtime\.exec') { return 50 }
    if ($f -match '^HTTP POST') { return 50 }
    if ($f -match '^HTTP file download') { return 40 }
    if ($f -match '^Hollow shell') { return 45 }
    if ($f -match '^Suspicious nested JAR') { return 35 }
    if ($f -match '^Known cheat obfuscator') { return 45 }
    if ($f -match '^(Fullwidth|Japanese)') { return 45 }
    if ($f -match '^Heavy obfuscation') { return 35 }
    return 30
}

# ---- mod klasorlerini bul ----
$mmDirs = New-Object System.Collections.Generic.List[string]
$mmDirSeen = @{}
function Add-MmDir([string]$d) {
    if ([string]::IsNullOrWhiteSpace($d)) { return }
    if (-not (Test-Path -LiteralPath $d -PathType Container)) { return }
    $k = $d.TrimEnd('\').ToLower()
    if ($mmDirSeen.ContainsKey($k)) { return }
    $mmDirSeen[$k] = 1
    [void]$mmDirs.Add($d)
}
Add-MmDir ($env:APPDATA + '\.minecraft\mods')
foreach ($g in $script:GameDirs) { Add-MmDir ($g + '\mods'); Add-MmDir ($g + '\.fabric\processedMods'); Add-MmDir ($g + '\.fabric\remappedJars') }
foreach ($pat in @(
    ($env:APPDATA + '\ModrinthApp\profiles\*\mods'),
    ($env:APPDATA + '\com.modrinth.theseus\profiles\*\mods'),
    ($env:APPDATA + '\PrismLauncher\instances\*\.minecraft\mods'),
    ($env:APPDATA + '\PrismLauncher\instances\*\minecraft\mods'),
    ($env:APPDATA + '\MultiMC\instances\*\.minecraft\mods'),
    ($env:USERPROFILE + '\curseforge\minecraft\Instances\*\mods'),
    ($env:APPDATA + '\ATLauncher\instances\*\mods'),
    ($env:APPDATA + '\.minecraft\versions\*\mods'),
    ($env:APPDATA + '\.minecraft\.fabric\processedMods'),
    ($env:APPDATA + '\.minecraft\.fabric\remappedJars'),
    ($env:APPDATA + '\ModrinthApp\profiles\*\.fabric\processedMods'),
    ($env:APPDATA + '\ModrinthApp\profiles\*\.fabric\remappedJars'),
    ($env:APPDATA + '\PrismLauncher\instances\*\.minecraft\.fabric\processedMods'),
    ($env:APPDATA + '\PrismLauncher\instances\*\.minecraft\.fabric\remappedJars')
)) {
    foreach ($x in @(Get-ChildItem -Path $pat -Directory -ErrorAction SilentlyContinue)) { Add-MmDir $x.FullName }
}
# Ozel isimli surum klasorleri (hile istemcileri genelde .minecraft\versions\<isim>\<isim>.jar olarak kurulur); resmi/vanilla/loader klasorleri atlanir
foreach ($vroot in @(($env:APPDATA + '\.minecraft\versions')) + @($script:GameDirs | ForEach-Object { $_ + '\versions' })) {
    foreach ($vd in @(Get-ChildItem -LiteralPath $vroot -Directory -Force -ErrorAction SilentlyContinue)) {
        if ($vd.Name -match '^(\d+\.\d+(\.\d+)?|\d{2}w\d{2}[a-z]|fabric-loader-[\d.]+-\d+\.\d+(\.\d+)?|quilt-loader-[\d.]+-\d+\.\d+(\.\d+)?|\d+\.\d+(\.\d+)?-forge-[\d.]+|neoforge-[\d.]+(-.*)?)$') { continue }
        Add-MmDir $vd.FullName
    }
}
$mmJars = New-Object System.Collections.Generic.List[object]
$mmJarSeen = @{}
foreach ($d in $mmDirs) {
    Log ('   mod klasoru: ' + $d) 'DarkGray'
    # Tam tarama: .jar disinda uzantisi degistirilmis (zip/tmp/dat/uzantisiz) arsivler ve alt klasorler dahil (derinlik 4)
    foreach ($j in @(Get-ChildItem -LiteralPath $d -File -Recurse -Depth 4 -Force -ErrorAction SilentlyContinue)) {
        $jx = $j.Extension.ToLowerInvariant()
        if ($jx -ne '.jar') {
            if ($j.Length -lt 1024 -or $j.Length -gt 629145600) { continue }
            if ($jx -match '^\.(txt|json|toml|cfg|properties|png|jpg|jpeg|gif|log|md|mcmeta|nbt|dat_old|ogg|wav|lang|yml|yaml|xml|html|css|js|ini|conf|snbt|mca|mcr|lock|json5|ico|svg|ttf|otf|csv)$') { continue }
            $jmg = ''
            try { $jmg = Get-Magic $j.FullName } catch {}
            if ($jmg -ne 'PK') { continue }
        }
        $jk = $j.FullName.ToLower()
        if ($mmJarSeen.ContainsKey($jk)) { continue }
        $mmJarSeen[$jk] = 1
        [void]$mmJars.Add($j)
    }
}
if ($mmDirs.Count -eq 0) { Log '   mod klasoru bulunamadi (.minecraft\mods, calisan oyunun gameDir i, Modrinth/Prism/CurseForge/ATLauncher profilleri).' 'DarkGray' }
if ($mmDirs.Count -gt 0 -and $mmJars.Count -eq 0) { Log '   mod klasorleri var ama icinde .jar yok.' 'DarkGray' }
Perf-Lap '10: mod klasorlerini gezme/listeleme'
if ($mmJars.Count -gt 0 -and $script:MmNet) { Log '   NOT: mod dosyalarinin SHA1 hash i Modrinth/Megabase te sorgulanacak (dosya icerigi gonderilmez). Kapatmak icin: $env:HK_NONET=1' 'DarkGray' }

# ---- HIZLI MOTOR: 3 ayri PowerShell gecisi (string/bypass/obfuscation) tek gecisli, paralel C# tarayiciya birlestirildi; SHA1 hesabi paralel ----
$mmCs = @'
using System;
using System.IO;
using System.IO.Compression;
using System.Text;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using System.Net;
using System.Security.Cryptography;
using System.Threading.Tasks;
public sealed class HkTrie {
    sealed class Node { public Dictionary<char, Node> Kids; public bool End; }
    readonly Node root = new Node();
    readonly bool[] first = new bool[65536];
    readonly bool bounded;
    static bool IsAlpha(char c) { return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z'); }
    public HkTrie(string[] words, bool bounded) {
        this.bounded = bounded;
        foreach (string w in words) {
            if (string.IsNullOrEmpty(w)) continue;
            Node nd = root;
            foreach (char c in w) {
                if (nd.Kids == null) nd.Kids = new Dictionary<char, Node>();
                Node nx;
                if (!nd.Kids.TryGetValue(c, out nx)) { nx = new Node(); nd.Kids[c] = nx; }
                nd = nx;
            }
            nd.End = true;
            first[w[0]] = true;
        }
    }
    public void Collect(string text, HashSet<string> into) {
        int n = text.Length, i = 0;
        while (i < n) {
            if (!first[text[i]]) { i++; continue; }
            if (bounded && i > 0 && IsAlpha(text[i - 1])) { i++; continue; }
            Node nd = root; int j = i, best = -1;
            while (j < n) {
                Node nx;
                if (nd.Kids == null || !nd.Kids.TryGetValue(text[j], out nx)) break;
                nd = nx; j++;
                if (nd.End && (!bounded || j >= n || !IsAlpha(text[j]))) best = j;
            }
            if (best > 0) { into.Add(text.Substring(i, best - i)); i = best; } else i++;
        }
    }
}
public class HkMmRes {
    public string[] Patterns = new string[0];
    public string[] Strings = new string[0];
    public string[] Fullwidth = new string[0];
    public string[] Bypass = new string[0];
    public string[] Obf = new string[0];
    public string[] ClassHits = new string[0];
}
public static class HkMm {
    const StringComparison SC = StringComparison.OrdinalIgnoreCase;
    static Regex RxNested = new Regex(@"^META-INF/jars/.+\.jar$", RegexOptions.IgnoreCase | RegexOptions.Compiled);
    static Regex RxModId = new Regex(@"""id""\s*:\s*""([^""]+)""", RegexOptions.IgnoreCase | RegexOptions.Compiled);
    static Regex RxDanger = new Regex(@"Runtime\.exec|HTTP file download|HTTP POST|Heavy obfuscation|Suspicious nested JAR", RegexOptions.IgnoreCase | RegexOptions.Compiled);
    static Regex RxNum = new Regex(@"^\d+$", RegexOptions.Compiled);
    static Regex RxNonAscii = new Regex(@"[^\x00-\x7F]", RegexOptions.Compiled);
    static Regex RxFwChar = new Regex(@"[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]", RegexOptions.IgnoreCase | RegexOptions.Compiled);
    static Regex RxJp = new Regex(@"[\u3040-\u309F\u30A0-\u30FF]", RegexOptions.Compiled);
    static Regex RxS1 = new Regex(@"^[a-zA-Z]$", RegexOptions.IgnoreCase | RegexOptions.Compiled);
    static Regex RxS2 = new Regex(@"^[a-zA-Z]{2}$", RegexOptions.IgnoreCase | RegexOptions.Compiled);
    static Regex RxConf = new Regex(@"^[Il1O0]+$|^_+$", RegexOptions.IgnoreCase | RegexOptions.Compiled);
    static Regex RxAlpha = new Regex(@"^[a-zA-Z]+$", RegexOptions.IgnoreCase | RegexOptions.Compiled);
    static Regex RxCluster = new Regex(@"[bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ]{3,}", RegexOptions.IgnoreCase | RegexOptions.Compiled);
    static Dictionary<string, Regex> Cache = new Dictionary<string, Regex>();
    static readonly Encoding Lat1 = Encoding.GetEncoding(28591);
    static string[] LegitIds = new string[] { "vmp-fabric","vmp","lithium","sodium","iris","fabric-api","modmenu","ferrite-core","lazydfu","starlight","entityculling","memoryleakfix","krypton","c2me-fabric","smoothboot-fabric","immediatelyfast","noisium","threadtweak" };
    static string[] Pfx = new string[] { "com_","org_","net_","io_","dev_","gs_","xyz_","app_","me_","tv_","uk_","be_","fr_","de_" };
    static string[] ObfNames = new string[] { "Skidfuscator","Paramorphism","Radon","Caesium","Bozar","Branchlock","Binscure","SuperBlaubeere","Qprotect","Zelix","Stringer","JNIC","Scuti","Smoke" };
    static string[][] ObfPats = new string[][] {
        new string[] { "dev/skidfuscator", "Skidfuscator", "skidfuscator.dev" },
        new string[] { "Paramorphism", "paramorphism-", "dev/paramorphism" },
        new string[] { "ItzSomebody/Radon", "me/itzsomebody/radon", "Radon Obfuscator" },
        new string[] { "sim0n/Caesium", "Caesium Obfuscator", "dev/sim0n/caesium" },
        new string[] { "vimasig/Bozar", "Bozar Obfuscator", "com/bozar" },
        new string[] { "Branchlock", "branchlock.dev" },
        new string[] { "Binscure", "com/binscure" },
        new string[] { "superblaubeere", "superblaubeere27" },
        new string[] { "Qprotect", "QProtect", "mdma.dev/qprotect" },
        new string[] { "ZKMFLOW", "ZelixKlassMaster", "com/zelix" },
        new string[] { "StringerJavaObfuscator", "com/licel/stringer" },
        new string[] { "jnic.obf", "jnic-obfuscator" },
        new string[] { "ScutiObf", "scuti.obf" },
        new string[] { "SmokeObf", "smoke.obf" }
    };
    static Regex Get(string p) {
        lock (Cache) {
            Regex r;
            if (!Cache.TryGetValue(p, out r)) { r = new Regex(p, RegexOptions.Compiled); Cache[p] = r; }
            return r;
        }
    }
    static byte[] ReadAll(ZipArchiveEntry e, long max) {
        try {
            long len = e.Length;
            if (len > max) return null;
            using (Stream s = e.Open()) {
                byte[] b = new byte[len];
                int off = 0;
                while (off < len) {
                    int c = s.Read(b, off, (int)(len - off));
                    if (c <= 0) break;
                    off += c;
                }
                if (off != len) Array.Resize(ref b, off);
                return b;
            }
        } catch { return null; }
    }
    static string LastSeg(string n) { int i = n.LastIndexOf('/'); return i >= 0 ? n.Substring(i + 1) : n; }
    static string NoExt(string n) { int d = n.LastIndexOf('.'); return d >= 0 ? n.Substring(0, d) : n; }
    static bool JarNameSus(string jarName) {
        string b = NoExt(jarName);
        foreach (char c in b) { if (char.IsDigit(c)) return false; }
        string lo = b.ToLowerInvariant();
        foreach (string p in Pfx) { if (lo.StartsWith(p, StringComparison.Ordinal)) return false; }
        if (b.Length > 20) return false;
        return true;
    }
    static int Pct(int n, int total) { return (int)Math.Round(((double)n / total) * 100.0); }
    static string[] ToArr(HashSet<string> h) { string[] a = new string[h.Count]; h.CopyTo(a); return a; }

    public static HkMmRes Scan(string path, Regex pat, Regex str, HkTrie tpat, HkTrie tstr, Regex fw, string[] fwPool) {
        HkMmRes r = new HkMmRes();
        ZipArchive zip = null;
        List<ZipArchive> inners = new List<ZipArchive>();
        try { zip = ZipFile.OpenRead(path); } catch { return r; }
        try {
            List<ZipArchiveEntry> entries = new List<ZipArchiveEntry>();
            List<ZipArchiveEntry> nested = new List<ZipArchiveEntry>();
            foreach (ZipArchiveEntry e in zip.Entries) entries.Add(e);
            int outerCount = entries.Count;
            for (int i = 0; i < outerCount; i++) {
                ZipArchiveEntry e = entries[i];
                if (RxNested.IsMatch(e.FullName)) {
                    nested.Add(e);
                    if (e.Length > 0 && e.Length < 31457280) {
                        try {
                            byte[] nb = ReadAll(e, 31457280);
                            if (nb != null) {
                                ZipArchive iz = new ZipArchive(new MemoryStream(nb), ZipArchiveMode.Read);
                                inners.Add(iz);
                                foreach (ZipArchiveEntry ie in iz.Entries) entries.Add(ie);
                            }
                        } catch { }
                    }
                }
            }
            HashSet<string> pats = new HashSet<string>();
            HashSet<string> strs = new HashSet<string>();
            HashSet<string> fws = new HashSet<string>();
            List<string> bypass = new List<string>();
            List<string> obf = new List<string>();

            // --- bypass: ic ice jar ve kabuk jar kontrolleri ---
            int outerClasses = 0;
            for (int i = 0; i < outerCount; i++) { if (entries[i].FullName.EndsWith(".class", SC)) outerClasses++; }
            string modId = "";
            for (int i = 0; i < outerCount; i++) {
                if (string.Equals(entries[i].FullName, "fabric.mod.json", SC)) {
                    byte[] fb = ReadAll(entries[i], 262144);
                    if (fb != null) { Match mm = RxModId.Match(Encoding.UTF8.GetString(fb)); if (mm.Success) modId = mm.Groups[1].Value; }
                    break;
                }
            }
            foreach (ZipArchiveEntry nj in nested) {
                string njBase = LastSeg(nj.FullName);
                if (JarNameSus(njBase)) bypass.Add("Suspicious nested JAR - no version, unknown dependency: " + njBase);
            }
            if (nested.Count == 1 && outerClasses < 3) bypass.Add("Hollow shell - only " + outerClasses + " own class(es), wraps: " + LastSeg(nested[0].FullName));

            // --- ad desenleri (tum girdiler) ---
            List<string> classHits = new List<string>();
            foreach (ZipArchiveEntry e in entries) {
                HashSet<string> enp = new HashSet<string>();
                if (tpat != null) { tpat.Collect(e.FullName, enp); } else { foreach (Match m in pat.Matches(e.FullName)) enp.Add(m.Value); }
                if (enp.Count > 0) {
                    foreach (string x in enp) pats.Add(x);
                    if (classHits.Count < 80) { string[] ea = new string[enp.Count]; enp.CopyTo(ea); classHits.Add(e.FullName + "  <- DOSYA ADINDA: " + string.Join(", ", ea)); }
                }
            }

            bool rtExec = false, httpDl = false, httpExfil = false;
            int obfN = 0, numN = 0, uniN = 0, totN = 0;
            int tc = 0, numeric = 0, unicode = 0, fullw = 0, jp = 0, s1 = 0, s2 = 0, gib = 0, nov = 0, conf = 0, singlePkg = 0;
            StringBuilder sample = new StringBuilder();
            int sampleSize = 0;

            for (int i = 0; i < entries.Count; i++) {
                ZipArchiveEntry e = entries[i];
                string n = e.FullName;
                bool isClass = n.EndsWith(".class", SC);
                bool isTxt = isClass || n.EndsWith(".json", SC) || n.IndexOf("MANIFEST.MF", SC) >= 0;
                byte[] bytes = null;
                if (isTxt) bytes = ReadAll(e, 3145728);
                if (bytes != null) {
                    try {
                        string t = Encoding.UTF8.GetString(bytes);
                        HashSet<string> ep = new HashSet<string>();
                        HashSet<string> es = new HashSet<string>();
                        if (tpat != null) { tpat.Collect(t, ep); tstr.Collect(t, es); }
                        else {
                            foreach (Match m in pat.Matches(t)) ep.Add(m.Value);
                            foreach (Match m in str.Matches(t)) es.Add(m.Value);
                        }
                        foreach (string x in ep) pats.Add(x);
                        foreach (string x in es) strs.Add(x);
                        if ((ep.Count > 0 || es.Count > 0) && classHits.Count < 80) {
                            HashSet<string> both = new HashSet<string>(ep);
                            foreach (string x in es) both.Add(x);
                            string[] ba = new string[both.Count]; both.CopyTo(ba);
                            string shown = string.Join(", ", ba, 0, Math.Min(ba.Length, 12));
                            classHits.Add(n + "  <- ICERIKTE: " + shown + (ba.Length > 12 ? " (+" + (ba.Length - 12) + " daha)" : ""));
                        }
                        foreach (Match m in fw.Matches(t)) fws.Add(m.Value);
                    } catch { }
                }
                if (!isClass) continue;
                string last = LastSeg(n);
                string cn = NoExt(last);
                string nm = n.Substring(0, n.Length - 6);
                string[] segs = nm.Split('/');
                // bypass sayaclari (tum class lar)
                totN++;
                if (RxNum.IsMatch(cn)) numN++;
                if (RxNonAscii.IsMatch(cn)) uniN++;
                int cons = 0, maxC = 0;
                foreach (string sg in segs) { if (sg.Length == 1) { cons++; if (cons > maxC) maxC = cons; } else cons = 0; }
                if (maxC >= 3) obfN++;
                if (bytes != null && bytes.Length <= 2097152 && !(rtExec && httpDl && httpExfil)) {
                    string ct = Lat1.GetString(bytes);
                    if (!rtExec && ct.Contains("java/lang/Runtime") && ct.Contains("getRuntime") && ct.Contains("exec")) rtExec = true;
                    if (!httpDl && ct.Contains("openConnection") && ct.Contains("HttpURLConnection") && ct.Contains("FileOutputStream")) httpDl = true;
                    if (!httpExfil && ct.Contains("openConnection") && ct.Contains("setDoOutput") && ct.Contains("getOutputStream") && ct.Contains("getProperty")) httpExfil = true;
                }
                // obfuscation sayaclari (sadece dis jar class lari)
                if (i < outerCount) {
                    tc++;
                    if (RxNum.IsMatch(cn)) numeric++;
                    if (RxNonAscii.IsMatch(cn)) unicode++;
                    if (RxFwChar.IsMatch(cn)) fullw++;
                    if (RxJp.IsMatch(cn)) jp++;
                    if (RxS1.IsMatch(cn)) s1++;
                    if (RxS2.IsMatch(cn)) s2++;
                    if (RxConf.IsMatch(cn)) conf++;
                    if (cn.Length >= 3 && cn.Length <= 8 && RxAlpha.IsMatch(cn)) {
                        int vow = 0;
                        foreach (char ch in cn) { if ("aeiouAEIOU".IndexOf(ch) >= 0) vow++; }
                        if (vow == 0) nov++;
                        if (RxCluster.IsMatch(cn) && ((double)vow / cn.Length) < 0.3) gib++;
                    }
                    if (segs.Length > 1) { for (int q = 0; q < segs.Length - 1; q++) { if (segs[q].Length == 1) singlePkg++; } }
                    if (sampleSize < 150000 && e.Length < 100000 && e.Length > 100 && bytes != null) {
                        string asx = Encoding.ASCII.GetString(bytes);
                        sample.Append(asx);
                        sampleSize += asx.Length;
                    }
                }
            }

            // --- bypass sonuc bayraklari ---
            int obfPct = 0, numPct = 0, uniPct = 0;
            if (totN >= 10) obfPct = Pct(obfN, totN);
            if (totN >= 5) { numPct = Pct(numN, totN); uniPct = Pct(uniN, totN); }
            if (rtExec && obfPct >= 25) bypass.Add("Runtime.exec() in obfuscated code - can run arbitrary OS commands");
            if (httpDl) bypass.Add("HTTP file download - fetches and writes files from a remote server at runtime");
            if (httpExfil) bypass.Add("HTTP POST exfiltration - sends system data to an external server");
            if (totN >= 10 && obfPct >= 25) bypass.Add("Heavy obfuscation - " + obfPct + "% of classes use single-letter path segments (a/b/c style)");
            if (numPct >= 20) bypass.Add("Numeric class names - " + numPct + "% of classes have numeric-only names");
            if (uniPct >= 10) bypass.Add("Unicode class names - " + uniPct + "% of classes use non-ASCII characters");
            int danger = 0;
            foreach (string f in bypass) { if (RxDanger.IsMatch(f)) danger++; }
            if (modId.Length > 0 && danger > 0) {
                foreach (string lg in LegitIds) {
                    if (string.Equals(lg, modId, SC)) { bypass.Add("Fake mod identity - claims to be '" + modId + "' but contains dangerous code"); break; }
                }
            }

            // --- obfuscation sonuc bayraklari ---
            if (tc >= 5) {
                int numPct2 = Pct(numeric, tc), uniPct2 = Pct(unicode, tc), fwPct = Pct(fullw, tc), jpPct = Pct(jp, tc);
                int s1Pct = Pct(s1, tc), s2Pct = Pct(s2, tc), gibPct = Pct(gib, tc), novPct = Pct(nov, tc), confPct = Pct(conf, tc);
                if (numPct2 >= 20) obf.Add("Numeric class names - " + numPct2 + "% of classes have numeric-only names");
                if (uniPct2 >= 10) obf.Add("Unicode class names - " + uniPct2 + "% of classes use non-ASCII characters");
                if (fwPct > 0) obf.Add("Fullwidth Unicode class names - " + fwPct + "% use fullwidth chars (" + fullw + " classes)");
                if (jpPct > 0) obf.Add("Japanese obfuscation - " + jpPct + "% use hiragana/katakana class names (" + jp + " classes)");
                if (s1Pct >= 15) obf.Add("Single-letter class names - " + s1Pct + "% (" + s1 + " classes)");
                if (s2Pct >= 20) obf.Add("Two-letter class names - " + s2Pct + "% (" + s2 + " classes)");
                if (gibPct >= 5) obf.Add("Gibberish class names - " + gibPct + "% have no vowels / consonant clusters (" + gib + " classes)");
                if (novPct >= 8) obf.Add("No-vowel class names - " + novPct + "% (" + nov + " classes)");
                if (confPct >= 3) obf.Add("Confusion-char names (Il1O0/_) - " + confPct + "% (" + conf + " classes)");
                if (singlePkg >= 6) obf.Add("Single-char package paths - " + singlePkg + " path segments like a/b/c");
                string sampleStr = sample.ToString();
                MatchCollection fwM = fw.Matches(sampleStr);
                if (fwM.Count > 0) {
                    List<string> ex = new List<string>();
                    for (int q = 0; q < fwM.Count && q < 3; q++) ex.Add(fwM[q].Value);
                    obf.Add("Fullwidth strings in class content - " + fwM.Count + " occurrences (e.g. " + string.Join(", ", ex.ToArray()) + ")");
                }
                for (int q = 0; q < ObfNames.Length; q++) {
                    foreach (string pt in ObfPats[q]) {
                        if (sampleStr.Contains(pt)) { obf.Add("Known cheat obfuscator detected - " + ObfNames[q] + " (matched: " + pt + ")"); break; }
                    }
                }
            }

            // --- fullwidth cozumleme ---
            List<string> resolved = new List<string>();
            HashSet<string> resSet = new HashSet<string>();
            foreach (string f in fws) {
                if (f.Length < 3) continue;
                string best = null;
                foreach (string cs in fwPool) { if (cs.Contains(f)) { if (best == null || cs.Length < best.Length) best = cs; } }
                if (best != null) { if (resSet.Add(best)) resolved.Add(best); }
                else if (f.Length >= 6) { if (resSet.Add(f)) resolved.Add(f); }
            }
            List<string> finalFw = new List<string>();
            foreach (string f in resolved) {
                bool red = false;
                foreach (string o in resolved) { if (f.Length < o.Length && o.Contains(f)) { red = true; break; } }
                if (!red) finalFw.Add(f);
            }
            r.Patterns = ToArr(pats);
            r.Strings = ToArr(strs);
            r.Fullwidth = finalFw.ToArray();
            r.Bypass = bypass.ToArray();
            r.Obf = obf.ToArray();
            r.ClassHits = classHits.ToArray();
        } catch { }
        finally {
            foreach (ZipArchive iz in inners) { try { iz.Dispose(); } catch { } }
            try { zip.Dispose(); } catch { }
        }
        return r;
    }
    public static bool UseTrie = false;
    public static bool SelfTest(string[] words) {
        try {
            if (words == null || words.Length == 0) return false;
            List<string> w = new List<string>();
            foreach (string x in words) { if (!string.IsNullOrEmpty(x)) w.Add(x); if (w.Count >= 80) break; }
            w.Sort(delegate(string a, string b) { return b.Length.CompareTo(a.Length); });
            List<string> esc = new List<string>();
            foreach (string x in w) esc.Add(Regex.Escape(x));
            string alt = string.Join("|", esc.ToArray());
            Regex rb = new Regex("(?<![A-Za-z])(" + alt + ")(?![A-Za-z])");
            Regex ru = new Regex(alt);
            HkTrie tb = new HkTrie(w.ToArray(), true);
            HkTrie tu = new HkTrie(w.ToArray(), false);
            StringBuilder sb = new StringBuilder();
            foreach (string x in w) { sb.Append("a").Append(x).Append(" ").Append(x).Append("z ").Append(x).Append(".").Append(x.Substring(0, x.Length / 2)).Append("|").Append(x).Append(x).Append(" "); }
            string text = sb.ToString();
            HashSet<string> a1 = new HashSet<string>();
            HashSet<string> a2 = new HashSet<string>();
            foreach (Match m in rb.Matches(text)) a1.Add(m.Value);
            tb.Collect(text, a2);
            if (a1.Count == 0 || !a1.SetEquals(a2)) return false;
            a1.Clear(); a2.Clear();
            foreach (Match m in ru.Matches(text)) a1.Add(m.Value);
            tu.Collect(text, a2);
            return a1.Count > 0 && a1.SetEquals(a2);
        } catch { return false; }
    }
    public static HkMmRes[] ScanMany(string[] paths, string patRx, string strRx, string fwRx, string[] fwPool, int threads, string[] patList, string[] strList) {
        HkTrie tp = null;
        HkTrie ts = null;
        Regex pat = null;
        Regex str = null;
        if (UseTrie && patList != null && strList != null) { tp = new HkTrie(patList, true); ts = new HkTrie(strList, false); }
        else { pat = Get(patRx); str = Get(strRx); }
        Regex fw = Get(fwRx);
        HkMmRes[] res = new HkMmRes[paths.Length];
        ParallelOptions po = new ParallelOptions();
        po.MaxDegreeOfParallelism = threads;
        Parallel.For(0, paths.Length, po, delegate(int i) {
            System.Threading.Thread th = System.Threading.Thread.CurrentThread;
            System.Threading.ThreadPriority oldP = th.Priority;
            try { th.Priority = System.Threading.ThreadPriority.BelowNormal; } catch { }
            try { res[i] = Scan(paths[i], pat, str, tp, ts, fw, fwPool); } catch { res[i] = new HkMmRes(); }
            finally { try { th.Priority = oldP; } catch { } }
        });
        return res;
    }
    public static string[] Sha1Many(string[] paths, int threads) {
        string[] res = new string[paths.Length];
        ParallelOptions po = new ParallelOptions();
        po.MaxDegreeOfParallelism = threads;
        Parallel.For(0, paths.Length, po, delegate(int i) {
            try {
                using (FileStream fs = new FileStream(paths[i], FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                using (SHA1 sha = SHA1.Create()) {
                    byte[] h = sha.ComputeHash(fs);
                    StringBuilder sb = new StringBuilder();
                    foreach (byte b in h) sb.Append(b.ToString("X2"));
                    res[i] = sb.ToString();
                }
            } catch { res[i] = ""; }
        });
        return res;
    }
    // null = ag hatasi, "" = sunucu yanit verdi ama kayit yok (404/400), diger = govde
    public static string[] FetchMany(string[] urls, int timeoutMs, int threads) {
        string[] res = new string[urls.Length];
        ServicePointManager.DefaultConnectionLimit = Math.Max(16, threads * 2);
        ParallelOptions po = new ParallelOptions();
        po.MaxDegreeOfParallelism = threads;
        Parallel.For(0, urls.Length, po, delegate(int i) {
            try {
                HttpWebRequest rq = (HttpWebRequest)WebRequest.Create(urls[i]);
                rq.Timeout = timeoutMs;
                rq.ReadWriteTimeout = timeoutMs;
                rq.UserAgent = "HileKiran/1.0";
                using (HttpWebResponse rs = (HttpWebResponse)rq.GetResponse())
                using (StreamReader sr = new StreamReader(rs.GetResponseStream(), Encoding.UTF8)) { res[i] = sr.ReadToEnd(); }
            } catch (WebException ex) {
                HttpWebResponse er = ex.Response as HttpWebResponse;
                if (er != null) { int code = (int)er.StatusCode; er.Close(); res[i] = (code == 404 || code == 400) ? "" : null; }
                else res[i] = null;
            } catch { res[i] = null; }
        });
        return res;
    }
}
'@
$mmCsOk = $false
try {
    if (-not ('HkMm' -as [type])) { Add-Type -TypeDefinition $mmCs -Language CSharp -ReferencedAssemblies @('System.IO.Compression', 'System.IO.Compression.FileSystem') -ErrorAction Stop }
    $mmCsOk = $true
    $mmFast = $false
    try { $mmFast = [bool]([HkMm]::SelfTest([string[]]@($mmPatSorted))) } catch { $mmFast = $false }
    [HkMm]::UseTrie = $mmFast
    if ($mmFast) { Log '   hizli eslestirici (self-test gecti): acik' 'DarkGray' } else { Log '   hizli eslestirici self-test GECEMEDI, klasik regex kullaniliyor (yavas olabilir)' 'DarkYellow' }
} catch { Log ('   UYARI: hizli mod motoru derlenemedi, yavas yola donuluyor: ' + $_.Exception.Message) 'DarkYellow' }

# Toplu hash dogrulama: Modrinth tek istekte (version_files + projects), bulunamayanlar Megabase te paralel
function Get-MmVerifyMany([string[]]$hashes) {
    $out = @{}
    if (-not $script:MmNet -or -not $hashes -or $hashes.Count -eq 0) { return $out }
    $lower = @($hashes | Where-Object { $_ } | ForEach-Object { $_.ToLower() } | Select-Object -Unique)
    $vers = @{}
    $bulkOk = $true
    for ($i = 0; $i -lt $lower.Count; $i += 200) {
        $hi = [Math]::Min($i + 199, $lower.Count - 1)
        $chunk = @($lower[$i..$hi])
        $body = '{"hashes":[' + (($chunk | ForEach-Object { '"' + $_ + '"' }) -join ',') + '],"algorithm":"sha1"}'
        try {
            $resp = Invoke-RestMethod -Uri 'https://api.modrinth.com/v2/version_files' -Method Post -Body $body -ContentType 'application/json' -UserAgent 'HileKiran/1.0' -TimeoutSec 30 -ErrorAction Stop
            if ($resp) { foreach ($p in $resp.PSObject.Properties) { if ($p.Value -and $p.Value.project_id) { $vers[$p.Name.ToLower()] = [string]$p.Value.project_id } } }
        } catch { $bulkOk = $false }
    }
    if (-not $bulkOk) {
        # toplu sorgu basarisiz: eski (tek tek) yontem, 4 ardisik hatada ag kapanir
        foreach ($h in $lower) {
            if (-not $script:MmNet) { break }
            $v = Get-MmVerify $h
            if ($v.By) { $out[$h.ToUpper()] = $v }
        }
        return $out
    }
    $projInfo = @{}
    $projIds = @($vers.Values | Select-Object -Unique)
    for ($i = 0; $i -lt $projIds.Count; $i += 100) {
        $hi = [Math]::Min($i + 99, $projIds.Count - 1)
        $c = @($projIds[$i..$hi])
        $idsJson = '[' + (($c | ForEach-Object { '"' + $_ + '"' }) -join ',') + ']'
        try {
            $pr = Invoke-RestMethod -Uri ('https://api.modrinth.com/v2/projects?ids=' + [uri]::EscapeDataString($idsJson)) -UserAgent 'HileKiran/1.0' -TimeoutSec 30 -ErrorAction Stop
            foreach ($pj in @($pr)) { if ($pj -and $pj.id) { $projInfo[[string]$pj.id] = $pj } }
        } catch {}
    }
    $rest = New-Object System.Collections.Generic.List[string]
    foreach ($h in $lower) {
        if ($vers.ContainsKey($h) -and $projInfo.ContainsKey($vers[$h])) {
            $pj = $projInfo[$vers[$h]]
            $out[$h.ToUpper()] = @{ Name = [string]$pj.title; Slug = [string]$pj.slug; By = 'Modrinth' }
        } else { [void]$rest.Add($h) }
    }
    if ($rest.Count -gt 0 -and $script:MmNet) {
        $mbRes = $null
        if ($mmCsOk) {
            $urls = [string[]]@($rest | ForEach-Object { 'https://megabase.vercel.app/api/query?hash=' + $_.ToUpper() })
            try { $mbRes = [HkMm]::FetchMany($urls, 8000, 8) } catch {}
        }
        if ($mbRes) {
            $okN = 0
            for ($k = 0; $k -lt $rest.Count; $k++) {
                $s = $mbRes[$k]
                if ($null -eq $s) { continue }
                $okN++
                if (-not $s) { continue }
                try {
                    $j = $s | ConvertFrom-Json -ErrorAction Stop
                    if ($j -and -not $j.error -and $j.data -and $j.data.name) { $out[$rest[$k].ToUpper()] = @{ Name = [string]$j.data.name; Slug = ''; By = 'Megabase' } }
                } catch {}
            }
            if ($okN -eq 0) { $script:MmNet = $false }
        } else {
            foreach ($h in $rest) {
                if (-not $script:MmNet) { break }
                $mb = Invoke-MmWeb ('https://megabase.vercel.app/api/query?hash=' + $h.ToUpper())
                if ($mb -and -not $mb.error -and $mb.data -and $mb.data.name) { $out[$h.ToUpper()] = @{ Name = [string]$mb.data.name; Slug = ''; By = 'Megabase' } }
            }
        }
    }
    return $out
}

$script:ModInv = New-Object System.Collections.Generic.List[object]
function Add-ModInv($jar, [string]$hash, $ver, [string]$sonuc, [int]$skor) {
    try {
        $dg = [string]$ver.By
        if ($ver.Name) { $dg = $dg + ':' + [string]$ver.Name }
        if (-not $dg) { $dg = 'hash dogrulanamadi' }
        [void]$script:ModInv.Add([pscustomobject]@{ Ad = $jar.Name; Yol = $jar.FullName; KB = [int]($jar.Length / 1KB); Tarih = $jar.LastWriteTime; Hash = $hash; Dogrulama = $dg; Sonuc = $sonuc; Skor = $skor })
    } catch {}
}
$script:ClassHitMap = @{}
$mmVerified = New-Object System.Collections.Generic.List[string]
$mmUnknown = New-Object System.Collections.Generic.List[string]
$mmCntSus = 0; $mmCntByp = 0; $mmCntObf = 0
$mmWhite = @('viafabricplus', 'viafabricversion')
$mmThr = [Math]::Max(2, $script:HkThr)
$mmPaths = [string[]]@($mmJars | ForEach-Object { $_.FullName })

# 1) SHA1 (paralel)
$mmHashMap = @{}
if ($mmJars.Count -gt 0) {
    Set-Frac 0.02 'sha1 hesaplaniyor'
    $hs = $null
    if ($mmCsOk) { try { $hs = [HkMm]::Sha1Many($mmPaths, $mmThr) } catch {} }
    for ($i = 0; $i -lt $mmPaths.Count; $i++) {
        $h = ''
        if ($hs -and $hs[$i]) { $h = [string]$hs[$i] } else { try { $h = (Get-FileHash -LiteralPath $mmPaths[$i] -Algorithm SHA1 -ErrorAction Stop).Hash } catch {} }
        $mmHashMap[$mmPaths[$i]] = $h
    }
}
# 2) Hash dogrulama (toplu)
Set-Frac 0.05 'hash dogrulamasi (toplu)'
$mmVerMap = @{}
if ($mmJars.Count -gt 0) { $mmVerMap = Get-MmVerifyMany ([string[]]@($mmHashMap.Values | Where-Object { $_ })) }
# 3) Icerik taramasi (tek gecis, paralel); buyuk dosyalar once
$mmScanRes = @{}
if ($mmCsOk) {
    $mmToScan = New-Object System.Collections.Generic.List[object]
    foreach ($jar in $mmJars) {
        $h0 = $mmHashMap[$jar.FullName]
        if ($h0 -and $mmVerMap.ContainsKey($h0) -and ($mmWhite -contains ([string]$mmVerMap[$h0].Slug).ToLower())) { continue }
        if ($jar.Length -gt 629145600) { Add-Cov 'Mod >600 MB: derin tarama atlandi' $jar.FullName; continue }
        [void]$mmToScan.Add($jar)
    }
    $mmSorted = @($mmToScan | Sort-Object Length -Descending)
    Perf-Lap '10: SHA1 hash + Modrinth/Megabase sorgusu (ag)'
    Log ('   ' + $mmSorted.Count + ' mod tek gecisli paralel motorla taraniyor (' + $mmThr + ' is parcacigi)...') 'DarkGray'
    $mmSw = [Diagnostics.Stopwatch]::StartNew()
    for ($ci = 0; $ci -lt $mmSorted.Count; $ci += 8) {
        $hi = [Math]::Min($ci + 7, $mmSorted.Count - 1)
        $paths = [string[]]@($mmSorted[$ci..$hi] | ForEach-Object { $_.FullName })
        $res = $null
        try { $res = [HkMm]::ScanMany($paths, $script:MmPatRx.ToString(), $script:MmStrRx.ToString(), $script:MmFwRx.ToString(), [string[]]@($script:MmFwPool), $mmThr, [string[]]@($mmPatSorted), [string[]]@($mmStrSorted)) } catch {}
        if ($res) { for ($k = 0; $k -lt $paths.Count; $k++) { $mmScanRes[$paths[$k]] = $res[$k] } }
        $dn = [Math]::Min($ci + 8, $mmSorted.Count)
        Set-Frac (0.1 + 0.9 * $dn / [Math]::Max(1, $mmSorted.Count)) ('mod ' + $dn + '/' + $mmSorted.Count)
        if ($env:HK_YAVAS -eq '1') { Start-Sleep -Milliseconds 120 }
        Write-Host ('   mod ilerleme: ' + $dn + '/' + $mmSorted.Count + ' (' + [int]$mmSw.Elapsed.TotalSeconds + ' sn)') -ForegroundColor DarkGray
    }
}
foreach ($jar in $mmJars) {
    $jp = $jar.FullName
    $hash = $mmHashMap[$jp]
    $ver = @{ Name = ''; Slug = ''; By = '' }
    if ($hash -and $mmVerMap.ContainsKey($hash)) { $ver = $mmVerMap[$hash] }
    $isVer = [bool]$ver.By
    $jarExt = $jar.Extension.ToLowerInvariant()
    if ($jarExt -ne '.jar' -and $jarExt -ne '.disabled') { Add-F -Kaynak 'Mod klasoru analizi' -Ad ('mod klasorunde jar olmayan uzantili arsiv: ' + $jar.Name.ToLower()) -Yol $jp -Skor 30 -Son $jar.LastWriteTime -Ilk $jar.CreationTime -Var 'Evet' -Not 'uzantisi degistirilmis olabilir (zip/tmp/dat/uzantisiz ama icerigi arsiv)' }
    if ($isVer -and ($mmWhite -contains ([string]$ver.Slug).ToLower())) { [void]$mmVerified.Add($ver.Name + ' -> ' + $jar.Name); Add-ModInv $jar $hash $ver 'beyaz liste: hash birebir dogrulanmis, taranmadi' 0; continue }
    if ($jar.Length -gt 629145600) {
        Add-ModInv $jar $hash $ver 'TARANMADI: 600 MB ustu' 12
        Add-F -Kaynak 'Mod klasoru analizi' -Ad ('mod: ' + $jar.Name.ToLower()) -Yol $jp -Skor 12 -Son $jar.LastWriteTime -Ilk $jar.CreationTime -Var 'Evet' -Not 'mod 600 MB ustu, derin tarama atlandi'
        continue
    }
    $ms = $null; $bf = @(); $of = @(); $chits = @()
    if ($mmCsOk) {
        $rr = $null
        if ($mmScanRes.ContainsKey($jp)) { $rr = $mmScanRes[$jp] }
        if ($rr) {
            $ms = @{ Patterns = @($rr.Patterns); Strings = @($rr.Strings); Fullwidth = @($rr.Fullwidth) }
            $bf = @($rr.Bypass)
            $of = @($rr.Obf)
            $chits = @($rr.ClassHits)
        }
    } else {
        try { $ms = Invoke-ModScan $jp; if ($ms -and $ms.ClassHits) { $chits = @($ms.ClassHits) } } catch {}
        try { $bf = @(Invoke-MmBypassScan $jp) } catch {}
        try { $of = @(Invoke-MmObfScan $jp) } catch {}
    }
    $hitSet = New-Object 'System.Collections.Generic.HashSet[string]'
    $fwList = @()
    if ($ms) {
        foreach ($x in $ms.Patterns) { [void]$hitSet.Add($x) }
        foreach ($x in $ms.Strings) { [void]$hitSet.Add($x) }
        $fwList = @($ms.Fullwidth)
    }
    $hitN = $hitSet.Count
    $fwN = $fwList.Count
    $sc1 = 0
    if ($hitN -ge 6) { $sc1 = 80 } elseif ($hitN -ge 4) { $sc1 = 65 } elseif ($hitN -eq 3) { $sc1 = 55 } elseif ($hitN -eq 2) { $sc1 = 45 } elseif ($hitN -eq 1) { $sc1 = 30 }
    if ($fwN -gt 0) { $sc1 = [Math]::Max($sc1, 50); if ($fwN -ge 2) { $sc1 += 10 } }
    $certHits = @($hitSet | Where-Object { $mmCertainSet.Contains([string]$_) })
    $cluNote = ''
    if (-not $isVer) {
        $clu = Get-MmModuleCluster $jp
        $cluN = @($clu.Names).Count
        $cluTxt = ((@($clu.Names) | Select-Object -First 12) -join ', ')
        if ($cluN -ge 4 -or ($clu.Struct -and $cluN -ge 1)) {
            # 4+ farkli hile modul sinifi ya da hile istemcisi dizilimi + en az 1 modul: kesin
            $certHits = @($certHits) + @('MODUL KUMESI: ' + $cluTxt + $(if ($clu.Struct) { ' + modules/combat-movement dizilimi' } else { '' }))
        } elseif ($cluN -ge 2 -or $clu.Struct) {
            $cluNote = 'olasi hile modul sinifi (' + $cluN + '): ' + $cluTxt + $(if ($clu.Struct) { ' + modules/combat-movement dizilimi' } else { '' })
            $sc1 = [Math]::Max($sc1, 55)
        }
    }
    if ($certHits.Count -gt 0) { $sc1 = 100 }
    $sc2 = 0
    foreach ($f in $bf) { $fs2 = Get-MmFlagScore $f; if ($fs2 -gt $sc2) { $sc2 = $fs2 } }
    if ($bf.Count -gt 1) { $sc2 += 5 * ($bf.Count - 1) }
    $sc3 = 0
    foreach ($f in $of) { $fs3 = Get-MmFlagScore $f; if ($fs3 -gt $sc3) { $sc3 = $fs3 } }
    if ($of.Count -gt 1) { $sc3 += 3 * ($of.Count - 1) }
    $cats = 0
    if ($sc1 -gt 0) { $cats++; $mmCntSus++ }
    if ($sc2 -gt 0) { $cats++; $mmCntByp++ }
    if ($sc3 -gt 0) { $cats++; $mmCntObf++ }
    $why = New-Object System.Collections.Generic.List[string]
    if ($chits.Count -gt 0) { [void]$why.Add('HILE IZI BULUNAN CLASS/DOSYA SAYISI: ' + $chits.Count + ' (asagida tek tek listelenir)') }
    if ($certHits.Count -gt 0) { [void]$why.Add('KESIN HILE IZI (%100): ' + ((@($certHits | Select-Object -First 15)) -join ', ')) }
    if ($cluNote) { [void]$why.Add($cluNote) }
    if ($isVer) { [void]$why.Add($ver.By + ' hash eslesmesi: ' + $ver.Name) }
    if ($hitN -gt 0) { [void]$why.Add('hile stringleri/desenleri (' + $hitN + '): ' + ((@($hitSet | Select-Object -First 15)) -join ', ')) }
    if ($fwN -gt 0) { [void]$why.Add('tam genislikli (fullwidth) unicode stringler: ' + ((@($fwList | Select-Object -First 10)) -join ', ')) }
    if ($bf.Count -gt 0) { [void]$why.Add('BYPASS/ENJEKSIYON: ' + ($bf -join ' | ')) }
    if ($of.Count -gt 0) {
        [void]$why.Add('OBFUSCATION: ' + ($of -join ' | '))
        Add-ObfNote $jp ('mod obfuscation izleri: ' + ((@($of | Select-Object -First 3)) -join ' | '))
    }
    $src = Get-MmSource $jp
    # ---- nereden indirildi + hile sitesi kontrolu ----
    $dlTxt = Get-DlSource $jp
    $cheatSite = Get-CheatSite $script:DlLastUrl
    if ($cheatSite) {
        $certHits = @($certHits) + @('hile sitesinden/adresinden indirilmis: ' + $cheatSite)
        [void]$why.Add('KESIN: hile sitesinden indirilmis (' + $cheatSite + ')')
        if ($cats -lt 1) { $cats = 1 }
    }
    if ($cats -eq 0) {
        if ($isVer) { [void]$mmVerified.Add($ver.Name + ' -> ' + $jar.Name); Add-ModInv $jar $hash $ver 'temiz: tarandi, hash dogrulandi' 0 }
        else {
            [void]$mmUnknown.Add($jar.Name + $(if ($src) { ' (kaynak: ' + $src + ')' } else { '' }))
            $usc = 12
            if ($src -match '^(Discord|MediaFire|MEGA|Dropbox|Google Drive|AnyDesk)$') { $usc = 27 }
            $unote = 'Modrinth/Megabase te hash eslesmesi yok (ozel/eski/degistirilmis mod olabilir)'
            if (-not $script:MmNet) { $unote = 'hash dogrulamasi yapilamadi (ag kapali/erisilemedi)' }
            $unote = $unote + ' | ' + $dlTxt
            Add-ModInv $jar $hash $ver 'tarandi, supheli yok ama hash dogrulanamadi' $usc
            Add-F -Kaynak 'Mod klasoru analizi' -Ad ('mod: ' + $jar.Name.ToLower()) -Yol $jp -Skor $usc -Son $jar.LastWriteTime -Ilk $jar.CreationTime -Var 'Evet' -Not $unote
        }
        continue
    }
    $total = [Math]::Max($sc1, [Math]::Max($sc2, $sc3)) + 8 * ($cats - 1)
    if ($isVer) { $total -= 25; [void]$why.Add('(dogrulanmis modda skor 25 dusuruldu; yine de kontrol et)') }
    if ($certHits.Count -gt 0) { $total = 100 }
    if ($total -lt 10) { $total = 10 }
    if ($total -gt 100) { $total = 100 }
    if (-not $isVer) { [void]$mmUnknown.Add($jar.Name + $(if ($src) { ' (kaynak: ' + $src + ')' } else { '' })) }
    [void]$why.Add($dlTxt)
    Add-ModInv $jar $hash $ver ('SUPHELI: ' + (($why | Select-Object -First 2) -join ' ; ')) $total
    if ($chits.Count -gt 0) { $script:ClassHitMap[$jp.ToLower()] = @($chits) }
    Add-F -Kaynak 'Mod klasoru analizi' -Ad ('mod: ' + $jar.Name.ToLower()) -Yol $jp -Skor $total -Son $jar.LastWriteTime -Ilk $jar.CreationTime -Var 'Evet' -Not (($why -join ' ; ') + ' | SHA1: ' + $hash)
    if ($certHits.Count -gt 0) {
        # kesin iz: adim bitmesini beklemeden hemen ekrana yaz
        try { [console]::Beep(1000, 150) } catch {}
        Show-Finding $script:HkFnd[$script:HkFnd.Count - 1]
    }
}
Perf-Lap '10: mod icerik taramasi (paralel motor)'
Log ('   ' + $mmJars.Count + ' mod incelendi: ' + $mmVerified.Count + ' dogrulanmis, ' + $mmUnknown.Count + ' bilinmeyen, ' + $mmCntSus + ' supheli string, ' + $mmCntByp + ' bypass/enjeksiyon, ' + $mmCntObf + ' obfuscated.') 'DarkGray'
if ($mmJars.Count -gt 0 -and -not $script:MmNet -and $env:HK_NONET -ne '1') { Log '   UYARI: ag erisimi basarisiz oldu, hash dogrulamasi yarida birakildi (bilinmeyen sayisi sisik olabilir).' 'DarkYellow' }
foreach ($vm in @($mmVerified | Select-Object -First 40)) { Log ('   dogrulanmis: ' + $vm) 'DarkGray' }
foreach ($um in @($mmUnknown | Select-Object -First 40)) { Log ('   bilinmeyen : ' + $um) 'DarkGray' }

# ---- calisan Java: JVM agent / enjeksiyon bayraklari ----
$legitAgents = 'jmxremote|yjp|jrebel|newrelic|jacoco|theseus'
foreach ($jpr in @(Get-CimInstance Win32_Process -Filter "Name='javaw.exe' OR Name='java.exe'" -ErrorAction SilentlyContinue)) {
    $cl = [string]$jpr.CommandLine
    if (-not $cl) { continue }
    foreach ($am in [regex]::Matches($cl, '-javaagent:(?:"([^"]+)"|([^\s"]+))')) {
        $ap = $am.Groups[1].Value
        if (-not $ap) { $ap = $am.Groups[2].Value }
        $eq = $ap.IndexOf('=')
        if ($eq -gt 0) { $ap = $ap.Substring(0, $eq) }
        $an = ''
        try { $an = [IO.Path]::GetFileName($ap) } catch {}
        if ($an -match $legitAgents) { continue }
        Add-Sys ('JVM agent: -javaagent:' + $an) 40 'Calisan Java a -javaagent ile dis kod yuklenmis (Lunar/Badlion gibi launcher lar da kullanabilir; dosyanin ne oldugunu kontrol et).' $jpr.CreationDate ('PID ' + $jpr.ProcessId + ' | yol: ' + $ap)
    }
    foreach ($sf in @(
        @('-Xbootclasspath/p:', 'bootstrap classpath in basina ekler, cekirdek Java siniflarini degistirebilir', 45),
        @('-Xbootclasspath/a:', 'bootstrap classpath e ekler, class loader in altina kod enjekte eder', 45),
        @('-agentlib:jdwp', 'JDWP hata ayiklama ajani, uzaktan debug acik', 35),
        @('-agentpath:', 'yerel (native) ajan yuklenmis, Java sandbox ini atlar', 45)
    )) {
        if ($cl.IndexOf($sf[0], [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            Add-Sys ('Supheli JVM parametresi: ' + $sf[0]) $sf[2] ('Calisan Java: ' + $sf[1]) $jpr.CreationDate ('PID ' + $jpr.ProcessId)
        }
    }
}
Show-Section

# ---------------------------------------------------------------------
Step '[11/17] Dosya taramasi (Downloads, Masaustu, Belgeler, Temp, AppData/Roaming, launcher klasorleri)...'
Start-Sec
Add-Root (Get-DownloadsPath)
Add-Root ([Environment]::GetFolderPath('Desktop'))
Add-Root ([Environment]::GetFolderPath('MyDocuments'))
Add-Root $env:APPDATA
Add-Root $env:TEMP
Add-Root ($env:WINDIR + '\Temp')
foreach ($gd in $script:GameDirs) { Add-Root $gd }
Add-Root ($env:ProgramData + '\Microsoft\Windows\Start Menu\Programs\StartUp')
Add-Root ($env:APPDATA + '\Microsoft\Windows\Start Menu\Programs\Startup')
foreach ($base in @($env:LOCALAPPDATA, $UP, $env:ProgramData, $env:ProgramFiles, ${env:ProgramFiles(x86)}, ($env:SystemDrive + '\'))) {
    if (-not $base) { continue }
    foreach ($d in @(Get-ChildItem -LiteralPath $base -Directory -Force -ErrorAction SilentlyContinue)) {
        if ($d.Name -match $script:LauncherRx -or ($base -eq $UP -and $d.Name -match '(?i)^\.(minecraft|lunarclient|tlauncher|badlion|feather|ichor)')) { Add-Root $d.FullName }
    }
}
$walkCs = @'
using System;
using System.Collections.Generic;
using System.IO;
public static class HkWalk {
    static readonly HashSet<string> Codes = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { ".exe", ".dll", ".jar", ".bat", ".cmd", ".ps1", ".vbs", ".scr", ".msi", ".com", ".zip", ".rar", ".7z" };
    public static List<string> CodeFiles(string root, int maxFiles) {
        List<string> res = new List<string>();
        Stack<string> st = new Stack<string>();
        st.Push(root);
        while (st.Count > 0 && res.Count < maxFiles) {
            string d = st.Pop();
            try {
                foreach (string f in Directory.GetFiles(d)) { if (Codes.Contains(Path.GetExtension(f))) res.Add(f); }
                foreach (string sd in Directory.GetDirectories(d)) {
                    try { if ((File.GetAttributes(sd) & FileAttributes.ReparsePoint) != 0) continue; } catch { continue; }
                    st.Push(sd);
                }
            } catch { }
        }
        return res;
    }
}
'@
$script:WalkOk = $false
try { Add-Type -TypeDefinition $walkCs -Language CSharp -ErrorAction Stop; $script:WalkOk = $true } catch {}
# Tarayici/uygulama onbellek klasorleri (yuz binlerce anlamsiz dosya): icerigi gezilmez, sadece icindeki kod/arsiv dosyalari yine incelenir
$pruneRx = '(?i)^(node_modules|Cache|Code Cache|GPUCache|CacheStorage|Service Worker|IndexedDB|Local Storage|Session Storage|Crashpad|blob_storage|\.git)$'
function Walk-Root([string]$root) {
    $stack = New-Object System.Collections.Generic.Stack[string]
    $stack.Push($root)
    while ($stack.Count -gt 0) {
        $d = $stack.Pop()
        $items = $null
        try { $items = (New-Object IO.DirectoryInfo $d).GetFileSystemInfos() } catch { Add-Cov 'Klasor okunamadi (erisim yok/hata): icindekiler TARANMADI' $d; continue }
        foreach ($it in $items) {
            if ($it -is [IO.DirectoryInfo]) {
                if ($it.Attributes -band [IO.FileAttributes]::ReparsePoint) { Add-Cov 'Reparse point/symlink/junction klasoru: gezilmedi' $it.FullName; continue }
                if ($it.Name -match $pruneRx) {
                    Add-Cov 'Onbellek klasoru (Cache/node_modules...): SADECE kod dosyalari tarandi' $it.FullName
                    if ($script:WalkOk) {
                        $cl = $null
                        try { $cl = [HkWalk]::CodeFiles($it.FullName, 1000000) } catch {}
                        foreach ($cp in @($cl)) { if ($cp) { try { Inspect-File (New-Object IO.FileInfo $cp) } catch {} } }
                    }
                    continue
                }
                $stack.Push($it.FullName)
            } else {
                Inspect-File $it
            }
        }
    }
}
foreach ($root in $script:ScanRoots) {
    $rootSw = [Diagnostics.Stopwatch]::StartNew()
    $rootF0 = $script:fileCount
    Log ('   taraniyor: ' + $root) 'DarkGray'
    if ($script:WalkOk) {
        Walk-Root $root
    } else {
        Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object { Inspect-File $_ }
    }
    Add-Perf ('11: kok klasor ' + $root) $rootSw.Elapsed.TotalSeconds ([string]($script:fileCount - $rootF0) + ' dosya')
}
Write-Host ''
$pfq = [double][Diagnostics.Stopwatch]::Frequency
Add-Perf '11: Get-Magic (dosya basi okuma) toplam' ([double]$script:PfMagic / $pfq) ([string]$script:PfMagicN + ' cagri')
Add-Perf '11: Inspect-Jar (jar acma, PowerShell) toplam' ([double]$script:PfInsJar / $pfq) ([string]$script:PfInsJarN + ' jar')
Add-Perf '11: ADS (gizli veri akisi) sorgusu toplam' ([double]$script:PfAds / $pfq) ([string]$script:PfAdsN + ' dosya')
Add-Perf 'Test-Signed (imza kontrolu) toplam, o ana kadar' ([double]$script:PfSign / $pfq) ([string]$script:PfSignN + ' cagri, ' + $script:PfSignFast + ' hizli yol')
Log ('   ' + $script:fileCount + ' dosya incelendi.') 'DarkGray'

# --- Phantom Client: JVM args ile calisan, dosya icermeyen hile. launcher_profiles.json (JavaArgs) + surum/feather json dosyalari taranir ---
$script:PhantomRx = New-Object System.Text.RegularExpressions.Regex ('(?i)phantom[\s._\-]*(client|launcher)')
foreach ($pj in $script:ProfileJsonCand) {
    try {
        $j = Get-Content -LiteralPath $pj.FullName -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if ($j.profiles) {
            foreach ($prop in $j.profiles.PSObject.Properties) {
                $prof = $prop.Value
                $ja = [string]$prof.javaArgs
                if (-not $ja) { continue }
                $lu = $pj.LastWriteTime
                try { if ($prof.lastUsed) { $lu = [datetime]([string]$prof.lastUsed) } } catch {}
                $ver = [string]$prof.lastVersionId
                $pmx = $script:PhantomRx.Match($ja)
                $h = Get-NameHit $ja $true
                if ($pmx.Success) {
                    Add-F -Kaynak 'launcher_profiles.json (JavaArgs)' -Ad ('javaargs: ' + $pmx.Value.ToLower()) -Yol $pj.FullName -Skor 75 -Son $lu -Var 'Evet' -Not ('profil: ' + $prop.Name + ' | surum/loader: ' + $ver + ' | JavaArgs icinde Phantom Client yaziyor (dosyasiz hile, JVM parametresiyle yuklenir) | JavaArgs: ' + $ja)
                } elseif ($h) {
                    Add-F -Kaynak 'launcher_profiles.json (JavaArgs)' -Ad ('javaargs: ' + $h.Name) -Yol $pj.FullName -Skor 55 -Son $lu -Var 'Evet' -Not ('profil: ' + $prop.Name + ' | surum/loader: ' + $ver + ' | JavaArgs icinde hile ismi geciyor (dosyasiz/fileless hile olabilir) | JavaArgs: ' + $ja)
                } elseif ($ja -match '(?i)-javaagent|-Xbootclasspath|-agentpath|-noverify|-Xverify:none') {
                    Add-F -Kaynak 'launcher_profiles.json (JavaArgs)' -Ad ('javaargs: ozel parametre (' + $prop.Name + ')') -Yol $pj.FullName -Skor 35 -Son $lu -Var 'Evet' -Not ('profil: ' + $prop.Name + ' | surum/loader: ' + $ver + ' | dis kod yukleyen JVM parametresi | JavaArgs: ' + $ja)
                }
            }
        }
    } catch {}
}
# Oyuncunun kullandigi surumun (loader) json dosyasi ve Feather klasoru: Phantom Client yazisi aranir
foreach ($jf in $script:JsonCand2) {
    try {
        $jt = [IO.File]::ReadAllText($jf.FullName)
        $jm = $script:PhantomRx.Match($jt)
        if ($jm.Success) {
            $a0 = [Math]::Max(0, $jm.Index - 60)
            $l0 = [Math]::Min(180, $jt.Length - $a0)
            $ctx = ($jt.Substring($a0, $l0) -replace '\s+', ' ')
            Add-F -Kaynak 'Surum/Feather json (JVM args)' -Ad ('json: ' + $jm.Value.ToLower()) -Yol $jf.FullName -Skor 65 -Son $jf.LastWriteTime -Ilk $jf.CreationTime -Var 'Evet' -Not ('Phantom Client yazisi bulundu | baglam: ' + $ctx)
        }
    } catch {}
}

# --- Run / RunOnce kayit defteri: bilgisayar acilista otomatik calisan programlar ve komutlar ---
foreach ($runKey in @(
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run',
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run',
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run'
)) {
    try {
        $rkItem = Get-Item -LiteralPath $runKey -ErrorAction Stop
        $rkTime = Get-KeyTime $rkItem
        $rkNote = ''
        if ($rkTime) { $rkNote = ' | Run anahtari son degisim: ' + (Fmt $rkTime) }
        foreach ($rn in $rkItem.GetValueNames()) {
            if (-not $rn) { continue }
            $cmdline = [string]$rkItem.GetValue($rn)
            if (-not $cmdline) { continue }
            $cmdX = [Environment]::ExpandEnvironmentVariables($cmdline)
            if ($cmdX -match $script:FlRx2) {
                Add-F -Kaynak 'Run (otomatik baslatma)' -Ad ('run: ' + $rn.ToLower()) -Yol $cmdX -Skor 55 -Var 'Evet' -Not ('acilista calisan komutta fileless/script kalibi var | anahtar: ' + $runKey + ' | tam komut: ' + $cmdline + $rkNote)
            }
            $runPaths = New-Object System.Collections.Generic.List[string]
            if ($cmdX -match '(?i)^\s*"([^"]+)"') { [void]$runPaths.Add($Matches[1]) } elseif ($cmdX -match '(?i)^\s*([A-Za-z]:\\.*?\.(?:exe|bat|cmd|ps1|vbs|jar|scr|com))') { [void]$runPaths.Add($Matches[1]) }
            foreach ($rp2 in (Find-Paths $cmdX 'exe|bat|cmd|ps1|vbs|jar|dll|scr')) { [void]$runPaths.Add($rp2) }
            $seenRun = @{}
            foreach ($ep in $runPaths) {
                if ($ep -notmatch '^[A-Za-z]:\\') { continue }
                $ek = $ep.ToLower()
                if ($seenRun.ContainsKey($ek)) { continue }
                $seenRun[$ek] = 1
                $pi = Test-PathInfo $ep
                Eval-Exec -Kaynak 'Run (otomatik baslatma)' -Path $ep -Exists $pi.Exists -Removed $pi.Removed -Note ('kayit adi: ' + $rn + ' | tam komut: ' + $cmdline + $rkNote)
            }
        }
    } catch {}
}

# --- XML Startup kayitlari (C:\Windows\System32\WDI\LogFiles\StartupInfo) ---
$xmlDir = $env:WINDIR + '\System32\WDI\LogFiles\StartupInfo'
if (Test-Path -LiteralPath $xmlDir) {
    $xmlList = @(Get-ChildItem -LiteralPath $xmlDir -Filter '*.xml' -File -Force -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 40)
    $xmlSeen = @{}
    foreach ($xf in $xmlList) {
        try {
            $xb = [IO.File]::ReadAllBytes($xf.FullName)
            foreach ($pth in (Get-PathsFromBytes $xb $true)) {
                $lk = $pth.ToLower()
                if ($xmlSeen.ContainsKey($lk)) { continue }
                $xmlSeen[$lk] = 1
                if ($pth -match '^[A-Za-z]:\\') {
                    $pi = Test-PathInfo $pth
                    Eval-Exec -Kaynak 'XML Startup (boot izleme)' -Path $pth -Exists $pi.Exists -Removed $pi.Removed -Last $xf.LastWriteTime -Note ('acilis kaydi: ' + $xf.Name)
                } else {
                    $h = Get-NameHit $pth $false
                    if ($h) {
                        Add-F -Kaynak 'XML Startup (boot izleme)' -Ad $lk -Yol $pth -Skor 45 -Son $xf.LastWriteTime -Var 'Bilinmiyor' -Not ('acilista calisan program olarak kaydedilmis, hile ismi: ' + $h.Name + ' | dosya: ' + $xf.Name)
                    }
                }
            }
        } catch {}
    }
    Log ('   ' + $xmlList.Count + ' XML Startup dosyasi incelendi.') 'DarkGray'
}

# --- PowerShell gecmisi ve olay loglari: fileless (dosyasiz) calistirma izleri ---
# Anahtar kelimeler: "Invoke-" ve "System.Reflection.Assembly". Tek basina BAN sebebi degildir, sadece suphe uyandirir;
# bulunan komutun tamamina bakip icinde bir dosya veya web sitesi var mi kontrol etmek gerekir.
$flRx = '(?i)Invoke-|System\.Reflection\.Assembly'
$flStrong = '(?i)((Invoke-Expression|\bIEX\b)[^\r\n]*(https?://|DownloadString|Invoke-RestMethod|Invoke-WebRequest))|((Invoke-RestMethod|Invoke-WebRequest|DownloadString)[^\r\n]*(Invoke-Expression|\bIEX\b))|(Reflection\.Assembly\]?::Load)'
$psHist = $env:APPDATA + '\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt'
if (Test-Path -LiteralPath $psHist) {
    $hcontent = @(Get-Content -LiteralPath $psHist -ErrorAction SilentlyContinue | Where-Object { $_ -notmatch 'HileKiran\.ps1' })
    $hTime = (Get-Item -LiteralPath $psHist).LastWriteTime
    $flHits = @($hcontent | Where-Object { $_ -match $flRx })
    if ($flHits.Count -gt 0) {
        $strongH = @($flHits | Where-Object { $_ -match $flStrong })
        $showH = $flHits
        $skorH = 35
        if ($strongH.Count -gt 0) { $showH = $strongH; $skorH = 55 }
        $samples = @($showH | Select-Object -First 3 | ForEach-Object { $t2 = ([string]$_).Trim(); if ($t2.Length -gt 220) { $t2 = $t2.Substring(0, 220) + '...' }; $t2 })
        Add-Sys ('PowerShell gecmisinde fileless calistirma izi (' + $flHits.Count + ' satir)') $skorH 'Invoke-* / System.Reflection.Assembly komutlari dosyasiz (bellekten) kod calistirmak icin kullanilabilir; her zaman kotu amacli degildir. Komutun tamamina bak: icinde bir dosya veya web sitesi var mi?' $null ($samples -join ' || ') $hTime
    }
    $wmH = @($hcontent | Where-Object { $_ -match '(?i)wmic(\.exe)?\s+.*process\s+call\s+create' })
    if ($wmH.Count -gt 0) {
        Add-Sys ('PowerShell gecmisinde wmic ile program baslatma (' + $wmH.Count + ' satir)') 45 'wmic ... process call create komutu bir exe/uzantisiz dosya/ADS baslatmak icin hilelerde kullanilir.' $null (([string]$wmH[0]).Trim()) $hTime
    }
}
foreach ($evId in @(4104, 4103)) {
    try {
        $evs = @(Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-PowerShell/Operational'; Id = $evId } -MaxEvents 300 -ErrorAction Stop | Where-Object { $_.ProcessId -ne $PID -and $_.Message -notmatch 'HileKiran\.ps1' })
        $flEvt = @($evs | Where-Object { $_.Message -match $flRx })
        if ($flEvt.Count -gt 0) {
            $strongE = @($flEvt | Where-Object { $_.Message -match $flStrong })
            $skorE = 35
            $firstE = $flEvt[0]
            if ($strongE.Count -gt 0) { $skorE = 55; $firstE = $strongE[0] }
            $mline = [string]($firstE.Message -split "`n" | Where-Object { $_ -match $flRx } | Select-Object -First 1)
            $mline = $mline.Trim()
            if ($mline.Length -gt 220) { $mline = $mline.Substring(0, 220) + '...' }
            Add-Sys ('PowerShell olay logunda (olay ' + $evId + ') fileless calistirma izi (' + $flEvt.Count + ' kayit)') $skorE 'Calistirilan PowerShell komut/script bloklarinda Invoke-* / System.Reflection.Assembly kaliplari bulundu. Tam komuta bak.' $firstE.TimeCreated $mline $firstE.TimeCreated
        }
    } catch {}
}
Show-Section

# ---------------------------------------------------------------------
Step '[12/17] Gorev Zamanlayici (Task Scheduler), WMI abonelikleri, StartUp klasoru...'
Start-Sec
$taskRoot2 = $env:WINDIR + '\System32\Tasks'
$taskFiles = @{}
$taskCount = 0
if (Test-Path -LiteralPath $taskRoot2) {
    foreach ($tf in @(Get-ChildItem -LiteralPath $taskRoot2 -Recurse -File -Force -ErrorAction SilentlyContinue)) {
        $rel = $tf.FullName.Substring($taskRoot2.Length)
        $taskFiles[$rel.ToLower()] = $tf
        $xml = $null
        try { $xml = [xml](Get-Content -LiteralPath $tf.FullName -Raw -ErrorAction Stop) } catch {}
        if (-not $xml -or -not $xml.Task) { continue }
        $taskCount++
        $isMs = ($rel -match '(?i)^\\Microsoft\\')
        $trig = ''
        try { if ($xml.Task.Triggers) { $trig = (@($xml.Task.Triggers.ChildNodes | ForEach-Object { $_.LocalName }) -join ',') } } catch {}
        $regDate = $null
        try { $rdS = [string]$xml.Task.RegistrationInfo.Date; if ($rdS) { $rdT = [datetime]::MinValue; if ([datetime]::TryParse($rdS, [ref]$rdT)) { $regDate = $rdT } } } catch {}
        foreach ($ex in @($xml.Task.Actions.Exec)) {
            if (-not $ex) { continue }
            $cmd = [string]$ex.Command
            if (-not $cmd) { continue }
            $targ = [string]$ex.Arguments
            $targX = [Environment]::ExpandEnvironmentVariables($targ)
            $cmdX = [Environment]::ExpandEnvironmentVariables($cmd).Trim().Trim('"')
            $full = $cmdX + ' ' + $targX
            $hit = Get-NameHit $full $false
            if ($isMs -and -not $hit) { continue }
            $sc = 0
            $why = New-Object System.Collections.Generic.List[string]
            if ($hit) { $sc += 45; [void]$why.Add('isim eslesmesi: ' + $hit.Name) }
            if ($full -match $script:FlRx2) { $sc += 40; [void]$why.Add('fileless/script kalibi (Invoke-/Reflection/base64/gizli pencere vb.)') }
            if ($full -match '(?i)https?://') { $sc += 15; [void]$why.Add('komutta web adresi var') }
            if ($cmdX -match '^[A-Za-z]:\\') {
                $cmdExists = [bool](Test-Path -LiteralPath $cmdX)
                $zc = Get-Zone $cmdX
                if (-not $cmdExists) {
                    $sc += 30; [void]$why.Add('gorevin komut dosyasi SILINMIS/yok')
                } elseif ($zc -eq 'user' -or $zc -eq 'temp' -or $zc -eq 'appdata' -or $zc -eq 'shared') {
                    $sc += 20; [void]$why.Add('gorev kullanici/temp/AppData klasorundeki bir programi calistiriyor')
                }
            }
            if (($trig -match '(?i)Boot|Logon') -and $sc -gt 0) { $sc += 10; [void]$why.Add('tetikleyici: ' + $trig) }
            if ($sc -ge 15) {
                $nt = ($why -join '; ') + ' | komut: ' + $cmd + ' | arguman: ' + $targ
                Add-F -Kaynak 'Gorev Zamanlayici' -Ad ('gorev: ' + $tf.Name.ToLower()) -Yol ($rel + '  ->  ' + $cmd) -Skor ([Math]::Min(100, $sc)) -Son $tf.LastWriteTime -Ilk $regDate -Var 'Evet' -Not $nt
            }
            foreach ($ap in (Find-Paths $targX 'exe|dll|jar|bat|ps1|cmd|vbs|scr')) {
                $api = Test-PathInfo $ap
                Eval-Exec -Kaynak 'Gorev Zamanlayici (arguman)' -Path $ap -Exists $api.Exists -Removed $api.Removed -Last $tf.LastWriteTime -Note ('gorev: ' + $rel)
            }
        }
    }
}
Log ('   ' + $taskCount + ' zamanlanmis gorev incelendi.') 'DarkGray'

# Gorev kayit defteri (TaskCache) ile Tasks klasoru birbirini tutuyor mu? (gizlenmis/silinmis gorev izi)
$taskTreeSet = @{}
try {
    $trBase = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree'
    $trLen = ('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree').Length
    foreach ($k in @(Get-ChildItem -LiteralPath $trBase -Recurse -ErrorAction SilentlyContinue)) {
        $tid = $k.GetValue('Id')
        if (-not $tid) { $k.Close(); continue }
        $krel = $k.Name.Substring($trLen)
        $taskTreeSet[$krel.ToLower()] = 1
        $ktime = Get-KeyTime $k
        $k.Close()
        if ($taskFiles.Count -gt 0 -and -not $taskFiles.ContainsKey($krel.ToLower())) {
            $tkSc = 40; if ($krel -match '(?i)^\\Microsoft\\Windows\\') { $tkSc = 10 }
            Add-Sys ('Gorev kayit defterinde var ama dosyasi YOK: ' + $krel) $tkSc 'Gorev Zamanlayici kaydi duruyor ama System32\Tasks icindeki dosyasi silinmis; gorev gizlenmis veya iz silinmis olabilir.' $null ('Id=' + $tid) $ktime
        }
    }
} catch {}
if ($taskTreeSet.Count -gt 0) {
    foreach ($fk in @($taskFiles.Keys)) {
        if (-not $taskTreeSet.ContainsKey($fk)) {
            $tfo = $taskFiles[$fk]
            Add-Sys ('Gorev dosyasi var ama kayit defterinde YOK: ' + $fk) 30 'System32\Tasks icinde dosya var ama TaskCache kaydi yok; Gorev Zamanlayici arayuzunde gorunmeyen gorev olabilir.' $null ('dosya: ' + $tfo.FullName) $tfo.LastWriteTime
        }
    }
}
# Silinen gorevler: olay gunlugu aciksa (Windows varsayilani kapali) silinme zamanlari buradan gelir
try {
    foreach ($e in @(Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-TaskScheduler/Operational'; Id = 141 } -MaxEvents 15 -ErrorAction Stop)) {
        $qm = [regex]::Matches([string]$e.Message, '"([^"]+)"')
        $tn = [string]$e.Message
        if ($qm.Count -gt 0) { $tn = $qm[$qm.Count - 1].Groups[1].Value }
        Add-Sys ('Gorev SILINMIS (olay 141): ' + $tn) 30 'Gorev Zamanlayici olay gunlugu: bu gorev silinmis.' $e.TimeCreated $null $e.TimeCreated
    }
} catch {}
try {
    foreach ($e in @(Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4699 } -MaxEvents 15 -ErrorAction Stop)) {
        $tn = ''
        try { $tn = [string]$e.Properties[4].Value } catch {}
        Add-Sys ('Gorev SILINMIS (guvenlik olayi 4699): ' + $tn) 30 'Guvenlik olay gunlugu: bir zamanlanmis gorev silinmis.' $e.TimeCreated $null $e.TimeCreated
    }
} catch {}
# WMI kalici olay aboneligi (kalici baslatma yontemi)
try {
    foreach ($e in @(Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-WMI-Activity/Operational'; Id = 5861 } -MaxEvents 10 -ErrorAction Stop)) {
        $wmsg = ([string]$e.Message -replace '\s+', ' ')
        if ($wmsg.Length -gt 220) { $wmsg = $wmsg.Substring(0, 220) + '...' }
        Add-Sys 'WMI kalici olay aboneligi olusturulmus (olay 5861)' 35 'WMI uzerinden kalici tetikleyici/komut tanimlanmis; hile veya zararli yazilim kalici calismak icin kullanabilir.' $e.TimeCreated $wmsg $e.TimeCreated
    }
} catch {}

# --- Start Menu\Programs\StartUp klasorleri: bilgisayar acilinca calisan kisayol/script/exe ---
$wsh2 = $null
try { $wsh2 = New-Object -ComObject WScript.Shell } catch {}
$suCount = 0
$scriptExt = @('.py', '.pyw', '.ps1', '.bat', '.cmd', '.vbs', '.vbe', '.js', '.jse', '.wsf', '.html', '.htm', '.hta', '.jar', '.exe', '.dll', '.scr', '.com', '.url')
foreach ($sd in @(($env:ProgramData + '\Microsoft\Windows\Start Menu\Programs\StartUp'), ($env:APPDATA + '\Microsoft\Windows\Start Menu\Programs\Startup'))) {
    if (-not (Test-Path -LiteralPath $sd)) { continue }
    foreach ($sf in @(Get-ChildItem -LiteralPath $sd -File -Force -ErrorAction SilentlyContinue)) {
        if ($sf.Name -ieq 'desktop.ini') { continue }
        $suCount++
        $sext = $sf.Extension.ToLower()
        $sc = 0
        $why = New-Object System.Collections.Generic.List[string]
        $hit = Get-NameHit $sf.Name $false
        if ($hit) { $sc += 45; [void]$why.Add('dosya adi: ' + $hit.Name) }
        if ($sext -eq '.lnk') {
            $tg = ''
            $ta = ''
            try { if ($wsh2) { $lk = $wsh2.CreateShortcut($sf.FullName); $tg = [string]$lk.TargetPath; $ta = [string]$lk.Arguments } } catch {}
            $lh = Get-NameHit ($tg + ' ' + $ta) $false
            if ($lh) { $sc += 40; [void]$why.Add('kisayol hedefinde isim: ' + $lh.Name) }
            if (($tg + ' ' + $ta) -match $script:FlRx2) { $sc += 40; [void]$why.Add('kisayol komutunda fileless/script kalibi') }
            if ($tg -match '^[A-Za-z]:\\') {
                $tpi = Test-PathInfo $tg
                Eval-Exec -Kaynak 'StartUp klasoru (kisayol)' -Path $tg -Exists $tpi.Exists -Removed $tpi.Removed -Last $sf.LastWriteTime -First $sf.CreationTime -Note ('kisayol: ' + $sf.Name + ' | arguman: ' + $ta)
            }
            if ($sc -gt 0) { [void]$why.Add('hedef: ' + $tg + ' ' + $ta) }
        } elseif ($scriptExt -contains $sext) {
            $sc += 30
            [void]$why.Add('StartUp klasorunde ' + $sext + ' dosyasi var (normalde sadece kisayol bulunur)')
            if (@('.html', '.htm', '.hta') -contains $sext) { $sc += 15 }
            if ($sf.Length -lt 2097152 -and (@('.exe', '.dll', '.scr', '.com', '.jar') -notcontains $sext)) {
                $ctext = ''
                try { $ctext = [IO.File]::ReadAllText($sf.FullName) } catch {}
                if ($ctext) {
                    $ch = Get-NameHit $ctext $false
                    if ($ch) { $sc += 30; [void]$why.Add('icerikte hile ismi: ' + $ch.Name) }
                    if ($ctext -match $script:FlRx2) { $sc += 25; [void]$why.Add('icerikte fileless/script kalibi') }
                    if ($ctext -match '(?i)https?://') { $sc += 10; [void]$why.Add('icerikte web adresi var') }
                }
            }
            if ($sext -eq '.exe' -and -not (Test-Signed $sf.FullName)) { $sc += 20; [void]$why.Add('imzasiz exe') }
        }
        if ($sc -ge 10) {
            Add-F -Kaynak 'StartUp klasoru' -Ad $sf.Name.ToLower() -Yol $sf.FullName -Skor ([Math]::Min(100, $sc)) -Son $sf.LastWriteTime -Ilk $sf.CreationTime -Var 'Evet' -Not ($why -join '; ')
        }
    }
}
Log ('   StartUp klasorlerinde ' + $suCount + ' oge incelendi.') 'DarkGray'
Show-Section

# ---------------------------------------------------------------------
Step '[13/17] Kayit defteri izleri (OpenSavePidlMRU, MountedDevices, VolumeInfoCache, DirectInput, WordWheelQuery, Uyumluluk, WinRAR, MuiCache)...'
Start-Sec
# --- Dosya Ac/Kaydet diyalogu gecmisi: OpenSavePidlMRU (uzantilar + dosya adlari), LastVisitedPidlMRU (diyalogu acan programlar) ---
$mruBase = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32'
$extFound = New-Object System.Collections.Generic.List[string]
$extTime = $null
foreach ($mk in @('OpenSavePidlMRU', 'LastVisitedPidlMRU')) {
    $rb = $mruBase + '\' + $mk
    if (-not (Test-Path -LiteralPath $rb)) { continue }
    $nodes = New-Object System.Collections.Generic.List[object]
    try { [void]$nodes.Add((Get-Item -LiteralPath $rb -ErrorAction Stop)) } catch {}
    foreach ($chd in @(Get-ChildItem -LiteralPath $rb -ErrorAction SilentlyContinue)) {
        [void]$nodes.Add($chd)
        if ($mk -eq 'OpenSavePidlMRU') {
            $en = $chd.PSChildName.ToLower()
            if (@('jar', 'exe', 'dll', 'bat', 'cmd', 'ps1', 'vbs', 'scr', 'zip', 'rar', '7z', 'py', 'msi') -contains $en) {
                [void]$extFound.Add($en)
                $ktE = Get-KeyTime $chd
                if ($ktE -and (-not $extTime -or $ktE -gt $extTime)) { $extTime = $ktE }
            }
        }
    }
    foreach ($nd in $nodes) {
        $kt = Get-KeyTime $nd
        foreach ($vn in $nd.GetValueNames()) {
            if ($vn -eq 'MRUListEx' -or -not $vn) { continue }
            $vb = $nd.GetValue($vn)
            if ($vb -isnot [byte[]]) { continue }
            foreach ($pth in (Get-PathsFromBytes $vb $true)) {
                if ($pth -match '^[A-Za-z]:\\') {
                    $pi = Test-PathInfo $pth
                    Eval-Exec -Kaynak ('ComDlg32\' + $mk) -Path $pth -Exists $pi.Exists -Removed $pi.Removed -Last $kt -Note 'Dosya Ac/Kaydet diyalogu gecmisi'
                } else {
                    Eval-Exec -Kaynak ('ComDlg32\' + $mk) -Path $pth -Last $kt -Note 'Dosya Ac/Kaydet diyalogu gecmisi (sadece dosya adi)' -NoLoc
                }
            }
        }
    }
}
if ($extFound.Count -gt 0) {
    $extList = (@($extFound | Select-Object -Unique) -join ', ')
    $extSkor = 8
    if (@($extFound) -contains 'jar' -or @($extFound) -contains 'exe' -or @($extFound) -contains 'dll') { $extSkor = 15 }
    Add-Sys 'Dosya Ac/Kaydet diyalogunda kod/arsiv uzantilari kullanilmis (OpenSavePidlMRU)' $extSkor 'Bu uzantilarla bir dosya acilmis/kaydedilmis. Ayrintili dosya adlari asagidaki bulgularda (varsa) listelenir.' $null ('uzantilar: ' + $extList) $extTime
}

# --- MountedDevices: harfi olup su an takili olmayan surucular, harf atanmamis (\??\Volume) hacimler ---
try {
    $md = Get-Item -LiteralPath 'HKLM:\SYSTEM\MountedDevices' -ErrorAction Stop
    $mdKt = Get-KeyTime $md
    $volOnly = 0
    $mdShown = 0
    foreach ($vn in $md.GetValueNames()) {
        if ($vn -match '^\\DosDevices\\([A-Za-z]:)$') {
            $dl = $Matches[1].ToUpper()
            if ($script:Drives -contains $dl) { continue }
            $desc = 'disk imzasi (sabit disk/bolum kaydi)'
            $bytes = $md.GetValue($vn)
            if ($bytes -is [byte[]] -and $bytes.Length -ge 8) {
                $tx = ([Text.Encoding]::Unicode.GetString($bytes)).TrimEnd([char]0)
                if ($tx -match '^_\?\?_') { $desc = $tx }
            }
            $mdShown++
            if ($mdShown -le 10) { Add-Sys ('Kayitli ama su an takili olmayan surucu harfi: ' + $dl) 15 'MountedDevices kaydinda var, simdi takili degil (cikarilmis USB/disk olabilir).' $null $desc $mdKt }
        } elseif ($vn -match '^\\\?\?\\Volume\{') {
            $volOnly++
        }
    }
    if ($volOnly -gt 0) {
        Add-Sys ('Harf atanmamis hacim kaydi: ' + $volOnly + ' adet (\??\Volume{...})') 10 'Bu kayitlar gizli veya silinmis suruculere ait olabilir (cogu zaman normaldir: kurtarma bolumu, eski USB).' $null $null $mdKt
    }
} catch {}

# --- Windows Search VolumeInfoCache: eskiden kullanilmis surucu harfleri (silinse de kayit kalir) ---
try {
    foreach ($c in @(Get-ChildItem -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows Search\VolumeInfoCache' -ErrorAction Stop)) {
        $dl = $c.PSChildName.TrimEnd('\').ToUpper()
        $lbl = [string]$c.GetValue('VolumeLabel')
        $dty = $c.GetValue('DriveType')
        $kt = Get-KeyTime $c
        $c.Close()
        if ($dl -match '^[A-Z]:$' -and ($script:Drives -notcontains $dl)) {
            $vs = 15
            if ($dty -eq 2) { $vs = 20 }
            Add-Sys ('Eskiden kullanilmis surucu (su an takili degil): ' + $dl) $vs 'Windows Search VolumeInfoCache: bu harfle bir surucu takilmis (surucu silinse de kayit kalir). Tur 2 = cikarilabilir (USB).' $null ('etiket=' + $lbl + ', surucu turu=' + $dty) $kt
        }
    }
} catch {}

# --- DirectInput: DirectInput kullanan programlar (bazi hileler kullanir) ---
try {
    foreach ($c in @(Get-ChildItem -LiteralPath 'HKCU:\Software\Microsoft\DirectInput' -ErrorAction Stop)) {
        $kn = $c.PSChildName
        $kt = Get-KeyTime $c
        $nameV = [string]$c.GetValue('Name')
        $pathV = [string]$c.GetValue('Path')
        $c.Close()
        $cand = ($kn -replace '[0-9A-Fa-f]{16}$', '')
        if ($nameV) { $cand = $nameV }
        if ($pathV -match '^[A-Za-z]:\\') {
            $pi = Test-PathInfo $pathV
            Eval-Exec -Kaynak 'DirectInput' -Path $pathV -Exists $pi.Exists -Removed $pi.Removed -Last $kt -Note ('DirectInput kaydi: ' + $kn)
        } elseif ($cand) {
            Eval-Exec -Kaynak 'DirectInput' -Path $cand -Last $kt -Note ('DirectInput kaydi: ' + $kn) -NoLoc
        }
    }
} catch {}

# --- WordWheelQuery: Dosya Gezgini sag ustteki arama kutusunun gecmisi ---
try {
    $ww = Get-Item -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery' -ErrorAction Stop
    $wwKt = Get-KeyTime $ww
    foreach ($vn in $ww.GetValueNames()) {
        if ($vn -eq 'MRUListEx' -or -not $vn) { continue }
        $vb = $ww.GetValue($vn)
        if ($vb -isnot [byte[]]) { continue }
        $q = ([Text.Encoding]::Unicode.GetString($vb)).TrimEnd([char]0)
        if (-not $q) { continue }
        $h = Get-NameHit $q $false
        if ($h) {
            Add-F -Kaynak 'Dosya Gezgini arama gecmisi (WordWheelQuery)' -Ad ('arama: ' + $q.ToLower()) -Yol $q -Skor 40 -Son $wwKt -Var 'Bilinmiyor' -Not ('Dosya Gezgini aramasinda hile ismi aranmis: ' + $h.Name + ' | anahtar son degisim: ' + (Fmt $wwKt))
        }
    }
} catch {}

# --- Compatibility Assistant (Store / Persisted): calistirilmis programlarin yollari ---
foreach ($cak in @('Store', 'Persisted')) {
    try {
        $cas = Get-Item -LiteralPath ('HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\' + $cak) -ErrorAction Stop
        foreach ($vn in $cas.GetValueNames()) {
            if ($vn -notmatch '^[A-Za-z]:\\') { continue }
            $pi = Test-PathInfo $vn
            Eval-Exec -Kaynak ('Compatibility Assistant ' + $cak) -Path $vn -Exists $pi.Exists -Removed $pi.Removed -Note 'Uyumluluk yardimcisi kaydi (program calistirilmis)'
        }
    } catch {}
}
# --- WinRAR gecmisi: acilan arsivler ---
try {
    $wr = Get-ItemProperty -LiteralPath 'HKCU:\Software\WinRAR\ArcHistory' -ErrorAction Stop
    foreach ($prop in $wr.PSObject.Properties) {
        if ($prop.Name -match '^PS') { continue }
        $vp = [string]$prop.Value
        if ($vp -notmatch '^[A-Za-z]:\\') { continue }
        $h = Get-NameHit $vp $true
        if ($h) {
            $pi = Test-PathInfo $vp
            $wvar = 'Hayir'
            if ($pi.Exists) { $wvar = 'Evet' }
            Add-F -Kaynak 'WinRAR gecmisi' -Ad (Split-Path -Leaf $vp).ToLower() -Yol $vp -Skor 40 -Var $wvar -Not ('WinRAR ile acilmis arsiv | isim eslesmesi: ' + $h.Name)
        }
    }
} catch {}
# --- MuiCache: calistirilmis programlarin gorunen adlari (deger adi: yol.FriendlyAppName) ---
try {
    $mc = Get-Item -LiteralPath 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache' -ErrorAction Stop
    $mcSeen = @{}
    foreach ($vn in $mc.GetValueNames()) {
        $mp = $vn -replace '\.(FriendlyAppName|ApplicationCompany)$', ''
        if ($mp -notmatch '(?i)^[A-Za-z]:\\.*\.(exe|dll)$') { continue }
        $mk2 = $mp.ToLower()
        if ($mcSeen.ContainsKey($mk2)) { continue }
        $mcSeen[$mk2] = 1
        $pi = Test-PathInfo $mp
        Eval-Exec -Kaynak 'MuiCache' -Path $mp -Exists $pi.Exists -Removed $pi.Removed -Note 'MuiCache kaydi (program en az bir kez calistirilmis)'
    }
} catch {}
Show-Section

# ---------------------------------------------------------------------
Step '[14/17] Bellek (RAM) string taramasi: ctfmon, sihost, explorer, DPS, Dnscache... (birkac dakika surebilir)'
Start-Sec
$script:MemOk = 0
$script:MemFail = 0
$script:MemFailNames = New-Object System.Collections.Generic.List[string]
if (-not $script:HkOk) {
    Log '   yardimci modul derlenemedi, bellek taramasi atlandi.' 'DarkYellow'; Add-Cov 'Bellek tarama motoru derlenemedi: bellek taramasi YAPILMADI' ''
} else {
    try { [void][HkNative]::EnableDebug() } catch {}
    $rxExe = '\.(?:exe|dll|jar|bat|ps1|cmd|vbs|scr)'
    $rxDom = '\.(?:com|net|org|gg|io|xyz|ru|to|cc|club|pw|dev|me|app|su|cloud|shop|store|lol|fun|top|info|site|online|space|tech|cx|ws)(?![a-z0-9])'
    $memDone = @{}
    # Normal process'ler: etiket, process adi, regex, mod
    $procTargets = @(
        @('ctfmon', 'ctfmon', $rxExe, 'exe'),
        @('sihost', 'sihost', $rxExe, 'exe'),
        @('taskhostw', 'taskhostw', $rxExe, 'exe'),
        @('explorer', 'explorer', ($rxExe + '|wmic'), 'wmic'),
        @('SearchIndexer', 'SearchIndexer', $rxExe, 'exe'),
        @('SmartScreen', 'smartscreen', $rxExe, 'exe'),
        @('csrss', 'csrss', $rxExe, 'exe'),
        @('SgrmBroker', 'SgrmBroker', 'wmic', 'wmic'),
        @('MsMpEng', 'MsMpEng', 'wmic', 'wmic')
    )
    foreach ($pt in $procTargets) {
        foreach ($gp in @(Get-Process -Name $pt[1] -ErrorAction SilentlyContinue)) {
            $mkey = ([string]$gp.Id) + '|' + $pt[3]
            if ($memDone.ContainsKey($mkey)) { continue }
            $memDone[$mkey] = 1
            Scan-MemProcess $pt[0] $gp.Id $pt[2] $pt[3]
        }
    }
    # Servisler (svchost icinde calisir): servis adi, regex, mod
    $svcTargets = @(
        @('Appinfo', $rxExe, 'exe'),
        @('DPS', $rxExe, 'dps'),
        @('mpssvc', $rxExe, 'exe'),
        @('BFE', $rxExe, 'exe'),
        @('DiagTrack', $rxExe, 'exe'),
        @('SysMain', $rxExe, 'exe'),
        @('Dnscache', $rxDom, 'dns')
    )
    foreach ($st in $svcTargets) {
        $svo = Get-CimInstance Win32_Service -Filter ("Name='" + $st[0] + "'")
        if (-not $svo -or -not $svo.ProcessId -or $svo.ProcessId -le 0) { continue }
        $mkey = ([string]$svo.ProcessId) + '|' + $st[2]
        if ($memDone.ContainsKey($mkey)) { continue }
        $memDone[$mkey] = 1
        Scan-MemProcess $st[0] ([int]$svo.ProcessId) $st[1] $st[2]
    }
    $failTxt = ''
    if ($script:MemFail -gt 0) { $failTxt = ' | okunamayanlar: ' + (($script:MemFailNames | Select-Object -Unique) -join ', ') + ' (korumali/PPL process olabilir)' }
    Log ('   ' + $script:MemOk + ' process bellegi tarandi, ' + $script:MemFail + ' tanesi okunamadi' + $failTxt) 'DarkGray'
}
Show-Section

# =====================================================================
# EK MODULLER (Discord rehberlerinden): JAVAW Prefetch, JavaLauncher.log, bellek (-jar/.jar),
# PowerShell gecmisi/olay gunlukleri, USN silinme, ENB/ReShade proxy dll, dizinlenmis konumlar, process modulleri
# =====================================================================
# ---------------- ek yardimcilar ----------------
$script:PsTamperRx = '(?i)wevtutil(\.exe)?\s+(cl|clear-log)|Clear-EventLog|Remove-EventLog|fsutil(\.exe)?\s+usn\s+deletejournal|(Remove-Item|\bdel\b|\brm\b|\berase\b)[^\r\n]*(Prefetch|ConsoleHost_history|JavaLauncher)|Set-MpPreference[^\r\n]*Disable|Add-MpPreference[^\r\n]*Exclusion(Path|Process|Extension)|Stop-Service[^\r\n]*(EventLog|DPS|SysMain|PcaSvc|bam|WinDefend)|Set-Service[^\r\n]*(EventLog|DPS|SysMain|PcaSvc|bam)|\bsc(\.exe)?\s+(config|stop)\s+(EventLog|DPS|SysMain|PcaSvc|bam)|\bClear-History\b|Set-PSReadLineOption[^\r\n]*SaveNothing|(Set-Content|Clear-Content|Out-File)[^\r\n]*(ConsoleHost_history|JavaLauncher)|reg(\.exe)?\s+(add|delete)[^\r\n]*(PrefetchParameters|EnablePrefetcher|DisableAntiSpyware)'
$script:ProxyDllRx = '(?i)^(d3d8|d3d9|d3d10|d3d10_1|d3d11|dxgi|opengl32|dinput8|dinput|winmm|version|xinput1_3|xinput1_4|xinput9_1_0|dsound|ddraw|msimg32|dbghelp|vorbisfile)\.dll$'
$script:OwnMarkers = 'HileKiran|\$StrongNames|Eval-Exec|Eval-JarArg|Analyze-PsText|Show-Section|HkNative|Add-F '

$script:HkUserDirs = @()
try {
    $script:HkUserDirs = @(Get-ChildItem -LiteralPath ($env:SystemDrive + '\Users') -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '^(All Users|Default|Default User|Public)$' })
} catch {}

function Get-SigInfo([string]$p) {
    $r = @{ Valid = $false; Subject = '' }
    try {
        $s = Get-AuthenticodeSignature -LiteralPath $p -ErrorAction Stop
        if ($s.Status -eq 'Valid') { $r.Valid = $true }
        if ($s.SignerCertificate) { $r.Subject = [string]$s.SignerCertificate.Subject }
    } catch {}
    return $r
}

# "java -jar <arg>" argumanini degerlendirir (uzanti degistirilmis mi, dosya silinmis mi, jar icinde hile var mi)
function Eval-JarArg([string]$arg, [string]$kaynak, $tm, [string]$note) {
    $arg = $arg.Trim().Trim('"').Trim([char]39).Trim()
    if ($arg.Length -lt 3) { return }
    if ($arg -match '^[-/%$]') { return }
    $leaf = $arg
    try { $leaf = Split-Path -Leaf $arg } catch {}
    if (-not $leaf) { return }
    $ext = ''
    try { $ext = [IO.Path]::GetExtension($leaf).ToLower() } catch {}
    $sc = 0
    $why = New-Object System.Collections.Generic.List[string]
    $hit = Get-NameHit $leaf $true
    if ($hit) {
        $ns = Name-Score $hit $true
        if ($ns -gt 0) { $sc += $ns; [void]$why.Add('isim eslesmesi: ' + $hit.Name) }
    }
    if ($ext -ne '.jar') {
        $extTxt = $ext
        if (-not $extTxt) { $extTxt = 'uzantisiz' }
        $sc += 55
        [void]$why.Add('java -jar ile calistirilmis ama uzanti .jar degil (' + $extTxt + ') - uzanti degistirilmis olabilir')
    }
    $var = 'Bilinmiyor'
    if ($arg -match '^[A-Za-z]:\\') {
        $pi = Get-PiCached $arg
        $zone = Get-Zone $arg
        if ($pi.Exists) {
            $var = 'Evet'
            if ($ext -ne '.jar') {
                $mg = Get-Magic $arg
                if ($mg -eq 'PK') { $sc += 25; [void]$why.Add('dosya icerigi gercekten ZIP/JAR (PK) - jar baska uzantiyla saklaniyor') }
                elseif ($mg -eq 'MZ') { $sc += 30; [void]$why.Add('dosya icerigi EXE/DLL (MZ)') }
            } else {
                $jr = Inspect-Jar $arg
                if ($jr.Hit) { $sc += 40; [void]$why.Add('jar ICINDE hile modulu/istemci ismi: ' + $jr.Hit) }
                if ($jr.Agent) { $sc += 15; [void]$why.Add('jar bir Java agent (' + $jr.AgentClass + ')') }
            }
            if ($zone -eq 'user' -or $zone -eq 'temp') { $sc += 10; [void]$why.Add('kullanici/temp klasorunde') }
        } else {
            $var = 'Hayir'
            if ($pi.Removed) {
                $sc += 30; [void]$why.Add('cikarilmis/eski surucuden calistirilmis')
            } elseif ($zone -eq 'user' -or $zone -eq 'temp' -or $zone -eq 'appdata' -or $zone -eq 'shared') {
                $sc += 30; [void]$why.Add('dosya SILINMIS (kullanici/temp/AppData klasoru)')
            } else {
                $sc += 15; [void]$why.Add('dosya su an bulunamiyor')
            }
        }
    }
    if ($arg -match '(?i)\\(\.minecraft|\.lunarclient|ModrinthApp|PrismLauncher)\\(libraries|versions|runtime)\\|^[A-Za-z]:\\Program Files') { $sc -= 20 }
    if ($leaf -match $script:BenignRx) { $sc -= 15 }
    if ($sc -lt 25) { return }
    $nt = ($why -join '; ')
    if ($note) { $nt = $nt + ' | ' + $note }
    Add-F -Kaynak $kaynak -Ad ('jar: ' + $leaf.ToLower()) -Yol $arg -Skor ([Math]::Min(100, $sc)) -Son $tm -Var $var -Not $nt
}

# Bellek string listesinden "-jar <arguman>" cikarir
function Analyze-MemJar([string]$label, $strings, [int]$procId) {
    if ($null -eq $strings -or $strings.Count -eq 0) { return }
    $seen = @{}
    foreach ($s in $strings) {
        if ($s.IndexOf('-jar', [StringComparison]::OrdinalIgnoreCase) -lt 0) { continue }
        foreach ($m in [regex]::Matches($s, '(?i)-jar\s+(?:"([^"]+)"|([^\s")]+))')) {
            $a = $m.Groups[1].Value
            if (-not $a) { $a = $m.Groups[2].Value }
            if (-not $a) { continue }
            $k = $a.ToLower()
            if ($seen.ContainsKey($k)) { continue }
            $seen[$k] = 1
            if ($seen.Count -gt 400) { return }
            $snip = $s
            if ($snip.Length -gt 200) { $snip = $snip.Substring(0, 200) + '...' }
            Eval-JarArg $a ('Bellek stringi: ' + $label + ' (-jar)') $null ('PID ' + $procId + ' | string: ' + $snip)
        }
    }
}
function Scan-MemJar([string]$label, [int]$procId, [string]$rx, [bool]$img) {
    Log ('   bellek taraniyor: ' + $label + ' (PID ' + $procId + ')') 'DarkGray'
    $list = $null
    try { $list = [HkNative]::MemStrings($procId, $rx, 4, $true, $true, $img, [long]734003200) } catch { $list = $null }
    if ($null -eq $list) { Log ('   okunamadi (korumali process olabilir): ' + $label) 'DarkYellow'; Add-Cov 'Java/JAR process bellegi okunamadi' $label; return }
    Analyze-MemJar $label $list $procId
    Analyze-MemExe $label $list $procId
}

# PowerShell komut/script metnini analiz eder (gecmis dosyasi, olay gunlugu, profil)
function Analyze-PsText([string]$text, [string]$kaynak, $tm, [bool]$useFl) {
    if ([string]::IsNullOrWhiteSpace($text)) { return }
    $snip = ($text -replace '\s+', ' ').Trim()
    if ($snip.Length -gt 260) { $snip = $snip.Substring(0, 260) + '...' }
    foreach ($m in [regex]::Matches($text, '(?i)-jar\s+(?:"([^"]+)"|([^\s")]+))')) {
        $a = $m.Groups[1].Value
        if (-not $a) { $a = $m.Groups[2].Value }
        if ($a) { Eval-JarArg $a $kaynak $tm ('PowerShell: ' + $snip) }
    }
    if ($text -match $script:PsTamperRx) {
        Add-F -Kaynak $kaynak -Ad 'powershell: iz temizleme / koruma kapatma komutu' -Yol $snip -Skor 55 -Son $tm -Var 'Bilinmiyor' -Not ('log/prefetch/gecmis silme veya Defender/servis kapatma komutu | komut: ' + $snip)
    }
    foreach ($pm in (Find-Paths $text 'exe|dll|jar|bat|ps1|scr|cmd|vbs')) {
        $pi = Get-PiCached $pm
        Eval-Exec -Kaynak $kaynak -Path $pm -Exists $pi.Exists -Removed $pi.Removed -Last $tm -Note ('PowerShell komutu: ' + $snip)
    }
    $h = Get-NameHit $text $false
    if ($h) {
        Add-F -Kaynak $kaynak -Ad ('powershell: ' + $h.Name) -Yol $snip -Skor 45 -Son $tm -Var 'Bilinmiyor' -Not ('PowerShell komutunda hile ismi geciyor: ' + $h.Name + ' | komut: ' + $snip)
    }
    if ($useFl -and ($text -match $script:FlRx2)) {
        Add-F -Kaynak $kaynak -Ad 'powershell: fileless/script kalibi' -Yol $snip -Skor 35 -Son $tm -Var 'Bilinmiyor' -Not ('gizli pencere/encoded/indirme kalibi (tek basina BAN sebebi degil, komutun tamamina bak) | komut: ' + $snip)
    }
}

# fsutil USN gunlugunde isim deseni arar (tek gecis, birden cok desen)
function Read-UsnPattern([string]$dl, [string[]]$patterns) {
    $out = New-Object System.Collections.Generic.List[object]
    $lines = @(Select-UsnLines $dl $patterns)
    foreach ($ln in $lines) {
        [void]$out.Add([pscustomobject]@{ Silme = (Test-UsnDelete $ln); Ad = (Get-UsnName $ln); Zaman = (Get-UsnTime $ln) })
    }
    return $out
}

# ENB / ReShade / taninmayan proxy dll degerlendirmesi
function Eval-ProxyDll([string]$p, [string]$kaynak, $tm, [string]$ctx) {
    $fi = $null
    try { $fi = Get-Item -LiteralPath $p -Force -ErrorAction Stop } catch { return }
    $dir = ''
    try { $dir = Split-Path -Parent $p } catch {}
    $sig = Get-SigInfo $p
    if ($sig.Valid -and $sig.Subject -match '(?i)Microsoft|NVIDIA|Intel|Advanced Micro Devices|Oracle|Azul|Eclipse|Amazon|Google') { return }
    $vi = $fi.VersionInfo
    $idText = (([string]$vi.ProductName) + ' ' + ([string]$vi.FileDescription) + ' ' + ([string]$vi.CompanyName) + ' ' + ([string]$vi.OriginalFilename))
    $ident = ''
    if ($idText -match '(?i)reshade') { $ident = 'ReShade' } elseif ($idText -match '(?i)\benb\b|enbseries|vorontsov') { $ident = 'ENB' }
    if (-not $ident -and $fi.Length -lt 41943040) {
        try {
            $b = [IO.File]::ReadAllBytes($p)
            $t = [Text.Encoding]::GetEncoding(28591).GetString($b)
            if ($t -match '(?i)reshade') { $ident = 'ReShade' } elseif ($t -match '(?i)enbseries|enblocal\.ini|boris vorontsov') { $ident = 'ENB' }
        } catch {}
    }
    $sib = @()
    if ($dir) {
        foreach ($sn in @('ReShade.ini', 'reshade-shaders', 'ReShade64.dll', 'ReShade32.dll', 'enbseries.ini', 'enbseries', 'enblocal.ini')) {
            if (Test-Path -LiteralPath (Join-Path $dir $sn)) { $sib += $sn }
        }
    }
    $sha = ''
    try { $sha = (Get-FileHash -LiteralPath $p -Algorithm SHA256 -ErrorAction Stop).Hash } catch {}
    $sc = 0
    $why = New-Object System.Collections.Generic.List[string]
    if ($ident -or $sib.Count -gt 0) {
        $nm2 = $ident
        if (-not $nm2) { $nm2 = 'ENB/ReShade' }
        $sc = 35
        [void]$why.Add($nm2 + ' (grafik modu) - mesru olabilir ama enjeksiyon/gizleme icin de kullanilir; SHA256 degerini bilinen surumle karsilastir')
        if ($sib.Count -gt 0) { [void]$why.Add('yaninda: ' + ($sib -join ', ')) }
        if (-not $sig.Valid) { $sc += 5 }
    } elseif ($sig.Valid) {
        $sc = 15
        [void]$why.Add('imzali proxy dll, yayinci: ' + $sig.Subject)
    } else {
        $sc = 65
        [void]$why.Add('IMZASIZ ve taninmayan proxy/sistem dll ismi (' + $fi.Name + ') oyun/java klasorunde - hile enjeksiyonunda sik kullanilir')
    }
    $h = Get-NameHit $fi.Name $false
    if ($h) { $sc += 40; [void]$why.Add('isim eslesmesi: ' + $h.Name) }
    $nt = ($why -join '; ')
    if ($sha) { $nt = $nt + ' | SHA256: ' + $sha }
    if ($ctx) { $nt = $nt + ' | ' + $ctx }
    Add-F -Kaynak $kaynak -Ad ($fi.Name.ToLower()) -Yol $p -Skor ([Math]::Min(100, $sc)) -Son $fi.LastWriteTime -Ilk $fi.CreationTime -Var 'Evet' -Not $nt
}

# =====================================================================
Step '[14+/17] A) JAVAW/JAVA Prefetch: calisma sirasinda acilan dosyalar (.jar ve uzantisi degistirilmis jar)...'
Start-Sec
$jvPf = @($pfFiles | Where-Object { $_.Name -match '(?i)^JAVAW?\.EXE-[0-9A-F]{8}\.pf$' })
if ($jvPf.Count -eq 0 -and ((Test-Path -LiteralPath ($env:APPDATA + '\.minecraft')) -or $script:GameDirs.Count -gt 0)) {
    Add-Sys 'JAVAW/JAVA Prefetch kaydi YOK' 30 '.minecraft klasoru var ama java.exe/javaw.exe icin Prefetch kaydi bulunamadi; kayit silinmis olabilir (WinPrefetchView ile bakilan ilk yer burasi).'
}
$jvSeen = @{}
$jvCount = 0
foreach ($jpf in $jvPf) {
    $info = Read-Prefetch $jpf.FullName
    $last = $jpf.LastWriteTime
    $runsTxt = ''
    Log ('   ' + $jpf.Name + ': ' + @($info.Runs).Count + ' calisma saati, ' + @($info.Paths).Count + ' dosya yolu okundu') 'DarkGray'
    if (@($info.Paths).Count -eq 0) { Log ('     (yol okunamadi - neden: ' + $script:PfDiag + ')') 'DarkYellow' }
    if ($info.Runs.Count -gt 0) {
        $sorted = @($info.Runs | Sort-Object -Descending)
        $last = $sorted[0]
        $runsTxt = 'Prefetch calisma saatleri: ' + ((@($sorted | Select-Object -First 8) | ForEach-Object { Fmt $_ }) -join ', ')
    }
    foreach ($raw in $info.Paths) {
        $rr = $null
        if ($raw -match '^\\VOLUME\{') { $rr = Resolve-PfPath $raw }
        elseif ($raw -match '^\\DEVICE\\HARDDISKVOLUME\d+\\') { $rr = Resolve-NtPath $raw }
        else { continue }
        $p = $rr.Path
        $lk = $p.ToLower()
        if ($jvSeen.ContainsKey($lk)) { continue }
        $jvSeen[$lk] = 1
        $ext = ''
        $leaf = ''
        try { $ext = [IO.Path]::GetExtension($p).ToLower(); $leaf = Split-Path -Leaf $p } catch {}
        if (-not $leaf) { continue }
        $jvCount++
        $zone = Get-Zone $p
        $isLib = ($p -match '(?i)\\(\.minecraft|\.lunarclient|ModrinthApp|PrismLauncher|\.tlauncher|\.feather|\.ichor)\\(libraries|assets|versions|runtime|bin)\\') -or ($p -match '(?i)^[A-Za-z]:\\(Windows|Program Files|Program Files \(x86\))\\')
        $sc = 0
        $why = New-Object System.Collections.Generic.List[string]
        $hit = Get-NameHit $leaf $false
        if ($hit) { $sc += 50; [void]$why.Add('isim eslesmesi: ' + $hit.Name) }
        $var = 'Bilinmiyor'
        if ($ext -eq '.jar') {
            if ($isLib -and -not $hit) { continue }
            if ($rr.Removed) {
                $var = 'Hayir'; $sc += 40; [void]$why.Add('javaw tarafindan acilan jar, surucu cikarilmis')
            } elseif (-not $rr.Exists) {
                $var = 'Hayir'
                if ($zone -eq 'user' -or $zone -eq 'temp' -or $zone -eq 'appdata' -or $zone -eq 'shared') { $sc += 40 } else { $sc += 25 }
                [void]$why.Add('javaw tarafindan acilan jar su an YOK (silinmis olabilir; silinen mod da olabilir)')
            } else {
                $var = 'Evet'
                $jr = Inspect-Jar $p
                if ($jr.Hit) { $sc += 40; [void]$why.Add('jar ICINDE hile modulu/istemci ismi: ' + $jr.Hit) }
                if ($jr.Agent) { $sc += 30; [void]$why.Add('jar bir Java agent (' + $jr.AgentClass + ')') }
                if ($zone -eq 'user' -or $zone -eq 'temp') { $sc += 10; [void]$why.Add('kullanici/temp klasorunde jar') }
            }
        } elseif ($rr.Exists -and -not $isLib -and (($DisguiseExt -contains $ext) -or $ext -eq '')) {
            $var = 'Evet'
            $fl = $null
            try { $fl = Get-Item -LiteralPath $p -Force -ErrorAction Stop } catch {}
            if ($fl -and -not $fl.PSIsContainer -and $fl.Length -ge 20480) {
                $mg = Get-Magic $p
                if ($mg -eq 'PK') { $sc += 65; [void]$why.Add('javaw acmis; uzanti ' + $ext + ' ama icerik ZIP/JAR (PK) - jar baska uzantiyla gizlenmis') }
                elseif ($mg -eq 'MZ') { $sc += 65; [void]$why.Add('javaw acmis; uzanti ' + $ext + ' ama icerik EXE/DLL (MZ)') }
            }
        }
        if ($sc -ge 25) {
            $nt = ($why -join '; ')
            if ($runsTxt) { $nt = $nt + ' | ' + $runsTxt }
            Add-F -Kaynak ('Prefetch: ' + $jpf.Name) -Ad $leaf.ToLower() -Yol $p -Skor ([Math]::Min(100, $sc)) -Son $last -Ilk $jpf.CreationTime -Var $var -Not $nt
        }
    }
}
Log ('   ' + $jvPf.Count + ' java/javaw Prefetch dosyasi, ' + $jvCount + ' dosya yolu incelendi.') 'DarkGray'
Show-Section

# =====================================================================
Step '[14+/17] B) JavaLauncher.log: java -jar ile baslatilan dosyalar (uzantisi degistirilmis jar)...'
Start-Sec
$tempDirs = New-Object System.Collections.Generic.List[string]
foreach ($t0 in @($env:TEMP, ($env:WINDIR + '\Temp'))) { if ($t0) { [void]$tempDirs.Add($t0) } }
foreach ($ud in $script:HkUserDirs) { [void]$tempDirs.Add((Join-Path $ud.FullName 'AppData\Local\Temp')) }
$jlSeenF = @{}
$jlSeenK = @{}
$jlTotal = 0
foreach ($tdir in $tempDirs) {
    if (-not (Test-Path -LiteralPath $tdir)) { continue }
    foreach ($f in @(Get-ChildItem -LiteralPath $tdir -Filter 'JavaLauncher*' -File -Force -ErrorAction SilentlyContinue)) {
        $fk = $f.FullName.ToLower()
        if ($jlSeenF.ContainsKey($fk)) { continue }
        $jlSeenF[$fk] = 1
        $lines = @(Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue)
        $n = 0
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $ln = [string]$lines[$i]
            if ($ln -notmatch '(?i)-jar\s') { continue }
            $tm = $null
            for ($j = $i; $j -lt [Math]::Min($lines.Count, $i + 5); $j++) {
                $tmm = [regex]::Match([string]$lines[$j], '\[(\d{4}/\d{2}/\d{2}\s+\d{2}:\d{2}:\d{2})')
                if ($tmm.Success) {
                    try { $tm = [datetime]::ParseExact(($tmm.Groups[1].Value -replace '\s+', ' '), 'yyyy/MM/dd HH:mm:ss', [Globalization.CultureInfo]::InvariantCulture) } catch {}
                    break
                }
            }
            foreach ($m in [regex]::Matches($ln, '(?i)-jar\s+(?:"([^"]+)"|([^\s")]+))')) {
                $a = $m.Groups[1].Value
                if (-not $a) { $a = $m.Groups[2].Value }
                if (-not $a) { continue }
                $dk = $a.ToLower() + '|' + [string]$tm
                if ($jlSeenK.ContainsKey($dk)) { continue }
                $jlSeenK[$dk] = 1
                $n++
                $jlTotal++
                Eval-JarArg $a 'JavaLauncher.log (-jar)' $tm ('log dosyasi: ' + $f.FullName)
            }
        }
        Log ('   ' + $f.FullName + ' : ' + $n + ' adet -jar kaydi (son degisim: ' + (Fmt $f.LastWriteTime) + ')') 'DarkGray'
    }
}
if ($jlSeenF.Count -eq 0) { Log '   JavaLauncher.log bulunamadi (bu dosya her bilgisayarda olmayabilir).' 'DarkGray' }
Show-Section

# =====================================================================
Step '[14+/17] C) Bellek: DcomLaunch (-jar), explorer (.jar), conhost (-jar) taramasi (System Informer mantigi)...'
Start-Sec
if (-not $script:HkOk) {
    Log '   yardimci modul derlenemedi, bellek taramasi atlandi.' 'DarkYellow'; Add-Cov 'Bellek tarama motoru derlenemedi: bellek taramasi YAPILMADI' ''
} else {
    try { [void][HkNative]::EnableDebug() } catch {}
    $dcom = Get-CimInstance Win32_Service -Filter "Name='DcomLaunch'"
    if ($dcom -and $dcom.ProcessId -gt 0) { Scan-MemJar 'DcomLaunch' ([int]$dcom.ProcessId) '-jar' $false }
    foreach ($gp in @(Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Scan-MemJar 'explorer' $gp.Id '\.jar' $true }
    foreach ($gp in @(Get-Process -Name conhost -ErrorAction SilentlyContinue | Select-Object -First 12)) { Scan-MemJar 'conhost' $gp.Id '-jar' $false }
}
Show-Section

# =====================================================================
Step '[14+/17] D) PowerShell: komut gecmisi, olay gunlukleri (400/403/600/800/4104), profil scriptleri...'
Start-Sec
$psSeen = @{}
foreach ($ud in $script:HkUserDirs) {
    $hd = Join-Path $ud.FullName 'AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine'
    $hp = Join-Path $hd 'ConsoleHost_history.txt'
    $isMe = ($ud.FullName -ieq $env:USERPROFILE)
    if (-not (Test-Path -LiteralPath $hp)) {
        if ($isMe) { Add-Sys 'PowerShell komut gecmisi dosyasi (ConsoleHost_history.txt) YOK' 20 'Hic PowerShell kullanilmamis olabilir; ama silinmis de olabilir (asagidaki USN kontrolune bak).' }
        continue
    }
    $hf = Get-Item -LiteralPath $hp -Force
    if ($hf.Length -eq 0) { Add-Sys ('PowerShell komut gecmisi BOS (' + $ud.Name + ')') 30 'ConsoleHost_history.txt var ama icerigi bos; icerigi silinmis olabilir.' $null ('boyut=0') $hf.LastWriteTime }
    if ($hf.Attributes -band [IO.FileAttributes]::ReadOnly) { Add-Sys ('PowerShell gecmis dosyasi SALT OKUNUR (' + $ud.Name + ')') 40 'Dosya salt okunur yapilarak PSReadLine yeni komut yazamaz hale getirilmis olabilir.' $null $hp $hf.LastWriteTime }
    foreach ($hx in @(Get-ChildItem -LiteralPath $hd -Filter '*_history.txt' -File -Force -ErrorAction SilentlyContinue)) {
        foreach ($ln in @(Get-Content -LiteralPath $hx.FullName -ErrorAction SilentlyContinue)) {
            $l = [string]$ln
            if ([string]::IsNullOrWhiteSpace($l)) { continue }
            if ($l -match $script:OwnMarkers) { continue }
            $k = $l.Trim().ToLower()
            if ($psSeen.ContainsKey($k)) { continue }
            $psSeen[$k] = 1
            Analyze-PsText $l ('PowerShell gecmisi (' + $ud.Name + ')') $hx.LastWriteTime $false
        }
    }
}
try {
    $o = Get-PSReadLineOption -ErrorAction Stop
    if ([string]$o.HistorySaveStyle -eq 'SaveNothing') { Add-Sys 'PSReadLine gecmis kaydi KAPALI (SaveNothing)' 45 'Komut gecmisi hic kaydedilmiyor; iz birakmamak icin ayarlanmis olabilir.' }
} catch {}

# Olay gunlugu acik mi / cok mu kucuk
foreach ($lname in @('Windows PowerShell', 'Microsoft-Windows-PowerShell/Operational')) {
    try {
        $lg = Get-WinEvent -ListLog $lname -ErrorAction Stop
        if (-not $lg.IsEnabled) { Add-Sys ('PowerShell olay gunlugu KAPALI: ' + $lname) 50 'Olay Goruntuleyicisinde bu gunluk kapatilmis; PowerShell calistirma izi tutulmuyor (bypass girisimi sayilir).' }
        elseif ($lg.MaximumSizeInBytes -lt 1048576) { Add-Sys ('PowerShell olay gunlugu cok kucuk: ' + $lname) 20 'Gunluk boyutu 1 MB altinda; eski kayitlar hemen uzerine yazilir.' $null ('MaxSize=' + $lg.MaximumSizeInBytes) }
    } catch {}
}
# Windows PowerShell (klasik) gunlugu: 400 / 600 = oturum acildi (HostApplication = tam komut satiri)
$ev400 = @()
try { $ev400 = @(Get-WinEvent -FilterHashtable @{ LogName = 'Windows PowerShell'; Id = 400, 403, 600 } -MaxEvents 600 -ErrorAction Stop) } catch {}
$evSeen = @{}
foreach ($e in $ev400) {
    $msg = [string]$e.Message
    if ($msg -match $script:OwnMarkers) { continue }
    $hm = [regex]::Match($msg, '(?im)HostApplication=(.+)$')
    if (-not $hm.Success) { continue }
    $ha = $hm.Groups[1].Value.Trim()
    $k = $ha.ToLower()
    if ($evSeen.ContainsKey($k)) { continue }
    $evSeen[$k] = 1
    Analyze-PsText $ha 'PowerShell olay gunlugu (400/600 HostApplication)' $e.TimeCreated $true
}
# 800 = pipeline calistirma ayrintilari (CommandLine)
try {
    foreach ($e in @(Get-WinEvent -FilterHashtable @{ LogName = 'Windows PowerShell'; Id = 800 } -MaxEvents 300 -ErrorAction Stop)) {
        $msg = [string]$e.Message
        if ($msg -match $script:OwnMarkers) { continue }
        if ($msg.Length -gt 3000) { $msg = $msg.Substring(0, 3000) }
        $k = $msg.Substring(0, [Math]::Min(200, $msg.Length)).ToLower()
        if ($evSeen.ContainsKey($k)) { continue }
        $evSeen[$k] = 1
        Analyze-PsText $msg 'PowerShell olay gunlugu (800)' $e.TimeCreated $false
    }
} catch {}
# 4104 = script blogu (Operational)
try {
    foreach ($e in @(Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-PowerShell/Operational'; Id = 4104 } -MaxEvents 400 -ErrorAction Stop | Where-Object { $_.ProcessId -ne $PID })) {
        $msg = [string]$e.Message
        if ($msg -match $script:OwnMarkers) { continue }
        if ($msg.Length -gt 6000) { $msg = $msg.Substring(0, 6000) }
        $k = $msg.Substring(0, [Math]::Min(200, $msg.Length)).ToLower()
        if ($evSeen.ContainsKey($k)) { continue }
        $evSeen[$k] = 1
        Analyze-PsText $msg 'PowerShell olay gunlugu (4104 script blogu)' $e.TimeCreated $false
    }
} catch {}
# powershell.exe Prefetch'te calismis ama olay gunlugunde karsiligi yok mu
$psPf = @($pfFiles | Where-Object { $_.Name -match '(?i)^POWERSHELL\.EXE-' } | Select-Object -First 1)
if ($psPf.Count -gt 0 -and $ev400.Count -gt 0) {
    $pinfo = Read-Prefetch $psPf[0].FullName
    $oldestEv = $ev400[$ev400.Count - 1].TimeCreated
    $un = 0
    $tot = 0
    foreach ($rt in @($pinfo.Runs | Sort-Object -Descending | Select-Object -First 8)) {
        if ($rt -lt $oldestEv) { continue }
        $tot++
        $mt = @($ev400 | Where-Object { [Math]::Abs(($_.TimeCreated - $rt).TotalSeconds) -le 120 })
        if ($mt.Count -eq 0) { $un++ }
    }
    if ($un -ge 2 -and $un -ge ($tot / 2)) {
        Add-Sys ('powershell.exe ' + $un + '/' + $tot + ' kez calistirilmis ama olay gunlugunde karsiligi yok') 40 'Prefetch calisma saatleriyle Windows PowerShell gunlugu (400/600) eslesmiyor; gunluk kapatilmis, temizlenmis veya kayit engellenmis olabilir.'
    }
}
# Profil scriptleri (her PowerShell acilisinda calisir)
$profFiles = New-Object System.Collections.Generic.List[string]
try { foreach ($pp in @($PROFILE.AllUsersAllHosts, $PROFILE.AllUsersCurrentHost, $PROFILE.CurrentUserAllHosts, $PROFILE.CurrentUserCurrentHost)) { if ($pp) { [void]$profFiles.Add([string]$pp) } } } catch {}
foreach ($ud in $script:HkUserDirs) {
    foreach ($rel in @('Documents\WindowsPowerShell\profile.ps1', 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1', 'Documents\PowerShell\profile.ps1', 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1')) { [void]$profFiles.Add((Join-Path $ud.FullName $rel)) }
}
$profSeen = @{}
foreach ($pf2 in $profFiles) {
    $pk = $pf2.ToLower()
    if ($profSeen.ContainsKey($pk)) { continue }
    $profSeen[$pk] = 1
    if (-not (Test-Path -LiteralPath $pf2)) { continue }
    $pitem = Get-Item -LiteralPath $pf2 -Force
    $ptxt = ''
    try { $ptxt = [IO.File]::ReadAllText($pf2) } catch {}
    if ($ptxt.Length -gt 100000) { $ptxt = $ptxt.Substring(0, 100000); Add-Cov 'PowerShell profil scripti 100000 karakterde kesildi' $pf2 }
    if ($ptxt) {
        Analyze-PsText $ptxt 'PowerShell profil scripti' $pitem.LastWriteTime $true
        Add-Sys ('PowerShell profil scripti var: ' + $pf2) 12 'Bu script her PowerShell acilisinda otomatik calisir; icerigi elle kontrol et.' $null $null $pitem.LastWriteTime
    }
}
Show-Section

# =====================================================================
Step '[14+/17] E) USN: ConsoleHost_history.txt ve JavaLauncher.log silinme kayitlari...'
Start-Sec
$usnHit = 0
foreach ($dl in $script:FixedNtfs) {
    & fsutil usn queryjournal $dl 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { continue }
    Log ('   USN gunlugu taraniyor: ' + $dl) 'DarkGray'
    $rows = @(Read-UsnPattern $dl @('ConsoleHost_history', 'JavaLauncher'))
    foreach ($grp in @('ConsoleHost_history', 'JavaLauncher')) {
        $dels = @($rows | Where-Object { $_.Silme -and $_.Ad -and ($_.Ad -match $grp) } | Sort-Object Zaman -Descending)
        if ($dels.Count -gt 0) {
            $usnHit++
            $skor = 35
            $baslik = 'JavaLauncher.log'
            $acik = 'Bu log (java -jar kayitlari) silinmis; Java bazen kendisi de yeniler, ama zamanina bak.'
            if ($grp -eq 'ConsoleHost_history') {
                $skor = 40
                $baslik = 'PowerShell komut gecmisi (ConsoleHost_history.txt)'
                $acik = 'PowerShell komut gecmisi dosyasi silinmis (USN gunlugu); iz temizleme girisimi olabilir.'
            }
            Add-Sys ($baslik + ' SILINMIS (' + $dl + ', ' + $dels.Count + ' silme kaydi)') $skor $acik $dels[0].Zaman ('en son silinme: ' + (Fmt $dels[0].Zaman))
        }
    }
}
if ($usnHit -eq 0) { Log '   USN gunlugunde ilgili silme kaydi bulunamadi.' 'DarkGray' }
Show-Section

# =====================================================================
Step '[14+/17] F) ENB / ReShade ve proxy dll (d3d9/d3d10/d3d11/dxgi/opengl32...) + grafik modu loglari...'
Start-Sec
$pdRoots = New-Object System.Collections.Generic.List[string]
function Add-PdRoot([string]$r) {
    if ([string]::IsNullOrWhiteSpace($r)) { return }
    if (-not (Test-Path -LiteralPath $r)) { return }
    foreach ($e in $pdRoots) { if ($e -ieq $r) { return } }
    [void]$pdRoots.Add($r)
}
foreach ($g in $script:GameDirs) { Add-PdRoot $g }
foreach ($r in $script:ScanRoots) { Add-PdRoot $r }
Add-PdRoot ($env:APPDATA + '\.minecraft')
Add-PdRoot ($env:USERPROFILE + '\.minecraft')
foreach ($pr in $procs) {
    if ($pr.Name -match '(?i)^javaw?\.exe$' -and $pr.ExecutablePath) {
        try { Add-PdRoot (Split-Path -Parent $pr.ExecutablePath) } catch {}
    }
}
foreach ($jb in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
    if (-not $jb) { continue }
    foreach ($jn in @('Java', 'Eclipse Adoptium', 'Zulu', 'Microsoft', 'AdoptOpenJDK', 'BellSoft', 'Amazon Corretto', 'Minecraft Launcher')) { Add-PdRoot (Join-Path $jb $jn) }
}
$pdHeavy = '(?i)\\(node_modules|Cache|Code Cache|GPUCache|CacheStorage|Service Worker|IndexedDB|\.git|assets)(\\|$)'
$pdSeen = @{}
$pdCount = 0
$pdRI = 0
foreach ($root in $pdRoots) {
    $pdRI++
    Set-Frac (0.6 * $pdRI / [Math]::Max(1, $pdRoots.Count)) ('proxy dll klasor ' + $pdRI + '/' + $pdRoots.Count)
    Log ('   proxy dll taraniyor (' + $pdRI + '/' + $pdRoots.Count + '): ' + $root) 'DarkGray'
    foreach ($d in @(Get-ChildItem -LiteralPath $root -Recurse -Depth 8 -File -Force -Filter '*.dll' -ErrorAction SilentlyContinue)) {
        if ($d.Name -notmatch $script:ProxyDllRx) { continue }
        if ($d.FullName -match $pdHeavy) { continue }
        $dk = $d.FullName.ToLower()
        if ($pdSeen.ContainsKey($dk)) { continue }
        $pdSeen[$dk] = 1
        $pdCount++
        Eval-ProxyDll $d.FullName 'Proxy dll taramasi (ENB/ReShade/hile)' $d.LastWriteTime ''
    }
}
foreach ($pr in $procs) {
    if ($pr.Name -notmatch '(?i)^javaw?\.exe$') { continue }
    try {
        $gp = Get-Process -Id $pr.ProcessId -ErrorAction Stop
        foreach ($mod in $gp.Modules) {
            if ($mod.ModuleName -notmatch $script:ProxyDllRx) { continue }
            if ($mod.FileName -match '(?i)^[A-Za-z]:\\Windows\\') { continue }
            $dk = $mod.FileName.ToLower()
            if ($pdSeen.ContainsKey($dk)) { continue }
            $pdSeen[$dk] = 1
            $pdCount++
            Eval-ProxyDll $mod.FileName 'Calisan Java: yuklu proxy dll' $pr.CreationDate ('PID ' + $pr.ProcessId + ' icine yuklenmis')
        }
    } catch {}
}
Log ('   ' + $pdCount + ' proxy dll adayi incelendi.') 'DarkGray'

# "Loaded graphics mod" / ReShade / ENB izleri: Minecraft loglari
$gfxRx = '(?i)Loaded graphics mod|reshade|enbseries|enblocal'
$gfxFiles = New-Object System.Collections.Generic.List[object]
$gfxSeen = @{}
foreach ($lf in $script:LogCand) {
    $lk = $lf.FullName.ToLower()
    if (-not $gfxSeen.ContainsKey($lk)) { $gfxSeen[$lk] = 1; [void]$gfxFiles.Add($lf) }
}
$latestCands = New-Object System.Collections.Generic.List[string]
[void]$latestCands.Add($env:APPDATA + '\.minecraft\logs\latest.log')
foreach ($g in $script:GameDirs) { [void]$latestCands.Add($g + '\logs\latest.log') }
foreach ($lc in $latestCands) {
    if (Test-Path -LiteralPath $lc) {
        $lk = $lc.ToLower()
        if (-not $gfxSeen.ContainsKey($lk)) { $gfxSeen[$lk] = 1; [void]$gfxFiles.Add((Get-Item -LiteralPath $lc -Force)) }
    }
}
foreach ($base in @($env:LOCALAPPDATA, $env:APPDATA)) {
    foreach ($mr in @(Get-ChildItem -LiteralPath $base -Directory -Filter 'Minecraft*' -Force -ErrorAction SilentlyContinue)) {
        foreach ($f in @(Get-ChildItem -LiteralPath $mr.FullName -Recurse -Depth 4 -File -Force -Filter '*.log' -ErrorAction SilentlyContinue)) {
            $lk = $f.FullName.ToLower()
            if (-not $gfxSeen.ContainsKey($lk)) { $gfxSeen[$lk] = 1; [void]$gfxFiles.Add($f) }
        }
    }
}
$gfxHit = 0
$gfI = 0
foreach ($lf in @($gfxFiles | Sort-Object LastWriteTime -Descending)) {
    $gfI++
    Set-Frac (0.6 + 0.4 * $gfI / [Math]::Max(1, $gfxFiles.Count)) ('grafik logu ' + $gfI + '/' + $gfxFiles.Count)
    if ($lf.Length -gt 31457280) { Add-Cov 'Grafik logu >30 MB: atlandi' $lf.FullName; continue }
    $txt = Read-LogText $lf.FullName
    if (-not $txt) { continue }
    $mm = [regex]::Match($txt, ($gfxRx + '[^\r\n]{0,160}'))
    if ($mm.Success) {
        $gfxHit++
        Add-F -Kaynak 'Minecraft logu: grafik modu izi' -Ad ('log: ' + $lf.Name.ToLower()) -Yol $lf.FullName -Skor 40 -Son $lf.LastWriteTime -Ilk $lf.CreationTime -Var 'Evet' -Not ('logda grafik modu/ENB/ReShade ifadesi: ' + ($mm.Value -replace '\s+', ' ') + ' | ENB/ReShade mesru olabilir; dll konumunu, imzasini ve SHA256 degerini kontrol et')
    }
}
Log ('   ' + $gfxFiles.Count + ' log dosyasindan ' + $gfxFiles.Count + ' tanesi tarandi, ' + $gfxHit + ' tanesinde grafik modu izi var.') 'DarkGray'
Show-Section
# ===================== EK MODUL SONU =====================

# =====================================================================
Step '[14+/17] G) Dizinlenmis konumlar (Searches\*.search-ms, "Indexed Locations")...'
Start-Sec
$isCount = 0
$isSeen = @{}
foreach ($ud in $script:HkUserDirs) {
    $sdir = Join-Path $ud.FullName 'Searches'
    if (-not (Test-Path -LiteralPath $sdir)) { continue }
    foreach ($sf in @(Get-ChildItem -LiteralPath $sdir -Filter '*.search-ms' -File -Force -ErrorAction SilentlyContinue)) {
        $stxt = ''
        try { $stxt = [IO.File]::ReadAllText($sf.FullName) } catch {}
        if (-not $stxt) { continue }
        try { $stxt = [System.Net.WebUtility]::HtmlDecode($stxt) } catch {}
        foreach ($m in [regex]::Matches($stxt, '[A-Za-z]:\\[^<>"|*?\r\n]{2,240}')) {
            $pth = $m.Value.Trim().TrimEnd('\')
            $lk = $pth.ToLower()
            if ($isSeen.ContainsKey($lk)) { continue }
            $isSeen[$lk] = 1
            $isCount++
            $pi = Get-PiCached $pth
            $zone = Get-Zone $pth
            $sc = 0
            $why = New-Object System.Collections.Generic.List[string]
            $h = Get-NameHit $pth $false
            if ($h) { $sc += 45; [void]$why.Add('dizinlenmis konum yolunda hile ismi: ' + $h.Name) }
            if ($pi.Removed) {
                $sc += 20; [void]$why.Add('cikarilmis/eski surucudeki klasor')
            } elseif (-not $pi.Exists -and ($zone -eq 'user' -or $zone -eq 'temp' -or $zone -eq 'appdata' -or $zone -eq 'shared')) {
                $sc += 25; [void]$why.Add('dizinlenmis klasor artik YOK (silinmis klasor olabilir)')
            }
            if ($sc -ge 20) {
                $var = 'Evet'
                if (-not $pi.Exists) { $var = 'Hayir' }
                $leaf = $pth
                try { $leaf = Split-Path -Leaf $pth } catch {}
                Add-F -Kaynak 'Dizinlenmis konumlar (.search-ms)' -Ad ('dizin: ' + $leaf.ToLower()) -Yol $pth -Skor ([Math]::Min(100, $sc)) -Son $sf.LastWriteTime -Var $var -Not (($why -join '; ') + ' | dosya: ' + $sf.FullName)
            }
        }
    }
}
# Windows Search "Indexed Locations" (Dizin Olusturma Secenekleri): kayit defterindeki tarama kapsami kurallari
function Eval-IdxPath([string]$pth, [string]$src, $when) {
    $pth = $pth.Trim().TrimEnd('\')
    if ($pth.Length -lt 3) { return }
    $lk = $pth.ToLower()
    if ($isSeen.ContainsKey($lk)) { return }
    $isSeen[$lk] = 1
    $script:isCount = $script:isCount + 1
    $pi = Get-PiCached $pth
    $zone = Get-Zone $pth
    $sc = 0
    $why = New-Object System.Collections.Generic.List[string]
    $h = Get-NameHit $pth $false
    if ($h) { $sc += 45; [void]$why.Add('dizinlenmis konum yolunda hile ismi: ' + $h.Name) }
    if ($pi.Removed) {
        $sc += 20; [void]$why.Add('cikarilmis/eski surucudeki klasor')
    } elseif (-not $pi.Exists -and ($zone -eq 'user' -or $zone -eq 'temp' -or $zone -eq 'appdata' -or $zone -eq 'shared')) {
        $sc += 25; [void]$why.Add('dizinlenmis klasor artik YOK (silinmis klasor olabilir)')
    }
    if ($sc -ge 20) {
        $var = 'Evet'
        if (-not $pi.Exists) { $var = 'Hayir' }
        $leaf = $pth
        try { $leaf = Split-Path -Leaf $pth } catch {}
        Add-F -Kaynak 'Dizinlenmis konumlar (Windows Search)' -Ad ('dizin: ' + $leaf.ToLower()) -Yol $pth -Skor ([Math]::Min(100, $sc)) -Son $when -Var $var -Not (($why -join '; ') + ' | kaynak: ' + $src)
    }
}
$idxKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows Search\CrawlScopeManager\Windows\SystemIndex\WorkingSetRules',
    'HKLM:\SOFTWARE\Microsoft\Windows Search\CrawlScopeManager\Windows\SystemIndex\DefaultRules',
    'HKLM:\SOFTWARE\Microsoft\Windows Search\Gather\Windows\SystemIndex\Sites\LocalHost\Paths',
    'HKCU:\Software\Microsoft\Windows Search\CrawlScopeManager\Windows\SystemIndex\WorkingSetRules'
)
$idxRegN = 0
foreach ($ik in $idxKeys) {
    foreach ($sk in @(Get-ChildItem -LiteralPath $ik -ErrorAction SilentlyContinue)) {
        $url = ''
        try { $url = [string]$sk.GetValue('URL') } catch {}
        if (-not $url) { continue }
        if ($url -notmatch '(?i)^file:///') { continue }
        $p2 = ($url -replace '(?i)^file:///', '') -replace '/', '\'
        $p2 = $p2 -replace '\\\*$', ''
        if ($p2 -notmatch '^[A-Za-z]:') { continue }
        $idxRegN++
        $kt = $null
        try { $kt = Get-KeyTime $sk } catch {}
        Eval-IdxPath $p2 ('kayit defteri: ' + $ik) $kt
    }
}
Log ('   kayit defterinden ' + $idxRegN + ' dizin kapsami kurali okundu.') 'DarkGray'
Log ('   ' + $isCount + ' dizinlenmis konum incelendi.') 'DarkGray'
Show-Section

# =====================================================================
Step '[14+/17] H) Process modulleri (System Informer > Modules mantigi): sistem DLL taklidi, AppData/Temp DLL...'
Start-Sec
$sysDll = @{}
foreach ($sdp in @(($env:WINDIR + '\System32'), ($env:WINDIR + '\SysWOW64'))) {
    foreach ($nm in @(Get-ChildItem -LiteralPath $sdp -Filter '*.dll' -File -Force -Name -ErrorAction SilentlyContinue)) { $sysDll[([string]$nm).ToLower()] = 1 }
}
$knownNat = '(?i)^(lwjgl|glfw|openal|jemalloc|stb|tinyfd|nanovg|nfd|jna|sqlite|libusb|vcruntime|msvcp|concrt|ucrtbase|api-ms)'
$modSeen = @{}
$modProcCnt = 0
foreach ($pr in $procs) {
    $pn = [string]$pr.Name
    if (-not $pn -or $pr.ProcessId -le 4 -or $pr.ProcessId -eq $PID) { continue }
    $isJavaP = ($pn -match '(?i)^javaw?\.exe$')
    $isExpl = ($pn -ieq 'explorer.exe')
    $gp = $null
    try { $gp = Get-Process -Id $pr.ProcessId -ErrorAction Stop } catch { continue }
    $mods = $null
    if ($null -eq $script:HkModCache) { $script:HkModCache = @{} }
    try { $mods = @($gp.Modules) } catch { continue }
    $script:HkModCache[[int]$gp.Id] = $mods
    $modProcCnt++
    foreach ($mod in $mods) {
        $mp = [string]$mod.FileName
        if (-not $mp -or $mp -notmatch '^[A-Za-z]:\\') { continue }
        if (Test-SysPathOk $mp) { continue }
        $mk = $mp.ToLower()
        if ($modSeen.ContainsKey($mk)) { continue }
        $modSeen[$mk] = 1
        $mn = ([string]$mod.ModuleName).ToLower()
        if ($mn -notmatch '\.(dll|ocx|drv)$') { continue }
        $sc = 0
        $why = New-Object System.Collections.Generic.List[string]
        if ($sysDll.ContainsKey($mn)) {
            $sdSc = 70; if (Test-Signed $mp) { $sdSc = 20 }
            $sc += $sdSc; [void]$why.Add('sistem DLL ismi (System32 icinde de var) ama baska klasorden yuklenmis')
        } else {
            $norm = (($mn -replace '1', 'l') -replace '0', 'o') -replace 'rn', 'm'
            if ($norm -ne $mn -and $sysDll.ContainsKey($norm)) { $sc += 60; [void]$why.Add('sistem DLL ismine benziyor (' + $norm + ')') }
        }
        $hit = Get-NameHit $mn $false
        if ($hit) { $sc += 50; [void]$why.Add('isim eslesmesi: ' + $hit.Name) }
        if ($isJavaP -or $isExpl) {
            $zone = Get-Zone $mp
            $isNat = ($mn -match $knownNat) -and ($mp -match '(?i)\\(lwjgl|\.minecraft|natives|ModrinthApp|PrismLauncher|\.lunarclient|Temp)\\')
            $launcherDir = ($mp -match '(?i)\\(\.minecraft|\.lunarclient|ModrinthApp|PrismLauncher|\.tlauncher|\.feather|\.ichor)\\|\\(runtime|jre|jdk|java)[^\\]*\\')
            if (($zone -eq 'appdata' -or $zone -eq 'temp' -or $zone -eq 'shared' -or $zone -eq 'user') -and -not $isNat -and -not $launcherDir) {
                if (-not (Test-Signed $mp)) { $sc += 40; [void]$why.Add('IMZASIZ DLL, ' + $zone + ' klasorunden yuklenmis') }
            } elseif ($zone -eq 'other' -and $isJavaP -and -not $launcherDir -and -not (Test-Signed $mp)) {
                $sc += 25; [void]$why.Add('Java icine olagan disi klasorden imzasiz DLL yuklenmis')
            }
        }
        if ($sc -ge 30) {
            $mdir = ''
            try { $mdir = Split-Path -Parent $mp } catch {}
            Add-F -Kaynak ('Process modulleri: ' + $pn) -Ad $mn -Yol $mp -Skor ([Math]::Min(100, $sc)) -Son $pr.CreationDate -Var 'Evet' -Not (($why -join '; ') + ' | process: ' + $pn + ' (PID ' + $pr.ProcessId + ') | DLL klasoru: ' + $mdir)
        }
    }
}
Log ('   ' + $modProcCnt + ' process modul listesi incelendi (korumali process ler atlanir).') 'DarkGray'
Show-Section
# ===================== EK MODUL 2 SONU =====================

# ---------------------------------------------------------------------
# =====================================================================
# BYPASS GECMISI MODULU: gecmiste yapilmis iz silme/bypass islemlerinin kalintilarini arar
# (Sadece OKUR; hicbir seyi silmez/degistirmez.)
# =====================================================================
Step '[14+/17] I) BYPASS GECMISI: olay zaman cizelgesi, USN/olay gunlugu temizleme, saat degisikligi, kutu bosaltma, toplu Prefetch silme, BAM karsilastirma...'
Start-Sec
function Add-Bt([string]$tur, $zaman) {
    if ($zaman) { [void]$script:Bt.Add([pscustomobject]@{ Tur = $tur; Zaman = [datetime]$zaman }) }
}
function Test-UsnBasicInfo([string]$ln) {
    if ($ln -match '(?i)basic info change') { return $true }
    foreach ($mm in [regex]::Matches($ln, '0x[0-9A-Fa-f]{8}(?![0-9A-Fa-f])')) {
        $val = [Convert]::ToUInt32($mm.Value.Substring(2), 16)
        if (($val -band 0x8000) -ne 0) { return $true }
    }
    return $false
}
# Prefetch (.pf) ile ilgili USN satirlarini okur: silme / nitelik-zaman degisikligi
function Read-UsnPfLines([string]$dl) {
    $res = New-Object System.Collections.Generic.List[object]
    $lines = @(Select-UsnLines $dl @('.pf'))
    foreach ($ln in $lines) {
        $nm = Get-UsnName $ln
        if (-not $nm) { continue }
        if ($nm -notmatch '(?i)\.pf$') { continue }
        [void]$res.Add([pscustomobject]@{ Ad = $nm; Zaman = (Get-UsnTime $ln); Info = (Test-UsnBasicInfo $ln); Silme = (Test-UsnDelete $ln) })
    }
    return $res
}

$tl = New-Object System.Collections.Generic.List[string]
$osInstall = $null
try { $osInstall = [datetime](Get-CimInstance Win32_OperatingSystem).InstallDate } catch {}

# --- 1) USN gunlugu: olusturulma zamani (Journal ID = olusturulma zamani). Windows kurulumundan sonra yeniden olusturulduysa silinip acilmis olabilir ---
foreach ($dl in $script:FixedNtfs) {
    $qo = ''
    try { $qo = (& fsutil usn queryjournal $dl 2>&1 | Out-String) } catch {}
    $jm = [regex]::Match($qo, '0x([0-9A-Fa-f]{16})')
    if (-not $jm.Success) { continue }
    $jt = $null
    try { $jt = Hk-Ft ([Convert]::ToInt64($jm.Groups[1].Value, 16)) } catch {}
    if (-not $jt) { continue }
    [void]$tl.Add('USN Journal olusturulma zamani (' + $dl + '): ' + (Fmt $jt))
    if ($osInstall -and $jt -gt $osInstall.AddDays(3)) {
        $sk = 35
        if ($jt -gt (Get-Date).AddDays(-30)) { $sk = 50 }
        Add-Sys ('USN gunlugu Windows kurulumundan SONRA yeniden olusturulmus (' + $dl + ')') $sk 'USN gunlugu silinip (fsutil usn deletejournal) yeniden acilmis olabilir. Sonradan bicimlendirilen ikincil suruculerde bu normaldir; C: icin supheli.' $jt ('journal olusturulma: ' + (Fmt $jt) + ' | Windows kurulum: ' + (Fmt $osInstall)) $null
        Add-Bt 'USN gunlugu sifirlandi' $jt
    }
}

# --- 2) Olay gunlugu temizleme zamanlari (Security 1102 / System 104) ---
foreach ($spec in @(@('Security', 1102), @('System', 104))) {
    try {
        $ce = @(Get-WinEvent -FilterHashtable @{ LogName = $spec[0]; Id = $spec[1] } -MaxEvents 1 -ErrorAction SilentlyContinue)
        if ($ce.Count -gt 0) {
            [void]$tl.Add('Olay gunlugu TEMIZLENMIS (' + $spec[0] + ' / olay ' + $spec[1] + '): ' + (Fmt $ce[0].TimeCreated))
            Add-Bt 'Olay gunlugu temizlendi' $ce[0].TimeCreated
        }
    } catch {}
}

# --- 3) Son kapanis (6006) ve Event Log servisi son baslama (6005) ---
try {
    $e6 = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'EventLog'; Id = 6006 } -MaxEvents 1 -ErrorAction SilentlyContinue)
    if ($e6.Count -gt 0) { [void]$tl.Add('Son temiz kapanis (6006): ' + (Fmt $e6[0].TimeCreated)) }
} catch {}
try {
    $e5 = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'EventLog'; Id = 6005 } -MaxEvents 1 -ErrorAction SilentlyContinue)
    if ($e5.Count -gt 0) { [void]$tl.Add('Event Log servisi son baslama (6005): ' + (Fmt $e5[0].TimeCreated)) }
} catch {}

# --- 4) Event Log servisi bilgisayar yeniden baslamadan durdurulup baslatilmis mi (6006 -> 6005 cifti, yaninda OS kapanis/acilis olayi yok) ---
try {
    $el = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'EventLog'; Id = 6005, 6006 } -MaxEvents 80 -ErrorAction Stop)
    $kg = @()
    try { $kg = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-Kernel-General'; Id = 12, 13 } -MaxEvents 200 -ErrorAction Stop) } catch {}
    if ($kg.Count -gt 0) {
        $kgOldest = ($kg | Sort-Object TimeCreated | Select-Object -First 1).TimeCreated
        $restarts = New-Object System.Collections.Generic.List[object]
        foreach ($st in @($el | Where-Object { $_.Id -eq 6006 })) {
            if ($st.TimeCreated -lt $kgOldest) { continue }
            $nx = @($el | Where-Object { $_.Id -eq 6005 -and $_.TimeCreated -gt $st.TimeCreated -and $_.TimeCreated -lt $st.TimeCreated.AddMinutes(10) } | Sort-Object TimeCreated | Select-Object -First 1)
            if ($nx.Count -eq 0) { continue }
            $stT = $st.TimeCreated
            $nxT = $nx[0].TimeCreated
            $near = @($kg | Where-Object { ([Math]::Abs(($_.TimeCreated - $stT).TotalMinutes) -le 3) -or ([Math]::Abs(($_.TimeCreated - $nxT).TotalMinutes) -le 3) })
            if ($near.Count -eq 0) { [void]$restarts.Add($st) }
        }
        if ($restarts.Count -gt 0) {
            $rt = $restarts[0].TimeCreated
            Add-Sys ('Event Log servisi bilgisayar yeniden baslamadan durdurulup baslatilmis (' + $restarts.Count + ' kez)') 55 'EventLog servisi durdu (6006) ve hemen tekrar basladi (6005) ama Windows kapanis/acilis olayi yok; servis elle durdurularak olay kaydi atlatilmis olabilir (bypass yontemi).' $rt ('en son: ' + (Fmt $rt)) $null
            Add-Bt 'Event Log servisi elle yeniden baslatildi' $rt
            [void]$tl.Add('Event Log servisi ELLE yeniden baslatilmis: ' + (Fmt $rt))
        }
    }
} catch {}

# --- 5) Sistem saati degistirilmis mi (Kernel-General olay 1) ---
try {
    $tc = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-Kernel-General'; Id = 1 } -MaxEvents 80 -ErrorAction Stop)
    if ($tc.Count -gt 0) { [void]$tl.Add('Sistem saati en son degisme olayi: ' + (Fmt $tc[0].TimeCreated)) }
    $bigN = 0
    foreach ($e in $tc) {
        $nt = $null
        $ot = $null
        try { $nt = [datetime]$e.Properties[0].Value; $ot = [datetime]$e.Properties[1].Value } catch {}
        if (-not $nt -or -not $ot) { continue }
        $df = [Math]::Abs(($nt - $ot).TotalSeconds)
        if ($df -le 120) { continue }
        $bigN++
        Add-Bt 'Sistem saati degistirildi' $e.TimeCreated
        if ($bigN -le 3) {
            $sk = 40
            if ($df -gt 3600) { $sk = 50 }
            Add-Sys ('Sistem saati ' + [Math]::Round($df / 60, 1) + ' dakika oynatilmis') $sk 'Saat degisikligi kayitlardaki zamanlari karistirmak/iz saklamak icin kullanilabilir (kucuk NTP duzeltmeleri filtrelendi, sadece 2 dakikadan buyukler gosterilir).' $e.TimeCreated ('eski: ' + (Fmt $ot) + ' -> yeni: ' + (Fmt $nt)) $null
        }
    }
} catch {}

# --- 6) Geri donusum kutusu yakin zamanda bosaltilmis gorunuyor mu ---
foreach ($dl in $script:Drives) {
    $bin = $dl + '\$Recycle.Bin'
    if (-not (Test-Path -LiteralPath $bin)) { continue }
    foreach ($sd in @(Get-ChildItem -LiteralPath $bin -Force -Directory -ErrorAction SilentlyContinue)) {
        $bitems = @(Get-ChildItem -LiteralPath $sd.FullName -Force -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' })
        if ($bitems.Count -eq 0 -and $sd.LastWriteTime -gt (Get-Date).AddDays(-30)) {
            [void]$tl.Add('Geri donusum kutusu BOS, son degisiklik (' + $dl + '): ' + (Fmt $sd.LastWriteTime))
            Add-Sys ('Geri donusum kutusu yakin zamanda bosaltilmis gorunuyor (' + $dl + ')') 20 'Kutu su an bos ve klasorunun son degisim zamani son 30 gun icinde. Tek basina supheli degildir; bu zamani diger bypass olaylariyla karsilastir.' $sd.LastWriteTime ($sd.Name) $null
            Add-Bt 'Geri donusum kutusu bosaltildi' $sd.LastWriteTime
        }
    }
}
foreach ($kv in $script:BinEmptied.GetEnumerator()) {
    if ($kv.Value -gt (Get-Date).AddDays(-30)) { Add-Bt 'Geri donusum kutusu bosaltildi' $kv.Value }
}

# --- 7) Toplu Prefetch silme (kisa surede cok sayida .pf silinmesi) ---
$pfDelT = @($script:DeletedPf | Where-Object { $_.Zaman } | Sort-Object Zaman)
$bestN = 0
$bestT = $null
for ($i = 0; $i -lt $pfDelT.Count; $i++) {
    $n = 1
    for ($j = $i + 1; $j -lt $pfDelT.Count; $j++) {
        if ((([datetime]$pfDelT[$j].Zaman) - ([datetime]$pfDelT[$i].Zaman)).TotalMinutes -le 5) { $n++ } else { break }
    }
    if ($n -gt $bestN) { $bestN = $n; $bestT = [datetime]$pfDelT[$i].Zaman }
}
if ($bestN -ge 15) {
    Add-Sys ('Toplu Prefetch silme: 5 dakika icinde ' + $bestN + ' adet .pf silinmis') 55 'Prefetch klasoru toplu temizlenmis olabilir (Windows 1024 dosya sinirini asinca eskileri kendisi de silebilir, ama bu kadar yogun silme supheli).' $bestT ('baslangic: ' + (Fmt $bestT)) $null
    Add-Bt 'Prefetch toplu silindi' $bestT
    $nearRuns = @($script:Runs | Where-Object { (Get-Zone $_.Yol) -ne 'system' -and ([Math]::Abs((([datetime]$_.Zaman) - $bestT).TotalMinutes) -le 10) } | Sort-Object { [Math]::Abs((([datetime]$_.Zaman) - $bestT).TotalSeconds) } | Select-Object -First 20)
    [void]$tl.Add('Toplu Prefetch silme zamani (' + (Fmt $bestT) + ') +-10 dk cevresinde calisan sistem disi programlar (BAM/UserAssist/Prefetch kayitlari):')
    foreach ($nr in $nearRuns) { [void]$tl.Add('      ' + (Fmt $nr.Zaman) + '  ' + $nr.Yol + '  (' + $nr.Kaynak + ')') }
    if ($nearRuns.Count -eq 0) { [void]$tl.Add('      kayit yok (ilgili Prefetch/BAM/UserAssist kayitlari silinmis olabilir)') }
    [void]$tl.Add('Prefetch toplu silme (' + $bestN + ' dosya): ' + (Fmt $bestT))
}

# --- 8) Prefetch dosyalarinda nitelik/zaman degisikligi izi (USN BASIC_INFO_CHANGE = Salt Okunur/Gizli yapma izi) ---
$sysDrv = [string]$env:SystemDrive
if ($sysDrv -and ($script:FixedNtfs -contains $sysDrv.ToUpper())) {
    Log ('   Prefetch USN izleri okunuyor: ' + $sysDrv.ToUpper() + ' (biraz surebilir)...') 'DarkGray'
    $pfRows = @(Read-UsnPfLines $sysDrv.ToUpper())
    $infoRows = @($pfRows | Where-Object { $_.Info -and -not $_.Silme } | Sort-Object Zaman -Descending)
    if ($infoRows.Count -gt 0) {
        $iNames = (($infoRows | Select-Object -First 5 | ForEach-Object { $_.Ad + ' (' + (Fmt $_.Zaman) + ')' }) -join '; ')
        Add-Sys ('Prefetch dosyalarinda nitelik/zaman degisikligi izi (USN) - ' + $infoRows.Count + ' kayit') 30 'USN gunlugunde .pf dosyalari icin "basic info change" kaydi var: Salt Okunur/Gizli yapilmis veya zamani oynanmis olabilir. Tek basina kesin degil; asagidaki nitelik kontroluyle birlikte degerlendir.' $infoRows[0].Zaman $iNames $null
        Add-Bt 'Prefetch niteligi degistirildi' $infoRows[0].Zaman
    }
}

# --- 9) BAM karsilastirma: Prefetch'te son gunlerde calismis ama BAM'de HIC kaydi olmayan programlar (BAM anahtari silinmis olabilir) ---
if ($script:PfExecs.Count -gt 20 -and $bamCount -eq 0) {
    Add-Sys 'BAM kayitlari tamamen BOS' 45 'Prefetch kayitlari var ama BAM (UserSettings) hic kayit icermiyor; BAM anahtarlari silinmis veya bam servisi kapatilmis olabilir.'
} elseif ($bamCount -gt 0) {
    $cut5 = (Get-Date).AddDays(-5)
    $missList = New-Object System.Collections.Generic.List[string]
    foreach ($pe in $script:PfExecs) {
        if (-not $pe.Last -or $pe.Last -lt $cut5) { continue }
        if ($pe.Path -notmatch '^[A-Za-z]:\\') { continue }
        if ((Get-Zone $pe.Path) -eq 'system') { continue }
        $lf = ''
        try { $lf = (Split-Path -Leaf $pe.Path).ToLower() } catch {}
        if (-not $lf -or $lf -notmatch '\.exe$') { continue }
        if ($script:BamLeaves.ContainsKey($lf)) { continue }
        [void]$missList.Add($lf + ' (' + (Fmt $pe.Last) + ')')
        $bh = Get-NameHit $lf $false
        if ($bh) {
            Add-F -Kaynak 'BAM/Prefetch karsilastirma' -Ad $lf -Yol $pe.Path -Skor 60 -Son $pe.Last -Var $(if ($pe.Exists) { 'Evet' } else { 'Hayir' }) -Not ('Prefetch''te son 5 gunde calismis ama BAM''de kaydi YOK, hile ismi: ' + $bh.Name + ' | BAM anahtari silinmis olabilir (BamDeletedKeys araciyla da dogrula)')
        }
    }
    if ($missList.Count -ge 3) {
        Add-Sys ('Prefetch''te var ama BAM''de olmayan ' + $missList.Count + ' program (son 5 gun)') 25 'BAM''den degerler silinmis olabilir. BAM yalnizca kullanici oturumunda calisan programlari tutar; servis olarak calisanlar yanlis alarm uretebilir, listeyi elle incele.' $null (($missList | Select-Object -First 6) -join '; ') $null
    }
}

# --- 10) KOMBINASYON: 24 saat icinde birden fazla farkli bypass turu = klasik bypass paketi ---
$btS = @($script:Bt | Sort-Object Zaman)
$bestCnt = 0
$bestTxt = ''
$bestStart = $null
for ($i = 0; $i -lt $btS.Count; $i++) {
    $set = @{}
    for ($j = $i; $j -lt $btS.Count; $j++) {
        if (($btS[$j].Zaman - $btS[$i].Zaman).TotalHours -le 24) { $set[$btS[$j].Tur] = $btS[$j].Zaman } else { break }
    }
    if ($set.Count -gt $bestCnt) {
        $bestCnt = $set.Count
        $bestStart = $btS[$i].Zaman
        $bestTxt = (($set.GetEnumerator() | Sort-Object Value | ForEach-Object { $_.Key + ' [' + (Fmt $_.Value) + ']' }) -join '; ')
    }
}
if ($bestCnt -ge 3) {
    Add-Sys ('BYPASS KOMBINASYONU: 24 saat icinde ' + $bestCnt + ' farkli iz silme/bypass olayi') 70 'USN sifirlama, olay gunlugu temizleme, saat degisikligi, Prefetch/geri donusum kutusu temizleme gibi olaylarin ayni gun icinde birlikte gorulmesi klasik bir bypass paketine isaret eder.' $bestStart $bestTxt $null
}

Log '' 'Gray'
Log '   --- OLAY ZAMAN CIZELGESI (bu zamanlar birbirine yakinsa bypass suphesi artar) ---' 'Cyan'
foreach ($t in $tl) { Log ('   ' + $t) 'Gray' }
if ($tl.Count -eq 0) { Log '   okunabilen olay yok' 'DarkGray' }
Show-Section

# ---------------------------------------------------------------------
Step '[15/17] Minecraft loglari (hile modulu isimleri, eski loglar dahil)...'
Start-Sec
$mcMain = $env:APPDATA + '\.minecraft'
if (Test-Path -LiteralPath $mcMain) {
    $lg = $mcMain + '\logs'
    $lgFiles = @()
    if (Test-Path -LiteralPath $lg) { $lgFiles = @(Get-ChildItem -LiteralPath $lg -File -Force -ErrorAction SilentlyContinue) }
    if ($lgFiles.Count -eq 0) { Add-Sys '.minecraft\logs klasoru bos/yok' 25 'Oyun loglari silinmis olabilir (normalde her oturumda log olusur).' }
}
$logs = @($script:LogCand | Sort-Object LastWriteTime -Descending)
$logHits = 0
$liN = 0
$logAgg = @{}
Log ('   ' + $logs.Count + ' log dosyasi okunacak...') 'DarkGray'
foreach ($lf in $logs) {
    $liN++
    Set-Frac ($liN / [Math]::Max(1, $logs.Count)) ('log ' + $liN + '/' + $logs.Count)
    if (($liN % 10) -eq 0) { Log ('   ' + $liN + '/' + $logs.Count + ' log okundu (%' + [int]($liN * 100 / [Math]::Max(1, $logs.Count)) + ')') 'DarkGray' }
    $lrSw = [Diagnostics.Stopwatch]::StartNew()
    $txt = Read-LogText $lf.FullName
    $script:LogReadSn = [double]$script:LogReadSn + $lrSw.Elapsed.TotalSeconds
    if ($lrSw.Elapsed.TotalSeconds -gt 1.5) { Add-Perf '15: yavas log okuma' $lrSw.Elapsed.TotalSeconds ($lf.FullName + ' (' + [int]($lf.Length / 1KB) + ' KB)') }
    if (-not $txt) { Add-Cov 'Log okunamadi/bos' $lf.FullName; continue }
    # Sohbet satirlari (oyuncularin yazdigi mesajlar: "doomsday calismiyo" gibi) hile kaniti degildir; taramadan cikar
    $nhSw = [Diagnostics.Stopwatch]::StartNew()
    $hitLines = @(Get-HitLines $txt 3)
    $script:LogScanSn = [double]$script:LogScanSn + $nhSw.Elapsed.TotalSeconds
    if ($hitLines.Count -eq 0) { continue }
    foreach ($line in $hitLines) {
        $h = Get-NameHit $line $false
        if ($h) {
            $ln2 = $line.Trim()
            if ($ln2.Length -gt 170) { $ln2 = $ln2.Substring(0, 170) + '...' }
            $k = [string]$h.Name
            if (-not $logAgg.ContainsKey($k)) {
                $logAgg[$k] = @{ Name = $k; Files = 0; Lines = 0; Last = $lf.LastWriteTime; First = $lf.CreationTime; Path = $lf.FullName; Leaf = $lf.Name.ToLower(); Sample = $ln2; Seen = @{} }
            }
            $ag = $logAgg[$k]
            $ag.Lines++
            if (-not $ag.Seen.ContainsKey($lf.FullName)) { $ag.Seen[$lf.FullName] = $true; $ag.Files++ }
            if ($lf.LastWriteTime -gt $ag.Last) { $ag.Last = $lf.LastWriteTime; $ag.Path = $lf.FullName; $ag.Leaf = $lf.Name.ToLower(); $ag.Sample = $ln2 }
            if ($lf.CreationTime -lt $ag.First) { $ag.First = $lf.CreationTime }
        }
    }
}
Add-Perf '15: log dosyalarini okuma (toplam, gz acma dahil)' ([double]$script:LogReadSn) ([string]$logs.Count + ' dosya')
Add-Perf '15: log metninde hile ismi aramasi (regex)' ([double]$script:LogScanSn) ''
foreach ($ag in $logAgg.Values) {
    $logHits++
    Add-F -Kaynak 'Minecraft logu' -Ad ('log: ' + $ag.Name + ' | ' + $ag.Files + ' log dosyasinda (en yeni: ' + $ag.Leaf + ')') -Yol $ag.Path -Skor 40 -Son $ag.Last -Ilk $ag.First -Var 'Evet' -Not ('satir: ' + $ag.Sample + ' | sohbet satirlari haric tutuldu')
}
Log ('   ' + $logs.Count + ' log dosyasi incelendi.') 'DarkGray'
Show-Section

# ---------------------------------------------------------------------
Step '[16/17] USB depolama gecmisi (harici surucuden calistirma ihtimali)...'
Start-Sec
$setup = @{}
foreach ($sf in @(Get-ChildItem -LiteralPath ($env:WINDIR + '\INF') -Filter 'setupapi.dev*.log' -File -Force -ErrorAction SilentlyContinue | Sort-Object LastWriteTime)) {
    $slines = @(Get-Content -LiteralPath $sf.FullName -ErrorAction SilentlyContinue)
    for ($i = 0; $i -lt ($slines.Count - 1); $i++) {
        if ($slines[$i] -match 'Device Install.*USBSTOR\\(.+?)\]\s*$') {
            $devId = $Matches[1].ToLower()
            if ($slines[$i + 1] -match 'Section start (\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2})') {
                if (-not $setup.ContainsKey($devId)) { $setup[$devId] = $Matches[1] }
            }
        }
    }
}
foreach ($dev in @(Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR' -ErrorAction SilentlyContinue)) {
    foreach ($inst in @(Get-ChildItem $dev.PSPath -ErrorAction SilentlyContinue)) {
        $fn = [string]$inst.GetValue('FriendlyName')
        if (-not $fn) { $fn = $dev.PSChildName }
        $key = ($dev.PSChildName + '\' + $inst.PSChildName).ToLower()
        $first = $null
        if ($setup.ContainsKey($key)) { try { $first = [datetime]::ParseExact($setup[$key], 'yyyy/MM/dd HH:mm:ss', [Globalization.CultureInfo]::InvariantCulture) } catch {} }
        [void]$script:UsbList.Add([pscustomobject]@{ Ad = $fn; Ilk = $first; Son = (Get-KeyTime $inst) })
    }
}
Log ('   ' + $script:UsbList.Count + ' USB depolama cihazi kaydi bulundu.') 'DarkGray'
Show-Section

# ---------------------------------------------------------------------
Step '[17/17] Windows Defender tespit gecmisi (silinmis/karantinaya alinmis dosyalar)...'
Start-Sec
$defCount = 0
try {
    Set-Frac 0 'defender kayitlari aliniyor'
    Log '   Defender kayitlari aliniyor (bu kisim sessiz bekletebilir, normal)...' 'DarkGray'
    $tdAll = @(Get-MpThreatDetection -ErrorAction Stop)
    Log ('   ' + $tdAll.Count + ' Defender kaydi var, inceleniyor...') 'DarkGray'
    $tdI = 0
    $tnCache = @{}
    foreach ($td in $tdAll) {
        $tdI++
        Set-Frac ($tdI / [Math]::Max(1, $tdAll.Count)) ('defender ' + $tdI + '/' + $tdAll.Count)
        if (($tdI % 25) -eq 0) { Log ('   ' + $tdI + '/' + $tdAll.Count + ' kayit (%' + [int]($tdI * 100 / [Math]::Max(1, $tdAll.Count)) + ')') 'DarkGray' }
        $tn = ''
        $tidk = [string]$td.ThreatID
        if ($tnCache.ContainsKey($tidk)) { $tn = $tnCache[$tidk] } else {
            try { $tn = (Get-MpThreat -ThreatID $td.ThreatID -ErrorAction Stop).ThreatName } catch {}
            $tnCache[$tidk] = $tn
        }
        foreach ($res in @($td.Resources)) {
            if ($res -notmatch '^file:_') { continue }
            $rp = $res -replace '^file:_', ''
            $leaf = ''
            try { $leaf = Split-Path -Leaf $rp } catch {}
            if (-not $leaf) { continue }
            $pi = Test-PathInfo $rp
            $dsc = 40
            if ($tn -match '(?i)hacktool|cheat|inject|gamehack|exploit|trojan|backdoor|pua|riskware') { $dsc = 55 }
            $dvar = 'Hayir'
            if ($pi.Exists) { $dvar = 'Evet' }
            Add-F -Kaynak 'Defender tespiti' -Ad $leaf.ToLower() -Yol $rp -Skor $dsc -Son $td.InitialDetectionTime -Ilk $td.InitialDetectionTime -Var $dvar -Not ('Defender tespit etti: ' + $tn)
            $defCount++
        }
    }
} catch {}
Log ('   ' + $defCount + ' Defender kaydi bulundu.') 'DarkGray'
Show-Section

# =====================================================================
# EK MODUL 3: Tarayici indirme gecmisi + kernel suruculeri
# =====================================================================
function Read-DbBytes([string]$p) {
    $r = $null
    try {
        $fs = [IO.File]::Open($p, [IO.FileMode]::Open, [IO.FileAccess]::Read, ([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
        try {
            if ($fs.Length -gt 134217728) { Add-Cov 'Dosya >128 MB: okunmadi (tarayici DB vb.)' $p; return $null }
            $r = New-Object byte[] ([int]$fs.Length)
            $off = 0
            while ($off -lt $r.Length) {
                $n = $fs.Read($r, $off, $r.Length - $off)
                if ($n -le 0) { break }
                $off += $n
            }
        } finally { $fs.Dispose() }
        return ,$r
    } catch {}
    # Tarayici aciksa dosya kilitli olabilir: golge kopya ile okumayi dene
    $r = $null
    $tmp = Join-Path $env:TEMP ('hk_db_' + [guid]::NewGuid().ToString('N') + '.tmp')
    try {
        & esentutl.exe /y /vss $p /d $tmp 2>&1 | Out-Null
        if (Test-Path -LiteralPath $tmp) {
            if ((Get-Item -LiteralPath $tmp).Length -le 134217728) { $r = [IO.File]::ReadAllBytes($tmp) }
        }
    } catch {}
    Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    if ($null -eq $r) { return $null }
    return ,$r
}

Step '[17+/17] J) Tarayici gecmisi: indirilen dosyalar ve ziyaret edilen hile siteleri (Chrome, Edge, Brave, Opera, Firefox)...'
Start-Sec
$brDbs = New-Object System.Collections.Generic.List[object]
$brRoots = @(
    @('Chrome', ($env:LOCALAPPDATA + '\Google\Chrome\User Data')),
    @('Edge', ($env:LOCALAPPDATA + '\Microsoft\Edge\User Data')),
    @('Brave', ($env:LOCALAPPDATA + '\BraveSoftware\Brave-Browser\User Data')),
    @('Opera', ($env:APPDATA + '\Opera Software\Opera Stable')),
    @('Opera GX', ($env:APPDATA + '\Opera Software\Opera GX Stable'))
)
foreach ($br in $brRoots) {
    if (-not (Test-Path -LiteralPath $br[1])) { continue }
    foreach ($h in @(Get-ChildItem -LiteralPath $br[1] -Recurse -Depth 2 -File -Force -Filter 'History' -ErrorAction SilentlyContinue)) {
        [void]$brDbs.Add([pscustomobject]@{ Tarayici = $br[0]; File = $h })
    }
}
$ffRoot = $env:APPDATA + '\Mozilla\Firefox\Profiles'
if (Test-Path -LiteralPath $ffRoot) {
    foreach ($h in @(Get-ChildItem -LiteralPath $ffRoot -Recurse -Depth 1 -File -Force -Filter 'places.sqlite' -ErrorAction SilentlyContinue)) {
        [void]$brDbs.Add([pscustomobject]@{ Tarayici = 'Firefox'; File = $h })
    }
}
$brSeen = @{}
$brScanned = 0
foreach ($db in $brDbs) {
    $b = Read-DbBytes $db.File.FullName
    if ($null -eq $b -or $b.Length -lt 100) { continue }
    $brScanned++
    $txt = [Text.Encoding]::GetEncoding(28591).GetString($b)
    $kaynak = 'Tarayici gecmisi: ' + $db.Tarayici
    # 1) indirilen/acilan dosya yollari (hile ismi, silinmis dosya, olagan disi konum)
    foreach ($pm in (Find-Paths $txt 'exe|dll|jar|bat|ps1|scr|cmd|vbs|msi|zip|rar|7z')) {
        $lk = $pm.ToLower()
        if ($brSeen.ContainsKey($lk)) { continue }
        $brSeen[$lk] = 1
        $pi = Get-PiCached $pm
        Eval-Exec -Kaynak $kaynak -Path $pm -Exists $pi.Exists -Removed $pi.Removed -Note ('indirme/gecmis kaydi (' + $db.Tarayici + ' veritabani, kayit bazinda zaman bilgisi okunmuyor)')
    }
    # 2) ziyaret edilen/indirilen adreslerde hile ismi (tek basina kanit degil, yanlis alarm olabilir)
    $urlN = 0
    foreach ($um in [regex]::Matches($txt, '(?i)https?://[^\s\x00-\x1f"<>\x7f-\xff]{6,300}')) {
        $u = $um.Value
        $uh = Get-NameHit $u $false
        if (-not $uh) { continue }
        $uk = $u.ToLower()
        if ($brSeen.ContainsKey($uk)) { continue }
        $brSeen[$uk] = 1
        $urlN++
        if ($urlN -gt 60) { break }
        $hm = [regex]::Match($u, '(?i)^https?://([^/?#:]+)')
        $hostName = $u
        if ($hm.Success) { $hostName = $hm.Groups[1].Value.ToLower() }
        Add-F -Kaynak $kaynak -Ad ('adres: ' + $hostName) -Yol $u -Skor 35 -Son $db.File.LastWriteTime -Var 'Bilinmiyor' -Not ('tarayici gecmisinde hile ismi iceren adres: ' + $uh.Name + ' | ismin gecmesi tek basina kanit degil (ornek: meteor, inertia gibi yazilim siteleri); adrese ve tarihe bak')
    }
}
Log ('   ' + $brScanned + ' tarayici gecmis veritabani incelendi.') 'DarkGray'
Show-Section

# =====================================================================
Step '[17+/17] K) Kernel suruculeri, test signing, savunmasiz surucu engeli...'
Start-Sec
$vulnDrv = @('capcom.sys', 'iqvw64e.sys', 'iqvw32.sys', 'gdrv.sys', 'dbutil_2_3.sys', 'rtcore64.sys', 'rtcore32.sys', 'winio64.sys', 'winio32.sys', 'winring0x64.sys', 'winring0.sys', 'physmem.sys', 'atillk64.sys', 'amifldrv64.sys', 'asmmap64.sys', 'mhyprot2.sys', 'mhyprot3.sys', 'kprocesshacker.sys', 'speedfan.sys', 'ene.sys', 'glckio2.sys')
$drvCount = 0
foreach ($dv in @(Get-CimInstance Win32_SystemDriver -ErrorAction SilentlyContinue)) {
    $raw = [string]$dv.PathName
    if (-not $raw) { continue }
    $dp = $raw.Trim().Trim('"')
    $dp = $dp -replace '^\\\?\?\\', ''
    $dp = $dp -replace '(?i)^\\SystemRoot', $env:WINDIR
    if ($dp -match '(?i)^System32\\') { $dp = $env:WINDIR + '\' + $dp }
    if ($dp -notmatch '^[A-Za-z]:\\') { continue }
    $drvCount++
    $dleaf = ''
    try { $dleaf = Split-Path -Leaf $dp } catch {}
    if (-not $dleaf) { continue }
    $dzone = Get-Zone $dp
    $dexists = [bool](Test-Path -LiteralPath $dp)
    $sysPath = ($dp -match '(?i)^[A-Za-z]:\\Windows\\') -or ($dp -match '(?i)^[A-Za-z]:\\Program Files') -or ($dp -match '(?i)\\ProgramData\\Microsoft\\Windows Defender\\')
    $sc = 0
    $why = New-Object System.Collections.Generic.List[string]
    if ($vulnDrv -contains $dleaf.ToLower()) { $sc += 40; [void]$why.Add('bilinen savunmasiz/kotuye kullanilan surucu ismi (BYOVD). Mesru yazilimla da gelmis olabilir, hangi programa ait oldugunu kontrol et') }
    $dh = Get-NameHit $dleaf $false
    if ($dh) { $sc += 50; [void]$why.Add('isim eslesmesi: ' + $dh.Name) }
    if (-not $sysPath) {
        if ($dzone -eq 'user' -or $dzone -eq 'temp' -or $dzone -eq 'appdata' -or $dzone -eq 'shared') {
            $sc += 35; [void]$why.Add('surucu kullanici/temp/AppData/ortak klasorden yukleniyor')
            if ($dexists -and -not (Test-Signed $dp)) { $sc += 20; [void]$why.Add('imzasiz') }
        } elseif (-not $dexists) {
            $sc += 20; [void]$why.Add('surucu dosyasi diskte bulunamiyor')
        } elseif (-not (Test-Signed $dp)) {
            $sc += 20; [void]$why.Add('olagan disi klasorde imzasiz surucu')
        }
    }
    if ($sc -ge 30) {
        $dvar = 'Hayir'
        if ($dexists) { $dvar = 'Evet' }
        Add-F -Kaynak 'Kernel surucusu' -Ad $dleaf.ToLower() -Yol $dp -Skor ([Math]::Min(100, $sc)) -Var $dvar -Not (($why -join '; ') + ' | servis: ' + $dv.Name + ' | durum: ' + $dv.State + ' | baslatma: ' + $dv.StartMode)
    }
}
Log ('   ' + $drvCount + ' kernel surucusu incelendi.') 'DarkGray'

try {
    $bcd = (& bcdedit.exe /enum '{current}' 2>&1 | Out-String)
    if ($bcd -match '(?im)^\s*testsigning\s+(Yes|Evet)') {
        Add-Sys 'Windows TEST SIGNING modu ACIK' 60 'Imzasiz kernel suruculerinin yuklenmesine izin verir; kernel seviyesinde hile suruculeri icin kullanilir.'
    }
    if ($bcd -match '(?im)^\s*nointegritychecks\s+(Yes|Evet)') {
        Add-Sys 'Surucu imza dogrulamasi KAPALI (nointegritychecks)' 60 'Boot ayarlarinda kod butunlugu kontrolleri kapatilmis.'
    }
} catch {}
Check-RegFlag 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Config' 'VulnerableDriverBlocklistEnable' 1 'Savunmasiz surucu engelleme listesi KAPALI' 'Microsoft''un bilinen savunmasiz suruculer listesi devre disi; BYOVD yontemiyle hile suruculeri yuklemeyi kolaylastirir (bazi oyuncular performans icin de kapatir).' 25
Check-RegFlag 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' 'Enabled' 1 'Bellek butunlugu (HVCI) KAPALI' 'Cekirdek yalitimi/bellek butunlugu kapali; tek basina supheli degil, diger bulgularla birlikte degerlendir.' 8
Show-Section

# =====================================================================
# EK MODUL 4: NirSoft mantigi, programsiz (SQLite, ShellBags, Uninstall, Defender, DLL, olaylar, jar icerigi, bellek)
# =====================================================================
function Ft-Webkit([string]$v) {
    $n = [long]0
    if ([long]::TryParse($v, [ref]$n) -and $n -gt 0) { try { return [datetime]::FromFileTimeUtc($n * 10).ToLocalTime() } catch {} }
    return $null
}
function Ft-Unix([string]$v) {
    $n = [long]0
    if ([long]::TryParse($v, [ref]$n) -and $n -gt 0) { try { return ([DateTimeOffset]::FromUnixTimeMilliseconds([long]($n / 1000))).LocalDateTime } catch {} }
    return $null
}
function Copy-DbTemp([string]$src) {
    $b = Read-DbBytes $src
    if ($null -eq $b -or $b.Length -lt 100) { return $null }
    $tmp = Join-Path $env:TEMP ('hk_q_' + [guid]::NewGuid().ToString('N') + '.db')
    [IO.File]::WriteAllBytes($tmp, $b)
    if (Test-Path -LiteralPath ($src + '-wal')) {
        $w = Read-DbBytes ($src + '-wal')
        if ($null -ne $w -and $w.Length -gt 0) { [IO.File]::WriteAllBytes(($tmp + '-wal'), $w) }
    }
    return $tmp
}
function Remove-DbTemp([string]$t) {
    foreach ($x in @($t, ($t + '-wal'), ($t + '-shm'), ($t + '-journal'))) { Remove-Item -LiteralPath $x -Force -ErrorAction SilentlyContinue }
}

# ---------------------------------------------------------------------
Step '[17+/17] M) BrowserDownloadsView + BrowsingHistoryView mantigi (winsqlite3 ile): ne, nereden, ne zaman indirildi...'
Start-Sec
$sqlCs = @'
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class HkSql {
    const string D = "winsqlite3.dll";
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] static extern int sqlite3_open_v2(byte[] f, out IntPtr db, int flags, IntPtr vfs);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] static extern int sqlite3_close(IntPtr db);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] static extern int sqlite3_prepare_v2(IntPtr db, byte[] sql, int n, out IntPtr st, IntPtr tail);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] static extern int sqlite3_step(IntPtr st);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] static extern int sqlite3_finalize(IntPtr st);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] static extern int sqlite3_column_count(IntPtr st);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] static extern IntPtr sqlite3_column_text(IntPtr st, int i);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] static extern int sqlite3_column_bytes(IntPtr st, int i);
    public static List<string[]> Query(string path, string sql, int max) {
        List<string[]> rows = new List<string[]>();
        IntPtr db;
        byte[] fb = Encoding.UTF8.GetBytes(path + "\0");
        if (sqlite3_open_v2(fb, out db, 2, IntPtr.Zero) != 0) { if (db != IntPtr.Zero) sqlite3_close(db); return null; }
        IntPtr st;
        byte[] sb = Encoding.UTF8.GetBytes(sql + "\0");
        if (sqlite3_prepare_v2(db, sb, -1, out st, IntPtr.Zero) != 0) { sqlite3_close(db); return null; }
        int cc = sqlite3_column_count(st);
        while (rows.Count < max && sqlite3_step(st) == 100) {
            string[] r = new string[cc];
            for (int i = 0; i < cc; i++) {
                IntPtr p = sqlite3_column_text(st, i);
                if (p == IntPtr.Zero) { r[i] = ""; continue; }
                int n = sqlite3_column_bytes(st, i);
                byte[] b = new byte[n];
                Marshal.Copy(p, b, 0, n);
                r[i] = Encoding.UTF8.GetString(b);
            }
            rows.Add(r);
        }
        sqlite3_finalize(st);
        sqlite3_close(db);
        return rows;
    }
}
'@
$script:SqlOk = $false
try { Add-Type -TypeDefinition $sqlCs -Language CSharp -ErrorAction Stop; $script:SqlOk = $true } catch {}
$dlHostRx = '(?i)cdn\.discordapp\.com/attachments|media\.discordapp\.net/attachments|mega\.nz|mediafire\.com|gofile\.io|pixeldrain\.com|anonfiles|transfer\.sh|workupload\.com|file\.io|catbox\.moe|dropbox\.com|drive\.google\.com|sendspace\.com|1fichier\.com'
$qSeenDl = @{}
$dlTotal = 0
$histTotal = 0
if (-not $script:SqlOk) {
    Log '   winsqlite3.dll kullanilamadi; yukaridaki J modulundeki metin taramasi gecerli.' 'DarkYellow'
} else {
    foreach ($db in $brDbs) {
        $tmp = $null
        try { $tmp = Copy-DbTemp $db.File.FullName } catch {}
        if (-not $tmp) { continue }
        $isFf = ($db.Tarayici -eq 'Firefox')
        $kaynak = 'Tarayici indirmesi: ' + $db.Tarayici
        try {
            if (-not $isFf) {
                $q1 = 'SELECT d.target_path, (SELECT c.url FROM downloads_url_chains c WHERE c.id = d.id ORDER BY c.chain_index DESC LIMIT 1), d.tab_url, d.start_time, d.total_bytes FROM downloads d ORDER BY d.start_time DESC'
                $rows = $null
                try { $rows = [HkSql]::Query($tmp, $q1, 20000) } catch {}
                if ($null -ne $rows) {
                    foreach ($r in $rows) {
                        $tp = [string]$r[0]
                        if (-not $tp) { continue }
                        $durl = [string]$r[1]
                        $tab = [string]$r[2]
                        $tm = Ft-Webkit ([string]$r[3])
                        $dk = $tp.ToLower() + '|' + [string]$r[3]
                        if ($qSeenDl.ContainsKey($dk)) { continue }
                        $qSeenDl[$dk] = 1
                        $dlTotal++
                        $leafD = ''
                        $extD = ''
                        try { $leafD = Split-Path -Leaf $tp; $extD = [IO.Path]::GetExtension($leafD).ToLower() } catch {}
                        $srcN = 'indirildigi adres: ' + $durl
                        if ($tab) { $srcN = $srcN + ' | sayfa: ' + $tab }
                        if ($tp -match '^[A-Za-z]:\\') {
                            $pi = Get-PiCached $tp
                            Eval-Exec -Kaynak $kaynak -Path $tp -Exists $pi.Exists -Removed $pi.Removed -Last $tm -First $tm -Note $srcN
                            if (($IntExt -contains $extD) -and (($durl + ' ' + $tab) -match $dlHostRx)) {
                                $sc2 = 30
                                $pvar = 'Evet'
                                if (-not $pi.Exists) { $sc2 = 45; $pvar = 'Hayir' }
                                Add-F -Kaynak ($kaynak + ' (paylasim sitesi)') -Ad $leafD.ToLower() -Yol $tp -Skor $sc2 -Son $tm -Ilk $tm -Var $pvar -Not ('dosya paylasim/sohbet sitesinden indirilmis kod/arsiv dosyasi (hile dagitiminda sik kullanilir ama mesru dosyalar da olabilir) | ' + $srcN)
                            }
                        }
                        $hu = Get-NameHit ($durl + ' ' + $tab + ' ' + $leafD) $false
                        if ($hu) {
                            Add-F -Kaynak ($kaynak + ' (hile ismi)') -Ad $leafD.ToLower() -Yol $tp -Skor 55 -Son $tm -Ilk $tm -Var 'Bilinmiyor' -Not ('indirme adresinde/dosya adinda hile ismi: ' + $hu.Name + ' | ' + $srcN)
                        }
                    }
                }
                $q2 = 'SELECT url, title, visit_count, last_visit_time FROM urls ORDER BY last_visit_time DESC LIMIT 30000'
                $rows2 = $null
                try { $rows2 = [HkSql]::Query($tmp, $q2, 30000) } catch {}
                $tmFn = 'W'
            } else {
                $q2 = 'SELECT url, title, visit_count, last_visit_date FROM moz_places WHERE last_visit_date IS NOT NULL ORDER BY last_visit_date DESC LIMIT 30000'
                $rows2 = $null
                try { $rows2 = [HkSql]::Query($tmp, $q2, 30000) } catch {}
                $tmFn = 'U'
            }
            if ($null -ne $rows2) {
                $hN = 0
                foreach ($r in $rows2) {
                    $u = [string]$r[0]
                    $ti = [string]$r[1]
                    $hh = Get-NameHit ($u + ' ' + $ti) $false
                    if (-not $hh) { continue }
                    $hN++
                    if ($hN -gt 80) { break }
                    $histTotal++
                    if ($tmFn -eq 'W') { $tm = Ft-Webkit ([string]$r[3]) } else { $tm = Ft-Unix ([string]$r[3]) }
                    $hm2 = [regex]::Match($u, '(?i)^https?://([^/?#:]+)')
                    $hostN = $u
                    if ($hm2.Success) { $hostN = $hm2.Groups[1].Value.ToLower() }
                    Add-F -Kaynak ('Tarayici gecmisi (SQL): ' + $db.Tarayici) -Ad ('adres: ' + $hostN) -Yol $u -Skor 35 -Son $tm -Var 'Bilinmiyor' -Not ('ziyaret sayisi: ' + $r[2] + ' | baslik: ' + $ti + ' | hile ismi: ' + $hh.Name + ' (ismin gecmesi tek basina kanit degil)')
                }
            }
        } catch {}
        Remove-DbTemp $tmp
    }
    Log ('   ' + $dlTotal + ' tarayici indirme kaydi, ' + $histTotal + ' supheli gecmis kaydi incelendi.') 'DarkGray'
}
Show-Section

# ---------------------------------------------------------------------
Step '[17+/17] N) ShellBags: gezilen klasorler (silinmis olsa bile) - ShellBagsView mantigi...'
Start-Sec
function Get-ShellName([byte[]]$b) {
    if ($null -eq $b -or $b.Length -lt 8) { return $null }
    if (($b[2] -band 0x70) -eq 0x20) {
        $dv = [Text.Encoding]::ASCII.GetString($b, 3, 3)
        if ($dv -match '^[A-Za-z]:\\') { return $dv.Substring(0, 2).ToUpper() }
        return $null
    }
    if (($b[2] -band 0x70) -ne 0x30) { return $null }
    $best = ''
    foreach ($off in @(0, 1)) {
        $len = $b.Length - $off
        $len = $len - ($len % 2)
        if ($len -lt 6) { continue }
        $txt = [Text.Encoding]::Unicode.GetString($b, $off, $len)
        foreach ($m in [regex]::Matches($txt, '[A-Za-z0-9 \.\-_\(\)\+&,!@#\u00C0-\u017F]{3,120}')) {
            $v = $m.Value.Trim()
            if ($v.Length -gt $best.Length -and $v -match '[A-Za-z]' -and $v -notmatch '^[0-9A-Fa-f\-]{20,}$') { $best = $v }
        }
    }
    if ($best) { return $best }
    $a = [Text.Encoding]::GetEncoding(28591).GetString($b, 4, $b.Length - 4)
    $am = [regex]::Match($a, '[A-Za-z0-9_\.\-~]{3,}')
    if ($am.Success) { return $am.Value }
    return $null
}
$script:SbSeen = @{}
$script:SbCount = 0
function Eval-Bag([string]$full, $kt) {
    if ($full -notmatch '^[A-Za-z]:\\.+') { return }
    $lk = $full.ToLower()
    if ($script:SbSeen.ContainsKey($lk)) { return }
    $script:SbSeen[$lk] = 1
    $script:SbCount++
    $leaf = ''
    try { $leaf = Split-Path -Leaf $full } catch {}
    if (-not $leaf) { return }
    $pi = Get-PiCached $full
    $sc = 0
    $why = New-Object System.Collections.Generic.List[string]
    $h = Get-NameHit $leaf $false
    if ($h) { $sc += 45; [void]$why.Add('klasor adinda hile ismi: ' + $h.Name) }
    if (-not $pi.Exists -and ((Test-MixedRandom $leaf) -or (Test-Gibberish $leaf))) { $sc += 30; [void]$why.Add('rastgele isimli klasor, su an SILINMIS') }
    if ($h -and -not $pi.Exists) { $sc += 15; [void]$why.Add('klasor su an yok (silinmis/tasinmis/cikarilmis surucu)') }
    if ($sc -ge 30) {
        $var = 'Evet'
        if (-not $pi.Exists) { $var = 'Hayir' }
        Add-F -Kaynak 'ShellBags (gezilen klasor)' -Ad ('klasor: ' + $leaf.ToLower()) -Yol $full -Skor ([Math]::Min(100, $sc)) -Son $kt -Var $var -Not (($why -join '; ') + ' | Zaman = klasorun en son acildigi/gezildigi zamana yakin kayit defteri degisimi')
    }
}
function Walk-BagMRU($key, [string]$parent, [int]$depth) {
    if ($depth -gt 14) { return }
    foreach ($vn in $key.GetValueNames()) {
        if ($vn -notmatch '^\d+$') { continue }
        $vb = $key.GetValue($vn)
        if ($vb -isnot [byte[]]) { continue }
        $nm = Get-ShellName $vb
        $full = $parent
        if ($nm) {
            if ($parent) { $full = $parent.TrimEnd('\') + '\' + $nm } else { $full = $nm }
        }
        $sub = $null
        try { $sub = $key.OpenSubKey($vn) } catch {}
        if ($sub) {
            if ($nm) { Eval-Bag $full (Get-KeyTime $sub) }
            Walk-BagMRU $sub $full ($depth + 1)
            $sub.Close()
        }
    }
}
foreach ($bk in @('HKCU:\Software\Microsoft\Windows\Shell\BagMRU', 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU')) {
    try {
        $root = Get-Item -LiteralPath $bk -ErrorAction Stop
        Walk-BagMRU $root '' 0
    } catch {}
}
Log ('   ' + $script:SbCount + ' ShellBag klasor kaydi cozuldu (isim cikarma sezgiseldir).') 'DarkGray'
Show-Section

# ---------------------------------------------------------------------
Step '[17+/17] O) Yuklu programlar listesi (UninstallView mantigi)...'
Start-Sec
$unToolRx = '(?i)cheat ?engine|process ?hacker|system ?informer|x64dbg|x32dbg|ollydbg|dnspy|extreme ?injector|autohotkey|auto ?clicker|tinytask|jitbit|op ?auto ?clicker'
$unCount = 0
foreach ($ur in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')) {
    foreach ($k in @(Get-ChildItem -LiteralPath $ur -ErrorAction SilentlyContinue)) {
        $dn = [string]$k.GetValue('DisplayName')
        if (-not $dn) { $k.Close(); continue }
        $pub = [string]$k.GetValue('Publisher')
        $loc = [string]$k.GetValue('InstallLocation')
        $uns = [string]$k.GetValue('UninstallString')
        $ids = [string]$k.GetValue('InstallDate')
        $kt = Get-KeyTime $k
        $k.Close()
        $unCount++
        $txt = $dn + ' ' + $pub + ' ' + $loc + ' ' + $uns
        $h = Get-NameHit $txt $false
        $tool = [regex]::Match($dn, $unToolRx)
        if (-not $h -and -not $tool.Success) { continue }
        $idt = $null
        if ($ids -match '^\d{8}$') { try { $idt = [datetime]::ParseExact($ids, 'yyyyMMdd', [Globalization.CultureInfo]::InvariantCulture) } catch {} }
        $sc = 0
        $nt = ''
        if ($h) { $sc += 45; $nt = 'program adinda/yolunda hile ismi: ' + $h.Name }
        if ($tool.Success) { $sc += 30; $nt = $nt + ' | hile/enjeksiyon/makro araci: ' + $tool.Value }
        $var = 'Evet'
        if ($loc -match '^[A-Za-z]:\\' -and -not (Test-Path -LiteralPath $loc)) { $sc += 10; $var = 'Hayir'; $nt = $nt + ' | kurulum klasoru artik yok' }
        Add-F -Kaynak 'Yuklu programlar (Uninstall)' -Ad ('program: ' + $dn.ToLower()) -Yol ($loc + ' ' + $uns) -Skor ([Math]::Min(100, $sc)) -Son $kt -Ilk $idt -Var $var -Not ($nt + ' | yayinci: ' + $pub + ' | Son: kayit defteri degisimi, Ilk: kurulum tarihi')
    }
}
Log ('   ' + $unCount + ' yuklu program kaydi incelendi.') 'DarkGray'
Show-Section

# ---------------------------------------------------------------------
Step '[17+/17] P) Windows Defender olay gunlugu ve MPLog (WinDefLogView mantigi)...'
Start-Sec
$defEv = @()
try { $defEv = @(Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Windows Defender/Operational'; Id = 1116, 1117, 1118, 1119, 5001, 5007, 5010, 5012, 5013 } -MaxEvents 800 -ErrorAction Stop) } catch {}
$defSeen = @{}
$defSysN = @{}
foreach ($e in $defEv) {
    $msg = [string]$e.Message
    if ($e.Id -ge 1116 -and $e.Id -le 1119) {
        $tn = ''
        $nmM = [regex]::Match($msg, '(?im)^\s*(?:Name|Ad|Adi|Ad\u0131)\s*:\s*(.+?)\s*$')
        if ($nmM.Success) { $tn = $nmM.Groups[1].Value }
        foreach ($pm in [regex]::Matches($msg, 'file:_([A-Za-z]:\\[^\r\n;]+)')) {
            $dp = $pm.Groups[1].Value.Trim()
            $dk = $dp.ToLower() + '|' + $e.Id
            if ($defSeen.ContainsKey($dk)) { continue }
            $defSeen[$dk] = 1
            $leaf = ''
            $bn = ''
            try { $leaf = Split-Path -Leaf $dp; $bn = [IO.Path]::GetFileNameWithoutExtension($leaf) } catch {}
            if (-not $leaf) { continue }
            $pi = Get-PiCached $dp
            $sc = 45
            $why = 'Defender olayi ' + $e.Id + ' (' + $tn + ')'
            if ((Test-MixedRandom $bn) -or (Test-Gibberish $bn)) { $sc += 15; $why = $why + ' | rastgele dosya adi' }
            $hh = Get-NameHit $leaf $true
            if ($hh) { $sc += 10; $why = $why + ' | isim eslesmesi: ' + $hh.Name }
            if ($tn -match '(?i)hacktool|cheat|inject|gamehack|trojan|exploit|pua|riskware|behavior') { $sc += 10 }
            $dvar = 'Hayir'
            if ($pi.Exists) { $dvar = 'Evet' }
            Add-F -Kaynak 'Defender olay gunlugu' -Ad $leaf.ToLower() -Yol $dp -Skor ([Math]::Min(100, $sc)) -Son $e.TimeCreated -Ilk $e.TimeCreated -Var $dvar -Not $why
        }
    } elseif ($e.Id -eq 5007) {
        foreach ($xm in [regex]::Matches($msg, '(?i)Exclusions\\(Paths|Processes|Extensions|IpAddresses)\\([^\r\n=]+?)\s*=')) {
            $xk = 'x|' + $xm.Groups[2].Value.ToLower()
            if ($defSeen.ContainsKey($xk)) { continue }
            $defSeen[$xk] = 1
            Add-Sys ('Defender dislama degisikligi (olay 5007): ' + $xm.Groups[2].Value) 40 'Defender ayar degisikligi olay gunlugunde; bu yol/uzanti/process icin dislama eklenmis ya da degistirilmis olabilir.' $e.TimeCreated $xm.Groups[1].Value $e.TimeCreated
        }
        if ($msg -match '(?i)DisableRealtimeMonitoring|DisableAntiSpyware|DisableBehaviorMonitoring|DisableIOAVProtection|DisableScriptScanning') {
            if (-not $defSysN.ContainsKey('5007k')) { $defSysN['5007k'] = 1; Add-Sys 'Defender koruma ayari degistirilmis (olay 5007)' 35 'Gercek zamanli/davranis/script tarama ayarlarindan biri degistirilmis.' $e.TimeCreated }
        }
    } else {
        $ik = [string]$e.Id
        if (-not $defSysN.ContainsKey($ik)) {
            $defSysN[$ik] = 1
            $sk = 40
            $bs = 'Defender olay ' + $e.Id
            if ($e.Id -eq 5001) { $sk = 50; $bs = 'Defender aninda koruma KAPATILMIS (olay 5001)' }
            if ($e.Id -eq 5013) { $sk = 35; $bs = 'Defender kurcalamaya karsi koruma bir degisikligi engellemis (olay 5013)' }
            Add-Sys $bs $sk 'Defender koruma durumu degistirilmis; zamanina ve diger bypass olaylarina bak.' $e.TimeCreated
        }
    }
}
Log ('   ' + $defEv.Count + ' Defender olayi incelendi.') 'DarkGray'

$mpDir = $env:ProgramData + '\Microsoft\Windows Defender\Support'
$mpFiles = @()
if (-not (Test-Path -LiteralPath $mpDir)) { Log ('   Defender Support klasoru yok/erisilemiyor: ' + $mpDir + ' (Defender kapali veya baska antivirus olabilir; yonetici degilse de okunamaz)') 'DarkYellow' }
if (Test-Path -LiteralPath $mpDir) { $mpFiles = @(Get-ChildItem -LiteralPath $mpDir -Filter 'MPLog-*.log' -File -Force -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 4) }
if ((Test-Path -LiteralPath $mpDir) -and $mpFiles.Count -eq 0) {
    $anyF = @(Get-ChildItem -LiteralPath $mpDir -Force -ErrorAction SilentlyContinue).Count
    Log ('   Defender Support klasoru var ama MPLog-*.log yok (klasordeki oge sayisi: ' + $anyF + '). 0 ise yonetici degilsin ya da Defender gunlukleri kapali/temizlenmis olabilir.') 'DarkYellow'
}
$mpPat = '(?i)(?:\\Device\\HarddiskVolume\d+|[A-Za-z]:)\\[^\r\n"<>|*?]{3,260}?\.(?:exe|dll|jar|bat|ps1|scr|cmd|vbs|msi)(?![A-Za-z0-9])'
$mpRx = New-Object System.Text.RegularExpressions.Regex($mpPat, [System.Text.RegularExpressions.RegexOptions]::Compiled, [TimeSpan]::FromSeconds(2))
$mpSeen = @{}
$mpN = 0
foreach ($mf in $mpFiles) {
    if ($mf.Length -gt 157286400) { Add-Cov 'Defender MPLog >150 MB: atlandi' $mf.FullName; continue }
    $mt = Read-LogText $mf.FullName
    if (-not $mt) { continue }
    foreach ($ln in $mt.Split("`n")) {
        if ($ln.Length -lt 10) { continue }
        $mm = $null
        try { $mm = $mpRx.Match($ln) } catch { continue }
        if (-not $mm.Success) { continue }
        $pth = $mm.Value
        $pk = $pth.ToLower()
        if ($mpSeen.ContainsKey($pk)) { continue }
        $mpSeen[$pk] = 1
        $mpN++
        if ($mpN -gt 6000) { break }
        $rr = Resolve-NtPath $pth
        $tt = $null
        $tmM = [regex]::Match($ln, '^(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2})')
        if ($tmM.Success) { try { $tt = [datetime]::ParseExact(($tmM.Groups[1].Value + ' ' + $tmM.Groups[2].Value), 'yyyy-MM-dd HH:mm:ss', [Globalization.CultureInfo]::InvariantCulture).ToLocalTime() } catch {} }
        Eval-Exec -Kaynak 'Defender MPLog (taranan dosya)' -Path $rr.Path -Exists $rr.Exists -Removed $rr.Removed -Last $tt -Note ('MPLog: Defender bu dosyayi taramis/gormus (dosya silinse de iz kalir) | ' + $mf.Name)
    }
}
Log ('   ' + $mpFiles.Count + ' MPLog dosyasindan ' + $mpN + ' farkli dosya yolu incelendi.') 'DarkGray'
Show-Section

# ---------------------------------------------------------------------
Step '[17+/17] Q) Yuklu DLL analizi: tum process ler (LoadedDllsView mantigi)...'
Start-Sec
$ldAll = @{}
foreach ($gp in @(Get-Process -ErrorAction SilentlyContinue)) {
    if ($gp.Id -le 4 -or $gp.Id -eq $PID) { continue }
    $mods = $null
    $mods = $null
    if ($script:HkModCache -and $script:HkModCache.ContainsKey([int]$gp.Id)) { $mods = $script:HkModCache[[int]$gp.Id] } else { try { $mods = @($gp.Modules) } catch { continue } }
    foreach ($m in $mods) {
        $mp = [string]$m.FileName
        if ($mp -notmatch '^[A-Za-z]:\\') { continue }
        if (Test-SysPathOk $mp) { continue }
        $mk = $mp.ToLower()
        if (-not $ldAll.ContainsKey($mk)) { $ldAll[$mk] = @{ Path = $mp; Procs = (New-Object System.Collections.Generic.List[string]) } }
        if ($ldAll[$mk].Procs.Count -lt 8 -and -not $ldAll[$mk].Procs.Contains($gp.ProcessName)) { [void]$ldAll[$mk].Procs.Add($gp.ProcessName) }
    }
}
$ldN = 0
foreach ($kv in $ldAll.GetEnumerator()) {
    $ldN++
    if ($ldN -gt 1500) { break }
    $mp = $kv.Value.Path
    $mn = ''
    try { $mn = (Split-Path -Leaf $mp).ToLower() } catch {}
    if (-not $mn) { continue }
    if ($mn -match $knownNat) { continue }
    if ($mp -match '(?i)\\(\.minecraft|\.lunarclient|ModrinthApp|PrismLauncher|\.tlauncher|\.feather|\.ichor)\\|\\(runtime|jre|jdk)[^\\]*\\') { continue }
    $procs = ($kv.Value.Procs -join ', ')
    $isJ = ($procs -match '(?i)javaw?')
    $fi = $null
    try { $fi = Get-Item -LiteralPath $mp -Force -ErrorAction Stop } catch {}
    $sc = 0
    $why = New-Object System.Collections.Generic.List[string]
    $bn = [IO.Path]::GetFileNameWithoutExtension($mn)
    if (-not $fi) {
        $sc += 50; [void]$why.Add('DLL diskte YOK ama bellekte yuklu (dosya silinmis)')
    } else {
        $comp = [string]$fi.VersionInfo.CompanyName
        $prod = [string]$fi.VersionInfo.ProductName
        $sig = Test-Signed $mp
        if (-not $sig) {
            if (-not $comp -and -not $prod) { $sc += 35; [void]$why.Add('imzasiz + sirket/urun adi YOK') } else { $sc += 10; [void]$why.Add('imzasiz (sirket: ' + $comp + ')') }
        }
        $zn = Get-Zone $mp
        if ($sc -gt 0 -and ($zn -eq 'user' -or $zn -eq 'temp' -or $zn -eq 'appdata' -or $zn -eq 'shared')) { $sc += 10; [void]$why.Add($zn + ' klasorunde') }
    }
    $hit = Get-NameHit $mn $false
    if ($hit) { $sc += 50; [void]$why.Add('isim eslesmesi: ' + $hit.Name) }
    if ($sc -gt 0 -and ((Test-MixedRandom $bn) -or (Test-Gibberish $bn))) { $sc += 20; [void]$why.Add('rastgele dll adi') }
    if ($sc -gt 0 -and $isJ) { $sc += 15; [void]$why.Add('Java process ine yuklenmis') }
    if ($sc -ge 40) {
        $son = $null
        $ilk = $null
        $var = 'Hayir'
        if ($fi) { $son = $fi.LastWriteTime; $ilk = $fi.CreationTime; $var = 'Evet' }
        Add-F -Kaynak 'Yuklu DLL (tum process ler)' -Ad $mn -Yol $mp -Skor ([Math]::Min(100, $sc)) -Son $son -Ilk $ilk -Var $var -Not (($why -join '; ') + ' | yukleyen process ler: ' + $procs)
    }
}
Log ('   ' + $ldAll.Count + ' farkli sistem disi DLL incelendi.') 'DarkGray'
Show-Section

# ---------------------------------------------------------------------
Step '[17+/17] R) Olay gunlukleri: servis/surucu kurulumu (7045), process baslatma (4688), uygulama cokmeleri (1000) - LastActivityView mantigi...'
Start-Sec
$r7 = 0
$r88 = 0
$r10 = 0
try {
    foreach ($e in @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 7045 } -MaxEvents 300 -ErrorAction Stop)) {
        $sn = ''
        $ip = ''
        try { $sn = [string]$e.Properties[0].Value; $ip = [string]$e.Properties[1].Value } catch {}
        if (-not $ip) { continue }
        if ($sn -match '(?i)^mbam') { continue }
        $ipx = [Environment]::ExpandEnvironmentVariables($ip).Trim()
        $ipx = $ipx -replace '^\\\?\?\\', ''
        $ipx = $ipx -replace '(?i)^\\SystemRoot', $env:WINDIR
        $cand = $null
        if ($ipx -match '(?i)^\s*"([^"]+)"') { $cand = $Matches[1] } elseif ($ipx -match '(?i)^\s*([A-Za-z]:\\.*?\.(?:exe|sys|dll|bat|cmd|ps1|vbs|jar))') { $cand = $Matches[1] }
        if (-not $cand -or $cand -notmatch '^[A-Za-z]:\\') { continue }
        $r7++
        $pi = Get-PiCached $cand
        if ($cand -match '(?i)\.sys$') {
            $sc = 0
            $why = New-Object System.Collections.Generic.List[string]
            $z = Get-Zone $cand
            if ($z -ne 'system') { $sc += 25; [void]$why.Add('surucu sistem klasoru disindan kurulmus') }
            if (-not $pi.Exists) { $sc += 20; [void]$why.Add('surucu dosyasi artik yok') }
            $hs = Get-NameHit (Split-Path -Leaf $cand) $false
            if ($hs) { $sc += 50; [void]$why.Add('isim eslesmesi: ' + $hs.Name) }
            if ($sc -ge 30) {
                $v = 'Hayir'
                if ($pi.Exists) { $v = 'Evet' }
                Add-F -Kaynak 'Servis/surucu kurulumu (olay 7045)' -Ad ((Split-Path -Leaf $cand).ToLower()) -Yol $cand -Skor $sc -Son $e.TimeCreated -Ilk $e.TimeCreated -Var $v -Not (($why -join '; ') + ' | servis adi: ' + $sn)
            }
        } else {
            Eval-Exec -Kaynak 'Servis kurulumu (olay 7045)' -Path $cand -Exists $pi.Exists -Removed $pi.Removed -Last $e.TimeCreated -First $e.TimeCreated -Note ('yeni servis kuruldu: ' + $sn)
        }
    }
} catch {}
try {
    $seen88 = @{}
    foreach ($e in @(Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4688 } -MaxEvents 3000 -ErrorAction Stop)) {
        $np = ''
        try { $np = [string]$e.Properties[5].Value } catch {}
        if ($np -notmatch '^[A-Za-z]:\\') { continue }
        $nk = $np.ToLower()
        if ($seen88.ContainsKey($nk)) { continue }
        $seen88[$nk] = 1
        $r88++
        $pi = Get-PiCached $np
        Eval-Exec -Kaynak 'Process baslatma kaydi (olay 4688)' -Path $np -Exists $pi.Exists -Removed $pi.Removed -Last $e.TimeCreated -Note 'Guvenlik gunlugu process olusturma kaydi'
    }
} catch {}
try {
    $seen10 = @{}
    foreach ($e in @(Get-WinEvent -FilterHashtable @{ LogName = 'Application'; Id = 1000 } -MaxEvents 300 -ErrorAction Stop)) {
        $ap = ''
        $mp2 = ''
        try { $ap = [string]$e.Properties[10].Value; $mp2 = [string]$e.Properties[11].Value } catch {}
        foreach ($c in @($ap, $mp2)) {
            if ($c -notmatch '^[A-Za-z]:\\') { continue }
            $ck = $c.ToLower()
            if ($seen10.ContainsKey($ck)) { continue }
            $seen10[$ck] = 1
            $r10++
            $pi = Get-PiCached $c
            Eval-Exec -Kaynak 'Uygulama hata kaydi (olay 1000)' -Path $c -Exists $pi.Exists -Removed $pi.Removed -Last $e.TimeCreated -Note 'bu program/modul bir uygulamayi cokertmis olabilir (yuklenmis kayit)'
        }
    }
} catch {}
Log ('   7045: ' + $r7 + ', 4688: ' + $r88 + ', 1000: ' + $r10 + ' kayit incelendi (4688 icin Windows denetimi acik olmali).') 'DarkGray'
Show-Section

# ---------------------------------------------------------------------
Step '[17+/17] S) Jar/zip ICERIK taramasi: class stringleri, ic ice jar, istemci markalari, paket yollari, obfuscation (isimsiz hileler icin)...'
Start-Sec
function Scan-Zip($zip, $r, [int]$depth) {
    foreach ($e in $zip.Entries) {
    # (sure siniri kaldirildi)
        $n = $e.FullName
        if ($n -match '(?i)^(plugin\.yml|bungee\.yml|paper-plugin\.yml|velocity-plugin\.json)$') { $r.Plugin = $true }
        if (-not $r.Pkg -and $n -match $script:PkgRx) { $r.Pkg = $Matches[1] }
        if ($n.EndsWith('.class')) {
            $r.Classes++
            $cb = ''
            try { $cb = [IO.Path]::GetFileNameWithoutExtension($n) } catch {}
            if ($cb.Length -le 2) { $r.Short++ }
            if ($r.Scanned -lt 2500 -and $e.Length -gt 0 -and $e.Length -lt 1048576) {
                $r.Scanned++
                $st = $e.Open()
                $ms = New-Object IO.MemoryStream
                $st.CopyTo($ms)
                $st.Dispose()
                $t = [Text.Encoding]::GetEncoding(28591).GetString($ms.ToArray())
                $ms.Dispose()
                Get-Terms $t $r.Terms
                Get-Brands $t $r.Brands
            }
        } elseif ($n -match '(?i)^(fabric\.mod\.json|quilt\.mod\.json|mcmod\.info|META-INF/mods\.toml|META-INF/neoforge\.mods\.toml)$' -and $e.Length -lt 65536) {
            $sr = New-Object IO.StreamReader($e.Open())
            $r.Meta = $r.Meta + ' ' + $sr.ReadToEnd()
            $sr.Dispose()
        } elseif ($depth -lt 2 -and $n -match '(?i)\.jar$' -and $e.Length -gt 0 -and $e.Length -lt 31457280 -and $r.Nested -lt 25) {
            $r.Nested++
            try {
                $st = $e.Open()
                $ms = New-Object IO.MemoryStream
                $st.CopyTo($ms)
                $st.Dispose()
                $ms.Position = 0
                $inner = New-Object IO.Compression.ZipArchive($ms, [IO.Compression.ZipArchiveMode]::Read)
                try { Scan-Zip $inner $r ($depth + 1) } finally { $inner.Dispose(); $ms.Dispose() }
            } catch {}
        } elseif ($n -match '(?i)\.(json|txt|cfg|toml|properties|yml|yaml)$' -and $e.Length -gt 20 -and $e.Length -lt 262144 -and $r.TextScanned -lt 150) {
            $r.TextScanned++
            try {
                $sr2 = New-Object IO.StreamReader($e.Open())
                $tx = $sr2.ReadToEnd()
                $sr2.Dispose()
                Get-Terms $tx $r.Terms
                Get-Brands $tx $r.Brands
            } catch {}
        }
    }
}
function Deep-Jar([string]$p) {
    $script:ZipSw = [Diagnostics.Stopwatch]::StartNew()
    $r = @{ Terms = @{}; Brands = @{}; Meta = ''; Plugin = $false; Pkg = ''; Classes = 0; Short = 0; Scanned = 0; Nested = 0; TextScanned = 0; Obf = $false; TimedOut = $false }
    try {
        $zip = [IO.Compression.ZipFile]::OpenRead($p)
        try { Scan-Zip $zip $r 0 } finally { $zip.Dispose() }
    } catch {}
    if ($r.Classes -ge 20 -and ($r.Short / [double]$r.Classes) -ge 0.6) { $r.Obf = $true }
    return $r
}
$jarCsOk = $false
try { Add-Type -TypeDefinition $jarCs -Language CSharp -ReferencedAssemblies @('System.IO.Compression', 'System.IO.Compression.FileSystem') -ErrorAction Stop; $jarCsOk = $true } catch {}
$jarResults = @{}
if ($jarCsOk) {
    try { Add-Type -AssemblyName System.IO.Compression.FileSystem } catch {}
    $stPath = Join-Path $env:TEMP ('hk_selftest_' + [guid]::NewGuid().ToString('N') + '.jar')
    $stN = -1
    try {
        $zf = [IO.Compression.ZipFile]::Open($stPath, [IO.Compression.ZipArchiveMode]::Create)
        $ze = $zf.CreateEntry('net/testclient/module/TestModule.class')
        $zs = $ze.Open()
        $zb = [Text.Encoding]::GetEncoding(28591).GetBytes('xxxx KillAura ClickGUI AutoCrystal ShieldBreaker xxxx')
        $zs.Write($zb, 0, $zb.Length)
        $zs.Dispose()
        $zf.Dispose()
        $stRes = [HkJar]::Scan($stPath, $script:ModTermPat, $script:BrandRx.ToString(), $script:PkgRx, 86400)
        $stN = $stRes.Terms.Count
    } catch {}
    Remove-Item -LiteralPath $stPath -Force -ErrorAction SilentlyContinue
    if ($stN -lt 3) { Write-Host ('   [oz-test] BASARISIZ: jar tarayici kendi test jar indeki modul isimlerini bulamadi (bulunan: ' + $stN + '). Bu bir tarayici hatasidir, bana bildir.') -ForegroundColor Red }
    # Masaustu/Indirilenler/Belgeler/script klasoru: dosya gezme adimina bagli kalmadan dogrudan listele
    $jarExtra = New-Object System.Collections.Generic.List[object]
    if ($script:WalkOk) {
        $xr = New-Object System.Collections.Generic.List[string]
        try { [void]$xr.Add((Get-DownloadsPath)) } catch {}
        [void]$xr.Add([Environment]::GetFolderPath('Desktop'))
        [void]$xr.Add([Environment]::GetFolderPath('MyDocuments'))
        if ($PSScriptRoot) { [void]$xr.Add($PSScriptRoot) }
        $xrSeen = @{}
        foreach ($xroot in $xr) {
            if (-not $xroot -or $xrSeen.ContainsKey($xroot.ToLower())) { continue }
            $xrSeen[$xroot.ToLower()] = 1
            $xl = $null
            try { $xl = [HkWalk]::CodeFiles($xroot, 8000) } catch {}
            foreach ($xp in @($xl)) {
                if (-not $xp) { continue }
                if ($xp -notmatch '(?i)\.(jar|zip)$') { continue }
                if ($xp -match $HeavyRx) { continue }
                try { $xf = New-Object IO.FileInfo $xp; if ($xf.Length -lt 104857600) { [void]$jarExtra.Add($xf) } } catch {}
            }
        }
    }
    $jarSrc = New-Object System.Collections.Generic.List[object]
    foreach ($ja in $script:JarCand) { [void]$jarSrc.Add($ja) }
    foreach ($ja in $jarExtra) { [void]$jarSrc.Add($ja) }
    $jarCandList = New-Object System.Collections.Generic.List[object]
    $jarCloud = 0
    $jarTotal = 0
    $jarSeenP = @{}
    foreach ($jx in $jarSrc) {
        $jarTotal++
        $jk = ([string]$jx.FullName).ToLower()
        if ($jarSeenP.ContainsKey($jk)) { continue }
        $jarSeenP[$jk] = 1
        $at = 0
        try { $at = [int]$jx.Attributes } catch {}
        if (($at -band 4460544) -ne 0) { $jarCloud++ } else { [void]$jarCandList.Add($jx) }
    }
    $jarCands = @($jarCandList.ToArray())
    $jarAllCands = $jarCands
    # Ayni icerikli jar kopyalari (farkli profillerde ayni mod): bir kez taranir, sonuc kopyalanir; buyukten kucuge siralanir
    $script:JarDup = @{}
    try {
        $dupSw = [Diagnostics.Stopwatch]::StartNew()
        $jarRep = New-Object System.Collections.Generic.List[object]
        foreach ($jg in @($jarCands | Group-Object -Property Length)) {
            if ($jg.Count -lt 2) { foreach ($jx in $jg.Group) { [void]$jarRep.Add($jx) }; continue }
            $hs = @{}
            foreach ($jx in $jg.Group) {
                $hk = ''
                if ($mmHashMap) { try { if ($mmHashMap.ContainsKey($jx.FullName)) { $hk = [string]$mmHashMap[$jx.FullName] } } catch {} }
                if (-not $hk) {
                    $sha = $null; $fs2 = $null
                    try { $sha = [Security.Cryptography.SHA1]::Create(); $fs2 = [IO.File]::Open($jx.FullName, 'Open', 'Read', 'ReadWrite'); $hk = [BitConverter]::ToString($sha.ComputeHash($fs2)) } catch { $hk = '' }
                    if ($fs2) { $fs2.Dispose() }
                    if ($sha) { $sha.Dispose() }
                }
                $hk = ([string]$hk).Replace('-', '').ToLower()
                if ($hk -and $hs.ContainsKey($hk)) { $script:JarDup[$jx.FullName] = $hs[$hk] } else { if ($hk) { $hs[$hk] = $jx.FullName }; [void]$jarRep.Add($jx) }
            }
        }
        $jarCands = @($jarRep.ToArray() | Sort-Object -Property Length -Descending)
        Add-Perf 'S: ayni icerikli jar kopyalarini eleme (SHA1)' $dupSw.Elapsed.TotalSeconds ([string]$script:JarDup.Count + ' kopya elendi, taranacak ' + $jarCands.Count)
    } catch { $jarCands = $jarAllCands }
    Write-Host ('   aday jar/zip: ' + $jarTotal + ' kayit, ' + $jarSeenP.Count + ' benzersiz dosya, ' + $jarCloud + ' bulut/cevrimdisi dosya') -ForegroundColor DarkGray
    Write-Host ('   ' + $jarCands.Count + ' jar/zip dosyasi derlenmis hizli tarayici ile taraniyor (sure siniri yok)...') -ForegroundColor DarkGray
    if ($jarCloud -gt 0) { Write-Host ('   ' + $jarCloud + ' bulut (OneDrive vb. indirilmemis) dosya atlandi: acilmasi dosyayi indirtir.') -ForegroundColor DarkYellow; Add-Cov 'Bulut/cevrimdisi jar-zip: atlandi (acilirsa indirilir)' '' ([string]$jarCloud + ' dosya') }
    $jarSw = [Diagnostics.Stopwatch]::StartNew()
    $jarThreads = [Math]::Max(2, $script:HkThr)
    for ($ci = 0; $ci -lt $jarCands.Count; $ci += 96) {
        $chSw = [Diagnostics.Stopwatch]::StartNew()
        $hi = [Math]::Min($ci + 95, $jarCands.Count - 1)
        $chunk = @($jarCands[$ci..$hi])
        $paths = [string[]]@($chunk | ForEach-Object { $_.FullName })
        $res = $null
        try { $res = [HkJar]::ScanMany($paths, $script:ModTermPat, $script:BrandRx.ToString(), $script:PkgRx, 86400, $jarThreads) } catch {}
        if ($res) {
            for ($k = 0; $k -lt $paths.Count; $k++) {
                $x = $res[$k]
                if (-not $x -or $x.Error) { continue }
                $ht = @{ Terms = @{}; Brands = @{}; Meta = $x.Meta; Plugin = $x.Plugin; Pkg = $x.Pkg; Classes = $x.Classes; Short = $x.Short; Nested = $x.Nested; TimedOut = $x.TimedOut; Obf = $false; Enc = $x.EncReason; BadMagic = $x.BadMagic; ObfMarks = @($x.ObfMarks); Native = @($x.NativeLibs); HiEnt = @($x.HiEnt) }
                foreach ($tt in $x.Terms) { $ht.Terms[$tt] = 1 }
                foreach ($bb in $x.Brands) { $ht.Brands[$bb] = 1 }
                if ($ht.Classes -ge 20 -and ($ht.Short / [double]$ht.Classes) -ge 0.6) { $ht.Obf = $true }
                $jarResults[$paths[$k]] = $ht
            }
        }
        $doneN = [Math]::Min($ci + 96, $jarCands.Count)
        if ($chSw.Elapsed.TotalSeconds -gt 20) { Add-Perf 'S: yavas jar grubu (96 jar)' $chSw.Elapsed.TotalSeconds ('en buyuk: ' + $chunk[0].FullName + ' ' + [int]($chunk[0].Length / 1MB) + ' MB') }
        Set-Frac ($doneN / [Math]::Max(1, $jarCands.Count)) ('jar/zip ' + $doneN + '/' + $jarCands.Count)
        Write-Host ('   jar/zip ilerleme: ' + $doneN + '/' + $jarCands.Count + ' (' + [int]$jarSw.Elapsed.TotalSeconds + ' sn)') -ForegroundColor DarkGray
    }
    Add-Perf 'S: ScanMany (yerel jar tarayici) toplam' $jarSw.Elapsed.TotalSeconds ([string]$jarCands.Count + ' jar, ' + $script:JarDup.Count + ' kopya elendi')
}
if (-not $jarCsOk) {
$deepJarScript = @'
param($path, $termPat, $brandPat, $pkgPat)
try { Add-Type -AssemblyName System.IO.Compression } catch {}
try { Add-Type -AssemblyName System.IO.Compression.FileSystem } catch {}
$termRx = New-Object System.Text.RegularExpressions.Regex ($termPat, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$brandRx = New-Object System.Text.RegularExpressions.Regex ($brandPat, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$lat = [Text.Encoding]::GetEncoding(28591)
$sw = [Diagnostics.Stopwatch]::StartNew()
$r = @{ Terms = @{}; Brands = @{}; Meta = ''; Plugin = $false; Pkg = ''; Classes = 0; Short = 0; Scanned = 0; Nested = 0; TextScanned = 0; Obf = $false; TimedOut = $false }
function Scan-ZipP($zip, [int]$depth) {
    foreach ($e in $zip.Entries) {
    # (sure siniri kaldirildi)
        $n = $e.FullName
        if ($n -match '(?i)^(plugin\.yml|bungee\.yml|paper-plugin\.yml|velocity-plugin\.json)$') { $r.Plugin = $true }
        if (-not $r.Pkg -and $n -match $pkgPat) { $r.Pkg = $Matches[1] }
        if ($n.EndsWith('.class')) {
            $r.Classes++
            $cb = ''
            try { $cb = [IO.Path]::GetFileNameWithoutExtension($n) } catch {}
            if ($cb.Length -le 2) { $r.Short++ }
            if ($r.Scanned -lt 2500 -and $e.Length -gt 0 -and $e.Length -lt 1048576) {
                $r.Scanned++
                $st = $e.Open()
                $ms = New-Object IO.MemoryStream
                $st.CopyTo($ms)
                $st.Dispose()
                $t = $lat.GetString($ms.ToArray())
                $ms.Dispose()
                foreach ($m in $termRx.Matches($t)) { $r.Terms[($m.Value.ToLower() -replace ' ', '')] = 1 }
                foreach ($m in $brandRx.Matches($t)) { $r.Brands[($m.Value.ToLower() -replace ' ', '')] = 1 }
            }
        } elseif ($n -match '(?i)^(fabric\.mod\.json|quilt\.mod\.json|mcmod\.info|META-INF/mods\.toml|META-INF/neoforge\.mods\.toml)$' -and $e.Length -lt 65536) {
            $sr = New-Object IO.StreamReader($e.Open())
            $r.Meta = $r.Meta + ' ' + $sr.ReadToEnd()
            $sr.Dispose()
        } elseif ($depth -lt 2 -and $n -match '(?i)\.jar$' -and $e.Length -gt 0 -and $e.Length -lt 31457280 -and $r.Nested -lt 25) {
            $r.Nested++
            try {
                $st = $e.Open()
                $ms = New-Object IO.MemoryStream
                $st.CopyTo($ms)
                $st.Dispose()
                $ms.Position = 0
                $inner = New-Object IO.Compression.ZipArchive($ms, [IO.Compression.ZipArchiveMode]::Read)
                try { Scan-ZipP $inner ($depth + 1) } finally { $inner.Dispose(); $ms.Dispose() }
            } catch {}
        } elseif ($n -match '(?i)\.(json|txt|cfg|toml|properties|yml|yaml)$' -and $e.Length -gt 20 -and $e.Length -lt 262144 -and $r.TextScanned -lt 150) {
            $r.TextScanned++
            try {
                $sr2 = New-Object IO.StreamReader($e.Open())
                $tx = $sr2.ReadToEnd()
                $sr2.Dispose()
                foreach ($m in $termRx.Matches($tx)) { $r.Terms[($m.Value.ToLower() -replace ' ', '')] = 1 }
                foreach ($m in $brandRx.Matches($tx)) { $r.Brands[($m.Value.ToLower() -replace ' ', '')] = 1 }
            } catch {}
        }
    }
}
try {
    $zip = [IO.Compression.ZipFile]::OpenRead($path)
    try { Scan-ZipP $zip 0 } finally { $zip.Dispose() }
} catch {}
if ($r.Classes -ge 20 -and ($r.Short / [double]$r.Classes) -ge 0.6) { $r.Obf = $true }
$r
'@
$jarResults = @{}
$jarJobs = New-Object System.Collections.Generic.List[object]
Write-Host ('   ' + $script:JarCand.Count + ' jar/zip dosyasi paralel taraniyor (sure siniri yok)...') -ForegroundColor DarkGray
$jarPool = $null
try {
    $nTh = [Math]::Max(2, [Math]::Min(6, [Environment]::ProcessorCount))
    $jarPool = [runspacefactory]::CreateRunspacePool(1, $nTh)
    $jarPool.Open()
    foreach ($jq in $script:JarCand) {
        $ps = [powershell]::Create()
        $ps.RunspacePool = $jarPool
        [void]$ps.AddScript($deepJarScript).AddArgument($jq.FullName).AddArgument($script:ModTermPat).AddArgument($script:BrandRx.ToString()).AddArgument($script:PkgRx)
        [void]$jarJobs.Add([pscustomobject]@{ PS = $ps; H = $ps.BeginInvoke(); Path = $jq.FullName })
    }
} catch {}
$jobTotal = $jarJobs.Count
$jobDone = 0
$jobSw = [Diagnostics.Stopwatch]::StartNew()
$timedOutJars = New-Object System.Collections.Generic.List[string]
foreach ($jj in $jarJobs) {
    $jobDone++
    Set-Frac ($jobDone / [Math]::Max(1, $jobTotal)) ('jar/zip ' + $jobDone + '/' + $jobTotal)
    if (($jobDone % 10) -eq 0 -or $jobDone -eq $jobTotal) { Write-Host ('   jar/zip ilerleme: ' + $jobDone + '/' + $jobTotal + ' (' + [int]$jobSw.Elapsed.TotalSeconds + ' sn)') -ForegroundColor DarkGray }
    if (-not $jj.H.AsyncWaitHandle.WaitOne(120000)) {
        [void]$timedOutJars.Add($jj.Path)
        Add-Cov 'Jar/zip 120 sn zaman asimi: TARANAMADI' $jj.Path
        try { [void]$jj.PS.BeginStop($null, $null) } catch {}
        $jarResults[$jj.Path] = @{ Terms = @{}; Brands = @{}; Meta = ''; Plugin = $true; Pkg = ''; Classes = 0; Short = 0; Obf = $false; Nested = 0; TimedOut = $true }
        continue
    }
    try {
        $out = $jj.PS.EndInvoke($jj.H)
        if ($out -and $out.Count -gt 0) {
            $o1 = $out[$out.Count - 1]
            if ($o1 -is [System.Management.Automation.PSObject]) { $o1 = $o1.BaseObject }
            if ($o1 -is [hashtable] -and $o1.ContainsKey('Terms')) { $jarResults[$jj.Path] = $o1 }
        }
    } catch {}
    try { $jj.PS.Dispose() } catch {}
}
if ($jarPool) { try { [void]$jarPool.BeginClose($null, $null) } catch {} }
if ($jobSw) { Add-Perf 'S: jar/zip paralel tarama' $jobSw.Elapsed.TotalSeconds ([string]$jobTotal + ' jar, ' + $timedOutJars.Count + ' zaman asimi') }
foreach ($toj in @($timedOutJars | Select-Object -First 10)) { Log ('   ZAMAN ASIMI (atlandi, elle bak): ' + $toj) 'DarkYellow' }
}
$jdN = 0
$jarIter = $script:JarCand
if ($jarCsOk) { $jarIter = $jarCands; if ($jarAllCands) { $jarIter = $jarAllCands } }
if ($script:JarDup) { foreach ($dk in @($script:JarDup.Keys)) { $rk = $script:JarDup[$dk]; if ($jarResults.ContainsKey($rk) -and -not $jarResults.ContainsKey($dk)) { $jarResults[$dk] = $jarResults[$rk] } } }
$testSeen = $false
foreach ($jf in $jarIter) {
    $jdN++
    $jr = $null
    if ($jarResults.ContainsKey($jf.FullName)) { $jr = $jarResults[$jf.FullName] }
    if (-not $jr) {
        if ($jf.Name -like 'TestHile*') { $testSeen = $true; $null = 0 }
        if ($jarCsOk) { continue }
        $jr = Deep-Jar $jf.FullName
    }
    if ($jr.Plugin) { continue }
    $tl = @($jr.Terms.Keys)
    $bl = @($jr.Brands.Keys)
    if ($jf.Name -like 'TestHile*') { $testSeen = $true; $null = 0 }
    $sc = 0
    $why = New-Object System.Collections.Generic.List[string]
    if ($tl.Count -ge 3) { $sc += 70 } elseif ($tl.Count -eq 2) { $sc += 55 } elseif ($tl.Count -eq 1) { $sc += 30 }
    if ($tl.Count -gt 0) { [void]$why.Add('icerikte hile modulu stringleri (' + $tl.Count + ' adet): ' + ($tl -join ', ')) }
    if ($bl.Count -gt 0) { $sc += 35; [void]$why.Add('icerikte bilinen hile istemcisi ismi: ' + ($bl -join ', ')) }
    if ($jr.Pkg) { $sc += 40; [void]$why.Add('bilinen hile istemcisi paket yolu: ' + $jr.Pkg) }
    if ($jr.Obf) { $sc += 25; [void]$why.Add('obfuscate edilmis gorunuyor (' + $jr.Short + '/' + $jr.Classes + ' sinif adi 1-2 harf)') }
    if ($jr.Nested -gt 0) { [void]$why.Add('ic ice jar: ' + $jr.Nested) }
    if ($jr.TimedOut) { [void]$why.Add('tarama 45 sn sinirina takildi, sonuc kismi'); Add-Cov 'Jar/zip 45 sn sinirina takildi: sonuc KISMI' $jf.FullName }
    $jfp = $jf.FullName
    if ($jr.Enc) { $sc += 25; [void]$why.Add([string]$jr.Enc); Add-ObfNote $jfp ([string]$jr.Enc) }
    if ($jr.BadMagic -gt 0) { $sc += 40; [void]$why.Add('class dosyalarinin ' + $jr.BadMagic + ' tanesi gecersiz (sifreli olabilir)'); Add-ObfNote $jfp ('sifreli/bozuk class dosyasi: ' + $jr.BadMagic) }
    $omk = @($jr.ObfMarks | Where-Object { $_ })
    if ($omk.Count -gt 0) { $sc += 15; [void]$why.Add('obfuscator imzasi: ' + ($omk -join ', ')); Add-ObfNote $jfp ('obfuscator imzasi: ' + ($omk -join ', ')) }
    $nlb = @($jr.Native | Where-Object { $_ })
    if ($nlb.Count -gt 0) { $sc += 10; [void]$why.Add('jar icinde yerel kutuphane: ' + ($nlb -join ', ')); Add-ObfNote $jfp ('jar icinde yerel kutuphane (dll/so): ' + ($nlb -join ', ')) }
    $heb = @($jr.HiEnt | Where-Object { $_ })
    if ($heb.Count -gt 0) { $sc += 15; [void]$why.Add('yuksek entropili veri dosyasi: ' + ($heb -join ', ')); Add-ObfNote $jfp ('yuksek entropili veri dosyasi: ' + ($heb -join ', ')) }
    if ($jr.Obf) { Add-ObfNote $jfp ('obfuscate edilmis (' + $jr.Short + '/' + $jr.Classes + ' sinif adi 1-2 harf)') }
    $mh = Get-NameHit $jr.Meta $false
    if ($mh) { $sc += 40; [void]$why.Add('mod bilgisinde (fabric.mod.json/mcmod.info vb.) hile ismi: ' + $mh.Name) }
    if ($sc -ge 25) {
        Add-F -Kaynak 'Jar/zip icerik taramasi' -Ad ('jar: ' + $jf.Name.ToLower()) -Yol $jf.FullName -Skor ([Math]::Min(100, $sc)) -Son $jf.LastWriteTime -Ilk $jf.CreationTime -Var 'Evet' -Not (($why -join '; ') + ' | NOT: string sifreleme/agir obfuscation kullanan hilelerde class stringleri gorunmez')
    }
}
foreach ($ap in @($script:ArcOther)) {
    $er = ''
    try { $er = [HkJar]::EncInfo($ap) } catch {}
    if ($er) {
        Add-ObfNote $ap $er
        Add-F -Kaynak 'Jar/zip icerik taramasi (sifreli arsiv)' -Ad ('arsiv: ' + (Split-Path -Leaf $ap).ToLower()) -Yol $ap -Skor 35 -Var 'Evet' -Not ($er + ' | icerigi okunamadi, elle ac ve bak')
    }
}
if (-not $testSeen) { $null = 0 }
Log ('   ' + $jdN + ' jar/zip dosyasinin icerigi (ic ice jar dahil) okundu.') 'DarkGray'
Show-Section

# ---------------------------------------------------------------------
Step '[17+/17] T) Bellek taramasi: Java ve kullanici klasorlerinden calisan process lerde hile modul isimleri (hile ACIKKEN calistir)...'
Start-Sec
if (-not $script:HkOk) {
    Log '   yardimci modul derlenemedi, bellek taramasi atlandi.' 'DarkYellow'; Add-Cov 'Bellek tarama motoru derlenemedi: bellek taramasi YAPILMADI' ''
} else {
    try { [void][HkNative]::EnableDebug() } catch {}
    $skipProc = '(?i)^(powershell|pwsh|conhost|WindowsTerminal|chrome|msedge|firefox|opera|brave|discord|code|notepad|explorer|steam|steamwebhelper|OneDrive|Teams|slack|Spotify|devenv|cmd)$'
    $tgts = New-Object System.Collections.Generic.List[object]
    foreach ($gp in @(Get-Process -ErrorAction SilentlyContinue)) {
        if ($gp.Id -le 4 -or $gp.Id -eq $PID) { continue }
        if ($gp.ProcessName -match $skipProc) { continue }
        $pth = ''
        try { $pth = [string]$gp.Path } catch {}
        $isJ = ($gp.ProcessName -match '(?i)^javaw?$')
        if (-not $isJ) {
            if (-not $pth) { continue }
            if ((Get-Zone $pth) -eq 'system') { continue }
            if (Test-Signed $pth) { continue }
        }
        [void]$tgts.Add([pscustomobject]@{ Id = $gp.Id; Name = $gp.ProcessName; Path = $pth; Java = $isJ })
    }
    $tN = 0
    $tgtArr = @()
    try { $tgtArr = @($tgts.ToArray()) } catch { $tgtArr = @() }
    foreach ($t in $tgtArr) {
        $tN++
        $cap = [long]157286400
        if ($t.Java) { $cap = [long]734003200 }
        Log ('   bellek taraniyor: ' + $t.Name + ' (PID ' + $t.Id + ')') 'DarkGray'
        $list = $null
        try { $list = [HkNative]::MemStrings([int]$t.Id, $script:ModTermPat, 5, $true, $true, $false, $cap) } catch { $list = $null }
        if ($null -eq $list) { Add-Cov 'Calisan process bellegi okunamadi (T adimi)' ([string]$t.Name + ' PID ' + $t.Id); continue }
        if ($list.Count -eq 0) { continue }
        $terms = @{}
        foreach ($sx in $list) { Get-Terms $sx $terms }
        $tk = @($terms.Keys)
        if ($tk.Count -eq 0) { continue }
        $sc = 25
        if ($tk.Count -ge 3) { $sc = 70 } elseif ($tk.Count -eq 2) { $sc = 50 }
        if ($t.Java -and $sc -ge 50) { $sc += 10 }
        Add-F -Kaynak 'Bellek stringi: hile modul isimleri' -Ad ('bellek: ' + $t.Name.ToLower() + ' (PID ' + $t.Id + ')') -Yol $t.Path -Skor ([Math]::Min(100, $sc)) -Var 'Evet' -Not ('process belleginde hile modul isimleri: ' + ($tk -join ', ') + ' | Hile bu process icine enjekte edilmis ya da kendisi olabilir; ayni isimler yazili bir sohbet/dokuman da olabilir, process in ne oldugunu kontrol et. Process kapaliysa gorunmez.')
    }
    Log ('   ' + $tN + ' process bellegi tarandi.') 'DarkGray'
}
Show-Section

# ---------------------------------------------------------------------
Step '[17+/17] U) Dosya ICERIK taramasi: exe/dll (JNI, enjektor, modul stringleri) ve ayar dosyalari (cfg/json/toml/txt)...'
Start-Sec
$jniRx = New-Object System.Text.RegularExpressions.Regex ('JNI_GetCreatedJavaVMs|GetCreatedJavaVMs|jvmtiEnv|AttachCurrentThread', [System.Text.RegularExpressions.RegexOptions]::None)
$mcRx = New-Object System.Text.RegularExpressions.Regex ('net/minecraft/client|net\.minecraft\.client|class_310|class_746|Lnet/minecraft/|net/minecraft/class_|com/mojang/blaze3d', [System.Text.RegularExpressions.RegexOptions]::None)
$injRx1 = New-Object System.Text.RegularExpressions.Regex ('WriteProcessMemory', [System.Text.RegularExpressions.RegexOptions]::None)
$injRx2 = New-Object System.Text.RegularExpressions.Regex ('CreateRemoteThread|NtCreateThreadEx|RtlCreateUserThread|QueueUserAPC|SetWindowsHookEx', [System.Text.RegularExpressions.RegexOptions]::None)
$injRx3 = New-Object System.Text.RegularExpressions.Regex ('javaw|java\.exe|Minecraft', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$binCs = @'
using System;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using System.Globalization;
using System.Threading.Tasks;
public class HkBinRes {
    public bool Ok;
    public string[] Terms = new string[0];
    public string[] Brands = new string[0];
    public bool Jni;
    public bool Mc;
    public bool Inj;
    public string PackReason = "";
    public int PackBonus;
}
public static class HkBin {
    static Dictionary<string, Regex> Cache = new Dictionary<string, Regex>();
    static Regex RxPack = new Regex(@"^\.?(upx\d|vmp\d|themida|winlice|enigma\d?|aspack|adata|petite|mpress\d|nsp\d|boom|perplex|pec\d?|yoda|rlpack|kkrunchy|neolite|molebox|obsidium|armadillo|svkp|ezip)", RegexOptions.IgnoreCase | RegexOptions.Compiled);
    static string[] JniN = new string[] { "JNI_GetCreatedJavaVMs", "GetCreatedJavaVMs", "jvmtiEnv", "AttachCurrentThread" };
    static string[] McN = new string[] { "net/minecraft/client", "net.minecraft.client", "class_310", "class_746", "Lnet/minecraft/", "net/minecraft/class_", "com/mojang/blaze3d" };
    static string[] Inj2 = new string[] { "CreateRemoteThread", "NtCreateThreadEx", "RtlCreateUserThread", "QueueUserAPC", "SetWindowsHookEx" };
    static string[] Inj3 = new string[] { "javaw", "java.exe", "Minecraft" };
    static Regex Get(string p) {
        lock (Cache) {
            Regex r;
            if (!Cache.TryGetValue(p, out r)) { r = new Regex(p, RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled); Cache[p] = r; }
            return r;
        }
    }
    static bool Any(string t, string[] nd, StringComparison c) {
        foreach (string s in nd) { if (t.IndexOf(s, c) >= 0) return true; }
        return false;
    }
    static void Harvest(Regex rx, string text, HashSet<string> set) {
        foreach (Match m in rx.Matches(text)) { set.Add(m.Value.ToLowerInvariant().Replace(" ", "")); }
    }
    static double Entropy(byte[] b, int max) {
        if (b == null || b.Length == 0) return 0.0;
        int n = Math.Min(b.Length, max);
        long[] cnt = new long[256];
        for (int i = 0; i < n; i++) cnt[b[i]]++;
        double h = 0.0;
        for (int i = 0; i < 256; i++) {
            if (cnt[i] == 0) continue;
            double p = (double)cnt[i] / n;
            h -= p * Math.Log(p, 2.0);
        }
        return h;
    }
    static List<string> PeSections(byte[] b) {
        List<string> r = new List<string>();
        try {
            if (b == null || b.Length < 256 || b[0] != 0x4D || b[1] != 0x5A) return r;
            int pe = BitConverter.ToInt32(b, 0x3C);
            if (pe < 0 || pe + 24 > b.Length) return r;
            if (b[pe] != 0x50 || b[pe + 1] != 0x45) return r;
            int nsec = BitConverter.ToUInt16(b, pe + 6);
            int optSize = BitConverter.ToUInt16(b, pe + 20);
            int sec = pe + 24 + optSize;
            for (int i = 0; i < nsec && i < 40; i++) {
                int o = sec + i * 40;
                if (o + 8 > b.Length) break;
                r.Add(Encoding.ASCII.GetString(b, o, 8).TrimEnd('\0'));
            }
        } catch { }
        return r;
    }
    static string[] ToArr(HashSet<string> h) { string[] a = new string[h.Count]; h.CopyTo(a); return a; }
    public static HkBinRes ScanBin(string path, Regex term, Regex brand) {
        HkBinRes r = new HkBinRes();
        byte[] b = null;
        try { b = File.ReadAllBytes(path); } catch { return r; }
        if (b == null) return r;
        r.Ok = true;
        string t = Encoding.GetEncoding(28591).GetString(b);
        r.Jni = Any(t, JniN, StringComparison.Ordinal);
        r.Mc = Any(t, McN, StringComparison.Ordinal);
        HashSet<string> tk = new HashSet<string>();
        HashSet<string> bk = new HashSet<string>();
        Harvest(term, t, tk);
        Harvest(brand, t, bk);
        if (b.Length < 8388608) {
            string tu = Encoding.Unicode.GetString(b);
            Harvest(term, tu, tk);
            Harvest(brand, tu, bk);
        }
        r.Inj = (t.IndexOf("WriteProcessMemory", StringComparison.Ordinal) >= 0) && Any(t, Inj2, StringComparison.Ordinal) && Any(t, Inj3, StringComparison.OrdinalIgnoreCase);
        r.Terms = ToArr(tk);
        r.Brands = ToArr(bk);
        if (b.Length >= 4096) {
            List<string> pk = new List<string>();
            foreach (string sn in PeSections(b)) { if (RxPack.IsMatch(sn)) pk.Add(sn); }
            double ent = Entropy(b, 8388608);
            List<string> parts = new List<string>();
            int bonus = 0;
            if (pk.Count > 0) { parts.Add("paketleyici/koruyucu bolum adlari: " + string.Join(", ", pk.ToArray())); bonus = 25; }
            if (ent > 7.4 && b.Length > 200000) { parts.Add("yuksek entropi " + Math.Round(ent, 2).ToString(CultureInfo.InvariantCulture) + " (paketlenmis/sifreli icerik olabilir)"); bonus += 15; }
            if (parts.Count > 0) { r.PackReason = string.Join("; ", parts.ToArray()); r.PackBonus = bonus; }
        }
        return r;
    }
    public static HkBinRes[] ScanBinMany(string[] paths, string termPat, string brandPat, int threads) {
        Regex term = Get(termPat);
        Regex brand = Get(brandPat);
        HkBinRes[] res = new HkBinRes[paths.Length];
        ParallelOptions po = new ParallelOptions();
        po.MaxDegreeOfParallelism = threads;
        Parallel.For(0, paths.Length, po, delegate(int i) {
            try { res[i] = ScanBin(paths[i], term, brand); } catch { res[i] = new HkBinRes(); }
        });
        return res;
    }
    public static HkBinRes[] CfgMany(string[] paths, string termPat, string brandPat, int threads) {
        Regex term = Get(termPat);
        Regex brand = Get(brandPat);
        HkBinRes[] res = new HkBinRes[paths.Length];
        ParallelOptions po = new ParallelOptions();
        po.MaxDegreeOfParallelism = threads;
        Parallel.For(0, paths.Length, po, delegate(int i) {
            HkBinRes r = new HkBinRes();
            try {
                string ct = File.ReadAllText(paths[i]);
                if (!string.IsNullOrEmpty(ct)) {
                    r.Ok = true;
                    HashSet<string> tk = new HashSet<string>();
                    HashSet<string> bk = new HashSet<string>();
                    Harvest(term, ct, tk);
                    Harvest(brand, ct, bk);
                    r.Terms = ToArr(tk);
                    r.Brands = ToArr(bk);
                }
            } catch { }
            res[i] = r;
        });
        return res;
    }
}
'@
$binCsOk = $false
try {
    if (-not ('HkBin' -as [type])) { Add-Type -TypeDefinition $binCs -Language CSharp -ErrorAction Stop }
    $binCsOk = $true
} catch { Log ('   UYARI: paralel icerik tarayici derlenemedi, eski sirali yola donuluyor: ' + $_.Exception.Message) 'DarkYellow' }
$budget = [long]1610612736
$uSw = [Diagnostics.Stopwatch]::StartNew()
$uIdx = 0
$binOrder = @($script:BinCand | Sort-Object @{ Expression = { if ($_.FullName -match $SigRx) { 0 } else { 1 } } }, Length)
$uTotal = $binOrder.Count
$uFastNote = $false
$script:BinSkipped = @()
$script:BinFastList = New-Object System.Collections.Generic.List[object]
function Has-Any([string]$t, [string[]]$needles, [bool]$ic = $false) {
    $cmp = [StringComparison]::Ordinal
    if ($ic) { $cmp = [StringComparison]::OrdinalIgnoreCase }
    foreach ($nd in $needles) { if ($t.IndexOf($nd, $cmp) -ge 0) { return $true } }
    return $false
}
$uN = 0
if ($binCsOk) {
    $uList = New-Object System.Collections.Generic.List[object]
    foreach ($bf in $binOrder) {
        $pth = $bf.FullName
        if ((Get-Zone $pth) -eq 'system') { continue }
        if ($bf.Name.ToLower() -match $knownNat) { continue }
        if ($bf.Length -gt 12582912 -and (Test-Signed $pth)) { Add-Cov 'Imzali buyuk (>12 MB) exe/dll: icerik taranmadi' $bf.FullName; continue }
        [void]$uList.Add($bf)
    }
    $uArr = $uList.ToArray()
    $uThr = [Math]::Max(2, [Math]::Min(4, [Environment]::ProcessorCount))
    Log ('   ' + $uArr.Count + ' exe/dll paralel taraniyor (' + $uThr + ' is parcacigi, sure siniri yok)...') 'DarkGray'
    for ($ci = 0; $ci -lt $uArr.Count; $ci += 16) {
        $hi = [Math]::Min($ci + 15, $uArr.Count - 1)
        $chunkP = [string[]]@($uArr[$ci..$hi] | ForEach-Object { $_.FullName })
        $res = $null
        try { $res = [HkBin]::ScanBinMany($chunkP, $script:ModTermPat, $script:BrandRx.ToString(), $uThr) } catch {}
        $dn = $ci + $chunkP.Count
        Set-Frac ($dn / [Math]::Max(1, $uArr.Count)) ('exe/dll ' + $dn + '/' + $uArr.Count)
        if (($dn % 64) -lt 16 -or $dn -ge $uArr.Count) { Write-Host ('   exe/dll ilerleme: ' + $dn + '/' + $uArr.Count + ' (' + [int]$uSw.Elapsed.TotalSeconds + ' sn)') -ForegroundColor DarkGray }
        if (-not $res) { continue }
        for ($k = 0; $k -lt $chunkP.Count; $k++) {
            $x = $res[$k]
            if (-not $x -or -not $x.Ok) { continue }
            $bf = $uArr[$ci + $k]
            $pth = $bf.FullName
            $uN++
            $tk = @($x.Terms)
            $bk = @($x.Brands)
            $sc = 0
            $why = New-Object System.Collections.Generic.List[string]
            if ($tk.Count -ge 3) { $sc += 70 } elseif ($tk.Count -eq 2) { $sc += 50 } elseif ($tk.Count -eq 1) { $sc += 25 }
            if ($tk.Count -gt 0) { [void]$why.Add('icerikte hile modulu stringleri: ' + ($tk -join ', ')) }
            if ($bk.Count -gt 0) { $sc += 35; [void]$why.Add('icerikte bilinen hile istemcisi ismi: ' + ($bk -join ', ')) }
            if ($x.Jni -and $x.Mc) { $sc += 40; [void]$why.Add('Minecraft sinif adlari + JNI/JVMTI: Java disindan oyuna baglanan program/DLL') }
            if ($x.Inj) { $sc += 45; [void]$why.Add('enjektor belirtileri (WriteProcessMemory + uzak thread + javaw/Minecraft)') }
            if ($x.PackReason) { $sc += $x.PackBonus; [void]$why.Add($x.PackReason) }
            if ($sc -lt 25) { continue }
            $sig = Test-Signed $pth
            if ($x.PackReason -and -not $sig) { Add-ObfNote $pth $x.PackReason }
            if ($sig -and $tk.Count -lt 3) { continue }
            $sg = 'imzasiz'
            if ($sig) { $sg = 'imzali' }
            Add-F -Kaynak 'Dosya icerik taramasi (exe/dll)' -Ad $bf.Name.ToLower() -Yol $pth -Skor ([Math]::Min(100, $sc)) -Son $bf.LastWriteTime -Ilk $bf.CreationTime -Var 'Evet' -Not (($why -join '; ') + ' | ' + $sg + ' | icerik: dosyanin ham baytlari (Latin1 + UTF-16) tarandi')
        }
    }
} else {
foreach ($bf in $binOrder) {
    # (sure siniri kaldirildi)
    if ($budget -le 0) { Log '   exe/dll okuma butcesi (1.5 GB) doldu, kalan dosyalar atlandi.' 'DarkYellow'; $script:BinSkipped = @($binOrder[$uIdx..($binOrder.Count - 1)]); break }
    # (sure siniri kaldirildi)
    $uIdx++
    Set-Frac ($uIdx / [Math]::Max(1, $uTotal)) ('exe/dll ' + $uIdx + '/' + $uTotal)
    if (($uIdx % 25) -eq 0) { Write-Host ('   exe/dll ilerleme: ' + $uIdx + '/' + $uTotal + ' (' + [int]$uSw.Elapsed.TotalSeconds + ' sn)') -ForegroundColor DarkGray }
    $pth = $bf.FullName
    if ((Get-Zone $pth) -eq 'system') { continue }
    if ($bf.Name.ToLower() -match $knownNat) { continue }
    if ($bf.Length -gt 12582912 -and (Test-Signed $pth)) { Add-Cov 'Imzali buyuk (>12 MB) exe/dll: icerik taranmadi' $bf.FullName; continue }
    $b = $null
    try { $b = [IO.File]::ReadAllBytes($pth) } catch { continue }
    if ($null -eq $b) { continue }
    $budget -= $b.Length
    $uN++
    $t = [Text.Encoding]::GetEncoding(28591).GetString($b)
    $isJni = Has-Any $t @('JNI_GetCreatedJavaVMs', 'GetCreatedJavaVMs', 'jvmtiEnv', 'AttachCurrentThread')
    $isMc = Has-Any $t @('net/minecraft/client', 'net.minecraft.client', 'class_310', 'class_746', 'Lnet/minecraft/', 'net/minecraft/class_', 'com/mojang/blaze3d')
    $terms = @{}
    $brands = @{}
    # Buyuk (4 MB ustu) dosyalarda agir modul/marka regex i sadece Minecraft/Java ile iliskili izler varsa calisir
    $mcRel = ($isJni -or $isMc -or (Has-Any $t @('minecraft', 'javaw', 'lwjgl', 'glfw', 'jvmti') $true))
    $fullMode = ($uSw.Elapsed.TotalSeconds -lt 150 -and ((Get-Date) - $Started).TotalSeconds -lt 420)
    if (-not $fullMode -and -not $uFastNote) {
        $uFastNote = $true
        Log '   sure butcesi nedeniyle buyuk dosyalarda hizli moda gecildi (Minecraft/Java izi olmayan 4 MB ustu dosyalarda modul stringi artik aranmiyor).' 'DarkYellow'
    }
    if ($b.Length -lt 4194304 -or $mcRel -or $fullMode) {
        Get-Terms $t $terms
        Get-Brands $t $brands
        if ($b.Length -lt 8388608) {
            $tu = [Text.Encoding]::Unicode.GetString($b)
            Get-Terms $tu $terms
            Get-Brands $tu $brands
        }
    } else {
        [void]$script:BinFastList.Add($bf)
    }
    $isInj = ((Has-Any $t @('WriteProcessMemory')) -and (Has-Any $t @('CreateRemoteThread', 'NtCreateThreadEx', 'RtlCreateUserThread', 'QueueUserAPC', 'SetWindowsHookEx')) -and (Has-Any $t @('javaw', 'java.exe', 'Minecraft') $true))
    $tk = @($terms.Keys)
    $bk = @($brands.Keys)
    $sc = 0
    $why = New-Object System.Collections.Generic.List[string]
    if ($tk.Count -ge 3) { $sc += 70 } elseif ($tk.Count -eq 2) { $sc += 50 } elseif ($tk.Count -eq 1) { $sc += 25 }
    if ($tk.Count -gt 0) { [void]$why.Add('icerikte hile modulu stringleri: ' + ($tk -join ', ')) }
    if ($bk.Count -gt 0) { $sc += 35; [void]$why.Add('icerikte bilinen hile istemcisi ismi: ' + ($bk -join ', ')) }
    if ($isJni -and $isMc) { $sc += 40; [void]$why.Add('Minecraft sinif adlari + JNI/JVMTI: Java disindan oyuna baglanan program/DLL') }
    if ($isInj) { $sc += 45; [void]$why.Add('enjektor belirtileri (WriteProcessMemory + uzak thread + javaw/Minecraft)') }
    $pk = Get-PackInfo $b
    if ($pk.Reason) { $sc += $pk.Bonus; [void]$why.Add($pk.Reason) }
    if ($sc -lt 25) { continue }
    $sig = Test-Signed $pth
    if ($pk.Reason -and -not $sig) { Add-ObfNote $pth $pk.Reason }
    if ($sig -and $tk.Count -lt 3) { continue }
    $sg = 'imzasiz'
    if ($sig) { $sg = 'imzali' }
    Add-F -Kaynak 'Dosya icerik taramasi (exe/dll)' -Ad $bf.Name.ToLower() -Yol $pth -Skor ([Math]::Min(100, $sc)) -Son $bf.LastWriteTime -Ilk $bf.CreationTime -Var 'Evet' -Not (($why -join '; ') + ' | ' + $sg + ' | icerik: dosyanin ham baytlari (Latin1 + UTF-16) tarandi')
}
}
Log ('   ' + $uN + ' exe/dll icerigi okundu.') 'DarkGray'

$cfN = 0
$cfgTestSeen = $false
$cfSw = [Diagnostics.Stopwatch]::StartNew()
$cfAll = $script:CfgCand.ToArray()
$cfIdx = 0
$script:CfgSkipped = @()
if ($binCsOk) {
    $cfPaths = [string[]]@($cfAll | ForEach-Object { $_.FullName })
    $cfThr = [Math]::Max(2, $script:HkThr)
    for ($ci = 0; $ci -lt $cfPaths.Count; $ci += 64) {
        $hi = [Math]::Min($ci + 63, $cfPaths.Count - 1)
        $chunkP = [string[]]@($cfPaths[$ci..$hi])
        $res = $null
        try { $res = [HkBin]::CfgMany($chunkP, $script:ModTermPat, $script:BrandRx.ToString(), $cfThr) } catch {}
        Set-Frac (($ci + $chunkP.Count) / [Math]::Max(1, $cfPaths.Count)) ('ayar dosyasi ' + ($ci + $chunkP.Count) + '/' + $cfPaths.Count)
        if (-not $res) { continue }
        for ($k = 0; $k -lt $chunkP.Count; $k++) {
            $x = $res[$k]
            if (-not $x -or -not $x.Ok) { continue }
            $cf = $cfAll[$ci + $k]
            $cfN++
            $tk = @($x.Terms)
            $bk = @($x.Brands)
            if ($cf.Name -like 'TestHile*') { $cfgTestSeen = $true; $null = 0 }
            $sc = 0
            if ($tk.Count -ge 3) { $sc = 60 } elseif ($tk.Count -eq 2) { $sc = 45 }
            if ($bk.Count -gt 0) { $sc += 35 }
            if ($sc -lt 35) { continue }
            $nt = 'ayar dosyasi icinde'
            if ($tk.Count -gt 0) { $nt = $nt + ' hile modulu isimleri: ' + ($tk -join ', ') }
            if ($bk.Count -gt 0) { $nt = $nt + ' | istemci ismi: ' + ($bk -join ', ') }
            Add-F -Kaynak 'Ayar dosyasi icerik taramasi' -Ad $cf.Name.ToLower() -Yol $cf.FullName -Skor ([Math]::Min(100, $sc)) -Son $cf.LastWriteTime -Ilk $cf.CreationTime -Var 'Evet' -Not ($nt + ' | hile istemcileri modul ayarlarini (acik/kapali, tus) boyle dosyalara yazar; ayri bir mesru program da olabilir')
        }
    }
} else {
foreach ($cf in $cfAll) {
    # (sure siniri kaldirildi)
    $cfIdx++
    $ct = $null
    try { $ct = [IO.File]::ReadAllText($cf.FullName) } catch { continue }
    if (-not $ct) { continue }
    $cfN++
    $terms = @{}
    $brands = @{}
    Get-Terms $ct $terms
    Get-Brands $ct $brands
    $tk = @($terms.Keys)
    $bk = @($brands.Keys)
    if ($cf.Name -like 'TestHile*') { $cfgTestSeen = $true; $null = 0 }
    $sc = 0
    if ($tk.Count -ge 3) { $sc = 60 } elseif ($tk.Count -eq 2) { $sc = 45 }
    if ($bk.Count -gt 0) { $sc += 35 }
    if ($sc -lt 35) { continue }
    $nt = 'ayar dosyasi icinde'
    if ($tk.Count -gt 0) { $nt = $nt + ' hile modulu isimleri: ' + ($tk -join ', ') }
    if ($bk.Count -gt 0) { $nt = $nt + ' | istemci ismi: ' + ($bk -join ', ') }
    Add-F -Kaynak 'Ayar dosyasi icerik taramasi' -Ad $cf.Name.ToLower() -Yol $cf.FullName -Skor ([Math]::Min(100, $sc)) -Son $cf.LastWriteTime -Ilk $cf.CreationTime -Var 'Evet' -Not ($nt + ' | hile istemcileri modul ayarlarini (acik/kapali, tus) boyle dosyalara yazar; ayri bir mesru program da olabilir')
}
}
if (-not $cfgTestSeen) { $null = 0 }
Log ('   ' + $cfN + ' ayar/metin dosyasinin icerigi okundu.') 'DarkGray'
Show-Section

# ---------------------------------------------------------------------
Invoke-NameDeep

# =====================================================================
# MEOW ARACLARI (her biri ayri adim). Not: araclarin kendi ic mantigi bilinmiyor; her adim aracin tanimina gore
# bu scriptteki mevcut motorlarla (bellek taramasi, USN, kayit defteri, mod envanteri) yapilir.
# =====================================================================
function Invoke-FocusMem([string]$Rx, [bool]$IncludeSvc, [bool]$JavaOnly = $true) {
    $res = New-Object System.Collections.Generic.List[object]
    if (-not $script:HkOk) { Log '   yardimci modul derlenemedi, bellek taramasi atlandi.' 'DarkYellow'; Add-Cov 'Bellek tarama motoru derlenemedi: Meow bellek adimi YAPILMADI' ''; return $res }
    try { [void][HkNative]::EnableDebug() } catch {}
    $fxProcs = New-Object System.Collections.Generic.List[object]
    foreach ($gp in @(Get-Process -ErrorAction SilentlyContinue)) {
        if ($gp.Id -le 4 -or $gp.Id -eq $PID) { continue }
        if ($gp.ProcessName -match '(?i)^javaw?$') { [void]$fxProcs.Add([pscustomobject]@{ Id = $gp.Id; Name = $gp.ProcessName; Java = $true; Path = '' }) }
    }
    if ($IncludeSvc) {
        foreach ($svn in @('DcomLaunch', 'DPS', 'PcaSvc')) {
            $sv = $null
            try { $sv = Get-CimInstance Win32_Service -Filter ("Name='" + $svn + "'") -ErrorAction Stop } catch {}
            if ($sv -and [int]$sv.ProcessId -gt 4) { [void]$fxProcs.Add([pscustomobject]@{ Id = [int]$sv.ProcessId; Name = ('svchost (' + $svn + ')'); Java = $false; Path = '' }) }
        }
    }
    foreach ($t in @($fxProcs.ToArray())) {
        $cap = [long]157286400
        if ($t.Java) { $cap = [long]734003200 }
        Log ('   bellek taraniyor: ' + $t.Name + ' (PID ' + $t.Id + ')') 'DarkGray'
        $list = $null
        try { $list = [HkNative]::MemStrings([int]$t.Id, $Rx, 5, $true, $true, $false, $cap) } catch { $list = $null }
        if ($null -eq $list) { Add-Cov 'Meow bellek adimi: process bellegi okunamadi' ([string]$t.Name + ' PID ' + $t.Id); continue }
        $terms = @{}
        foreach ($sx in $list) { foreach ($mm in [regex]::Matches([string]$sx, $Rx)) { $terms[$mm.Value.ToLower().Trim()] = 1 } }
        if ($terms.Count -gt 0) { [void]$res.Add([pscustomobject]@{ Proc = $t; Terms = @($terms.Keys) }) }
    }
    return $res
}
function Show-FocusFindings([string]$Rx, [string]$Baslik) {
    # Diger adimlarda bu istemciyle ilgili bulunan tum izleri tek yerde ozetler
    $fh = @($script:HkFnd | Where-Object { ([string]$_.Ad + ' ' + [string]$_.Yol + ' ' + [string]$_.Not) -match $Rx -and $_.Kaynak -notmatch '^Meow' })
    if ($fh.Count -eq 0) { Log ('   ' + $Baslik + ': diger adimlarda iz bulunmadi.') 'DarkGray'; return }
    $fs = @($fh | ForEach-Object { $_.Kaynak } | Select-Object -Unique)
    $sc = [Math]::Min(90, 40 + 10 * $fs.Count)
    $ex = @($fh | Select-Object -First 5 | ForEach-Object { $_.Ad + ' [' + $_.Kaynak + ']' }) -join ' ; '
    Add-Sys ($Baslik + ': diger adimlarda ' + $fh.Count + ' iz (' + $fs.Count + ' farkli kaynak)') $sc ('Ornekler: ' + $ex) $null 'ozet'
}

Step '[17+/17] X2) MeowClientFucker mantigi: Java belleginde bilinen hile istemcisi markalari + tum adimlardaki marka izleri...'
Start-Sec
$fxBrandRx = '(?:' + $script:ClientRx.ToString() + ')|(?:' + $script:CamelRx.ToString() + ')|(?:' + $script:ExtraRx.ToString() + ')'
foreach ($fh in @(Invoke-FocusMem $fxBrandRx $true)) {
    $fsc = 25
    $fdist = @($fh.Terms | ForEach-Object { ([string]$_ -replace '[ _\-\.]', '') } | Select-Object -Unique)
    if ($fdist.Count -ge 3) { $fsc = 65 } elseif ($fdist.Count -eq 2) { $fsc = 45 }
    if (-not $fh.Proc.Java) { $fsc = [Math]::Min(80, $fsc + 15) }
    $fnt = 'process belleginde istemci markalari: ' + (@($fh.Terms | Select-Object -First 12) -join ', ')
    if ($fh.Proc.Java -and $fdist.Count -eq 1) { $fnt = $fnt + ' (tek marka; sohbet/sunucu adi olabilir, DOGRULA)' }
    Add-F -Kaynak 'MeowClient: bellek' -Ad ('istemci markasi bellek: ' + $fh.Proc.Name.ToLower() + ' (PID ' + $fh.Proc.Id + ')') -Yol ('PID ' + $fh.Proc.Id) -Skor $fsc -Var 'Evet' -Not $fnt
}
foreach ($ur in @($script:UsnRecent | Where-Object { $script:ClientRx.IsMatch([string]$_.Ad) -or $script:CamelRx.IsMatch([string]$_.Ad) -or $script:ExtraRx.IsMatch([string]$_.Ad) } | Select-Object -First 20)) {
    Add-F -Kaynak 'MeowClient: NTFS gunlugu' -Ad ([string]$ur.Ad).ToLower() -Yol ([string]$ur.Surucu) -Skor 55 -Son $ur.Zaman -Var 'Hayir' -Silinme $ur.Zaman -Not 'NTFS (USN) gunlugunda istemci adli dosya silinme/degisim kaydi'
}
Show-FocusFindings $fxBrandRx 'Istemci markalari'
Show-Section

Step '[17+/17] X3) MeowNovowareFucker mantigi: RAM (Java/DcomLaunch) + NTFS gunlugu (silinen dosyalar) ile Novoware...'
Start-Sec
$fxRx = '(?i)novo[ _\-]?ware'
foreach ($fh in @(Invoke-FocusMem $fxRx $true)) {
    $fsc = 70
    $fnt = 'process belleginde: ' + ($fh.Terms -join ', ')
    if ($fh.Proc.Java) { $fsc = 45; $fnt = $fnt + ' (oyun sohbetinde yazilmis olabilir; tek basina kesin degil)' }
    Add-F -Kaynak 'MeowNovoware: bellek' -Ad ('novoware bellek: ' + $fh.Proc.Name.ToLower() + ' (PID ' + $fh.Proc.Id + ')') -Yol ('PID ' + $fh.Proc.Id) -Skor $fsc -Var 'Evet' -Not $fnt
}
foreach ($ur in @($script:UsnRecent | Where-Object { [string]$_.Ad -match $fxRx } | Select-Object -First 20)) {
    Add-F -Kaynak 'MeowNovoware: NTFS gunlugu' -Ad ([string]$ur.Ad).ToLower() -Yol ([string]$ur.Surucu) -Skor 65 -Son $ur.Zaman -Var 'Hayir' -Silinme $ur.Zaman -Not 'NTFS (USN) gunlugunda Novoware adli dosya silinme/degisim kaydi'
}
Show-FocusFindings $fxRx 'Novoware'
Show-Section

Step '[17+/17] X4) Meow Resolver mantigi: adli bilisimi engelleyen kayit defteri politikalari ve olay gunlugu manipulasyonlari...'
Start-Sec
$fxRegChecks = @(
    @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat', 'DisableInventory', 1, 'Amcache envanteri politikayla kapatilmis', 45),
    @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat', 'DisablePCA', 1, 'Program Uyumluluk Yardimcisi (PCA) kapatilmis', 35),
    @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat', 'AITEnable', 0, 'Uygulama telemetrisi kapatilmis', 25),
    @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat', 'DisableUAR', 1, 'Adim kaydedici kapatilmis', 15),
    @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced', 'Start_TrackProgs', 0, 'Program calistirma takibi (UserAssist) kapatilmis', 40),
    @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced', 'Start_TrackDocs', 0, 'Son belge takibi kapatilmis', 25),
    @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer', 'NoRecentDocsHistory', 1, 'Son belge gecmisi politikayla kapatilmis', 35),
    @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer', 'ClearRecentDocsOnExit', 1, 'Cikista son belgeler siliniyor', 40),
    @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer', 'NoInstrumentation', 1, 'Kullanici izleme kapatilmis', 30),
    @('HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore', 'DisableSR', 1, 'Sistem geri yukleme kapatilmis', 25)
)
$fxN = 0
foreach ($fc in $fxRegChecks) {
    $fv = $null
    try { $fv = (Get-ItemProperty -LiteralPath $fc[0] -Name $fc[1] -ErrorAction Stop).($fc[1]) } catch { $fv = $null }
    if ($null -ne $fv -and [int]$fv -eq [int]$fc[2]) { $fxN++; Add-Sys $fc[3] $fc[4] ('Kayit defteri: ' + $fc[0] + ' | ' + $fc[1] + ' = ' + $fv) $null 'ayarli' }
}
foreach ($ln in @('Security', 'System', 'Application', 'Microsoft-Windows-PowerShell/Operational', 'Microsoft-Windows-TaskScheduler/Operational', 'Microsoft-Windows-Windows Defender/Operational', 'Microsoft-Windows-Kernel-PnP/Device Configuration')) {
    $lg = $null
    try { $lg = Get-WinEvent -ListLog $ln -ErrorAction Stop } catch { $lg = $null }
    if (-not $lg) { continue }
    if (-not $lg.IsEnabled) { $fxN++; Add-Sys ('Olay gunlugu kapatilmis: ' + $ln) 40 'Bu olay gunlugu kaydi devre disi birakilmis (adli iz azaltma).' $null 'kapali'; continue }
    $rc = [int64]0
    try { $rc = [int64]$lg.RecordCount } catch {}
    if ($rc -eq 0 -and $ln -match '^(Security|System|Application)$') { $fxN++; Add-Sys ('Olay gunlugu bos: ' + $ln) 45 'Normalde dolu olan bu gunluk bos: yakin zamanda temizlenmis olabilir.' $null 'bos'; continue }
    if ([int64]$lg.MaximumSizeInBytes -lt 1048576) { $fxN++; Add-Sys ('Olay gunlugu cok kucuk: ' + $ln) 30 ('Maksimum boyut ' + [int]([int64]$lg.MaximumSizeInBytes / 1KB) + ' KB: eski kayitlar hizla silinir.') $null 'kucuk' }
}
Log ('   ' + $fxN + ' adli bilisim engelleyici ayar/olay gunlugu manipulasyonu bulundu (bypass adimlari 1 ve I ayrica calisti).') 'DarkGray'
Show-Section

Step '[17+/17] X5) Meow Mod Analizer mantigi: mod klasoru ozeti, populer mod adini taklit edenler, yeni dogrulanamayan modlar...'
Start-Sec
$fxLegit = 'sodium|lithium|iris|fabric-?api|modmenu|optifine|xaero|journeymap|jei|roughlyenoughitems|emi|replaymod|litematica|malilib|tweakeroo|minihud|itemscroller|worldedit|voicechat|continuity|indium|ferritecore|krypton|entityculling|starlight|immediatelyfast|dynamic-?fps|mousetweaks|appleskin|cloth-?config|architectury|yacl|fabric-language-kotlin|lazydfu|memoryleakfix|moreculling|c2me|noisium|sodium-?extra|reeses|bettercombat|ambientsounds|essential'
$fxInv = @($script:ModInv)
$fxUnv = @($fxInv | Where-Object { $_.Dogrulama -eq 'hash dogrulanamadi' })
$fxSus = @($fxInv | Where-Object { [string]$_.Sonuc -like 'SUPHELI*' })
$fxRecent = @($fxUnv | Where-Object { $_.Tarih -gt (Get-Date).AddDays(-14) })
Log ('   mod ozeti: ' + $fxInv.Count + ' mod | hash dogrulanamayan: ' + $fxUnv.Count + ' | supheli: ' + $fxSus.Count + ' | son 14 gunde degisen ve dogrulanamayan: ' + $fxRecent.Count) 'DarkGray'
if ($script:MmNet) {
    foreach ($fm in $fxUnv) {
        if ([string]$fm.Ad -match ('(?i)^(' + $fxLegit + ')[-_ .0-9+]')) {
            Add-F -Kaynak 'Meow Mod Analizer: populer mod adini tasiyor' -Ad ('mod: ' + ([string]$fm.Ad).ToLower()) -Yol $fm.Yol -Skor 40 -Son $fm.Tarih -Var 'Evet' -Not 'Populer bir mod adini tasiyor ama Modrinth/Megabase te birebir hash eslesmesi yok: degistirilmis veya sahte olabilir (eski/ozel surum de olabilir, incele)'
        }
    }
} else { Log '   ag kapali/erisilemedi: taklit mod kontrolu yapilamadi.' 'DarkYellow' }
foreach ($fm in $fxRecent) {
    Add-F -Kaynak 'Meow Mod Analizer: yeni dogrulanamayan mod' -Ad ('mod: ' + ([string]$fm.Ad).ToLower()) -Yol $fm.Yol -Skor 22 -Son $fm.Tarih -Var 'Evet' -Not 'Son 14 gunde eklenen/degisen ve hash i bilinen bir mod olmayan jar'
}
Show-Section

Step '[17+/17] X6) Meow Imports Checker mantigi: .bat/.cmd/.vbs/.ps1 calistirma kalintilari ve icerik kontrolu (adli bilisim temizleme/enjeksiyon komutlari)...'
Start-Sec
$fxBadRx = New-Object System.Text.RegularExpressions.Regex ('javaw?(\.exe)?\s+.*-jar|taskkill|wevtutil\s+cl|fsutil\s+usn\s+deletejournal|vssadmin\s+delete|reg\s+delete|attrib\s+\+h|powershell.*-enc|-executionpolicy\s+bypass|clear-eventlog|del\s+/[fq]|rmdir\s+/s|certutil.*-urlcache|bitsadmin|mshta|schtasks\s+/create|sc\s+(stop|delete)|net\s+stop|add-mppreference.*exclusion|disableantispyware|bcdedit.*testsigning', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$fxSN = 0
foreach ($sf in @($script:ScriptCand.ToArray() | Sort-Object LastWriteTime -Descending)) {
    $fxSN++
    $stxt = ''
    try { $stxt = [IO.File]::ReadAllText($sf.FullName) } catch { continue }
    if (-not $stxt) { continue }
    if ($stxt.Length -gt 200000) { $stxt = $stxt.Substring(0, 200000) }
    $kw = @{}
    foreach ($km in $fxBadRx.Matches($stxt)) { $kw[$km.Value.ToLower().Trim()] = 1; if ($kw.Count -ge 8) { break } }
    if ($kw.Count -eq 0) { continue }
    $ssc = [Math]::Min(70, 25 + 10 * ($kw.Count - 1))
    if ($sf.LastWriteTime -gt (Get-Date).AddDays(-7)) { $ssc += 10 }
    Add-F -Kaynak 'Meow Imports Checker: script dosyasi' -Ad $sf.Name.ToLower() -Yol $sf.FullName -Skor $ssc -Son $sf.LastWriteTime -Ilk $sf.CreationTime -Var 'Evet' -Not ('icerikte: ' + (@($kw.Keys | Select-Object -First 8) -join ' | '))
}
Log ('   ' + $fxSN + ' script dosyasi (.bat/.cmd/.vbs/.ps1/.hta/.wsf) incelendi.') 'DarkGray'
Show-Section

# =====================================================================
# BIRLESTIRME (ayni dosya adi birden fazla kaynakta gorunuyorsa guven artar)
# =====================================================================
$merged = New-Object System.Collections.Generic.List[object]
$all = @($script:HkFnd.ToArray())
foreach ($g in ($all | Group-Object -Property Ad)) {
    $items = @($g.Group)
    $mx = 0
    foreach ($i in $items) { if ($i.Skor -gt $mx) { $mx = $i.Skor } }
    $srcs = @($items | ForEach-Object { $_.Kaynak } | Select-Object -Unique)
    $bonus = [Math]::Min(30, 10 * ($srcs.Count - 1))
    $skor = [Math]::Min(100, $mx + $bonus)
    $var = 'Bilinmiyor'
    $yol = $items[0].Yol
    $ev = @($items | Where-Object { $_.Var -eq 'Evet' })
    $hy = @($items | Where-Object { $_.Var -eq 'Hayir' })
    if ($ev.Count -gt 0) { $var = 'Evet'; $yol = $ev[0].Yol } elseif ($hy.Count -gt 0) { $var = 'Hayir'; $yol = $hy[0].Yol }
    $sonList = @($items | Where-Object { $_.Son } | ForEach-Object { [datetime]$_.Son })
    $ilkList = @($items | Where-Object { $_.Ilk } | ForEach-Object { [datetime]$_.Ilk })
    $silList = @($items | Where-Object { $_.Silinme } | ForEach-Object { [datetime]$_.Silinme })
    $son = $null
    $ilk = $null
    $sil = $null
    if ($sonList.Count -gt 0) { $son = ($sonList | Sort-Object -Descending | Select-Object -First 1) }
    if ($ilkList.Count -gt 0) { $ilk = ($ilkList | Sort-Object | Select-Object -First 1) }
    if ($silList.Count -gt 0) { $sil = ($silList | Sort-Object -Descending | Select-Object -First 1) }
    $notes = @($items | ForEach-Object { $_.Not } | Where-Object { $_ } | Select-Object -Unique)
    if ($var -eq 'Hayir' -and -not $sil) {
        $k = ([string]$g.Name).ToLower()
        if ($script:UsnDel.ContainsKey($k)) { $sil = $script:UsnDel[$k]; $notes += 'silinme zamani USN gunlugunden' }
        if (-not $sil) {
            foreach ($bi in $script:BinItems) {
                $bl = ''
                try { $bl = (Split-Path -Leaf $bi.Orijinal).ToLower() } catch {}
                if ($bl -eq $k -and $bi.Silinme) { $sil = $bi.Silinme; $notes += 'silinme zamani geri donusum kutusu kaydindan'; break }
            }
        }
    }
    $allBenign = (@($items | Where-Object { -not $_.Benign }).Count -eq 0)
    [void]$merged.Add([pscustomobject]@{ Ad = $g.Name; Yol = $yol; Skor = $skor; Var = $var; Son = $son; Ilk = $ilk; Silinme = $sil; Kaynaklar = ($srcs -join ', '); Not = ($notes -join ' ; '); Benign = $allBenign })
}
$ranked = @($merged | Sort-Object -Property @{ Expression = 'Skor'; Descending = $true }, @{ Expression = 'Son'; Descending = $true })
$high = @($ranked | Where-Object { $_.Skor -ge 60 })
$mid = @($ranked | Where-Object { $_.Skor -ge 40 -and $_.Skor -lt 60 })
$low = @($ranked | Where-Object { $_.Skor -lt 40 })
$total = $ranked.Count

# =====================================================================
# SONUC EKRANI
# =====================================================================
Log '' 'Gray'
Log '===================================================================' 'Green'
Log '  SONUC - HileKiran' 'Green'
Log '===================================================================' 'Green'
if ($total -gt 0) {
    $ph = [Math]::Round(100 * $high.Count / $total)
    $pm = [Math]::Round(100 * $mid.Count / $total)
    $pl = 100 - $ph - $pm
    Log ('  Toplam bulgu: ' + $total) 'White'
    Log ('   %' + $ph + ' YUKSEK guven (' + $high.Count + ')  - buyuk ihtimalle gercek, incele') 'Red'
    Log ('   %' + $pm + ' ORTA guven   (' + $mid.Count + ')  - suphe var, tarih/yola bak') 'Yellow'
    Log ('   %' + $pl + ' DUSUK guven  (' + $low.Count + ')  - buyuk ihtimalle yanlis alarm (sonda TAM LISTE bolumunde)') 'DarkGray'
    Log '  (Yuzdeler tahmini dagilimdir, kesin dogruluk orani DEGILDIR.)' 'DarkGray'
} else {
    Log '  Hicbir bulgu yok.' 'Green'
}

Log '' 'Gray'
Log '--- BYPASS TESPITI (iz saklama/temizleme, servis ve ayar durumlari) ---' 'Yellow'
if ($script:Sys.Count -eq 0) { Log '   Uyari yok: Prefetch, servisler, olay gunlukleri, USN gunlugu, Defender ayarlari, zamanlanmis gorevler normal gorunuyor.' 'Green' }
foreach ($s in ($script:Sys | Sort-Object -Property Skor -Descending)) {
    $zt = ''
    if ($s.Zaman) { $zt = '  [olay zamani: ' + (Fmt $s.Zaman) + ']' }
    Log ('   [%' + $s.Skor + '] ' + $s.Baslik + $zt) 'Yellow'
    Log ('        ' + $s.Aciklama) 'DarkGray'
    if ($s.Durum) { Log ('        Durum          : ' + $s.Durum) 'DarkGray' }
    if ($s.Degisim) { Log ('        Son elle degisim: ' + (Fmt $s.Degisim)) 'DarkGray' }
}

Log '' 'Gray'
Log '--- YUKSEK GUVENLI BULGULAR ---' 'Red'
if ($high.Count -eq 0) { Log '   Yok.' 'Green' }
foreach ($m in $high) { Show-Item $m 'Red' }

Log '' 'Gray'
Log '--- ORTA GUVENLI BULGULAR ---' 'Yellow'
if ($mid.Count -eq 0) { Log '   Yok.' 'Green' }
foreach ($m in $mid) {
    $d2 = 'DURUYOR'
    if ($m.Var -eq 'Hayir') { $d2 = 'SILINMIS' }
    if ($m.Var -eq 'Bilinmiyor') { $d2 = '?' }
    Log ('   [%' + $m.Skor + '] ' + $m.Ad + ' | ' + $d2 + ' | son: ' + (Fmt $m.Son) + ' | ' + $m.Yol) 'Yellow'
}

Log '' 'Gray'
Log '--- CALISTIRILIP SONRA SILINEN PROGRAMLAR (en yeniden eskiye) ---' 'Magenta'
$delProg = @($ranked | Where-Object { $_.Var -eq 'Hayir' -and $_.Kaynaklar -match 'BAM|Prefetch|UserAssist|Amcache|Shimcache|Jump|Recent|Geri' -and -not $_.Benign } | Sort-Object -Property @{ Expression = 'Son'; Descending = $true })
if ($delProg.Count -eq 0) { Log '   Yok.' 'Green' }
foreach ($m in ($delProg | Select-Object -First 25)) {
    $sz = 'silinme zamani bilinmiyor'
    if ($m.Silinme) { $sz = 'silindi: ' + (Fmt $m.Silinme) }
    Log ('   ' + $m.Ad + '  | son calisma: ' + (Fmt $m.Son) + ' | ' + $sz) 'Magenta'
    Log ('        yer: ' + $m.Yol) 'DarkGray'
}
if ($delProg.Count -gt 25) { Log ('   ... ve ' + ($delProg.Count - 25) + ' tane daha (sonda TAM LISTE bolumunde).') 'DarkGray' }

Log '' 'Gray'
Log '--- GERI DONUSUM KUTUSU ---' 'Cyan'
foreach ($bs2 in $script:BinState) { Log ('   ' + $bs2) 'Gray' }
foreach ($kv in $script:BinEmptied.GetEnumerator()) { Log ('   ' + $kv.Key + ' en son bosaltma/kalici silme (USN kaydi): ' + (Fmt $kv.Value)) 'Cyan' }
if ($script:BinEmptied.Count -eq 0) { Log '   USN gunlugunde kutu bosaltma kaydi bulunamadi (kayit eski/yok olabilir).' 'DarkGray' }
$binX = @($script:BinItems | Where-Object { $_.Orijinal -match '(?i)\.(exe|jar|rar|zip|7z|bat|ps1|scr)$' } | Sort-Object -Property @{ Expression = 'Silinme'; Descending = $true } | Select-Object -First 10)
foreach ($bi in $binX) { Log ('   kutuda: ' + $bi.Orijinal + '  (silindi: ' + (Fmt $bi.Silinme) + ')') 'Gray' }

Log '' 'Gray'
Log '--- SON 30 GUNDE SILINEN exe/jar/zip/rar/7z (USN gunlugu, en yeni 15) ---' 'Cyan'
$ur = @($script:UsnRecent | Where-Object { $_.Ad -notmatch '^(~\$|\$)' } | Sort-Object -Property @{ Expression = 'Zaman'; Descending = $true } | Select-Object -First 15)
if ($ur.Count -eq 0) { Log '   Kayit yok.' 'DarkGray' }
foreach ($u in $ur) { Log ('   ' + (Fmt $u.Zaman) + '  ' + $u.Ad + '  (' + $u.Surucu + ')') 'Gray' }

Log '' 'Gray'
Log '--- USB DEPOLAMA GECMISI ---' 'Cyan'
if ($script:UsbList.Count -eq 0) { Log '   Kayit yok.' 'DarkGray' }
foreach ($u in $script:UsbList) { Log ('   ' + $u.Ad + '  | ilk baglanti: ' + (Fmt $u.Ilk) + ' | son kayit: ' + (Fmt $u.Son)) 'Gray' }

Log '' 'Gray'
Log '--- CALISAN JAVA (Minecraft) ---' 'Cyan'
if ($script:JavaInfo.Count -eq 0) { Log '   Su an calisan Java yok. Hile acikken/Minecraft acikken tekrar calistirirsan enjeksiyon kontrolu de yapilir.' 'DarkGray' }
foreach ($j in $script:JavaInfo) { Log ('   ' + $j) 'Gray' }

Log '' 'Gray'
Log '--- BU ARACIN GOREMEDIGI SEYLER (durust sinirlar) ---' 'DarkGray'
Log '   * Bellekte (RAM) calisan hilelerin tamami: sadece secili process stringleri taranir; korumali (PPL) process ler (csrss, MsMpEng, SgrmBroker) okunamaz. DMA/ikinci PC gibi donanim hileleri gorulmez' 'DarkGray'
Log '   * Adi ve icerigi listede olmayan, obfuscate edilmis ozel (private) hileler' 'DarkGray'
Log '   * Kesin silinme zamani: sadece USN gunlugunde kaydi varsa bulunur (gunluk eskirse kaybolur)' 'DarkGray'
Log '   * Bu bir kanit degil, incelenecek ipuclari listesidir; dosyayi acip elle dogrula.' 'DarkGray'

# tam liste sadece rapor dosyasina
Log '' 'Gray' $true
Log '=================== TAM LISTE (tum bulgular) ===================' 'Gray' $true
foreach ($m in $ranked) { Show-Item $m 'Gray' $true }
Log '' 'Gray' $true
Log '=================== SON 30 GUN SILINENLER (USN, tumu) ===================' 'Gray' $true
foreach ($u in ($script:UsnRecent | Sort-Object -Property @{ Expression = 'Zaman'; Descending = $true } | Select-Object -First 300)) { Log ('   ' + (Fmt $u.Zaman) + '  ' + $u.Ad + '  (' + $u.Surucu + ')') 'Gray' $true }

if ($script:StepName) { [void]$script:StepTimes.Add([pscustomobject]@{ Ad = $script:StepName; Sn = [int]((Get-Date) - $script:StepT0).TotalSeconds }) }
Log '' 'Gray'
Log 'Adim sureleri (en uzundan):' 'Cyan'
foreach ($stt in @($script:StepTimes | Sort-Object Sn -Descending | Select-Object -First 12)) {
    $stn = [string]$stt.Ad
    if ($stn.Length -gt 95) { $stn = $stn.Substring(0, 95) }
    Log ('   ' + $stt.Sn + ' sn   ' + $stn) 'Gray'
}
$el = [int]((Get-Date) - $Started).TotalSeconds
Log '' 'Gray'
Log ('Tarama suresi: ' + $el + ' sn.') 'Cyan'

Show-ObfSummary
if ($uSw) { Add-Perf 'U: exe/dll icerik taramasi' $uSw.Elapsed.TotalSeconds ([string]$uTotal + ' aday') }
if ($cfSw) { Add-Perf 'U: ayar/metin dosyasi taramasi' $cfSw.Elapsed.TotalSeconds ([string]@($cfAll).Count + ' aday') }
foreach ($dx in @($script:BinSkipped)) { if ($dx) { Add-Cov 'exe/dll: sure/butce siniri nedeniyle ATLANDI' $dx.FullName } }
$bflArr = @()
try { $bflArr = @($script:BinFastList.ToArray()) } catch { $bflArr = @() }
foreach ($dx in $bflArr) { if ($dx) { Add-Cov 'exe/dll: hizli modda gecildi (tam taranmadi)' $dx.FullName } }
foreach ($dx in @($script:CfgSkipped)) { if ($dx) { Add-Cov 'ayar/metin dosyasi: sure siniri nedeniyle ATLANDI' $dx.FullName } }
$dBin = New-Object System.Collections.Generic.List[object]
foreach ($dx in @($script:BinSkipped)) { if ($dx) { [void]$dBin.Add($dx) } }
foreach ($dx in $bflArr) { [void]$dBin.Add($dx) }
$dCfg = @($script:CfgSkipped)
if (($dBin.Count + $dCfg.Count) -gt 0) {
    function Scan-BinDeferred($bf) {
        $pth = $bf.FullName
        if ((Get-Zone $pth) -eq 'system') { return }
        if ($bf.Name.ToLower() -match $knownNat) { return }
        if ($bf.Length -gt 12582912 -and (Test-Signed $pth)) { Add-Cov 'Imzali buyuk (>12 MB) exe/dll: icerik taranmadi' $bf.FullName; return }
        $b = $null
        try { $b = [IO.File]::ReadAllBytes($pth) } catch { return }
        if ($null -eq $b) { return }
        $t = [Text.Encoding]::GetEncoding(28591).GetString($b)
        $isJni = Has-Any $t @('JNI_GetCreatedJavaVMs', 'GetCreatedJavaVMs', 'jvmtiEnv', 'AttachCurrentThread')
        $isMc = Has-Any $t @('net/minecraft/client', 'net.minecraft.client', 'class_310', 'class_746', 'Lnet/minecraft/', 'net/minecraft/class_', 'com/mojang/blaze3d')
        $isInj = ((Has-Any $t @('WriteProcessMemory')) -and (Has-Any $t @('CreateRemoteThread', 'NtCreateThreadEx', 'RtlCreateUserThread', 'QueueUserAPC', 'SetWindowsHookEx')) -and (Has-Any $t @('javaw', 'java.exe', 'Minecraft') $true))
        $terms = @{}
        $brands = @{}
        Get-Terms $t $terms
        Get-Brands $t $brands
        if ($b.Length -lt 8388608) {
            $tu = [Text.Encoding]::Unicode.GetString($b)
            Get-Terms $tu $terms
            Get-Brands $tu $brands
        }
        $tk = @($terms.Keys)
        $bk = @($brands.Keys)
        $sc = 0
        $why = New-Object System.Collections.Generic.List[string]
        if ($tk.Count -ge 3) { $sc += 70 } elseif ($tk.Count -eq 2) { $sc += 50 } elseif ($tk.Count -eq 1) { $sc += 25 }
        if ($tk.Count -gt 0) { [void]$why.Add('icerikte hile modulu stringleri: ' + ($tk -join ', ')) }
        if ($bk.Count -gt 0) { $sc += 35; [void]$why.Add('icerikte bilinen hile istemcisi ismi: ' + ($bk -join ', ')) }
        if ($isJni -and $isMc) { $sc += 40; [void]$why.Add('Minecraft sinif adlari + JNI/JVMTI: Java disindan oyuna baglanan program/DLL') }
        if ($isInj) { $sc += 45; [void]$why.Add('enjektor belirtileri (WriteProcessMemory + uzak thread + javaw/Minecraft)') }
        $pk = Get-PackInfo $b
        if ($pk.Reason) { $sc += $pk.Bonus; [void]$why.Add($pk.Reason) }
        if ($sc -lt 25) { return }
        $sig = Test-Signed $pth
        if ($pk.Reason -and -not $sig) { Add-ObfNote $pth $pk.Reason }
        if ($sig -and $tk.Count -lt 3) { return }
        $sg = 'imzasiz'
        if ($sig) { $sg = 'imzali' }
        Add-F -Kaynak 'Dosya icerik taramasi (exe/dll, sonradan)' -Ad $bf.Name.ToLower() -Yol $pth -Skor ([Math]::Min(100, $sc)) -Son $bf.LastWriteTime -Ilk $bf.CreationTime -Var 'Evet' -Not (($why -join '; ') + ' | ' + $sg + ' | icerik: dosyanin ham baytlari tam modda tarandi')
    }
    function Scan-CfgDeferred($cf) {
        $ct = $null
        try { $ct = [IO.File]::ReadAllText($cf.FullName) } catch { return }
        if (-not $ct) { return }
        $terms = @{}
        $brands = @{}
        Get-Terms $ct $terms
        Get-Brands $ct $brands
        $tk = @($terms.Keys)
        $bk = @($brands.Keys)
        if ($cf.Name -like 'TestHile*') { $null = 0 }
        $sc = 0
        if ($tk.Count -ge 3) { $sc = 60 } elseif ($tk.Count -eq 2) { $sc = 45 }
        if ($bk.Count -gt 0) { $sc += 35 }
        if ($sc -lt 35) { return }
        $nt = 'ayar dosyasi icinde'
        if ($tk.Count -gt 0) { $nt = $nt + ' hile modulu isimleri: ' + ($tk -join ', ') }
        if ($bk.Count -gt 0) { $nt = $nt + ' | istemci ismi: ' + ($bk -join ', ') }
        Add-F -Kaynak 'Ayar dosyasi icerik taramasi (sonradan)' -Ad $cf.Name.ToLower() -Yol $cf.FullName -Skor ([Math]::Min(100, $sc)) -Son $cf.LastWriteTime -Ilk $cf.CreationTime -Var 'Evet' -Not ($nt + ' | hile istemcileri modul ayarlarini boyle dosyalara yazar; ayri bir mesru program da olabilir')
    }
    Log '' 'Gray'
    Log ('Sure siniri nedeniyle ATLANAN / HIZLI MODDA gecilen dosyalar: ' + $dBin.Count + ' exe/dll, ' + $dCfg.Count + ' ayar/metin dosyasi.') 'Yellow'
    $dAns = Read-Host 'Simdi bunlar da (sure siniri olmadan) taransin mi? Birkac dakika surebilir (E/H)'
    if ($dAns -match '^[eE]') {
        Start-Sec
        $dSw = [Diagnostics.Stopwatch]::StartNew()
        $dI = 0
        foreach ($dx in $dBin) {
            $dI++
            Set-Frac ($dI / [Math]::Max(1, $dBin.Count)) ('exe/dll (sonradan) ' + $dI + '/' + $dBin.Count)
            if (($dI % 25) -eq 0 -or $dI -eq $dBin.Count) { Write-Host ('   exe/dll (sonradan) ilerleme: ' + $dI + '/' + $dBin.Count + ' (' + [int]$dSw.Elapsed.TotalSeconds + ' sn)') -ForegroundColor DarkGray }
            try { Scan-BinDeferred $dx } catch {}
        }
        $dI = 0
        foreach ($dx in $dCfg) {
            $dI++
            Set-Frac ($dI / [Math]::Max(1, $dCfg.Count)) ('ayar dosyasi (sonradan) ' + $dI + '/' + $dCfg.Count)
            if (($dI % 200) -eq 0 -or $dI -eq $dCfg.Count) { Write-Host ('   ayar dosyasi (sonradan) ilerleme: ' + $dI + '/' + $dCfg.Count + ' (' + [int]$dSw.Elapsed.TotalSeconds + ' sn)') -ForegroundColor DarkGray }
            try { Scan-CfgDeferred $dx } catch {}
        }
        Log '' 'Gray'
        Log 'SONRADAN TARANAN DOSYALARIN SONUCU:' 'Cyan'
        Show-Section
    } else {
        Log 'Atlanan dosyalar taranmadi.' 'DarkGray'
    }
}
if (($dBin.Count + $dCfg.Count) -eq 0) { Log 'Sure siniri nedeniyle atlanan dosya yok, bu yuzden atlananlari tarama sorusu cikmadi.' 'DarkGray' }
# =====================================================================
# EK ASAMALAR 21-32: sosyal medyada paylasilan SS arac listesindeki araclarin yaptigi analizlerin en yakin karsiliklari (hepsi sadece OKUR)
# =====================================================================
function Initialize-XPaths {
    if ($script:XPaths) { return }
    $res = New-Object System.Collections.Generic.List[string]
    $hs = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($root in @($script:ScanRoots)) {
        if (-not $root) { continue }
        $st = New-Object System.Collections.Generic.Stack[string]
        $st.Push([string]$root)
        while ($st.Count -gt 0) {
            $d = $st.Pop()
            try { foreach ($f in [IO.Directory]::GetFiles($d)) { if ($hs.Add($f)) { [void]$res.Add($f) } } } catch {}
            try {
                foreach ($sd in [IO.Directory]::GetDirectories($d)) {
                    if ([IO.Path]::GetFileName($sd) -match $pruneRx) { continue }
                    try { if (([IO.File]::GetAttributes($sd) -band [IO.FileAttributes]::ReparsePoint) -ne 0) { continue } } catch { continue }
                    $st.Push($sd)
                }
            } catch {}
        }
    }
    $script:XPaths = $res
    Log ('   ortak dosya listesi: ' + $res.Count + ' dosya yolu') 'DarkGray'
}
function Read-TailLines([string]$p, [int]$n, [string]$rx = '') {
    $q = New-Object System.Collections.Generic.Queue[string]
    try {
        $fs = [IO.File]::Open($p, 'Open', 'Read', 'ReadWrite')
        $sr = New-Object IO.StreamReader($fs)
        while ($true) {
            $ln = $sr.ReadLine()
            if ($null -eq $ln) { break }
            if ($rx -and $ln -notmatch $rx) { continue }
            $q.Enqueue($ln)
            if ($q.Count -gt $n) { [void]$q.Dequeue() }
        }
        $sr.Dispose(); $fs.Dispose()
    } catch {}
    return @($q.ToArray())
}
$script:NonAsciiRx = New-Object System.Text.RegularExpressions.Regex ('[^\x00-\x7F]')
function Test-UniOdd([string]$n) {
    $hasLat = $false; $hasOth = $false; $odd = ''; $why = New-Object System.Collections.Generic.List[string]
    $len = $n.Length
    for ($i = 0; $i -lt $len; $i++) {
        $c = [int]$n[$i]
        if ($c -lt 128) { if (($c -ge 65 -and $c -le 90) -or ($c -ge 97 -and $c -le 122)) { $hasLat = $true }; continue }
        if (($c -ge 0x200B -and $c -le 0x200F) -or ($c -ge 0x202A -and $c -le 0x202E) -or ($c -ge 0x2060 -and $c -le 0x2064) -or $c -eq 0xFEFF -or $c -eq 0x00AD -or $c -eq 0x3164 -or $c -eq 0x2800 -or $c -eq 0x115F -or $c -eq 0x1160 -or $c -eq 0x180E -or ($c -ge 0x2066 -and $c -le 0x206F) -or $c -eq 0x00A0 -or $c -eq 0x2007 -or $c -eq 0x202F -or $c -eq 0x205F -or $c -eq 0x3000 -or $c -eq 0x1680 -or $c -eq 0x034F -or ($c -ge 0xFE00 -and $c -le 0xFE0F)) { return ('gorunmez/bosluk/yon kontrol karakteri U+' + $c.ToString('X4')) }
        if ($c -eq 0x202E) { return 'RLO (sagdan sola) uzanti hilesi' }
        if (($c -ge 0x0400 -and $c -le 0x04FF) -or ($c -ge 0x0370 -and $c -le 0x03FF) -or ($c -ge 0x0530 -and $c -le 0x058F) -or ($c -ge 0x13A0 -and $c -le 0x13FF)) { $hasOth = $true; $odd = 'Kiril/Yunan/Ermeni/Cherokee'; continue }
        if ($c -ge 0xFF01 -and $c -le 0xFF5E) { $hasOth = $true; $odd = 'tam genislikli'; continue }
        if (($c -ge 0x0250 -and $c -le 0x02FF) -or ($c -ge 0x1D00 -and $c -le 0x1DBF) -or ($c -ge 0x2100 -and $c -le 0x214F) -or ($c -ge 0x24B6 -and $c -le 0x24E9)) { $hasOth = $true; $odd = 'IPA/modifiye/daire/harf benzeri sembol'; continue }
        if ($c -ge 0xD835 -and $c -le 0xD835 -and ($i + 1) -lt $len) { $hasOth = $true; $odd = 'matematiksel alfanumerik (kalin/italik harf)'; $i++; continue }
        if ($c -ge 0x0300 -and $c -le 0x036F) { [void]$why.Add('birlestirici isaret U+' + $c.ToString('X4')); continue }
        if ($c -ge 0xE000 -and $c -le 0xF8FF) { return ('ozel kullanim alani karakteri U+' + $c.ToString('X4')) }
        if ($c -ge 0xFFF0 -and $c -le 0xFFFF) { return ('gecersiz/ozel karakter U+' + $c.ToString('X4')) }
    }
    if ($hasLat -and $hasOth) { return ('Latin harflerle karisik ' + $odd + ' karakter (benzer karakter hilesi)') }
    if ($hasOth -and $n -match '(?i)\.(exe|dll|jar|bat|cmd|ps1|vbs|scr|lnk)$') { return ('tamamen ' + $odd + ' karakterli calistirilabilir/jar dosya adi') }
    if ($why.Count -gt 0) { return ($why[0] + ' (gorunmez birlestirici/aksan, ' + $why.Count + ' adet)') }
    if ($n -match '[ \.]+$') { return 'dosya adi bosluk veya nokta ile bitiyor' }
    if ($n -match '(?i)\.(jpg|jpeg|png|gif|txt|pdf|docx?|mp4|mp3|zip)\s*\.(exe|jar|bat|cmd|scr|vbs|ps1|dll)$') { return 'cift uzanti hilesi' }
    return ''
}

# ---- 21) Shellbag Analyzer & Cleaner ----
Step '[17+/17] 21) Shellbag Analyzer & Cleaner: ShellBags temizleme izleri ve arac kalintilari...'
Start-Sec
try {
    Initialize-XPaths
    foreach ($sbr in @('HKCU:\Software\Microsoft\Windows\Shell\BagMRU', 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU')) {
        if (-not (Test-Path -LiteralPath $sbr)) { Add-Sys ('ShellBags anahtari YOK: ' + $sbr) 35 'ShellBags kaydi silinmis olabilir (Shellbag Cleaner).'; continue }
        $sbk = Get-Item -LiteralPath $sbr -ErrorAction Ignore
        if (-not $sbk) { continue }
        $kt = Get-KeyTime $sbk
        if ($sbk.SubKeyCount -lt 3) { Add-Sys ('ShellBags (BagMRU) neredeyse bos: ' + $sbk.SubKeyCount + ' alt anahtar') 45 'Kullanilan bir Windows da normalde onlarca klasor kaydi bulunur; temizlenmis olabilir.' $null $sbr $kt }
        elseif ($kt -and $kt -gt (Get-Date).AddDays(-2)) { Add-Sys 'ShellBags anahtari son 2 gun icinde yazilmis' 10 'Normal gezinmeyle de olur; temizleyici calistirildiysa da boyle gorunur.' $null $sbr $kt }
    }
    $sbRx = New-Object System.Text.RegularExpressions.Regex ('(?i)^(shellbags?(explorer|view|analyzer|cleaner)?|sbecmd|sbe|shellbag.*)\.(exe|zip|rar|7z)$')
    foreach ($p in $script:XPaths) { $lf = [IO.Path]::GetFileName($p); if ($sbRx.IsMatch($lf)) { Add-F -Kaynak 'Shellbag arac izi' -Ad $lf.ToLower() -Yol $p -Skor 30 -Var 'Evet' -Not 'ShellBags analiz/temizleme araci dosyasi' } }
} catch {}
Show-Section

# ---- 22) Unicode ----
Step '[17+/17] 22) Unicode: gorunmez / benzer karakterli dosya, klasor ve jar ici adlari...'
Start-Sec
try {
    Initialize-XPaths
    $uniDirs = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($p in $script:XPaths) {
        $lf = [IO.Path]::GetFileName($p)
        $dn = [IO.Path]::GetDirectoryName($p)
        if ($dn -and $script:NonAsciiRx.IsMatch($dn) -and $uniDirs.Add($dn)) {
            $dl = [IO.Path]::GetFileName($dn)
            $dwhy = ''
            if ($dl) { $dwhy = Test-UniOdd $dl }
            if ($dwhy) { Add-F -Kaynak 'Unicode analizi (klasor adi)' -Ad $dl.ToLower() -Yol $dn -Skor 45 -Var 'Evet' -Not ('klasor adi: ' + $dwhy) }
        }
        $why = ''
        if ($script:NonAsciiRx.IsMatch($lf)) { $why = Test-UniOdd $lf }
        elseif ($lf -match '[ \.]+$|(?i)\.(jpg|jpeg|png|gif|txt|pdf|docx?|mp4|mp3|zip)\s*\.(exe|jar|bat|cmd|scr|vbs|ps1|dll)$') { $why = Test-UniOdd $lf }
        if ($why) {
            $sc = 40
            if ($lf -match '(?i)\.(exe|dll|jar|bat|cmd|ps1|vbs|scr|lnk)$') { $sc = 65 }
            if ($why -match 'RLO|yon kontrol|gorunmez') { $sc = [Math]::Min(85, $sc + 15) }
            Add-F -Kaynak 'Unicode analizi' -Ad $lf.ToLower() -Yol $p -Skor $sc -Var 'Evet' -Not $why
        }
    }
    # jar/zip icindeki sinif ve dosya adlari (gizlenmis class adlari)
    $uj = 0
    foreach ($p in $script:XPaths) {
        if (-not $p.EndsWith('.jar', [StringComparison]::OrdinalIgnoreCase)) { continue }
        if ($uj -ge 600) { break }
        $zip = $null
        try {
            $zip = [IO.Compression.ZipFile]::OpenRead($p)
            $uj++
            $uh = New-Object System.Collections.Generic.List[string]
            foreach ($e in $zip.Entries) {
                $fn = [string]$e.FullName
                if (-not $script:NonAsciiRx.IsMatch($fn)) { continue }
                $w = Test-UniOdd $fn
                if ($w -and $uh.Count -lt 8) { [void]$uh.Add($fn + '  <- ' + $w) }
            }
            if ($uh.Count -gt 0) { Add-F -Kaynak 'Unicode analizi (jar ici)' -Ad ('jar: ' + [IO.Path]::GetFileName($p).ToLower()) -Yol $p -Skor ([Math]::Min(85, 50 + 5 * $uh.Count)) -Var 'Evet' -Not ('JAR ICINDE UNICODE ADLI CLASS/DOSYALAR (' + $uh.Count + '): ' + ($uh -join ' | ')) }
        } catch {} finally { if ($zip) { $zip.Dispose() } }
    }
    # Son kullanilan (Recent) ve prefetch adlari
    foreach ($rd in @(($env:APPDATA + '\Microsoft\Windows\Recent'), ($env:WINDIR + '\Prefetch'))) {
        foreach ($rf in @(Get-ChildItem -LiteralPath $rd -Force -ErrorAction Ignore | Select-Object -First 3000)) {
            if (-not $script:NonAsciiRx.IsMatch($rf.Name)) { continue }
            $w = Test-UniOdd $rf.Name
            if ($w) { Add-F -Kaynak 'Unicode analizi (Recent/Prefetch)' -Ad $rf.Name.ToLower() -Yol $rf.FullName -Skor 45 -Son $rf.LastWriteTime -Var 'Bilinmiyor' -Not $w }
        }
    }
} catch {}
Show-Section

# ---- 23) PathsParser ----
Step '[17+/17] 23) PathsParser: MuiCache / Uyumluluk / BAM yollari (silinmis program izleri)...'
Start-Sec
try {
    $ppSeen = @{}
    $ppKeys = New-Object System.Collections.Generic.List[string]
    [void]$ppKeys.Add('HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache')
    [void]$ppKeys.Add('HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\Store')
    [void]$ppKeys.Add('HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers')
    foreach ($bk in @(Get-ChildItem -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings' -ErrorAction Ignore)) { [void]$ppKeys.Add($bk.PSPath) }
    foreach ($pk in $ppKeys) {
        $kk = Get-Item -LiteralPath $pk -ErrorAction Ignore
        if (-not $kk) { continue }
        foreach ($vn in $kk.GetValueNames()) {
            if ($vn -notmatch '^[A-Za-z]:\\') { continue }
            $pth = ($vn -replace '\.(FriendlyAppName|ApplicationCompany)$', '')
            $lk = $pth.ToLower()
            if ($ppSeen.ContainsKey($lk)) { continue }
            $ppSeen[$lk] = 1
            $pi = Test-PathInfo $pth
            Eval-Exec -Kaynak 'PathsParser' -Path $pth -Exists $pi.Exists -Removed $pi.Removed -Note ('kayit: ' + ($pk -replace '^.*::', ''))
        }
    }
    Log ('   ' + $ppSeen.Count + ' benzersiz yol incelendi.') 'DarkGray'
} catch {}
Show-Section

# ---- 24) Echo ----
Step '[17+/17] 24) Echo: son 3 gunde calisan programlar ve imzasiz calisan process ler...'
Start-Sec
try {
    $pfDir = $env:WINDIR + '\Prefetch'
    $pfN = 0
    foreach ($pf in @(Get-ChildItem -LiteralPath $pfDir -Filter '*.pf' -File -Force -ErrorAction Ignore)) {
        if ($pf.LastWriteTime -lt (Get-Date).AddDays(-3)) { continue }
        $pfN++
        $pn = ($pf.BaseName -replace '-[0-9A-Fa-f]{8}$', '')
        $h = Get-NameHit $pn $true
        if ($h) { $sc = 30; if (-not $h.Weak) { $sc = 55 }; Add-F -Kaynak 'Echo: yakin zamanda calisan program' -Ad $pn.ToLower() -Yol $pf.FullName -Skor $sc -Son $pf.LastWriteTime -Var 'Bilinmiyor' -Not ('son 3 gunde calistirilmis, isim eslesmesi: ' + $h.Name) }
    }
    Log ('   son 3 gunde ' + $pfN + ' Prefetch kaydi incelendi.') 'DarkGray'
    $pcN = 0
    foreach ($gp in @(Get-Process -ErrorAction Ignore)) {
        $pth = ''
        try { $pth = [string]$gp.Path } catch {}
        if (-not $pth) { continue }
        if ($pth -match '(?i)^[A-Za-z]:\\(Windows|Program Files|Program Files \(x86\)|ProgramData\\Microsoft)\\') { continue }
        $pcN++
        if (-not (Test-Signed $pth)) {
            $zn = Get-Zone $pth
            $sc = 20; if ($zn -eq 'user' -or $zn -eq 'temp') { $sc = 40 }
            Add-F -Kaynak 'Echo: imzasiz calisan process' -Ad ($gp.ProcessName.ToLower() + ' (PID ' + $gp.Id + ')') -Yol $pth -Skor $sc -Var 'Evet' -Not 'calisan process in dosyasi dijital olarak imzasiz'
        }
    }
    Log ('   ' + $pcN + ' sistem disi process incelendi.') 'DarkGray'
} catch {}
Show-Section

# ---- 26-28 icin ortak jar gecisi (Meow*Fucker mantigi: istemci ailesi imzalari) + Luyten icin URL toplama ----
$script:FamDone = $false
function Scan-FamJars {
    if ($script:FamDone) { return }
    $script:FamDone = $true
    $script:FamHits = @{ Client = (New-Object System.Collections.Generic.List[object]); Novoware = (New-Object System.Collections.Generic.List[object]) }
    $script:UrlHits = New-Object System.Collections.Generic.List[object]
    $rxN = New-Object System.Text.RegularExpressions.Regex ('(?i)novo[ _\-]?ware')
    $rxInj = New-Object System.Text.RegularExpressions.Regex ('(?i)doomsdayclient\.com|found minecraft processes|advanced inject|select (?:a )?minecraft process|inject(?:ing)? (?:into|to) minecraft|doomsday ?(?:client|inject)|novaclient\.lol|official site: ?[a-z0-9\-]+client\.(?:com|net|xyz|lol|gg|dev)')
    $rxU = New-Object System.Text.RegularExpressions.Regex ('(?i)https?://[A-Za-z0-9._~:/?#@%&=+\-]{6,120}')
    $jarSet = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $jars = New-Object System.Collections.Generic.List[string]
    foreach ($p in $script:XPaths) { if ($p.EndsWith('.jar', [StringComparison]::OrdinalIgnoreCase) -and $jarSet.Add($p)) { [void]$jars.Add($p) } }
    foreach ($jc in @($script:JarCand)) { $p = [string]$jc.FullName; if ($p -and $jarSet.Add($p)) { [void]$jars.Add($p) } }
    foreach ($mj in @($mmJars)) { $p = [string]$mj.FullName; if ($p -and $jarSet.Add($p)) { [void]$jars.Add($p) } }
    Log ('   ' + $jars.Count + ' jar icerigi istemci ailesi imzalari ve URL ler icin taraniyor...') 'DarkGray'
    $lat = [Text.Encoding]::GetEncoding(28591)
    $jn = 0
    foreach ($p in $jars) {
        $jn++
        if (($jn % 100) -eq 0) { Set-Frac ($jn / [Math]::Max(1, $jars.Count)) ('jar ' + $jn + '/' + $jars.Count); Write-Host ('   jar ilerleme: ' + $jn + '/' + $jars.Count) -ForegroundColor DarkGray }
        $len = 0
        try { $len = (New-Object IO.FileInfo $p).Length } catch { continue }
        if ($len -gt 157286400 -or $len -lt 30) { continue }
        $zip = $null
        try {
            $zip = [IO.Compression.ZipFile]::OpenRead($p)
            $names = [string]::Join("`n", [string[]]@($zip.Entries.FullName))
            $ev = @{ Inj = $false; Client = (New-Object System.Collections.Generic.List[string]); Novoware = (New-Object System.Collections.Generic.List[string]) }
            foreach ($en0 in $zip.Entries) {
                $fn0 = [string]$en0.FullName
                $m = $rxN.Match($fn0); if ($m.Success -and $ev.Novoware.Count -lt 6) { [void]$ev.Novoware.Add($fn0 + '  <- DOSYA ADINDA: ' + $m.Value) }
                if ($ev.Client.Count -lt 6) {
                    $m = $script:BrandRx.Match($fn0); if (-not $m.Success) { $m = $script:ClientRx.Match($fn0) }; if (-not $m.Success) { $m = $script:CamelRx.Match($fn0) }; if (-not $m.Success) { $m = $script:ExtraRx.Match($fn0) }
                    if ($m.Success) { [void]$ev.Client.Add($fn0 + '  <- DOSYA ADINDA: ' + $m.Value) }
                }
            }
            $cls = 0
            $urls = New-Object 'System.Collections.Generic.HashSet[string]'
            foreach ($e in $zip.Entries) {
                $en = $e.FullName
                $isCls = $en.EndsWith('.class')
                $isMeta = ($en -match '(?i)^(fabric\.mod\.json|quilt\.mod\.json|mcmod\.info|META-INF/mods\.toml|META-INF/neoforge\.mods\.toml|META-INF/MANIFEST\.MF)$') -or ($en -match '(?i)\.(properties|fxml|json|txt|html?|xml|css|cfg|ini|lang)$' -and $e.Length -le 262144)
                if (-not $isCls -and -not $isMeta) { continue }
                if ($isCls -and $cls -ge 120) { continue }
                if ($e.Length -le 0 -or $e.Length -gt 1048576) { continue }
                if ($isCls) { $cls++ }
                $st = $e.Open()
                $ms = New-Object IO.MemoryStream
                $st.CopyTo($ms)
                $st.Dispose()
                $t = $lat.GetString($ms.ToArray())
                $ms.Dispose()
                $m = $rxInj.Match($t); if ($m.Success -and $ev.Client.Count -lt 6) { [void]$ev.Client.Add($en + '  <- ENJEKTOR/YUKLEYICI YAZISI: ' + $m.Value); $ev.Inj = $true }
                if ($ev.Novoware.Count -lt 6) { $m = $rxN.Match($t); if ($m.Success) { [void]$ev.Novoware.Add($en + '  <- ICERIKTE: ' + $m.Value) } }
                if ($ev.Client.Count -lt 6) {
                    $m = $script:BrandRx.Match($t); if (-not $m.Success) { $m = $script:ClientRx.Match($t) }; if (-not $m.Success) { $m = $script:ExtraRx.Match($t) }
                    if ($m.Success) { [void]$ev.Client.Add($en + '  <- ICERIKTE: ' + $m.Value) }
                }
                if ($urls.Count -lt 40) { foreach ($um in $rxU.Matches($t)) { if ($urls.Count -lt 40) { [void]$urls.Add($um.Value) } } }
            }
            if ($ev.Client.Count -gt 0) { [void]$script:FamHits.Client.Add([pscustomobject]@{ Path = $p; Why = ('HILE BULUNAN CLASS/DOSYALAR (' + $ev.Client.Count + '): ' + ($ev.Client -join ' | ')); N = $(if ($ev.Inj) { 4 } else { $ev.Client.Count }) }) }
            if ($ev.Novoware.Count -gt 0) { [void]$script:FamHits.Novoware.Add([pscustomobject]@{ Path = $p; Why = ('HILE BULUNAN CLASS/DOSYALAR (' + $ev.Novoware.Count + '): ' + ($ev.Novoware -join ' | ')); N = $ev.Novoware.Count }) }
            foreach ($u in $urls) {
                $sc = 0
                if ($u -match '(?i)discord(app)?\.com/api/webhooks') { $sc = 75 }
                elseif ($u -match '(?i)pastebin\.com|hastebin|ghostbin|anonfiles|transfer\.sh|ngrok|cdn\.discordapp\.com/attachments|api\.telegram\.org') { $sc = 55 }
                elseif ($u -match '^https?://\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}') { $sc = 45 }
                if ($sc -gt 0) { [void]$script:UrlHits.Add([pscustomobject]@{ Path = $p; Url = $u; Skor = $sc }) }
            }
        } catch {} finally { if ($zip) { $zip.Dispose() } }
    }
}
function Show-Fam([string]$fam, [string]$rxs, [int]$sc) {
    $rx = New-Object System.Text.RegularExpressions.Regex ($rxs)
    foreach ($p in $script:XPaths) {
        $lf = [IO.Path]::GetFileName($p)
        if ($rx.IsMatch($lf) -or ($fam -eq 'Client' -and ($script:ClientRx.IsMatch($lf) -or $script:CamelRx.IsMatch($lf) -or $script:ExtraRx.IsMatch($lf)))) { Add-F -Kaynak ('Meow ' + $fam + ' analizi (dosya adi)') -Ad $lf.ToLower() -Yol $p -Skor $sc -Var 'Evet' -Not ('dosya adinda ' + $fam + ' izi') }
    }
    foreach ($h in $script:FamHits[$fam]) {
        Add-F -Kaynak ('Meow ' + $fam + ' analizi (jar icerigi)') -Ad ('jar: ' + [IO.Path]::GetFileName($h.Path).ToLower()) -Yol $h.Path -Skor ([Math]::Min(100, $sc + 10 + 5 * [Math]::Min(4, [int]$h.N - 1))) -Var 'Evet' -Not ([string]$h.Why)
    }
}

Step '[17+/17] 27) MeowClientFucker: bilinen hile istemcisi imzalari (dosya adi + jar icerigi)...'
Start-Sec
try { Initialize-XPaths; Scan-FamJars; Show-Fam 'Client' $script:BrandRx.ToString() 60; Show-FocusFindings ($script:ClientRx.ToString() + '|' + $script:CamelRx.ToString() + '|' + $script:ExtraRx.ToString()) 'Istemci markalari (ozet)' } catch {}
Show-Section

Step '[17+/17] 28) MeowNovowareFucker: Novoware istemcisi izleri (dosya adi + jar icerigi)...'
Start-Sec
try { Initialize-XPaths; Scan-FamJars; Show-Fam 'Novoware' '(?i)novo[ _\-\.]?ware|novoline[ _\-]?ware' 75; Show-FocusFindings '(?i)novo[ _\-]?ware' 'Novoware' } catch {}
Show-Section

# ---- 28b) Ismi degistirilmis dosyalar: asil ad (PE/jar ust verisi) hile ismi mi ----
Step '[17+/17] 28b) Ismi degistirilmis dosyalar: asil ad (OriginalFilename / jar meta verisi / ana paket) hile ismi mi...'
Start-Sec
try {
    Initialize-XPaths
    $rnSeen = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $rnList = New-Object System.Collections.Generic.List[string]
    foreach ($p in $script:XPaths) { if ($p -match '(?i)\.(exe|dll|scr|jar)$' -and $rnSeen.Add($p)) { [void]$rnList.Add($p) } }
    foreach ($mj in @($mmJars)) { $p = [string]$mj.FullName; if ($p -and $rnSeen.Add($p)) { [void]$rnList.Add($p) } }
    Log ('   ' + $rnList.Count + ' dosyanin asil adi inceleniyor...') 'DarkGray'
    $rnMetaRx = New-Object System.Text.RegularExpressions.Regex ('(?im)^\s*(Main-Class|Premain-Class|Agent-Class|Launcher-Agent-Class|Implementation-Title|Specification-Title|Bundle-Name|Bundle-SymbolicName|Automatic-Module-Name|Application-Name)\s*:\s*(.+?)\s*$')
    $rn = 0
    $rnHit = 0
    foreach ($p in $rnList) {
        $rn++
        if (($rn % 200) -eq 0) { Set-Frac ($rn / [Math]::Max(1, $rnList.Count)) ('asil ad ' + $rn + '/' + $rnList.Count) }
        $lf = [IO.Path]::GetFileName($p)
        $fnHit = Get-NameHit $lf $false
        $orig = New-Object System.Collections.Generic.List[string]
        $origName = ''
        if ($p -match '(?i)\.(exe|dll|scr)$') {
            try {
                $vi = [Diagnostics.FileVersionInfo]::GetVersionInfo($p)
                foreach ($pair in @(@('OriginalFilename', $vi.OriginalFilename), @('InternalName', $vi.InternalName), @('ProductName', $vi.ProductName), @('FileDescription', $vi.FileDescription), @('Comments', $vi.Comments))) {
                    $v = [string]$pair[1]
                    if (-not $v) { continue }
                    $h = Get-NameHit $v $false
                    if ($h) { [void]$orig.Add($pair[0] + ' = ' + $v + '  <- ' + $h.Name); if (-not $origName) { $origName = $h.Name } }
                }
            } catch {}
        } else {
            $len = 0
            try { $len = (New-Object IO.FileInfo $p).Length } catch { continue }
            if ($len -gt 157286400 -or $len -lt 30) { continue }
            $zip = $null
            try {
                $zip = [IO.Compression.ZipFile]::OpenRead($p)
                $pk = @{}
                foreach ($e in $zip.Entries) {
                    $en = [string]$e.FullName
                    if ($en.EndsWith('.class') -and $en.Contains('/')) { $parts = $en.Split('/'); $pre = $parts[0]; if ($parts.Length -gt 2) { $pre = $parts[0] + '/' + $parts[1] }; if ($pk.Count -lt 400) { $pk[$pre] = 1 } }
                    if ($en -match '(?i)^(META-INF/MANIFEST\.MF|fabric\.mod\.json|quilt\.mod\.json|mcmod\.info|plugin\.yml|bungee\.yml|META-INF/mods\.toml|META-INF/neoforge\.mods\.toml|pack\.mcmeta)$' -and $e.Length -gt 0 -and $e.Length -le 262144) {
                        $sr = New-Object IO.StreamReader($e.Open(), [Text.Encoding]::UTF8)
                        $mt = $sr.ReadToEnd(); $sr.Dispose()
                        $chk = New-Object System.Collections.Generic.List[string]
                        if ($en -match '(?i)MANIFEST\.MF') { foreach ($mm2 in $rnMetaRx.Matches($mt)) { [void]$chk.Add($mm2.Groups[1].Value + ': ' + $mm2.Groups[2].Value) } }
                        else { foreach ($ln in ($mt -split "`n")) { if ($ln -match '(?i)"?(name|id|modid|displayName|main|description|entrypoints?|mixins?)"?\s*[:=]') { [void]$chk.Add($ln.Trim()) } } }
                        foreach ($c in $chk) {
                            $h = Get-NameHit $c $false
                            if ($h) { [void]$orig.Add($en + ' -> ' + $c + '  <- ' + $h.Name); if (-not $origName) { $origName = $h.Name } }
                        }
                    }
                }
                foreach ($pre in $pk.Keys) {
                    $h = Get-NameHit $pre $false
                    if ($h) { [void]$orig.Add('ana paket: ' + $pre + '  <- ' + $h.Name); if (-not $origName) { $origName = $h.Name } }
                }
            } catch {} finally { if ($zip) { $zip.Dispose() } }
        }
        if ($orig.Count -eq 0) { continue }
        $rnHit++
        $renamed = (-not $fnHit) -or ($fnHit.Name -ne $origName -and $lf.ToLower().IndexOf($origName.ToLower()) -lt 0)
        $sc = 70
        if ($renamed) { $sc = 88 }
        if ($orig.Count -ge 3) { $sc = [Math]::Min(100, $sc + 7) }
        $lead = 'ASIL AD HILE ISMI'
        if ($renamed) { $lead = 'ISMI DEGISTIRILMIS: dosya adi "' + $lf + '" ama asil ad hile ismi (' + $origName + ')' }
        $fi = $null
        try { $fi = Get-Item -LiteralPath $p -ErrorAction Stop } catch {}
        $lw = $null; $cw = $null
        if ($fi) { $lw = $fi.LastWriteTime; $cw = $fi.CreationTime }
        Add-F -Kaynak 'Ismi degistirilmis dosya (asil ad)' -Ad $lf.ToLower() -Yol $p -Skor $sc -Son $lw -Ilk $cw -Var 'Evet' -Not ($lead + ' | ' + (@($orig | Select-Object -First 6) -join ' | '))
    }
    Log ('   asil adi hile ismi olan dosya: ' + $rnHit) 'DarkGray'
} catch {}
Show-Section

$hkHeurCs = @'
using System;
using System.IO;
using System.IO.Compression;
using System.Text;
using System.Collections.Generic;
public static class HkHeur {
    public static double Ent(byte[] b, int off, int n) {
        if (n <= 0) return 0;
        int[] c = new int[256];
        for (int i = off; i < off + n; i++) c[b[i]]++;
        double e = 0;
        for (int i = 0; i < 256; i++) { if (c[i] == 0) continue; double p = (double)c[i] / n; e -= p * Math.Log(p, 2); }
        return e;
    }
    static bool Has(string s, string k) { return s.IndexOf(k, StringComparison.Ordinal) >= 0; }
    public static string Pe(string path) {
        try {
            using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite)) {
                long len = fs.Length;
                if (len < 1024) return "";
                int rd = (int)Math.Min(len, 2097152);
                byte[] h = new byte[rd];
                int got = fs.Read(h, 0, rd);
                if (got < 512 || h[0] != 0x4D || h[1] != 0x5A) return "";
                int pe = BitConverter.ToInt32(h, 0x3C);
                if (pe <= 0 || pe + 264 > got || h[pe] != 0x50 || h[pe + 1] != 0x45) return "badpe=1";
                int nsec = BitConverter.ToUInt16(h, pe + 6);
                int optSize = BitConverter.ToUInt16(h, pe + 20);
                int opt = pe + 24;
                bool plus = BitConverter.ToUInt16(h, opt) == 0x20B;
                int dd = opt + (plus ? 112 : 96);
                StringBuilder sb = new StringBuilder();
                uint impSz = 0, clrSz = 0, sigSz = 0;
                if (dd + 120 <= got) { impSz = BitConverter.ToUInt32(h, dd + 8 + 4); sigSz = BitConverter.ToUInt32(h, dd + 32 + 4); clrSz = BitConverter.ToUInt32(h, dd + 112 + 4); }
                sb.Append("impsz=" + impSz + ";clr=" + (clrSz > 0 ? 1 : 0) + ";sig=" + (sigSz > 0 ? 1 : 0) + ";");
                int so = opt + optSize;
                long maxEnd = 0;
                int hi = 0;
                List<string> packers = new List<string>();
                List<string> hiNames = new List<string>();
                string[] pk = new string[] { "upx0", "upx1", "upx2", ".themida", ".winlice", ".vmp0", ".vmp1", ".vmp2", ".enigma1", ".enigma2", ".aspack", ".adata", ".petite", ".mpress1", ".mpress2", ".nsp0", ".nsp1", ".boom", ".perplex", ".taz", ".yp", "pec1", "pec2", ".svkp", ".packed", ".neolite", ".rmnet", ".themida" };
                for (int i = 0; i < nsec && i < 40; i++) {
                    int s = so + i * 40;
                    if (s + 40 > got) break;
                    string nm = Encoding.ASCII.GetString(h, s, 8).TrimEnd('\0').ToLowerInvariant();
                    uint raw = BitConverter.ToUInt32(h, s + 16);
                    uint ptr = BitConverter.ToUInt32(h, s + 20);
                    if ((long)ptr + raw > maxEnd) maxEnd = (long)ptr + raw;
                    foreach (string k in pk) { if (nm == k) { packers.Add(nm); break; } }
                    if (raw >= 20480 && ptr < len) {
                        int take = (int)Math.Min((long)raw, Math.Min(1048576L, len - ptr));
                        if (take > 4096) {
                            byte[] sbuf = new byte[take];
                            fs.Seek(ptr, SeekOrigin.Begin);
                            int r2 = fs.Read(sbuf, 0, take);
                            if (r2 > 4096) {
                                double e = Ent(sbuf, 0, r2);
                                bool code = nm == ".text" || nm == "code";
                                if (e >= 7.3 || (e >= 7.0 && !code && nm != ".rsrc")) { hi++; hiNames.Add(nm + ":" + e.ToString("0.0")); }
                            }
                        }
                    }
                }
                long overlay = len - maxEnd - sigSz;
                if (overlay < 0) overlay = 0;
                sb.Append("overlay=" + overlay + ";hi=" + hi + ";hinames=" + string.Join(",", hiNames.ToArray()) + ";packer=" + string.Join(",", packers.ToArray()) + ";");
                string txt = Encoding.GetEncoding(28591).GetString(h, 0, got);
                string[] mk = new string[] { "UPX!", "ConfuserEx", "Eazfuscator", "SmartAssembly", "Dotfuscator", ".NET Reactor", "Themida", "VMProtect", "Enigma Protector", "Obfuscated with", "BabelObfuscator", "Agile.NET", "KoiVM", "Armadillo", "MPRESS", "PELock", "Obsidium", "ASProtect", "Costura", "Fody" };
                List<string> found = new List<string>();
                foreach (string k in mk) { if (Has(txt, k)) found.Add(k); }
                sb.Append("markers=" + string.Join(",", found.ToArray()) + ";");
                string[] inj = new string[] { "WriteProcessMemory", "CreateRemoteThread", "VirtualAllocEx", "NtCreateThreadEx", "QueueUserAPC", "SetWindowsHookEx", "LoadLibraryA", "LoadLibraryW", "OpenProcess", "jvm.dll", "JNI_GetCreatedJavaVMs", "GetAsyncKeyState", "mouse_event", "SendInput", "javaw", "minecraft", "Minecraft", "LWJGL", "lwjgl", "ManualMap" };
                List<string> ip = new List<string>();
                foreach (string k in inj) { if (Has(txt, k)) ip.Add(k); }
                sb.Append("api=" + string.Join(",", ip.ToArray()) + ";");
                return sb.ToString();
            }
        } catch (Exception ex) { return "err=" + ex.GetType().Name; }
    }
    public static string Jar(string path) {
        try {
            using (ZipArchive z = ZipFile.OpenRead(path)) {
                int cls = 0, shortN = 0, nonAscii = 0, defPkg = 0, nested = 0, enc = 0, readN = 0;
                bool meta = false;
                List<string> nestedN = new List<string>();
                List<string> encN = new List<string>();
                List<string> naN = new List<string>();
                Dictionary<string, string> mk = new Dictionary<string, string>();
                string[] keys = new string[] { "com/sun/tools/attach", "loadAgent", "VirtualMachine", "java/lang/instrument", "javax/swing", "javafx/", "java/awt", "javax/crypto", "defineClass", "sun/misc/Unsafe", "loadLibrary", "java/lang/ProcessBuilder", "java/awt/Robot", "jnativehook", "com/sun/jna", "javaw", "jvm.dll", "Instrumentation", "getResourceAsStream", "java/net/URL", "java/util/zip/ZipInputStream", "AES", "Base64", "ClassLoader" };
                foreach (ZipArchiveEntry e in z.Entries) {
                    string n = e.FullName;
                    string ln = n.ToLowerInvariant();
                    if (ln == "fabric.mod.json" || ln == "quilt.mod.json" || ln == "mcmod.info" || ln == "meta-inf/mods.toml" || ln == "meta-inf/neoforge.mods.toml" || ln == "plugin.yml") meta = true;
                    if (ln == "meta-inf/manifest.mf" && e.Length > 0 && e.Length < 65536) {
                        using (StreamReader sr = new StreamReader(e.Open(), Encoding.UTF8)) {
                            string m = sr.ReadToEnd();
                            if (Has(m, "Agent-Class") || Has(m, "Premain-Class") || Has(m, "Launcher-Agent-Class")) mk["manifest-agent"] = "1";
                            if (Has(m, "Can-Retransform-Classes") || Has(m, "Can-Redefine-Classes")) mk["manifest-retransform"] = "1";
                        }
                        continue;
                    }
                    if (ln.EndsWith(".class", StringComparison.Ordinal)) {
                        cls++;
                        int sl = n.LastIndexOf('/');
                        string simple = n.Substring(sl + 1, n.Length - sl - 1 - 6);
                        if (sl < 0) defPkg++;
                        if (simple.Length <= 2) shortN++;
                        bool na = false;
                        foreach (char c in n) { if (c > 127) { na = true; break; } }
                        if (na) { nonAscii++; if (naN.Count < 3) naN.Add(n); }
                        if (readN < 120 && e.Length > 0 && e.Length < 786432) {
                            readN++;
                            using (Stream s = e.Open()) {
                                byte[] b = new byte[e.Length];
                                int tot = 0, r;
                                while (tot < b.Length && (r = s.Read(b, tot, b.Length - tot)) > 0) tot += r;
                                string t = Encoding.GetEncoding(28591).GetString(b, 0, tot);
                                foreach (string k in keys) { if (!mk.ContainsKey(k) && Has(t, k)) mk[k] = n; }
                            }
                        }
                        continue;
                    }
                    if (ln.EndsWith(".jar", StringComparison.Ordinal) || ln.EndsWith(".dll", StringComparison.Ordinal) || ln.EndsWith(".exe", StringComparison.Ordinal) || ln.EndsWith(".so", StringComparison.Ordinal) || ln.EndsWith(".dylib", StringComparison.Ordinal)) {
                        if (!ln.StartsWith("meta-inf/jars/", StringComparison.Ordinal) && !ln.StartsWith("meta-inf/jarjar/", StringComparison.Ordinal)) { nested++; if (nestedN.Count < 4) nestedN.Add(n); }
                        continue;
                    }
                    int dot = ln.LastIndexOf('.');
                    string ext = dot > ln.LastIndexOf('/') ? ln.Substring(dot) : "";
                    bool candExt = ext == "" || ext == ".dat" || ext == ".bin" || ext == ".enc" || ext == ".data" || ext == ".res" || ext == ".txt" || ext == ".json" || ext == ".properties" || ext == ".xml" || ext == ".cfg" || ext == ".lang" || ext == ".tmp" || ext == ".key";
                    if (candExt && e.Length >= 2048 && e.Length <= 16777216 && !ln.EndsWith("/", StringComparison.Ordinal)) {
                        using (Stream s = e.Open()) {
                            int take = (int)Math.Min(e.Length, 65536);
                            byte[] b = new byte[take];
                            int tot = 0, r;
                            while (tot < take && (r = s.Read(b, tot, take - tot)) > 0) tot += r;
                            if (tot >= 2048 && Ent(b, 0, tot) >= 7.5) { enc++; if (encN.Count < 3) encN.Add(n); }
                        }
                    }
                }
                StringBuilder sb = new StringBuilder();
                sb.Append("cls=" + cls + ";short=" + shortN + ";nonascii=" + nonAscii + ";defpkg=" + defPkg + ";meta=" + (meta ? 1 : 0) + ";nested=" + nested + ";enc=" + enc + ";");
                sb.Append("nestedn=" + string.Join(",", nestedN.ToArray()) + ";encn=" + string.Join(",", encN.ToArray()) + ";nan=" + string.Join(",", naN.ToArray()) + ";");
                List<string> ks = new List<string>();
                foreach (KeyValuePair<string, string> kv in mk) ks.Add(kv.Key + (kv.Value == "1" ? "" : "@" + kv.Value));
                sb.Append("mk=" + string.Join("|", ks.ToArray()) + ";");
                return sb.ToString();
            }
        } catch (Exception ex) { return "err=" + ex.GetType().Name; }
    }
}
'@

# ---- 28c) GENEL TARAMA: rastgele adli / sifreli / paketlenmis / enjektor davranisli jar, exe, dll ----
Step '[17+/17] 28c) Genel tarama + otomatik karar: rastgele adli, sifreli, paketlenmis veya enjektor davranisli jar/exe/dll...'
Start-Sec
try {
    Initialize-XPaths
    $hhOk = $false
    try {
        if (-not ('HkHeur' -as [type])) { Add-Type -TypeDefinition $hkHeurCs -Language CSharp -ReferencedAssemblies @('System.IO.Compression', 'System.IO.Compression.FileSystem') -ErrorAction Stop }
        $hhOk = $true
    } catch { Log '   genel tarama motoru derlenemedi, yalnizca ad analizi yapilacak.' 'DarkYellow'; Add-Cov 'Genel tarama (28c) motoru derlenemedi: sifreli/paketli analiz YAPILMADI' '' }
    function Test-RandName([string]$f) {
        $b = [IO.Path]::GetFileNameWithoutExtension($f)
        if ($b.Length -lt 5 -or $b.Length -gt 60) { return '' }
        if ($b -match '(?i)(^|[ _\-\.])v?\d+(\.\d+)+' -or $b -match '(?i)[a-z]{3,}[ _\-][a-z]{3,}') { return '' }
        if ($b -match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-') { return 'GUID biciminde ad' }
        if ($b -match '^[0-9a-fA-F]{8,}$' -and $b -match '\d' -and $b -match '[a-fA-F]') { return 'hex/hash benzeri ad' }
        if ($b -match '^\d{5,}$') { return 'sadece rakamdan olusan ad' }
        $l = ($b -replace '[^A-Za-z]', '')
        if ($l.Length -ge 7) { $v = ($l -replace '[^aeiouAEIOU]', '').Length; if (($v / $l.Length) -lt 0.2) { return 'sesli harf neredeyse yok (rastgele ad)' } }
        if ($b -match '(?i)[^aeiou\d_\-\. ]{6,}') { return 'ardisik 6+ sessiz harf (rastgele ad)' }
        $tr = [regex]::Matches($b, '(?<=[A-Za-z])\d|(?<=\d)[A-Za-z]').Count
        if ($b.Length -ge 7 -and $tr -ge 4) { return 'harf-rakam karisik rastgele ad' }
        if ($b.Length -ge 10 -and $b -notmatch '[ _\-\.]' -and $b -notmatch '^[A-Z]?[a-z]+([A-Z][a-z]+)+$') {
            $cnt = @{}
            foreach ($ch in $b.ToLower().ToCharArray()) { if ($cnt.ContainsKey($ch)) { $cnt[$ch]++ } else { $cnt[$ch] = 1 } }
            $en = 0.0
            foreach ($kv in $cnt.GetEnumerator()) { $pp = $kv.Value / $b.Length; $en -= $pp * [Math]::Log($pp, 2) }
            if ($en -ge 3.45) { return ('yuksek entropili ad (' + [Math]::Round($en, 2) + ')') }
        }
        return ''
    }
    $gSeen = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $gList = New-Object System.Collections.Generic.List[object]
    $sysRx = '(?i)^[A-Za-z]:\\(Windows|Program Files|Program Files \(x86\)|ProgramData\\Microsoft|\$Recycle\.Bin\\S-[\d\-]+\\\$I)'
    foreach ($p in $script:XPaths) {
        $x = [IO.Path]::GetExtension($p).ToLowerInvariant()
        $kind = ''
        if ($x -eq '.jar') { $kind = 'jar' }
        elseif ($x -match '^\.(exe|dll|scr|cpl|ocx)$') { if ($p -notmatch $sysRx) { $kind = 'pe' } }
        elseif ($x -match '^\.(tmp|dat|bin|bak|old|temp|cache|res|data|obj|lib|sys)$') { $kind = 'magic' }
        if (-not $kind) { continue }
        if ($gSeen.Add($p)) { [void]$gList.Add([pscustomobject]@{ P = $p; K = $kind }) }
    }
    foreach ($mj in @($mmJars)) { $p = [string]$mj.FullName; if ($p -and $gSeen.Add($p)) { [void]$gList.Add([pscustomobject]@{ P = $p; K = 'jar' }) } }
    Log ('   ' + $gList.Count + ' dosya genel taramadan geciriliyor...') 'DarkGray'
    $gi = 0; $gOut = 0
    $gRes = New-Object System.Collections.Generic.List[object]
    foreach ($it in $gList) {
        $gi++
        if (($gi % 150) -eq 0) { Set-Frac ($gi / [Math]::Max(1, $gList.Count)) ('genel tarama ' + $gi + '/' + $gList.Count) }
        $p = [string]$it.P
        $fi = $null
        try { $fi = New-Object IO.FileInfo $p } catch { continue }
        $len = 0
        try { $len = $fi.Length } catch { continue }
        if ($len -lt 1024 -or $len -gt 419430400) { continue }
        $kind = [string]$it.K
        if ($kind -eq 'magic') {
            if ($len -lt 20480) { continue }
            $mg = ''
            try { $mg = Get-Magic $p } catch {}
            if ($mg -eq 'MZ') { $kind = 'pe' } elseif ($mg -eq 'PK') { $kind = 'jar' } else { continue }
        }
        $lf = [IO.Path]::GetFileName($p)
        $why = New-Object System.Collections.Generic.List[string]
        $sc = 0
        $rnd = Test-RandName $lf
        $realExt = [IO.Path]::GetExtension($p).ToLowerInvariant()
        if ($rnd) { $sc += 30; [void]$why.Add('RASTGELE ISIM: ' + $rnd) }
        if ($realExt -notmatch '^\.(jar|exe|dll|scr|cpl|ocx)$') { $sc += 25; [void]$why.Add('UZANTISI DEGISTIRILMIS: icerik ' + $(if ($kind -eq 'pe') { 'calistirilabilir (MZ)' } else { 'jar/zip (PK)' }) + ' ama uzanti ' + $realExt) }
        $inf = ''
        if ($hhOk) {
            if ($kind -eq 'pe') { try { $inf = [HkHeur]::Pe($p) } catch {} } else { try { $inf = [HkHeur]::Jar($p) } catch {} }
        }
        $d = @{}
        foreach ($kv in ($inf -split ';')) { $i2 = $kv.IndexOf('='); if ($i2 -gt 0) { $d[$kv.Substring(0, $i2)] = $kv.Substring($i2 + 1) } }
        if ($kind -eq 'pe' -and $d.Count -gt 0) {
            if ($d['packer']) { $sc += 35; [void]$why.Add('PAKETLEYICI bolum adi: ' + $d['packer']) }
            if ([int]$d['hi'] -ge 1) { $add = 20; if ([int]$d['hi'] -ge 2) { $add = 30 }; $sc += $add; [void]$why.Add('SIFRELI/SIKISTIRILMIS bolum (yuksek entropi): ' + $d['hinames']) }
            if ($d['markers']) { $sc += 30; [void]$why.Add('koruyucu/obfuscator izi: ' + $d['markers']) }
            if ([int]$d['impsz'] -gt 0 -and [int]$d['impsz'] -lt 120 -and $len -gt 200000) { $sc += 15; [void]$why.Add('neredeyse bos import tablosu (calisirken API cozuyor/paketli olabilir)') }
            if ([long]$d['overlay'] -gt 300000) { $sc += 10; [void]$why.Add('buyuk eklenti verisi (overlay ' + [int]([long]$d['overlay'] / 1024) + ' KB, gomulu/sifreli veri olabilir)') }
            if ($d['api']) {
                $ap = @($d['api'] -split ',' | Where-Object { $_ })
                $inj = @($ap | Where-Object { $_ -match 'WriteProcessMemory|CreateRemoteThread|VirtualAllocEx|NtCreateThreadEx|QueueUserAPC|ManualMap|JNI_GetCreatedJavaVMs|jvm\.dll' })
                $mcw = @($ap | Where-Object { $_ -match '(?i)javaw|minecraft|lwjgl' })
                if ($inj.Count -ge 2 -and $mcw.Count -ge 1) { $sc += 45; [void]$why.Add('MINECRAFT/JAVA ENJEKSIYON davranisi: ' + ($ap -join ', ')) }
                elseif ($inj.Count -ge 2) { $sc += 20; [void]$why.Add('process enjeksiyon API leri: ' + ($inj -join ', ')) }
                elseif ($mcw.Count -ge 2 -and $ap -contains 'OpenProcess') { $sc += 25; [void]$why.Add('Minecraft/Java sureci ile ilgilenen program: ' + ($ap -join ', ')) }
                if (($ap -contains 'GetAsyncKeyState' -or $ap -contains 'mouse_event' -or $ap -contains 'SendInput') -and $mcw.Count -ge 1) { $sc += 20; [void]$why.Add('tus/fare tetikleme + Minecraft (autoclicker/macro olasi)') }
            }
            if ($d['clr'] -eq '1' -and $d['markers']) { $sc += 5 }
        }
        if ($kind -eq 'jar' -and $d.Count -gt 0 -and -not $d.ContainsKey('err')) {
            $cls = [int]$d['cls']
            $mk = [string]$d['mk']
            $isMod = ($d['meta'] -eq '1')
            $hasAtt = ($mk -match 'com/sun/tools/attach|loadAgent|VirtualMachine')
            $hasAgent = ($mk -match 'manifest-agent|java/lang/instrument|Instrumentation')
            $hasGui = ($mk -match 'javax/swing|javafx/|java/awt')
            if ($hasAtt -and -not $isMod) { $sc += 40; [void]$why.Add('JVM ATTACH/loadAgent kullaniyor (baska bir Java surecine enjeksiyon API si)') }
            if ($hasAtt -and $hasGui -and -not $isMod) { $sc += 20; [void]$why.Add('arayuzlu (Swing/JavaFX) + attach = ENJEKTOR/YUKLEYICI yapisi') }
            if ($hasAgent -and -not $isMod -and -not $hasAtt) { $sc += 15; [void]$why.Add('Java agent (instrument) yapisi mod degil') }
            if ($mk -match 'javax/crypto' -and $mk -match 'defineClass') { $sc += 30; [void]$why.Add('sifre cozup class yukluyor (javax.crypto + defineClass: korumali/sifreli yukleyici)') }
            elseif ($mk -match 'defineClass' -and $mk -match 'Base64|AES') { $sc += 20; [void]$why.Add('Base64/AES + defineClass (gizli class yukleme olasi)') }
            if ($mk -match 'sun/misc/Unsafe' -and -not $isMod) { $sc += 10; [void]$why.Add('Unsafe kullaniyor') }
            if ($mk -match 'loadLibrary' -and -not $isMod) { $sc += 12; [void]$why.Add('yerel (native) kutuphane yukluyor') }
            if ($mk -match 'java/awt/Robot' -and -not $isMod) { $sc += 20; [void]$why.Add('java.awt.Robot (otomatik tiklama olasi)') }
            if ($mk -match 'jnativehook|com/sun/jna') { $sc += 10; [void]$why.Add('genel tus/fare dinleme veya JNA (' + $mk + ')') }
            if ($cls -ge 20 -and ([int]$d['short'] / $cls) -ge 0.6) { $sc += 25; [void]$why.Add('OBFUSCATE: class adlarinin %' + [int](100 * [int]$d['short'] / $cls) + ' i 1-2 harfli (' + $d['short'] + '/' + $cls + ')') }
            if ($cls -ge 5 -and ([int]$d['nonascii'] / $cls) -ge 0.3) { $sc += 30; [void]$why.Add('OBFUSCATE: class adlari ASCII disi karakterli: ' + $d['nan']) }
            if ([int]$d['enc'] -ge 1) { $sc += 25; [void]$why.Add('SIFRELI KAYNAK dosyalari (rastgele veri gibi): ' + $d['encn']) }
            if ([int]$d['nested'] -ge 1 -and -not $isMod) { $sc += 10; [void]$why.Add('icinde gomulu jar/dll/exe: ' + $d['nestedn']) }
            if (-not $isMod -and [int]$d['defpkg'] -ge 3 -and $cls -ge 3) { $sc += 8; [void]$why.Add('mod bilgisi (fabric.mod.json/mods.toml) yok ve varsayilan pakette ' + $d['defpkg'] + ' class') }
            if ($isMod -and $rnd) { $sc += 10; [void]$why.Add('mod klasorunde/yolunda rastgele adli jar') }
            if ($why.Count -eq 1 -and $rnd -and -not $isMod -and $cls -ge 1 -and ($mk -notmatch 'manifest-agent|attach|defineClass')) { }
        }
        if ($sc -lt 30) { continue }
        # imzali (gecerli) yazilimlar: dusur
        if ($kind -eq 'pe') {
            $signed = $false
            try { $signed = Test-Signed $p } catch {}
            if ($signed) { continue }
            if ($d.ContainsKey('sig') -and $d['sig'] -eq '0') { $sc += 8; [void]$why.Add('dijital imza yok') }
            if ($p -match '(?i)\\(Downloads|Desktop|Temp|AppData|Documents|Masaustu|Indirilenler)\\') { $sc += 8; [void]$why.Add('kullanici/gecici klasorde') }
        }
        [void]$gRes.Add([pscustomobject]@{ P = $p; K = $kind; Lf = $lf; Sc = [Math]::Min(100, $sc); Why = @($why); Fi = $fi })
    }
    # ---- 2. gecis: OTOMATIK KARAR (manuel kontrol gerektirmesin) ----
    $hashN = 0
    foreach ($g in @($gRes | Sort-Object -Property @{ Expression = 'Sc'; Descending = $true })) {
        $sc = [int]$g.Sc
        $why = New-Object System.Collections.Generic.List[string]
        foreach ($w in $g.Why) { [void]$why.Add([string]$w) }
        $lf = [string]$g.Lf
        $p = [string]$g.P
        $legit = ''
        $nStruct = $why.Count
        if ($g.K -eq 'jar') {
            # (a) yayinlanmis mod mu? hash birebir Modrinth/Megabase te varsa temizdir
            if ($script:MmNet -and $hashN -lt 80) {
                $hashN++
                try {
                    $hh = (Get-FileHash -LiteralPath $p -Algorithm SHA1 -ErrorAction Stop).Hash
                    $vv = Get-MmVerify $hh
                    if ($vv.Name) {
                        $vh = Get-NameHit ([string]$vv.Name) $false
                        if ($vh) { $sc = 100; [void]$why.Add('hash bilinen bir HILE istemcisiyle eslesti: ' + $vv.Name + ' (' + $vv.By + ')') }
                        else { $legit = $vv.By + ': ' + $vv.Name }
                    }
                } catch {}
            }
            if ($legit) { Log ('   temiz (yayinlanmis mod, hash dogrulandi): ' + $lf + ' = ' + $legit) 'DarkGray'; continue }
            # (b) derin icerik taramasi: class/dosya adlari ve icindeki hile stringleri
            $ds = $null
            try { $ds = Invoke-ModScan $p } catch {}
            if ($ds) {
                $dn = @($ds.Patterns).Count + @($ds.Strings).Count
                if ($dn -gt 0) {
                    $sc += [Math]::Min(45, 25 + 5 * $dn)
                    [void]$why.Add('ICERIKTE HILE IZLERI: ' + ((@(@($ds.Patterns) + @($ds.Strings) | Select-Object -First 8)) -join ', '))
                    if (@($ds.ClassHits).Count -gt 0) { $script:ClassHitMap[$p.ToLower()] = @($ds.ClassHits) }
                }
            }
        }
        # (c) baska adimlarda ayni dosya/ad icin iz (calistirilmis, silinmis, son acilanlar...)
        $lfl = $lf.ToLower()
        $oth = @($script:HkFnd | Where-Object { $_.Kaynak -notmatch '^Genel tarama' -and (([string]$_.Yol).ToLower() -eq $p.ToLower() -or ([string]$_.Ad).ToLower() -eq $lfl) })
        if ($oth.Count -gt 0) {
            $osrc = @($oth | ForEach-Object { [string]$_.Kaynak } | Select-Object -Unique)
            $sc += [Math]::Min(20, 8 * $osrc.Count)
            [void]$why.Add('baska adimlarda da iz var (' + $osrc.Count + ' kaynak: ' + ((@($osrc) | Select-Object -First 4) -join ', ') + ')')
        }
        # (d) birden cok bagimsiz yapisal iz = otomatik olarak yuksek guvenli
        if ($nStruct -ge 2 -and $sc -ge 55) { $sc = [Math]::Max($sc, 70) }
        if ($nStruct -ge 3 -and $sc -ge 70) { $sc = [Math]::Max($sc, 85) }
        $sc = [Math]::Min(100, $sc)
        $karar = 'KARAR: SUPHELI (yapisal iz)'
        if ($sc -ge 85) { $karar = 'KARAR: HILE / ENJEKTOR (otomatik)' } elseif ($sc -ge 65) { $karar = 'KARAR: BUYUK IHTIMALLE HILE/GIZLENMIS PROGRAM' }
        $gOut++
        Add-F -Kaynak 'Genel tarama (rastgele ad/sifreli/paketli/enjektor)' -Ad $lfl -Yol $p -Skor $sc -Son $g.Fi.LastWriteTime -Ilk $g.Fi.CreationTime -Var 'Evet' -Not ($karar + ' | ' + (@($why) -join ' ; '))
    }
    Log ('   genel taramada isaretlenen: ' + $gOut + ' dosya') 'DarkGray'
} catch { Log ('   genel tarama hatasi: ' + $_.Exception.Message) 'DarkYellow' }
Show-Section

# ---- 29) RedLotus Mod Analyzer ----
Step '[17+/17] 29) RedLotus Mod Analyzer: mod yapisi analizi (meta verisi, varsayilan paket, gomulu jar/dll)...'
Start-Sec
try {
    $rlN = 0
    foreach ($mj in @($mmJars)) {
        $zip = $null
        try {
            $zip = [IO.Compression.ZipFile]::OpenRead($mj.FullName)
            $nm = @($zip.Entries.FullName)
            $rlN++
            $why = New-Object System.Collections.Generic.List[string]
            $sc = 0
            $hasMeta = ($nm -contains 'fabric.mod.json') -or ($nm -contains 'quilt.mod.json') -or ($nm -contains 'mcmod.info') -or ($nm -contains 'META-INF/mods.toml') -or ($nm -contains 'META-INF/neoforge.mods.toml')
            if (-not $hasMeta) { $sc += 30; [void]$why.Add('mod meta dosyasi yok (fabric.mod.json/mods.toml/mcmod.info)') }
            $dp = @($nm | Where-Object { $_ -match '^[^/]+\.class$' }).Count
            if ($dp -ge 3) { $sc += 35; [void]$why.Add('varsayilan pakette ' + $dp + ' class (normal modlar paket kullanir)') }
            $nat = @($nm | Where-Object { $_ -match '(?i)\.(dll|so|dylib)$' })
            if ($nat.Count -gt 0) { $sc += 25; [void]$why.Add('yerel kutuphane: ' + (($nat | Select-Object -First 3) -join ', ')) }
            $inner = @($nm | Where-Object { $_ -match '(?i)\.jar$' -and $_ -notmatch '^META-INF/jars/' })
            if ($inner.Count -gt 0) { $sc += 25; [void]$why.Add('standart disi gomulu jar: ' + (($inner | Select-Object -First 3) -join ', ')) }
            if ($sc -ge 25) { Add-F -Kaynak 'RedLotus mod yapisi analizi' -Ad ('mod: ' + $mj.Name.ToLower()) -Yol $mj.FullName -Skor ([Math]::Min(100, $sc)) -Son $mj.LastWriteTime -Ilk $mj.CreationTime -Var 'Evet' -Not (($why -join '; ') + ' | tek basina kanit degil, DOGRULA') }
        } catch {} finally { if ($zip) { $zip.Dispose() } }
    }
    Log ('   ' + $rlN + ' mod yapisal olarak incelendi.') 'DarkGray'
} catch {}
Show-Section

# ---- 30) Luyten ----
Step '[17+/17] 30) Luyten: jar icindeki sabit URL / webhook / IP adresleri (dekompile mantigi) ve dekompiler izleri...'
Start-Sec
try {
    Initialize-XPaths
    Scan-FamJars
    foreach ($u in $script:UrlHits) { Add-F -Kaynak 'Luyten: jar icinde dis adres' -Ad ('jar: ' + [IO.Path]::GetFileName($u.Path).ToLower()) -Yol $u.Path -Skor $u.Skor -Var 'Evet' -Not ('sabit adres: ' + $u.Url + ' | hile istemcileri veri/webhook gondermek icin kullanabilir') }
    $lzRx = New-Object System.Text.RegularExpressions.Regex ('(?i)^(luyten|jd-gui|recaf|bytecode-?viewer|cfr|procyon|fernflower|jadx)[^\\]*\.(jar|exe|zip)$')
    foreach ($p in $script:XPaths) { $lf = [IO.Path]::GetFileName($p); if ($lzRx.IsMatch($lf)) { Add-F -Kaynak 'Dekompiler arac izi' -Ad $lf.ToLower() -Yol $p -Skor 20 -Var 'Evet' -Not 'Java dekompiler/analiz araci dosyasi' } }
} catch {}
Show-Section

# ---- 31) Zimmerman Tools ----
Step '[17+/17] 31) Zimmerman Tools: LNK (LECmd) analizi, silinmis/cikarilmis hedefler ve EZ arac izleri...'
Start-Sec
try {
    $wsh = New-Object -ComObject WScript.Shell
    $lnN = 0
    $recent = [Environment]::GetFolderPath('Recent')
    foreach ($ln in @(Get-ChildItem -LiteralPath $recent -Filter '*.lnk' -File -Force -ErrorAction Ignore)) {
        $tg = ''
        try { $tg = [string]$wsh.CreateShortcut($ln.FullName).TargetPath } catch {}
        if (-not $tg -or $tg -notmatch '^[A-Za-z]:\\') { continue }
        $lnN++
        $tl = [IO.Path]::GetFileName($tg)
        if ($tl -notmatch '(?i)\.(exe|dll|jar|bat|cmd|ps1|vbs|scr|zip|rar|7z|msi)$') { continue }
        $drv = $tg.Substring(0, 2).ToUpper()
        $h = Get-NameHit $tl $true
        if ($script:Drives -notcontains $drv) { Add-F -Kaynak 'LNK (LECmd): cikarilmis surucu' -Ad $tl.ToLower() -Yol $tg -Skor 45 -Son $ln.LastWriteTime -Var 'Hayir' -Not ('kisayol hedefi su an takili olmayan surucuye ait (' + $drv + ') - harici diskten calistirilmis olabilir') }
        elseif (-not (Test-Path -LiteralPath $tg)) {
            $sc = 30; if ($h -and -not $h.Weak) { $sc = 60 }
            Add-F -Kaynak 'LNK (LECmd): silinmis hedef' -Ad $tl.ToLower() -Yol $tg -Skor $sc -Son $ln.LastWriteTime -Var 'Hayir' -Not 'Son kullanilanlar kisayolu var ama hedef dosya silinmis'
        } elseif ($h -and -not $h.Weak) { Add-F -Kaynak 'LNK (LECmd): hile ismi' -Ad $tl.ToLower() -Yol $tg -Skor 55 -Son $ln.LastWriteTime -Var 'Evet' -Not ('hile ismi: ' + $h.Name) }
    }
    Log ('   ' + $lnN + ' kisayol hedefi incelendi.') 'DarkGray'
    try { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($wsh) } catch {}
    Initialize-XPaths
    $ezRx = New-Object System.Text.RegularExpressions.Regex ('(?i)^(AmcacheParser|AppCompatCacheParser|MFTECmd|PECmd|LECmd|JLECmd|RECmd|SBECmd|SQLECmd|EvtxECmd|RBCmd|WxTCmd|SrumECmd|TimelineExplorer|RegistryExplorer|ShellBagsExplorer|MFTExplorer|bstrings)\.(exe|zip)$')
    foreach ($p in $script:XPaths) { $lf = [IO.Path]::GetFileName($p); if ($ezRx.IsMatch($lf)) { Add-F -Kaynak 'Zimmerman arac izi' -Ad $lf.ToLower() -Yol $p -Skor 20 -Var 'Evet' -Not 'Eric Zimmerman adli bilisim araci dosyasi' } }
} catch {}
Show-Section

# ---- 32) MandarinTool ----
Step '[17+/17] 32) MandarinTool (tahmini): DNS onbellegi, hosts, proxy, guvenlik duvari ve ag gecmisi...'
Start-Sec
try {
    $dnN = 0
    $cheatDomRx = New-Object System.Text.RegularExpressions.Regex ('(?i)(?:^|\.)(?:vape\.gg|intent\.store|rise\.today|riseclient\.com|novoline\.(?:wtf|xyz|today)|novoware\.(?:lol|xyz|wtf|to)|api\.novaclient\.lol|novaclient\.lol|liquidbounce\.net|meteorclient\.com|wurstclient\.net|rusherhack\.org|astralux\.(?:xyz|lol)|doomsdayclient\.(?:com|xyz|net)|fdp-client\.com|tenacity\.dev|sigmaclient\.info|exhibition\.cc|pandaware\.(?:lol|xyz)|aristois\.net|futureclient\.net|impactclient\.net|hypixel-?cheat|cheat-?(?:mc|minecraft)|unknowncheats\.me|mpgh\.net|ownedcore\.com|hackforums\.net|nulled\.to|cracked\.io|pastebin\.com|hastebin\.com|anonfiles\.com|gofile\.io|mega\.nz|ngrok(?:-free)?\.(?:io|app|dev))$')
    foreach ($d in @(Get-DnsClientCache -ErrorAction Ignore)) {
        $en = [string]$d.Entry
        if (-not $en) { continue }
        $dnN++
        $h = Get-NameHit $en $false
        if ($h) { Add-F -Kaynak 'DNS onbellegi' -Ad $en.ToLower() -Yol $en -Skor 45 -Var 'Bilinmiyor' -Not ('alan adinda hile ismi: ' + $h.Name) }
        elseif ($script:ClientRx.IsMatch($en) -or $script:ExtraRx.IsMatch($en)) { Add-F -Kaynak 'DNS onbellegi' -Ad $en.ToLower() -Yol $en -Skor 45 -Var 'Bilinmiyor' -Not 'alan adinda istemci markasi' }
        elseif ($cheatDomRx.IsMatch($en)) { Add-F -Kaynak 'DNS onbellegi' -Ad $en.ToLower() -Yol $en -Skor 40 -Var 'Bilinmiyor' -Not 'bilinen hile/paylasim sitesi alan adi (tek basina kesin degil)' }
    }
    Log ('   ' + $dnN + ' DNS kaydi incelendi.') 'DarkGray'
    if ($dnN -eq 0) { Add-Sys 'DNS onbellegi bos/okunamadi' 20 'ipconfig /flushdns ile temizlenmis olabilir (hile sonrasi iz silme).' }
    $hostsP = $env:WINDIR + '\System32\drivers\etc\hosts'
    foreach ($hl in @(Get-Content -LiteralPath $hostsP -ErrorAction Ignore)) {
        $t = ([string]$hl).Trim()
        if (-not $t -or $t.StartsWith('#')) { continue }
        if ($t -match '^(127\.0\.0\.1|::1|0\.0\.0\.0)\s+(localhost|kubernetes\.docker\.internal|host\.docker\.internal|gateway\.docker\.internal)\b') { continue }
        $sc = 15
        if ($t -match '(?i)minecraft|mojang|sessionserver|authserver|hypixel|anticheat|easyanticheat|battleye|vanguard|riot|ac\.|screenshare|ss\.|discord|telemetry|sentry') { $sc = 50 }
        Add-Sys ('hosts dosyasinda ozel kayit: ' + $t) $sc 'hosts ile alan adi yonlendirmesi/engellemesi anticheat veya oyun sunucularini etkilemek icin kullanilabilir.'
    }
    $hostsI = Get-Item -LiteralPath $hostsP -ErrorAction Ignore
    if ($hostsI -and $hostsI.LastWriteTime -gt (Get-Date).AddDays(-3)) { Add-Sys 'hosts dosyasi son 3 gunde degistirilmis' 25 ('Son yazma: ' + $hostsI.LastWriteTime) $null $hostsP $hostsI.LastWriteTime }
    $ps = Get-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction Ignore
    if ($ps -and $ps.ProxyEnable -eq 1) { Add-Sys ('Sistem proxy si acik: ' + $ps.ProxyServer) 20 'Trafik bir proxy uzerinden geciyor (VPN/proxy hile veya engel atlatma icin de kullanilabilir).' }
    if ($ps -and $ps.AutoConfigURL) { Add-Sys ('Otomatik proxy (PAC) betigi ayarli: ' + $ps.AutoConfigURL) 30 'PAC betigi trafigi yonlendirebilir.' }
    if ($ps -and $ps.ProxyServer -match '(?i)127\.0\.0\.1|localhost') { Add-Sys ('Proxy yerel adrese yonlendirilmis: ' + $ps.ProxyServer) 40 'Yerel proxy (MITM/tunel araci) kullaniliyor olabilir.' }
    try {
        $wh = (& netsh winhttp show proxy 2>$null) -join ' '
        if ($wh -and $wh -notmatch '(?i)Direct access|dogrudan') { Add-Sys ('WinHTTP proxy ayarli: ' + ($wh -replace '\s+', ' ').Trim()) 20 'Sistem genelinde proxy tanimli.' }
    } catch {}
    # Guvenlik duvari: oyun/anticheat/Java'yi engelleyen giden kurallar
    try {
        $fwN = 0
        foreach ($fr in @(Get-NetFirewallRule -Direction Outbound -Action Block -Enabled True -ErrorAction Ignore)) {
            $fwN++
            if ($fwN -gt 400) { break }
            $disp = [string]$fr.DisplayName
            if ($disp -match '(?i)minecraft|java|javaw|mojang|anticheat|easyanticheat|battleye|vanguard|screenshare|hypixel') { Add-Sys ('Giden baglanti engelleme kurali: ' + $disp) 40 'Oyun/anticheat/Java trafigini engelleyen guvenlik duvari kurali (anticheat atlatma olabilir).' }
        }
    } catch {}
    # Ag gecmisi: bilinen profil adlari ve VPN/tunel adaptorleri
    try {
        foreach ($ad in @(Get-NetAdapter -ErrorAction Ignore | Where-Object { $_.Status -eq 'Up' })) {
            if (([string]$ad.InterfaceDescription + ' ' + [string]$ad.Name) -match '(?i)wintun|wireguard|openvpn|tap-windows|nordlynx|proton|mullvad|tailscale|zerotier|radmin') { Add-Sys ('Aktif VPN/tunel adaptoru: ' + $ad.Name + ' (' + $ad.InterfaceDescription + ')') 15 'VPN/tunel adaptoru aktif; tek basina hile degil.' }
        }
    } catch {}
} catch {}
Show-Section

# =====================================================================
# EK MODULLER 33-38: Vigil Task Parser / Vigil Registry Scanner / MarsPixel Dump Analyzer /
# Prefetch Parser / Echo Strings / BAM View mantigi (mevcut adimlarin ustune derin analiz)
# =====================================================================
$script:DumpOk = $false
$dumpCs = @'
using System;
using System.IO;
using System.Text;
using System.Collections.Generic;
using System.Text.RegularExpressions;
public static class HkDump {
    public static string LastErr = "";
    public static long BytesRead = 0;
    public static bool Truncated = false;
    static Dictionary<string, Regex> cache = new Dictionary<string, Regex>();
    static Regex MkRx(string pat) {
        if (string.IsNullOrEmpty(pat)) return null;
        Regex r;
        if (cache.TryGetValue(pat, out r)) return r;
        r = new Regex(pat, RegexOptions.CultureInvariant | RegexOptions.Compiled, TimeSpan.FromSeconds(60));
        cache[pat] = r;
        return r;
    }
    static string Clean(string s) {
        StringBuilder sb = new StringBuilder(s.Length);
        for (int i = 0; i < s.Length; i++) { char c = s[i]; if (c >= 32 && c < 127) sb.Append(c); else sb.Append('.'); }
        return sb.ToString();
    }
    static void Collect(string text, int baseOff, int mult, long chunkStart, Regex rx, Dictionary<string, string> seen, List<string> outList, int cap, string tag) {
        if (rx == null || outList.Count >= cap) return;
        Match m = rx.Match(text);
        int guard = 0;
        while (m.Success && guard < 20000 && outList.Count < cap) {
            guard++;
            string v = m.Value;
            string k = tag + "|" + v.ToLowerInvariant();
            if (!seen.ContainsKey(k)) {
                int a = Math.Max(0, m.Index - 40);
                int b = Math.Min(text.Length, m.Index + m.Length + 40);
                string ctx = Clean(text.Substring(a, b - a));
                long off = chunkStart + baseOff + (long)m.Index * mult;
                seen[k] = "1";
                outList.Add(tag + "\t" + Clean(v) + "\t" + off.ToString("X") + "\t" + ctx);
            }
            m = m.NextMatch();
        }
    }
    // Dosyayi parca parca okur; ASCII ve UTF-16 (iki hizalama) stringlerde desenleri arar.
    // Donen satirlar: TAG \t eslesme \t dosya ofseti(hex) \t baglam   (TAG: N=isim, C=kesin, P=yol, U=adres, X=ekstra)
    public static List<string> Scan(string path, string namePat, string certainPat, string pathPat, string urlPat, string extraPat, long maxBytes, int maxMs, int capEach) {
        List<string> ln = new List<string>(); List<string> lc = new List<string>(); List<string> lp = new List<string>();
        List<string> lu = new List<string>(); List<string> lx = new List<string>();
        LastErr = ""; BytesRead = 0; Truncated = false;
        try {
            Regex rN = MkRx(namePat); Regex rC = MkRx(certainPat); Regex rP = MkRx(pathPat); Regex rU = MkRx(urlPat); Regex rX = MkRx(extraPat);
            Dictionary<string, string> seen = new Dictionary<string, string>();
            System.Diagnostics.Stopwatch sw = System.Diagnostics.Stopwatch.StartNew();
            Encoding lat = Encoding.GetEncoding(28591);
            using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete, 1 << 20)) {
                int chunk = 8 * 1024 * 1024;
                int overlap = 4096;
                byte[] buf = new byte[chunk + overlap];
                int carry = 0;
                long pos = 0;
                while (true) {
                    int n = fs.Read(buf, carry, chunk);
                    if (n <= 0) break;
                    int total = carry + n;
                    if (total >= 4) {
                        string s1 = lat.GetString(buf, 0, total);
                        string s2 = Encoding.Unicode.GetString(buf, 0, total & ~1);
                        string s3 = Encoding.Unicode.GetString(buf, 1, (total - 1) & ~1);
                        Collect(s1, 0, 1, pos, rN, seen, ln, capEach, "N");
                        Collect(s2, 0, 2, pos, rN, seen, ln, capEach, "N");
                        Collect(s3, 1, 2, pos, rN, seen, ln, capEach, "N");
                        Collect(s1, 0, 1, pos, rC, seen, lc, capEach, "C");
                        Collect(s2, 0, 2, pos, rC, seen, lc, capEach, "C");
                        Collect(s3, 1, 2, pos, rC, seen, lc, capEach, "C");
                        Collect(s1, 0, 1, pos, rP, seen, lp, capEach * 4, "P");
                        Collect(s2, 0, 2, pos, rP, seen, lp, capEach * 4, "P");
                        Collect(s3, 1, 2, pos, rP, seen, lp, capEach * 4, "P");
                        Collect(s1, 0, 1, pos, rU, seen, lu, capEach, "U");
                        Collect(s2, 0, 2, pos, rU, seen, lu, capEach, "U");
                        Collect(s3, 1, 2, pos, rU, seen, lu, capEach, "U");
                        Collect(s1, 0, 1, pos, rX, seen, lx, capEach, "X");
                        Collect(s2, 0, 2, pos, rX, seen, lx, capEach, "X");
                        Collect(s3, 1, 2, pos, rX, seen, lx, capEach, "X");
                    }
                    BytesRead = pos + total;
                    if (maxBytes > 0 && BytesRead >= maxBytes) { Truncated = true; break; }
                    if (maxMs > 0 && sw.ElapsedMilliseconds > maxMs) { Truncated = true; break; }
                    if (total > overlap) {
                        Buffer.BlockCopy(buf, total - overlap, buf, 0, overlap);
                        pos += total - overlap;
                        carry = overlap;
                    } else { pos += total; carry = 0; }
                }
            }
        } catch (Exception ex) { LastErr = ex.GetType().Name + ": " + ex.Message; }
        List<string> res = new List<string>();
        res.AddRange(lc); res.AddRange(ln); res.AddRange(lx); res.AddRange(lu); res.AddRange(lp);
        return res;
    }
}
'@
try {
    Add-Type -TypeDefinition $dumpCs -Language CSharp -ErrorAction Stop
    $script:DumpOk = $true
} catch { $script:DumpOk = $false }

# ortak desenler (dump / strings taramasi icin)
$script:DmpNamePat = '(?:' + (@($script:SubRx.ToString(), $script:StrongRx.ToString(), $script:ClientRx.ToString(), ('(?i)' + $script:ExtraRx.ToString())) -join ')|(?:') + ')'
$script:DmpCertPat = ''
try { $script:DmpCertPat = '(?:' + ((@($mmCertain | Where-Object { $_.Length -ge 6 } | ForEach-Object { [regex]::Escape($_) })) -join '|') + ')' } catch {}
$script:DmpPathPat = '(?i)[A-Za-z]:\\[^\x00-\x1f"<>|*?:]{3,260}?\.(?:exe|dll|jar|bat|ps1|scr|cmd|vbs|sys)(?![A-Za-z0-9])'
$script:DmpUrlPat = '(?i)(?:https?://[a-z0-9\-\.]{4,80}(?:/[^\s\x00-\x1f"<>]{0,120})?|discord(?:app)?\.com/api/webhooks/[0-9]+/[A-Za-z0-9_\-]{20,})'
$script:DmpInjPat = '(?i)(?:CreateRemoteThread|NtCreateThreadEx|WriteProcessMemory|VirtualAllocEx|ManualMap|manual[ _\-]?map|ReflectiveLoader|SetWindowsHookEx|QueueUserAPC|LdrLoadDll|NtMapViewOfSection|JNI_OnLoad|Java_[A-Za-z0-9_]{6,}|attach(?:ing)?[ _\-]?to[ _\-]?javaw|inject(?:ed|ing|or)?[ _\-]?(?:dll|jar|client)|self[ _\-]?destruct|unhook|spoof(?:er|ing)?[ _\-]?hwid)'

# Tek bir dosyayi tarar ve bulgulari Add-F / Add-Sys ile kaydeder. Kaynak: raporda gorunen adim adi.
function Invoke-DumpFile([string]$file, [string]$kaynak, [bool]$javaHint = $false, [long]$maxBytes = 900MB, [int]$maxMs = 150000) {
    if (-not $script:DumpOk) { return }
    $fi = $null
    try { $fi = Get-Item -LiteralPath $file -Force -ErrorAction Stop } catch { return }
    $lines = $null
    try { $lines = [HkDump]::Scan($file, $script:DmpNamePat, $script:DmpCertPat, $script:DmpPathPat, $script:DmpUrlPat, $script:DmpInjPat, $maxBytes, $maxMs, 40) } catch { $lines = $null }
    if ($null -eq $lines) { Add-Cov 'Dump/strings dosyasi okunamadi' $file ([HkDump]::LastErr); return }
    if ([HkDump]::LastErr) { Add-Cov 'Dump/strings dosyasi kismen okundu' $file ([HkDump]::LastErr) }
    if ([HkDump]::Truncated) { Add-Cov 'Dump/strings dosyasi kismi tarandi (boyut/sure siniri)' $file ([string][int]([HkDump]::BytesRead / 1MB) + ' MB okundu') }
    $isJ = ($javaHint -or $fi.Name -match '(?i)java|minecraft|hs_err|\.hprof|lunar|badlion|javaw')
    $names = New-Object System.Collections.Generic.List[string]
    $certs = New-Object System.Collections.Generic.List[string]
    $injs = New-Object System.Collections.Generic.List[string]
    $urls = New-Object System.Collections.Generic.List[string]
    $paths = New-Object System.Collections.Generic.List[string]
    foreach ($ln in $lines) {
        $f = ([string]$ln).Split("`t")
        if ($f.Count -lt 3) { continue }
        $item = $f[1] + ' @0x' + $f[2]
        switch ($f[0]) {
            'N' { [void]$names.Add($item) }
            'C' { [void]$certs.Add($item) }
            'X' { [void]$injs.Add($item) }
            'U' { [void]$urls.Add($f[1]) }
            'P' { [void]$paths.Add($f[1]) }
        }
    }
    $tm = $fi.LastWriteTime
    if ($certs.Count -gt 0) {
        $sc = 40; if ($isJ) { $sc = 80 } elseif ($certs.Count -ge 2) { $sc = 65 }
        Add-F -Kaynak $kaynak -Ad ($fi.Name.ToLower() + ' (kesin hile stringi)') -Yol $file -Skor $sc -Son $tm -Ilk $fi.CreationTime -Var 'Evet' -Not ('dump/bellek dosyasinda kesin hile stringleri (' + $certs.Count + '): ' + (($certs | Select-Object -First 8) -join ' ; '))
    }
    if ($names.Count -gt 0) {
        $sc = 35; if ($isJ) { $sc = 60 }
        if ($names.Count -ge 3) { $sc += 10 }
        Add-F -Kaynak $kaynak -Ad ($fi.Name.ToLower() + ' (hile ismi)') -Yol $file -Skor ([Math]::Min(100, $sc)) -Son $tm -Ilk $fi.CreationTime -Var 'Evet' -Not ('dump/bellek dosyasinda bilinen hile istemcisi isimleri (' + $names.Count + '): ' + (($names | Select-Object -First 10) -join ' ; '))
    }
    if ($injs.Count -ge 3 -or ($injs.Count -ge 1 -and $isJ)) {
        Add-F -Kaynak $kaynak -Ad ($fi.Name.ToLower() + ' (enjeksiyon izi)') -Yol $file -Skor 30 -Son $tm -Ilk $fi.CreationTime -Var 'Evet' -Not ('enjeksiyon/yukleyici belirteci stringleri: ' + (($injs | Select-Object -First 8) -join ' ; ') + ' (tek basina kesin degil; arac/AV de icerebilir)')
    }
    foreach ($u in $urls) {
        if ($u -match '(?i)discord(app)?\.com/api/webhooks/') {
            Add-F -Kaynak $kaynak -Ad ($fi.Name.ToLower() + ' (webhook)') -Yol $file -Skor 35 -Son $tm -Var 'Evet' -Not ('discord webhook adresi bulundu: ' + $u)
            break
        }
    }
    $hu = $null
    foreach ($u in $urls) { $h = Get-NameHit $u $false; if ($h) { $hu = $u; break } }
    if ($hu) { Add-F -Kaynak $kaynak -Ad ($fi.Name.ToLower() + ' (hile sitesi)') -Yol $file -Skor 45 -Son $tm -Var 'Evet' -Not ('hile ismi iceren adres: ' + $hu) }
    $pn = 0
    foreach ($p in ($paths | Select-Object -Unique)) {
        if ($pn -ge 400) { break }
        $pn++
        $pi = Get-PiCached $p
        Eval-Exec -Kaynak ($kaynak + ' (dump icindeki yol)') -Path $p -Exists $pi.Exists -Removed $pi.Removed -Last $tm -Note ('dosya: ' + $fi.Name)
    }
}

# ---------------------------------------------------------------------
# ---- 33) Vigil Task Parser ----
Step '[17+/17] 33) Vigil Task Parser: gizli/yukseltilmis gorevler, COM isleyiciler, TaskCache eylemleri, calistirma gecmisi...'
Start-Sec
try {
    $tpRoot = $env:WINDIR + '\System32\Tasks'
    $tcBase = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache'
    $tpLastRun = @{}
    $tpIdSet = @{}
    $tpN = 0
    $tpNow = Get-Date
    # --- TaskCache\Tree: SD degeri olmayan gorev = Task Scheduler arayuzunden gizlenmis gorev (Tarrask teknigi) ---
    try {
        $trLen2 = ('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree').Length
        foreach ($k in @(Get-ChildItem -LiteralPath ($tcBase + '\Tree') -Recurse -ErrorAction SilentlyContinue)) {
            $tid = $k.GetValue('Id')
            if (-not $tid) { $k.Close(); continue }
            $tpIdSet[([string]$tid).ToLower()] = 1
            $krel = $k.Name.Substring($trLen2)
            $hasSd = ($null -ne $k.GetValue('SD'))
            $ktm = Get-KeyTime $k
            $k.Close()
            if (-not $hasSd -and $krel -notmatch '(?i)^\\Microsoft\\') {
                Add-Sys ('GIZLI gorev (SD degeri silinmis): ' + $krel) 65 'Gorev kaydinda guvenlik tanimlayicisi (SD) yok: gorev Gorev Zamanlayici arayuzunde ve schtasks ciktisinda gorunmez ama calisir. Kalici gizli baslatma yontemi.' $null ('Id=' + $tid) $ktm
            }
        }
    } catch {}
    # --- TaskCache\Tasks: son calisma zamani + silinmis XML'in eylem (komut) kalintisi ---
    try {
        foreach ($tk in @(Get-ChildItem -LiteralPath ($tcBase + '\Tasks') -ErrorAction SilentlyContinue)) {
            $guid = $tk.PSChildName
            $tpath = [string]$tk.GetValue('Path')
            $dyn = $tk.GetValue('DynamicInfo')
            $actB = $tk.GetValue('Actions')
            $tk.Close()
            $lr = $null
            if ($dyn -is [byte[]] -and $dyn.Length -ge 20) { try { $lr = Hk-Ft ([BitConverter]::ToInt64($dyn, 12)) } catch {} }
            if ($tpath) { $tpLastRun[$tpath.ToLower()] = $lr }
            $isMsT = ($tpath -match '(?i)^\\Microsoft\\')
            $xmlOk = $false
            if ($tpath) { $xmlOk = [bool](Test-Path -LiteralPath ($tpRoot + $tpath)) }
            if (-not $tpIdSet.ContainsKey($guid.ToLower()) -and -not $isMsT -and $tpath) {
                Add-Sys ('Gorev kaydi AGAC (Tree) disinda: ' + $tpath) 25 'TaskCache\Tasks icinde kayit var ama Tree icinde karsiligi yok; gorev gizlenmis veya yarim silinmis olabilir.' $lr ('Id=' + $guid)
            }
            if (($actB -is [byte[]]) -and (-not $xmlOk) -and $tpath) {
                foreach ($ap in (Get-PathsFromBytes $actB $false)) {
                    $api = Get-PiCached $ap
                    Eval-Exec -Kaynak 'Vigil Task Parser (TaskCache eylemi, XML dosyasi silinmis)' -Path $ap -Exists $api.Exists -Removed $api.Removed -Last $lr -Note ('gorev: ' + $tpath + ' | gorev dosyasi artik yok, komut kayit defteri kalintisindan okundu')
                }
            }
        }
    } catch {}

    # --- XML gorevleri: derin analiz (step 12 ile ayni gorevleri farkli sinyallerle degerlendirir) ---
    $interpRx = '(?i)(^|\\)(cmd|powershell|pwsh|wscript|cscript|mshta|rundll32|regsvr32|msbuild|installutil|regasm|bitsadmin|certutil|forfiles)(\.exe)?$'
    if (Test-Path -LiteralPath $tpRoot) {
        foreach ($tf in @(Get-ChildItem -LiteralPath $tpRoot -Recurse -File -Force -ErrorAction SilentlyContinue)) {
            $rel = $tf.FullName.Substring($tpRoot.Length)
            $isMs = ($rel -match '(?i)^\\Microsoft\\')
            $xml = $null
            try { $xml = [xml](Get-Content -LiteralPath $tf.FullName -Raw -ErrorAction Stop) } catch {}
            if (-not $xml -or -not $xml.Task) { continue }
            $tpN++
            $sc = 0
            $why = New-Object System.Collections.Generic.List[string]
            $hidden = ([string]$xml.Task.Settings.Hidden -ieq 'true')
            $disabled = ([string]$xml.Task.Settings.Enabled -ieq 'false')
            $runLvl = ''; $uid = ''
            try { $runLvl = [string]$xml.Task.Principals.Principal.RunLevel; $uid = [string]$xml.Task.Principals.Principal.UserId } catch {}
            $isSysUser = ($uid -match '(?i)^(S-1-5-18|SYSTEM|NT AUTHORITY\\SYSTEM)$')
            $author = ''; $regDate = $null
            try { $author = [string]$xml.Task.RegistrationInfo.Author } catch {}
            try { $rdS = [string]$xml.Task.RegistrationInfo.Date; if ($rdS) { $rdT = [datetime]::MinValue; if ([datetime]::TryParse($rdS, [ref]$rdT)) { $regDate = $rdT } } } catch {}
            $tname = $tf.Name
            $lastRun = $null
            if ($tpLastRun.ContainsKey($rel.ToLower())) { $lastRun = $tpLastRun[$rel.ToLower()] }
            $when = $lastRun; if (-not $when) { $when = $tf.LastWriteTime }
            $newTask = (($regDate -and $regDate -gt $tpNow.AddDays(-14)) -or $tf.CreationTime -gt $tpNow.AddDays(-14))
            if (-not $isMs) {
                if ($hidden) { $sc += 30; [void]$why.Add('gizli gorev (Settings/Hidden=true)') }
                $th = Get-NameHit ($tname + ' ' + $author) $false
                if ($th) { $sc += 45; [void]$why.Add('gorev adi/yazari hile ismi: ' + $th.Name) }
                if ((Test-MixedRandom $tname) -or (Test-Gibberish $tname)) { $sc += 15; [void]$why.Add('rastgele/anlamsiz gorev adi') }
            }
            # tetikleyiciler
            $trig = ''
            try { if ($xml.Task.Triggers) { $trig = (@($xml.Task.Triggers.ChildNodes | ForEach-Object { $_.LocalName }) -join ',') } } catch {}
            # Exec eylemleri
            $zoneBad = $false
            foreach ($ex in @($xml.Task.Actions.Exec)) {
                if (-not $ex) { continue }
                $cmd = [string]$ex.Command
                if (-not $cmd) { continue }
                $targ = [string]$ex.Arguments
                $cmdX = [Environment]::ExpandEnvironmentVariables($cmd).Trim().Trim('"')
                $targX = [Environment]::ExpandEnvironmentVariables($targ)
                $wd = [Environment]::ExpandEnvironmentVariables([string]$ex.WorkingDirectory)
                if ($isMs) {
                    # Microsoft klasorunde yalnizca sistem disi bir yola isaret edenler veya hile ismi tasiyanlar
                    $mz = Get-Zone $cmdX
                    if ($cmdX -match '^[A-Za-z]:\\' -and ($mz -eq 'user' -or $mz -eq 'temp' -or $mz -eq 'appdata' -or $mz -eq 'shared')) { $sc += 40; $zoneBad = $true; [void]$why.Add('Microsoft klasorundeki gorev kullanici/temp klasorundeki programi calistiriyor (gorev adi taklidi)') }
                    elseif (Get-NameHit ($cmdX + ' ' + $targX) $false) { $sc += 45; [void]$why.Add('Microsoft klasorundeki gorevde hile ismi') }
                    continue
                }
                $czone = Get-Zone $cmdX
                $userZone = ($czone -eq 'user' -or $czone -eq 'temp' -or $czone -eq 'appdata' -or $czone -eq 'shared')
                if ($userZone) { $zoneBad = $true }
                $isInterp = ($cmdX -match $interpRx)
                $argPaths = @(Find-Paths $targX 'exe|dll|jar|bat|ps1|cmd|vbs|js|scr|hta')
                foreach ($ap in $argPaths) { $az = Get-Zone $ap; if ($az -eq 'user' -or $az -eq 'temp' -or $az -eq 'appdata' -or $az -eq 'shared') { $zoneBad = $true } }
                if ($cmdX -match '^\\\\' -or $targX -match '(?i)\\\\[A-Za-z0-9\.\-]+\\[A-Za-z0-9\$]+\\') { $sc += 15; [void]$why.Add('ag (UNC) yolundan calistirma') }
                if ($isInterp -and ($zoneBad -or $targX -match '(?i)https?://|-enc|-w(indowstyle)?\s+h(idden)?|bypass|downloadstring|frombase64')) { $sc += 25; [void]$why.Add('yorumlayici (' + (Split-Path -Leaf $cmdX) + ') kullanici klasorundeki dosya/web adresi/gizli arguman ile calisiyor') }
                if ($userZone -and $isSysUser) { $sc += 25; [void]$why.Add('SYSTEM yetkisiyle kullanici-yazilabilir klasorden program (yetki yukseltme/kalicilik)') }
                if ($userZone -and $runLvl -ieq 'HighestAvailable') { $sc += 20; [void]$why.Add('UAC sorusu olmadan yukseltilmis (HighestAvailable) calisan kullanici klasoru programi') }
                if ($cmdX -match '^[A-Za-z]:\\' -and (Test-Path -LiteralPath $cmdX) -and ($czone -ne 'system') -and (-not (Test-Signed $cmdX))) { $sc += 12; [void]$why.Add('gorev programi dijital olarak imzasiz') }
                if ($wd -match '^[A-Za-z]:\\') { $wz = Get-Zone ($wd.TrimEnd('\') + '\x'); if ($wz -eq 'temp') { $sc += 8; [void]$why.Add('calisma klasoru Temp') } }
                if ($newTask -and $zoneBad) { $sc += 10; [void]$why.Add('son 14 gunde olusturulmus') }
                # calistirma gecmisi (TaskCache DynamicInfo) icin Eval-Exec
                $cpi = Get-PiCached $cmdX
                if ($cmdX -match '^[A-Za-z]:\\') { Eval-Exec -Kaynak 'Vigil Task Parser (gorev programi)' -Path $cmdX -Exists $cpi.Exists -Removed $cpi.Removed -Last $when -First $regDate -Note ('gorev: ' + $rel + ' | tetikleyici: ' + $trig) }
            }
            # COM isleyici eylemleri: CLSID -> InprocServer32 yolu (COM hijacking / DLL tabanli gorev)
            foreach ($ch in @($xml.Task.Actions.ComHandler)) {
                if (-not $ch) { continue }
                $cid = [string]$ch.ClassId
                if (-not $cid) { continue }
                $dllP = ''
                try { $dllP = [string](Get-ItemProperty -LiteralPath ('Registry::HKEY_CLASSES_ROOT\CLSID\' + $cid + '\InprocServer32') -ErrorAction Stop).'(default)' } catch {}
                if (-not $dllP) { try { $dllP = [string](Get-Item -LiteralPath ('Registry::HKEY_CLASSES_ROOT\CLSID\' + $cid + '\InprocServer32') -ErrorAction Stop).GetValue('') } catch {} }
                $dllX = [Environment]::ExpandEnvironmentVariables($dllP).Trim().Trim('"')
                $hijack = $false
                try { if (Test-Path -LiteralPath ('HKCU:\Software\Classes\CLSID\' + $cid)) { $hijack = $true } } catch {}
                if ($hijack) { $sc += 40; [void]$why.Add('COM isleyici CLSID ' + $cid + ' HKCU altinda da tanimli (COM hijacking)') }
                if ($dllX -match '^[A-Za-z]:\\') {
                    $dz = Get-Zone $dllX
                    $dpi = Get-PiCached $dllX
                    if (-not $isMs -and ($dz -eq 'user' -or $dz -eq 'temp' -or $dz -eq 'appdata' -or $dz -eq 'shared' -or -not $dpi.Exists)) { $sc += 35; [void]$why.Add('COM isleyici DLL kullanici klasorunde veya yok: ' + $dllX) }
                    Eval-Exec -Kaynak 'Vigil Task Parser (COM isleyici DLL)' -Path $dllX -Exists $dpi.Exists -Removed $dpi.Removed -Last $when -Note ('gorev: ' + $rel + ' | CLSID ' + $cid)
                } elseif (-not $isMs -and -not $dllP) { $sc += 15; [void]$why.Add('COM isleyici CLSID ' + $cid + ' kayit defterinde cozulemedi') }
            }
            if (-not $isMs) {
                foreach ($odd in @('SendEmail', 'ShowMessage')) { if ($xml.Task.Actions.$odd) { $sc += 15; [void]$why.Add('kullanilmayan/eski eylem turu: ' + $odd) } }
            }
            if ($disabled -and $sc -gt 0) { $sc = [int]($sc * 0.6); [void]$why.Add('gorev su an devre disi') }
            if ($sc -ge 20) {
                $nt = ($why -join '; ') + ' | yazar: ' + $author + ' | kullanici: ' + $uid + ' | tetikleyici: ' + $trig
                if ($lastRun) { $nt = $nt + ' | son calisma: ' + (Fmt $lastRun) }
                Add-F -Kaynak 'Vigil Task Parser' -Ad ('gorev (derin): ' + $tname.ToLower()) -Yol $rel -Skor ([Math]::Min(100, $sc)) -Son $when -Ilk $regDate -Var 'Evet' -Not $nt
            }
        }
    }
    Log ('   ' + $tpN + ' gorev derin incelendi (TaskCache + XML).') 'DarkGray'

    # --- Gorev Zamanlayici olay gunlugu: kaydedilen/guncellenen (106/140) ve baslatilan (200) gorevler ---
    try {
        $evShown = 0
        foreach ($e in @(Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-TaskScheduler/Operational'; Id = 106, 140 } -MaxEvents 80 -ErrorAction Stop)) {
            $qm = [regex]::Matches([string]$e.Message, '"([^"]+)"')
            $tn = ''
            if ($qm.Count -gt 0) { $tn = $qm[$qm.Count - 1].Groups[1].Value }
            if (-not $tn -or $tn -match '(?i)^\\Microsoft\\') { continue }
            $eh = Get-NameHit $tn $false
            if ($eh) { Add-F -Kaynak ('Vigil Task Parser (olay ' + $e.Id + ')') -Ad ('gorev: ' + $tn.ToLower()) -Yol $tn -Skor 60 -Son $e.TimeCreated -Var 'Bilinmiyor' -Not 'gorev adinda hile ismi; gorev kaydedildi/guncellendi' }
            elseif ($e.TimeCreated -gt $tpNow.AddDays(-7) -and $evShown -lt 8) { $evShown++; Add-Sys ('Gorev ' + $(if ($e.Id -eq 106) { 'kaydedildi' } else { 'guncellendi' }) + ' (son 7 gun, olay ' + $e.Id + '): ' + $tn) 12 'Microsoft disi bir gorev yakin zamanda olusturulmus/degistirilmis.' $e.TimeCreated }
        }
    } catch {}
    try {
        foreach ($e in @(Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-TaskScheduler/Operational'; Id = 200 } -MaxEvents 200 -ErrorAction Stop)) {
            foreach ($ap in (Find-Paths ([string]$e.Message) 'exe|dll|jar|bat|ps1|cmd|vbs|scr|hta')) {
                $api = Get-PiCached $ap
                Eval-Exec -Kaynak 'Vigil Task Parser (olay 200: gorev eylemi baslatildi)' -Path $ap -Exists $api.Exists -Removed $api.Removed -Last $e.TimeCreated -Note 'Gorev Zamanlayici bu programi baslatmis'
            }
        }
    } catch {}
} catch {}
Show-Section

# ---- 34) Vigil Registry Scanner ----
Step '[17+/17] 34) Vigil Registry Scanner: kalicilik (IFEO/Winlogon/AppInit/COM/servis), calistirma gecmisi (FeatureUsage/RecentApps/guvenlik duvari), iz silme...'
Start-Sec
function Vr-Cmd([string]$cmd, [string]$kaynak, [string]$desc, $when) {
    if ([string]::IsNullOrWhiteSpace($cmd)) { return }
    $cx = [Environment]::ExpandEnvironmentVariables($cmd)
    if ($cx -match $script:FlRx2) { Add-F -Kaynak $kaynak -Ad ('komut: ' + $desc.ToLower()) -Yol $cx -Skor 55 -Son $when -Var 'Evet' -Not ($desc + ' | komutta fileless/script kalibi var') }
    $vh = Get-NameHit $cx $false
    if ($vh) { Add-F -Kaynak $kaynak -Ad ('komut: ' + $desc.ToLower()) -Yol $cx -Skor 60 -Son $when -Var 'Evet' -Not ($desc + ' | komutta hile ismi: ' + $vh.Name) }
    $vp = New-Object System.Collections.Generic.List[string]
    if ($cx -match '(?i)^\s*"([^"]+)"') { [void]$vp.Add($Matches[1]) } elseif ($cx -match '(?i)^\s*([A-Za-z]:\\.*?\.(?:exe|bat|cmd|ps1|vbs|jar|scr|com|dll|sys))') { [void]$vp.Add($Matches[1]) }
    foreach ($x in (Find-Paths $cx 'exe|bat|cmd|ps1|vbs|jar|dll|scr|sys|hta')) { [void]$vp.Add($x) }
    $vs = @{}
    foreach ($ep in $vp) {
        if ($ep -notmatch '^[A-Za-z]:\\') { continue }
        $k = $ep.ToLower()
        if ($vs.ContainsKey($k)) { continue }
        $vs[$k] = 1
        $pi = Get-PiCached $ep
        Eval-Exec -Kaynak $kaynak -Path $ep -Exists $pi.Exists -Removed $pi.Removed -Last $when -Note $desc
    }
}
function Vr-Val([string]$key, [string]$name) {
    try { return (Get-ItemProperty -LiteralPath $key -Name $name -ErrorAction Stop).$name } catch { return $null }
}
$vrN = 0
try {
    # 1) IFEO Debugger / GlobalFlag + SilentProcessExit MonitorProcess
    foreach ($ib in @('HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\Image File Execution Options')) {
        foreach ($ik in @(Get-ChildItem -LiteralPath $ib -ErrorAction SilentlyContinue)) {
            $vrN++
            $dbg = [string]$ik.GetValue('Debugger')
            $gf = $ik.GetValue('GlobalFlag')
            $vd = [string]$ik.GetValue('VerifierDlls')
            $it = Get-KeyTime $ik
            $inm = $ik.PSChildName
            $ikFull = $ik.Name
            $ik.Close()
            if ($dbg) {
                $sc = 50
                if ($inm -match '(?i)^(taskmgr|procexp|procexp64|procmon|procmon64|systeminformer|processhacker|regedit|cmd|powershell|mmc|eventvwr|msconfig|autoruns|autoruns64|wevtutil|MsMpEng|MpCmdRun|SecurityHealthSystray|sihost|explorer|csrss|lsass)\.exe$') { $sc = 75 }
                Add-Sys ('IFEO Debugger ayarli: ' + $inm + ' -> ' + $dbg) $sc 'Image File Execution Options: bu program her acildiginda baska bir komut calisir/engellenir (arac engelleme veya kalici calistirma yontemi).' $null ('anahtar: ' + $ikFull) $it
                Vr-Cmd $dbg 'Vigil Registry: IFEO Debugger' ('IFEO ' + $inm) $it
            }
            if ($null -ne $gf -and (([int]$gf -band 0x200) -ne 0)) { Add-Sys ('IFEO GlobalFlag SilentProcessExit: ' + $inm) 40 'Program cikisinda ek bir komut/izleme tetiklenecek sekilde ayarlanmis (kalici calistirma yontemi).' $null ('GlobalFlag=0x' + ([int]$gf).ToString('X')) $it }
            if ($vd) { Add-Sys ('IFEO VerifierDlls ayarli: ' + $inm) 55 'Programa DLL enjekte etmek icin kullanilabilen Application Verifier ayari.' $null $vd $it; Vr-Cmd $vd 'Vigil Registry: IFEO VerifierDlls' ('IFEO ' + $inm) $it }
        }
    }
    foreach ($sk in @(Get-ChildItem -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SilentProcessExit' -ErrorAction SilentlyContinue)) {
        $vrN++
        $mp = [string]$sk.GetValue('MonitorProcess')
        $st = Get-KeyTime $sk
        $snm = $sk.PSChildName
        $sk.Close()
        if ($mp) { Add-Sys ('SilentProcessExit MonitorProcess: ' + $snm + ' -> ' + $mp) 55 'Program kapaninca calisacak komut tanimlanmis (kalici calistirma yontemi).' $null '' $st; Vr-Cmd $mp 'Vigil Registry: SilentProcessExit' ('SPE ' + $snm) $st }
    }
    # 2) AppInit_DLLs / Windows Load-Run
    foreach ($wk in @('HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\Windows')) {
        $vrN++
        $ai = [string](Vr-Val $wk 'AppInit_DLLs')
        $li = Vr-Val $wk 'LoadAppInit_DLLs'
        if ($ai -and $ai.Trim()) { $scA = 45; if ($null -ne $li -and [int]$li -eq 1) { $scA = 70 }; Add-Sys ('AppInit_DLLs dolu: ' + $ai) $scA ('Her GUI programina DLL yukleyen eski mekanizma (LoadAppInit_DLLs=' + $li + '). Hile enjektoru/kalicilik icin kullanilabilir.') $null $wk; Vr-Cmd $ai 'Vigil Registry: AppInit_DLLs' 'AppInit' $null }
        foreach ($lv in @('Load', 'Run')) { $lvv = [string](Vr-Val $wk $lv); if ($lvv -and $lvv.Trim()) { Add-Sys ('Windows\' + $lv + ' degeri dolu: ' + $lvv) 45 'Eski otomatik baslatma degeri; normalde bos olur.' $null $wk; Vr-Cmd $lvv 'Vigil Registry: Windows Load/Run' $lv $null } }
    }
    # 3) Winlogon Shell/Userinit/Taskman/AppSetup (HKLM + HKCU)
    foreach ($wl in @('HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon', 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon')) {
        $vrN++
        $sh = [string](Vr-Val $wl 'Shell')
        if ($sh -and $sh.Trim() -and $sh.Trim() -notmatch '(?i)^explorer\.exe$') { Add-Sys ('Winlogon Shell degistirilmis: ' + $sh) 65 'Oturum acilinca calisan kabuk explorer.exe degil.' $null $wl; Vr-Cmd $sh 'Vigil Registry: Winlogon Shell' 'Shell' $null }
        $ui = [string](Vr-Val $wl 'Userinit')
        if ($ui -and $ui.Trim() -and $ui.Trim().TrimEnd(',') -notmatch '(?i)^[A-Za-z]:\\Windows\\system32\\userinit\.exe$') { Add-Sys ('Winlogon Userinit degistirilmis: ' + $ui) 65 'Userinit normalde yalnizca userinit.exe icerir; ek komut kalici calistirma saglar.' $null $wl; Vr-Cmd $ui 'Vigil Registry: Winlogon Userinit' 'Userinit' $null }
        foreach ($wn in @('Taskman', 'AppSetup', 'GinaDLL', 'System', 'UIHost')) { $wv = [string](Vr-Val $wl $wn); if ($wv -and $wv.Trim()) { Add-Sys ('Winlogon ' + $wn + ' ayarli: ' + $wv) 55 'Winlogon uzerinden ek program/DLL yuklenmesi (olagan disi).' $null $wl; Vr-Cmd $wv 'Vigil Registry: Winlogon' $wn $null } }
    }
    # 4) Session Manager: BootExecute / SetupExecute / PlatformExecute, AppCertDLLs
    $smk = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    $vrN++
    foreach ($bn in @('BootExecute', 'SetupExecute', 'PlatformExecute', 'S0InitialCommand')) {
        $bv = Vr-Val $smk $bn
        if ($null -eq $bv) { continue }
        $bt = (@($bv) | Where-Object { $_ -and ([string]$_).Trim() }) -join ' | '
        if (-not $bt) { continue }
        if ($bn -eq 'BootExecute' -and $bt -match '(?i)^autocheck autochk \*$') { continue }
        Add-Sys ('Session Manager ' + $bn + ' olagan disi: ' + $bt) 55 'Acilista cekirdek asamasinda calisan komut listesi degistirilmis.' $null $smk
    }
    foreach ($acd in @(Get-Item -LiteralPath ($smk + '\AppCertDlls') -ErrorAction SilentlyContinue)) {
        foreach ($an in $acd.GetValueNames()) { $av = [string]$acd.GetValue($an); if ($av) { Add-Sys ('AppCertDlls kaydi: ' + $an + ' -> ' + $av) 60 'Her process olusturmada DLL yukleyen mekanizma (olagan disi).' $null $smk; Vr-Cmd $av 'Vigil Registry: AppCertDlls' $an $null } }
    }
    # 5) Active Setup StubPath (HKLM + HKCU)
    foreach ($asb in @('HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components', 'HKCU:\SOFTWARE\Microsoft\Active Setup\Installed Components')) {
        foreach ($ak in @(Get-ChildItem -LiteralPath $asb -ErrorAction SilentlyContinue)) {
            $vrN++
            $stub = [string]$ak.GetValue('StubPath')
            $at = Get-KeyTime $ak
            $ak.Close()
            if ($stub) { Vr-Cmd $stub 'Vigil Registry: Active Setup' ('ActiveSetup ' + $ak.PSChildName) $at }
        }
    }
    # 6) Command Processor AutoRun, UserInitMprLogonScript, Run-benzeri tek degerler
    foreach ($cp in @('HKCU:\Software\Microsoft\Command Processor', 'HKLM:\Software\Microsoft\Command Processor')) {
        $vrN++
        $ar = [string](Vr-Val $cp 'AutoRun')
        if ($ar -and $ar.Trim()) { Add-Sys ('cmd.exe AutoRun ayarli: ' + $ar) 50 'Her cmd.exe acilisinda calisan komut (kalici calistirma / izleme).' $null $cp; Vr-Cmd $ar 'Vigil Registry: cmd AutoRun' 'AutoRun' $null }
    }
    $umls = [string](Vr-Val 'HKCU:\Environment' 'UserInitMprLogonScript')
    if ($umls -and $umls.Trim()) { Add-Sys ('UserInitMprLogonScript ayarli: ' + $umls) 55 'Oturum acilisinda calisan logon script kaydi (kalici calistirma yontemi).' $null 'HKCU:\Environment'; Vr-Cmd $umls 'Vigil Registry: UserInitMprLogonScript' 'LogonScript' $null }
    # 7) Dosya iliskilendirme / UAC bypass anahtarlari (HKCU altinda olmamasi gerekenler)
    foreach ($hj in @('exefile', 'ms-settings', 'mscfile', 'Folder', 'Launcher.SystemSettings', 'AppX82a6gwre4fdg3bt635tn5ctqjf8msdd2')) {
        $hk = 'HKCU:\Software\Classes\' + $hj + '\shell\open\command'
        if (Test-Path -LiteralPath $hk) {
            $vrN++
            $hv = [string](Vr-Val $hk '(default)')
            if (-not $hv) { try { $hv = [string](Get-Item -LiteralPath $hk).GetValue('') } catch {} }
            if ($hj -eq 'exefile' -and $hv.Trim() -match '^"%1"\s+%\*$') { continue }
            Add-Sys ('HKCU dosya iliskilendirme/UAC bypass anahtari: ' + $hj + '\shell\open\command') 60 ('Komut: ' + $hv + ' | Bu anahtarlar HKCU altinda normalde yoktur; UAC bypass veya program yakalama icin kullanilir.') $null $hk
            Vr-Cmd $hv 'Vigil Registry: dosya iliskilendirme' $hj $null
        }
    }
    # 8) Servis ImagePath / ServiceDll: kullanici-yazilabilir klasorden calisan servis/surucu
    $svCnt = 0
    foreach ($sv in @(Get-ChildItem -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services' -ErrorAction SilentlyContinue)) {
        $svCnt++
        $img = [string]$sv.GetValue('ImagePath')
        $stt = $sv.GetValue('Start')
        $svt = Get-KeyTime $sv
        $svn = $sv.PSChildName
        $sdll = ''
        try { $pk = $sv.OpenSubKey('Parameters'); if ($pk) { $sdll = [string]$pk.GetValue('ServiceDll'); $pk.Close() } } catch {}
        $sv.Close()
        foreach ($raw in @($img, $sdll)) {
            if (-not $raw) { continue }
            $r2 = [Environment]::ExpandEnvironmentVariables($raw).Trim()
            $r2 = $r2 -replace '^\\\?\?\\', ''
            $r2 = $r2 -replace '(?i)^\\SystemRoot\\', ($env:SystemRoot + '\')
            if ($r2 -match '(?i)^system32\\') { $r2 = $env:SystemRoot + '\' + $r2 }
            $sp = $null
            if ($r2 -match '(?i)^\s*"?([A-Za-z]:\\[^"]*?\.(?:exe|sys|dll))') { $sp = $Matches[1] }
            if (-not $sp) { continue }
            $sz = Get-Zone $sp
            if ($sz -eq 'user' -or $sz -eq 'temp' -or $sz -eq 'appdata' -or $sz -eq 'shared') {
                $spi = Get-PiCached $sp
                $sc = 50
                if ($spi.Exists -and -not (Test-Signed $sp)) { $sc += 20 }
                if (-not $spi.Exists) { $sc += 10 }
                Add-F -Kaynak 'Vigil Registry: servis/surucu yolu' -Ad ('servis: ' + $svn.ToLower()) -Yol $sp -Skor ([Math]::Min(100, $sc)) -Son $svt -Var $(if ($spi.Exists) { 'Evet' } else { 'Hayir' }) -Not ('servis kullanici/temp/AppData/ortak klasorden calisiyor | Start=' + $stt + ' | anahtar son degisim: ' + (Fmt $svt))
            } elseif ($raw -eq $img) {
                $hn = Get-NameHit $svn $false
                if ($hn) { Add-F -Kaynak 'Vigil Registry: servis/surucu yolu' -Ad ('servis: ' + $svn.ToLower()) -Yol $sp -Skor 55 -Son $svt -Var 'Bilinmiyor' -Not ('servis adinda hile ismi: ' + $hn.Name) }
            }
        }
    }
    Log ('   ' + $svCnt + ' servis kaydi (ImagePath/ServiceDll) incelendi.') 'DarkGray'
    # 9) COM hijacking: HKCU\Software\Classes\CLSID altindaki sunucu kayitlari
    $comN = 0
    foreach ($ck in @(Get-ChildItem -LiteralPath 'HKCU:\Software\Classes\CLSID' -ErrorAction SilentlyContinue)) {
        if ($comN -ge 600) { break }
        $comN++
        $cid = $ck.PSChildName
        foreach ($sub in @('InprocServer32', 'LocalServer32')) {
            $sk2 = $null
            try { $sk2 = $ck.OpenSubKey($sub) } catch {}
            if (-not $sk2) { continue }
            $cv = [string]$sk2.GetValue('')
            $ct = Get-KeyTime $sk2
            $sk2.Close()
            if (-not $cv) { continue }
            $cx2 = [Environment]::ExpandEnvironmentVariables($cv).Trim().Trim('"')
            $dup = $false
            try { $dup = [bool](Test-Path -LiteralPath ('HKLM:\SOFTWARE\Classes\CLSID\' + $cid)) } catch {}
            $zz = Get-Zone $cx2
            $cpi2 = Get-PiCached $cx2
            $sc = 0
            $why2 = New-Object System.Collections.Generic.List[string]
            if ($dup) { $sc += 30; [void]$why2.Add('HKLM de kayitli CLSID u HKCU eziyor (COM hijacking)') }
            if ($zz -eq 'user' -or $zz -eq 'temp' -or $zz -eq 'appdata' -or $zz -eq 'shared') { $sc += 30; [void]$why2.Add('sunucu kullanici/temp/AppData klasorunde') }
            if ($cx2 -match '^[A-Za-z]:\\' -and -not $cpi2.Exists) { $sc += 15; [void]$why2.Add('sunucu dosyasi yok') }
            if ($sc -ge 30) { Add-F -Kaynak 'Vigil Registry: COM kaydi (HKCU)' -Ad ('clsid: ' + $cid.ToLower()) -Yol $cx2 -Skor ([Math]::Min(100, $sc)) -Son $ct -Var $(if ($cpi2.Exists) { 'Evet' } else { 'Hayir' }) -Not (($why2 -join '; ') + ' | ' + $sub) }
        }
        $ck.Close()
    }
    Log ('   ' + $comN + ' HKCU COM (CLSID) kaydi incelendi.') 'DarkGray'
    # 10) Explorer politikalari: DisallowRun (arac engelleme), DisableRegistryTools/TaskMgr/CMD
    foreach ($pb in @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer', 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer')) {
        $vrN++
        $dr = Vr-Val $pb 'DisallowRun'
        if ($null -ne $dr -and [int]$dr -eq 1) {
            $drk = $null
            try { $drk = Get-Item -LiteralPath ($pb + '\DisallowRun') -ErrorAction Stop } catch {}
            if ($drk) {
                $blk = @($drk.GetValueNames() | ForEach-Object { [string]$drk.GetValue($_) } | Where-Object { $_ })
                $drk.Close()
                $tools = @($blk | Where-Object { $_ -match '(?i)processhacker|systeminformer|procexp|procmon|regedit|taskmgr|autoruns|everything|wireshark|eventvwr|recuva|usbdeview|strings|echo|journal|mftecmd|prefetch|shellbag|winprefetch|lastactivity|bamparser|fileseek|hxd|x64dbg|cheatengine' })
                if ($tools.Count -gt 0) { Add-Sys ('DisallowRun ile kontrol/arac programlari engellenmis: ' + ($tools -join ', ')) 60 'Bu programlarin calismasi politikayla engellenmis (ekran paylasimi/kontrol araclarini calistirmayi onleme yontemi).' $null $pb }
                elseif ($blk.Count -gt 0) { Add-Sys ('DisallowRun listesi dolu (' + $blk.Count + ' program): ' + (($blk | Select-Object -First 6) -join ', ')) 25 'Bazi programlarin calismasi politikayla engellenmis.' $null $pb }
            }
        }
        foreach ($pr in @(@('DisableRegistryTools', 'Kayit defteri araclari (regedit) politikayla kapatilmis', 50), @('DisableTaskMgr', 'Gorev Yoneticisi politikayla kapatilmis', 45), @('DisableCMD', 'Komut istemi politikayla kapatilmis', 25))) {
            $pv = Vr-Val ($pb -replace 'Explorer$', 'System') $pr[0]
            if ($null -ne $pv -and [int]$pv -ge 1) { Add-Sys $pr[1] $pr[2] ('Kayit defteri: ' + ($pb -replace 'Explorer$', 'System') + ' | ' + $pr[0] + ' = ' + $pv) $null 'ayarli' }
        }
    }
    # 11) Regedit son ziyaret edilen anahtar: iz silme kaniti
    $rl = [string](Vr-Val 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit' 'LastKey')
    if ($rl) {
        if ($rl -match '(?i)\\(bam|UserAssist|MuiCache|AppCompatCache|AppCompatFlags|Compatibility Assistant|Amcache|ComDlg32|RecentDocs|RunMRU|BagMRU|Bags|TypedPaths|Prefetch|Schedule\\TaskCache|Services\\bam|Persisted|Store|FeatureUsage|RecentApps|TaskCache)(\\|$)') {
            Add-Sys ('Regedit son acik anahtar bir iz/gecmis anahtari: ' + $rl) 45 'Regedit en son bir calistirma gecmisi/iz anahtarinda acik kalmis: kullanici bu kayitlari elle duzenlemis/silmis olabilir.' $null 'HKCU\...\Applets\Regedit\LastKey'
        } else { Log ('   Regedit son anahtar: ' + $rl) 'DarkGray' }
    }
    # 12) Calistirma gecmisi kayitlari: FeatureUsage\AppSwitched/AppLaunch, RecentApps, JumplistData, App Paths
    $fuBase = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage'
    $fuN = 0
    foreach ($fu in @('AppSwitched', 'AppLaunch')) {
        $fk = $null
        try { $fk = Get-Item -LiteralPath ($fuBase + '\' + $fu) -ErrorAction Stop } catch {}
        if (-not $fk) { continue }
        $fkt = Get-KeyTime $fk
        foreach ($vn in $fk.GetValueNames()) {
            if ($vn -notmatch '^[A-Za-z]:\\') { continue }
            $fuN++
            $fpi = Get-PiCached $vn
            Eval-Exec -Kaynak ('Vigil Registry: FeatureUsage\' + $fu) -Path $vn -Exists $fpi.Exists -Removed $fpi.Removed -Last $null -Note ('gorev cubugu/baslatma kullanim sayaci: ' + [string]$fk.GetValue($vn) + ' | anahtar son degisim: ' + (Fmt $fkt))
        }
        $fk.Close()
    }
    $raN = 0
    foreach ($ra in @(Get-ChildItem -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\RecentApps' -ErrorAction SilentlyContinue)) {
        $aid = [string]$ra.GetValue('AppId')
        $lat = $null
        $lb = $ra.GetValue('LastAccessedTime')
        if ($lb -is [byte[]] -and $lb.Length -ge 8) { try { $lat = Hk-Ft ([BitConverter]::ToInt64($lb, 0)) } catch {} }
        $lc2 = [string]$ra.GetValue('LaunchCount')
        $ra.Close()
        if ($aid -match '^[A-Za-z]:\\') { $raN++; $rpi = Get-PiCached $aid; Eval-Exec -Kaynak 'Vigil Registry: RecentApps' -Path $aid -Exists $rpi.Exists -Removed $rpi.Removed -Last $lat -Note ('baslatma sayisi: ' + $lc2) }
    }
    $jk = $null
    try { $jk = Get-Item -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\JumplistData' -ErrorAction Stop } catch {}
    if ($jk) {
        foreach ($vn in $jk.GetValueNames()) {
            if ($vn -notmatch '^[A-Za-z]:\\') { continue }
            $jb = $jk.GetValue($vn)
            $jt = $null
            if ($jb -is [byte[]] -and $jb.Length -ge 8) { try { $jt = Hk-Ft ([BitConverter]::ToInt64($jb, 0)) } catch {} }
            $jpi = Get-PiCached $vn
            Eval-Exec -Kaynak 'Vigil Registry: Search JumplistData' -Path $vn -Exists $jpi.Exists -Removed $jpi.Removed -Last $jt -Note 'arama/jumplist verisinde program kaydi'
        }
        $jk.Close()
    }
    foreach ($apb in @('HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths', 'HKLM:\Software\Microsoft\Windows\CurrentVersion\App Paths', 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths')) {
        foreach ($apk in @(Get-ChildItem -LiteralPath $apb -ErrorAction SilentlyContinue)) {
            $apv = [string]$apk.GetValue('')
            $apt = Get-KeyTime $apk
            $apk.Close()
            if ($apv) { Vr-Cmd $apv 'Vigil Registry: App Paths' ('AppPaths ' + $apk.PSChildName) $apt }
        }
    }
    Log ('   FeatureUsage ' + $fuN + ' kayit, RecentApps ' + $raN + ' kayit incelendi.') 'DarkGray'
    # 13) Guvenlik duvari kurallari (kayit defterinden): kullanici klasorundeki programlar icin izin/engel kurallari
    $fwN = 0
    $fwk = $null
    try { $fwk = Get-Item -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules' -ErrorAction Stop } catch {}
    if ($fwk) {
        $fwT = Get-KeyTime $fwk
        foreach ($vn in $fwk.GetValueNames()) {
            $rv = [string]$fwk.GetValue($vn)
            if ($rv -match '(?i)\|App=([A-Za-z]:\\[^|]+?)\|') { $app = $Matches[1] } else { continue }
            $fwN++
            if ($fwN -gt 4000) { break }
            $z = Get-Zone $app
            if ($z -eq 'system') { continue }
            $act = ''; if ($rv -match '\|Action=(\w+)\|') { $act = $Matches[1] }
            $nm = ''; if ($rv -match '\|Name=([^|]+)\|') { $nm = $Matches[1] }
            $fpi = Get-PiCached $app
            Eval-Exec -Kaynak 'Vigil Registry: guvenlik duvari kurali' -Path $app -Exists $fpi.Exists -Removed $fpi.Removed -Last $null -Note ('kural: ' + $nm + ' | eylem: ' + $act + ' | kural anahtari son degisim: ' + (Fmt $fwT))
        }
        $fwk.Close()
    }
    Log ('   ' + $fwN + ' guvenlik duvari kurali (program yolu olan) incelendi.') 'DarkGray'
} catch {}
Log ('   ' + $vrN + ' kalicilik/politika anahtari incelendi.') 'DarkGray'
Show-Section

# ---- 35) MarsPixel Dump Analyzer ----
Step '[17+/17] 35) MarsPixel Dump Analyzer: RAM/cokme dokumleri (.dmp, MEMORY.DMP, WER, hs_err, hprof) icinde hile ismi, kesin hile stringi, enjeksiyon izi...'
Start-Sec
try {
    $dmpDirs = New-Object System.Collections.Generic.List[string]
    $dmpFiles = New-Object System.Collections.Generic.List[object]
    $dmpSeen = @{}
    $dmpExt = '(?i)\.(dmp|mdmp|hdmp|dump|hprof|raw|mem|vmem)$'
    $dmpUsers = @()
    try { $dmpUsers = @(Get-ChildItem -LiteralPath ($env:SystemDrive + '\Users') -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '(?i)^(All Users|Default|Default User|Public)$' }) } catch {}
    $std = @(
        @(($env:WINDIR + '\Minidump'), $false),
        @(($env:WINDIR + '\LiveKernelReports'), $true),
        @(($env:ProgramData + '\Microsoft\Windows\WER\ReportArchive'), $true),
        @(($env:ProgramData + '\Microsoft\Windows\WER\ReportQueue'), $true),
        @(($env:WINDIR + '\System32\config\systemprofile\AppData\Local\CrashDumps'), $false),
        @(($env:SystemDrive + '\Users\Public'), $true),
        @(($env:SystemDrive + '\ProcDump'), $true),
        @(($env:SystemDrive + '\Dumps'), $true)
    )
    foreach ($u in $dmpUsers) {
        $ub = $u.FullName
        foreach ($sd in @('Downloads', 'Desktop', 'Documents', 'AppData\Local\CrashDumps', 'AppData\Local\Temp', 'AppData\Local\Microsoft\Windows\WER\ReportArchive', 'AppData\Local\Microsoft\Windows\WER\ReportQueue', 'AppData\Roaming\.minecraft', 'AppData\Roaming\.tlauncher', 'AppData\Roaming\.lunarclient')) { $std += , @(($ub + '\' + $sd), $true) }
    }
    if ($env:HK_DUMP) { foreach ($hd in ($env:HK_DUMP -split ';')) { if ($hd.Trim()) { $std += , @($hd.Trim(), $true) } } }
    # MEMORY.DMP (tam/cekirdek bellek dokumu)
    $mdp = $env:WINDIR + '\MEMORY.DMP'
    if (Test-Path -LiteralPath $mdp) { $mi = Get-Item -LiteralPath $mdp -Force -ErrorAction SilentlyContinue; if ($mi) { $dmpSeen[$mi.FullName.ToLower()] = 1; [void]$dmpFiles.Add($mi) } }
    foreach ($d in $std) {
        $dp = [string]$d[0]
        if (-not (Test-Path -LiteralPath $dp)) { continue }
        $it0 = Get-Item -LiteralPath $dp -Force -ErrorAction SilentlyContinue
        if ($it0 -and -not $it0.PSIsContainer) { if (-not $dmpSeen.ContainsKey($it0.FullName.ToLower())) { $dmpSeen[$it0.FullName.ToLower()] = 1; [void]$dmpFiles.Add($it0) }; continue }
        $items = @()
        try { if ($d[1]) { $items = @(Get-ChildItem -LiteralPath $dp -Recurse -File -Force -ErrorAction SilentlyContinue | Select-Object -First 4000) } else { $items = @(Get-ChildItem -LiteralPath $dp -File -Force -ErrorAction SilentlyContinue) } } catch {}
        foreach ($f in $items) {
            $isD = ($f.Name -match $dmpExt) -or ($f.Name -match '(?i)^hs_err_pid\d+\.log$') -or ($f.Name -match '(?i)\.wer$')
            if (-not $isD) { continue }
            if ($dmpSeen.ContainsKey($f.FullName.ToLower())) { continue }
            $dmpSeen[$f.FullName.ToLower()] = 1
            [void]$dmpFiles.Add($f)
        }
    }
    $dmpFiles = @($dmpFiles | Sort-Object -Property LastWriteTime -Descending)
    Log ('   ' + $dmpFiles.Count + ' dump / cokme raporu dosyasi bulundu.') 'DarkGray'
    if ($dmpFiles.Count -gt 0 -and $script:DumpOk) {
        $dn = 0
        $budget = [Diagnostics.Stopwatch]::StartNew()
        foreach ($f in $dmpFiles) {
    # (sure siniri kaldirildi)
            if ($f.Length -lt 1024) { continue }
            $dn++
            Set-Frac ([Math]::Min(0.99, $dn / [double][Math]::Max(1, $dmpFiles.Count))) ($f.Name)
            $isJava = ($f.Name -match '(?i)java|minecraft|hs_err|hprof')
            $kind = 'MarsPixel Dump Analyzer'
            # cokme raporlari (.wer): uygulama yolu + modul listesi
            if ($f.Name -match '(?i)\.wer$' -and $f.Length -lt 2MB) {
                $wt = ''
                try { $wt = [IO.File]::ReadAllText($f.FullName) } catch {}
                if ($wt) {
                    foreach ($ap in (Find-Paths $wt 'exe|dll|jar')) { $api = Get-PiCached $ap; Eval-Exec -Kaynak 'MarsPixel: WER cokme raporu' -Path $ap -Exists $api.Exists -Removed $api.Removed -Last $f.LastWriteTime -Note ('rapor: ' + $f.Name) }
                    $wh = Get-NameHit $wt $false
                    if ($wh) { Add-F -Kaynak 'MarsPixel: WER cokme raporu' -Ad $f.Name.ToLower() -Yol $f.FullName -Skor 50 -Son $f.LastWriteTime -Var 'Evet' -Not ('cokme raporunda hile ismi: ' + $wh.Name) }
                }
                continue
            }
            # hs_err_pid*.log: Java cokme gunlugu (yuklu kutuphaneler, JVM argumanlari, modul listesi)
            if ($f.Name -match '(?i)^hs_err_pid\d+\.log$') {
                if ($f.Length -lt 20MB) {
                    $ht = ''
                    try { $ht = [IO.File]::ReadAllText($f.FullName) } catch {}
                    if ($ht) {
                        foreach ($hl in (Get-HitLines $ht 6)) { Add-F -Kaynak 'MarsPixel: Java cokme gunlugu (hs_err)' -Ad $f.Name.ToLower() -Yol $f.FullName -Skor 60 -Son $f.LastWriteTime -Var 'Evet' -Not ('hile ismi iceren satir: ' + $hl.Trim()) }
                        foreach ($m in [regex]::Matches($ht, '(?im)^(?:jvm_args|java_command|VM Arguments)\s*:?\s*(.*)$')) {
                            $ja = $m.Groups[1].Value
                            if ($ja -match '(?i)-javaagent:|-agentpath:|-agentlib:|-Xbootclasspath|-Xverify:none|-noverify|-XX:\+DisableAttachMechanism') { Add-F -Kaynak 'MarsPixel: Java cokme gunlugu (hs_err)' -Ad $f.Name.ToLower() -Yol $f.FullName -Skor 55 -Son $f.LastWriteTime -Var 'Evet' -Not ('JVM argumani agent/dogrulama kapatma: ' + $ja.Trim()) }
                        }
                        foreach ($ap in (Find-Paths $ht 'jar|dll')) { $api = Get-PiCached $ap; Eval-Exec -Kaynak 'MarsPixel: Java cokme gunlugu (hs_err)' -Path $ap -Exists $api.Exists -Removed $api.Removed -Last $f.LastWriteTime -Note ('gunluk: ' + $f.Name) }
                    }
                }
                continue
            }
            Invoke-DumpFile $f.FullName $kind $isJava 900MB 150000
        }
        $budget.Stop()
    } elseif ($dmpFiles.Count -gt 0) { Add-Cov 'Dump dosyalari taranamadi (C# modulu derlenemedi)' ($dmpFiles.Count.ToString()) }
    if ($dmpFiles.Count -eq 0) { Log '   (taranacak dump yok. Kendi dump dosyani vermek icin: $env:HK_DUMP=''C:\yol\dosya.dmp'' ya da klasor yolu; birden fazlasi ; ile)' 'DarkGray' }
    # Kendi dump klasorunu temizlemis olabilir: WER / CrashDumps / Minidump dizinleri ve LocalDumps ayari
    try {
        $ldk = Get-Item -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps' -ErrorAction Stop
        $ldf = [string]$ldk.GetValue('DumpFolder'); $ldt = $ldk.GetValue('DumpType'); $ldk.Close()
        if ($ldf -or $null -ne $ldt) { Add-Sys ('WER LocalDumps etkin: klasor=' + $ldf + ' tur=' + $ldt) 15 'Cokme dokumleri ozel bir klasore yazilacak sekilde ayarli; bu klasor da taranir (HK_DUMP ile ekleyebilirsin).' $null $ldf }
        if ($ldf) { $ldx = [Environment]::ExpandEnvironmentVariables($ldf); if ((Test-Path -LiteralPath $ldx) -and -not $dmpSeen.ContainsKey($ldx.ToLower())) { foreach ($lf in @(Get-ChildItem -LiteralPath $ldx -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $dmpExt } | Select-Object -First 50)) { if ($script:DumpOk) { Invoke-DumpFile $lf.FullName 'MarsPixel Dump Analyzer' $false 900MB 150000 } } } }
    } catch {}
    $wdk = $null
    try { $wdk = Get-Item -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting' -ErrorAction Stop } catch {}
    if ($wdk) { $dis = $wdk.GetValue('Disabled'); $wdk.Close(); if ($null -ne $dis -and [int]$dis -eq 1) { Add-Sys 'Windows Hata Raporlama (WER) devre disi' 25 'Cokme raporu/dump uretimi kapatilmis; cokme izleri azalir.' $null 'Disabled=1' } }
} catch {}
Show-Section

# ---- 36) Prefetch Parser (derin) ----
Step '[17+/17] 36) Prefetch Parser: calistirma sayisi, hacim (USB/harici disk), zaman damgasi tutarsizligi, yeniden adlandirilmis .pf, yuklenen DLL/jar...'
Start-Sec
function Read-PfExtra([string]$file) {
    $res = @{ Ver = 0; RunCount = -1; Vols = @(); Ok = $false }
    try {
        $raw = [IO.File]::ReadAllBytes($file)
        $data = $raw
        if ($raw.Length -gt 8 -and $raw[0] -eq 0x4D -and $raw[1] -eq 0x41 -and $raw[2] -eq 0x4D) {
            if (-not $script:HkOk) { return $res }
            $usize = [BitConverter]::ToUInt32($raw, 4)
            $comp = New-Object byte[] ($raw.Length - 8)
            [Array]::Copy($raw, 8, $comp, 0, $comp.Length)
            $data = [HkNative]::Xpress($comp, $usize)
        }
        if ($null -eq $data -or $data.Length -lt 200) { return $res }
        if ([Text.Encoding]::ASCII.GetString($data, 4, 4) -ne 'SCCA') { return $res }
        $ver = [BitConverter]::ToUInt32($data, 0)
        $res.Ver = $ver
        $cnt = -1
        if ($ver -ge 26 -and $data.Length -ge 212) { $cnt = [int][BitConverter]::ToUInt32($data, 208) }
        elseif ($ver -eq 23 -and $data.Length -ge 156) { $cnt = [int][BitConverter]::ToUInt32($data, 152) }
        elseif ($ver -eq 17 -and $data.Length -ge 148) { $cnt = [int][BitConverter]::ToUInt32($data, 144) }
        $res.RunCount = $cnt
        # hacim bilgileri: ofset 108 (v17: 108), sayi 112
        $vo = [int][BitConverter]::ToUInt32($data, 108)
        $vc = [int][BitConverter]::ToUInt32($data, 112)
        $esz = 104; if ($ver -eq 17) { $esz = 40 } elseif ($ver -ge 30) { $esz = 96 }
        $vols = New-Object System.Collections.Generic.List[object]
        if ($vo -gt 0 -and $vc -gt 0 -and $vc -lt 32) {
            for ($i = 0; $i -lt $vc; $i++) {
                $b = $vo + $i * $esz
                if ($b + 20 -gt $data.Length) { break }
                $dpo = [int][BitConverter]::ToUInt32($data, $b)
                $dpl = [int][BitConverter]::ToUInt32($data, $b + 4)
                $ctm = Hk-Ft ([BitConverter]::ToInt64($data, $b + 8))
                $ser = [BitConverter]::ToUInt32($data, $b + 16)
                $dp = ''
                if ($dpl -gt 0 -and $dpl -lt 400 -and ($vo + $dpo + $dpl * 2) -le $data.Length) { $dp = [Text.Encoding]::Unicode.GetString($data, $vo + $dpo, $dpl * 2).TrimEnd([char]0) }
                [void]$vols.Add([pscustomobject]@{ Path = $dp; Created = $ctm; Serial = ('{0:X8}' -f $ser) })
            }
        }
        $res.Vols = $vols.ToArray()
        $res.Ok = $true
    } catch {}
    return $res
}
try {
    $pfx = @($pfFiles | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1500)
    $pfxN = 0
    $pfOk = 0
    $pfNow = Get-Date
    $sysSerial = ''
    $pfRemov = 0
    $pfShift = 0
    $pfRename = 0
    foreach ($pf in $pfx) {
        $pfxN++
        if (($pfxN % 100) -eq 0) { Set-Frac ([Math]::Min(0.99, $pfxN / [double][Math]::Max(1, $pfx.Count))) ($pf.Name) }
        $nm = $pf.BaseName
        $exeName = ($nm -replace '-[0-9A-Fa-f]{8}$', '')
        $info = Read-Prefetch $pf.FullName
        $ex = Read-PfExtra $pf.FullName
        if (-not $ex.Ok -and -not $info.Exe) { continue }
        $pfOk++
        $last = $null
        if ($info.Runs.Count -gt 0) { $last = (@($info.Runs | Sort-Object -Descending))[0] }
        # 1) .pf dosyasi yeniden adlandirilmis mi? (ust veri exe adi ile dosya adi uyusmali)
        if ($info.Exe -and $info.Exe -ine $exeName -and $exeName.Length -lt 27) {
            $pfRename++
            Add-F -Kaynak 'Prefetch Parser: yeniden adlandirilmis .pf' -Ad $pf.Name.ToLower() -Yol $pf.FullName -Skor 55 -Son $pf.LastWriteTime -Var 'Evet' -Not ('dosya adi ' + $exeName + ' ama ic veri exe adi ' + $info.Exe + ' (Prefetch dosyasi elle yeniden adlandirilmis/degistirilmis olabilir)')
        }
        # 2) zaman damgasi tutarsizligi: dosya son yazma zamani, gomulu son calisma zamanindan once olamaz
        if ($last -and $pf.LastWriteTime -lt $last.AddMinutes(-2)) {
            $pfShift++
            Add-F -Kaynak 'Prefetch Parser: zaman damgasi tutarsiz' -Ad $pf.Name.ToLower() -Yol $pf.FullName -Skor 45 -Son $pf.LastWriteTime -Var 'Evet' -Not ('dosyanin son yazma zamani (' + (Fmt $pf.LastWriteTime) + ') icindeki son calisma zamanindan (' + (Fmt $last) + ') ONCE: dosya zaman damgasi elle degistirilmis olabilir')
        }
        # 3) hacim analizi: sistem surucusu disindaki hacimler (Win10'da tum hacimler \VOLUME{guid-seri} biciminde yazilir; seri numarasi ile eslestirilir)
        foreach ($v in $ex.Vols) {
            if ($v.Path -notmatch '(?i)^\\VOLUME\{') { continue }
            $drv = $null
            if ($script:SerialMap.ContainsKey($v.Serial)) { $drv = [string]$script:SerialMap[$v.Serial] }
            if ($drv -and $drv -eq ([string]$env:SystemDrive).ToUpper()) { continue }
            $isSysExe = ($exeName -match '(?i)^(SVCHOST|EXPLORER|CONHOST|SEARCHINDEXER|RUNTIMEBROKER|BACKGROUNDTASKHOST|DLLHOST|TASKHOSTW|SIHOST|WMIPRVSE)\.EXE$')
            if ($isSysExe) { continue }
            $vsc = 0
            $vwhy = ''
            if (-not $drv) { $vsc = 35; $vwhy = 'hacim su an takili degil (cikarilmis harici/eski surucu)' }
            else {
                $dtype = ''
                try { $dtype = [string]([IO.DriveInfo]($drv + '\')).DriveType } catch {}
                if ($dtype -eq 'Removable') { $vsc = 30; $vwhy = 'cikarilabilir (USB) surucu ' + $drv }
            }
            if ($vsc -gt 0) {
                $pfRemov++
                if (Get-NameHit $exeName $true) { $vsc += 25 }
                Add-F -Kaynak 'Prefetch Parser: harici/USB surucuden calistirma' -Ad $exeName.ToLower() -Yol ($v.Path + '  (seri ' + $v.Serial + ')') -Skor $vsc -Son $last -Ilk $pf.CreationTime -Var 'Bilinmiyor' -Not ($vwhy + ' | hacim olusturma: ' + (Fmt $v.Created) + ' | calisma sayisi: ' + $ex.RunCount)
            }
            break
        }
        # 4) calisma sayisi: kullanici klasorunden tek seferlik calistirma + isim eslesmesi
        $zoneP = $null
        foreach ($sp in $info.Paths) { if ($sp -like ('*\' + $info.Exe)) { $zoneP = $sp; break } }
        if ($zoneP -and $ex.RunCount -ge 1) {
            $rr = Resolve-PfPath $zoneP
            $zz = Get-Zone $rr.Path
            if ($ex.RunCount -eq 1 -and ($zz -eq 'user' -or $zz -eq 'temp') -and -not $rr.Exists) {
                Add-F -Kaynak 'Prefetch Parser: tek seferlik calistirilip silinmis' -Ad $exeName.ToLower() -Yol $rr.Path -Skor 40 -Son $last -Ilk $pf.CreationTime -Var 'Hayir' -Not ('kullanici/temp klasorunden yalnizca 1 kez calistirilmis ve dosya su an yok | calisma sayisi: 1')
            }
        }
        # 5) yuklenen dosyalar: Temp/Downloads/AppData altindan yuklenen DLL / jar ve isim eslesmesi (tum process'ler)
        $ldN = 0
        foreach ($sp in $info.Paths) {
            if ($ldN -ge 6) { break }
            if ($sp -notmatch '(?i)\.(dll|jar|sys|drv)$') { continue }
            $hn2 = Get-NameHit ($sp -replace '^.*\\', '') $false
            if ($sp -match '(?i)^\\VOLUME\{') { $rp = Resolve-PfPath $sp } else { $rp = Resolve-NtPath $sp }
            $z2 = Get-Zone $rp.Path
            $sc = 0
            $why = ''
            if ($hn2) { $sc = 60; $why = 'yuklenen dosya adinda hile ismi: ' + $hn2.Name }
            elseif (($z2 -eq 'temp' -or $z2 -eq 'user') -and $exeName -match '(?i)^(JAVAW?|MINECRAFT|EXPLORER|CSRSS|LSASS|WINLOGON|SVCHOST|DWM)\.EXE$') { $sc = 40; $why = 'bu program kullanici/Temp klasorunden dosya yuklemis (enjeksiyon/hile yukleme belirtisi)' }
            if ($sc -gt 0) {
                $ldN++
                $sig = ''
                if ($rp.Exists -and $sc -lt 60 -and (Test-Signed $rp.Path)) { continue }
                Add-F -Kaynak 'Prefetch Parser: yuklenen dosya' -Ad (($sp -replace '^.*\\', '').ToLower() + ' (' + $exeName.ToLower() + ' icinde)') -Yol $rp.Path -Skor $sc -Son $last -Var $(if ($rp.Exists) { 'Evet' } else { 'Hayir' }) -Not ($why + ' | prefetch: ' + $pf.Name)
            }
        }
    }
    Log ('   ' + $pfOk + ' Prefetch dosyasi derin ayristirildi (calisma sayisi, hacim, dosya listesi).') 'DarkGray'
    if ($pfRemov -gt 0) { Log ('   harici/USB hacimden calistirilmis kayit: ' + $pfRemov) 'DarkGray' }
    if ($pfShift -gt 3) { Add-Sys ('Prefetch zaman damgasi tutarsizligi: ' + $pfShift + ' dosya') 40 'Birden cok .pf dosyasinin son yazma zamani, icindeki son calisma zamanindan once: Prefetch dosyalarinin zaman damgalari toplu degistirilmis olabilir.' }
} catch {}
Show-Section

# ---- 37) Echo Strings ----
Step '[17+/17] 37) Echo Strings: yakin zamanda degisen uzantisiz/gizlenmis dosyalarda ve secilen alanlarda string (isim, yol, imza, adres) taramasi...'
Start-Sec
try {
    if (-not $script:DumpOk) { Add-Cov 'Echo Strings taranamadi (C# modulu derlenemedi)' '' }
    else {
        $esFiles = New-Object System.Collections.Generic.List[object]
        $esSeen = @{}
        $esRoots = New-Object System.Collections.Generic.List[string]
        foreach ($u in @(Get-ChildItem -LiteralPath ($env:SystemDrive + '\Users') -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '(?i)^(All Users|Default|Default User)$' })) {
            foreach ($sd in @('Downloads', 'Desktop', 'AppData\Local\Temp', 'AppData\Roaming', 'AppData\Local\Programs')) { [void]$esRoots.Add($u.FullName + '\' + $sd) }
        }
        [void]$esRoots.Add($env:WINDIR + '\Temp'); [void]$esRoots.Add($env:ProgramData); [void]$esRoots.Add($env:SystemDrive + '\Users\Public')
        if ($env:HK_STRINGS) { foreach ($hs in ($env:HK_STRINGS -split ';')) { if ($hs.Trim()) { [void]$esRoots.Add($hs.Trim()) } } }
        $esExt = '(?i)^(\.tmp|\.dat|\.bin|\.log|\.txt|\.cfg|\.db|\.cache|\.bak|\.old|\.dump|\.mem|\.png|\.jpg|\.ico|\.dll|\.exe|\.sys|\.jar|\.lib|\.pak|\.ini|\.json|)$'
        $cut = (Get-Date).AddDays(-14)
        $esHeavy = '(?i)\\(node_modules|Cache|Code Cache|GPUCache|CacheStorage|Service Worker|IndexedDB|Crashpad|blob_storage|assets|libraries|\.git|Microsoft|Packages|Google|Mozilla|npm|pip|NVIDIA|Discord|Spotify|Steam|Epic|Riot|Adobe)(\\|$)'
        $capDirs = 0
        foreach ($rt in $esRoots) {
            if (-not (Test-Path -LiteralPath $rt)) { continue }
            foreach ($f in @(Get-ChildItem -LiteralPath $rt -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt $cut -and $_.Length -ge 8192 -and $_.Length -le 80MB } | Select-Object -First 3000)) {
                if ($f.FullName -match $esHeavy -and $f.FullName -notmatch '(?i)\\(Downloads|Desktop|Temp)\\') { continue }
                if ($f.Extension -notmatch $esExt) { continue }
                if ($esSeen.ContainsKey($f.FullName.ToLower())) { continue }
                # yalnizca uzantisiz/uzantisi gizlenmis dosyalar ve exe/dll/sys: icerik MZ ise veya uzantisiz ise
                $isCode = ($f.Extension -match '(?i)^(\.exe|\.dll|\.sys)$')
                $needMz = (-not $isCode)
                if ($needMz) {
                    $hd = New-Object byte[] 4
                    try { $fs = [IO.File]::Open($f.FullName, 'Open', 'Read', 'ReadWrite'); [void]$fs.Read($hd, 0, 4); $fs.Close() } catch { continue }
                    $isMz = ($hd[0] -eq 0x4D -and $hd[1] -eq 0x5A)
                    $isPk = ($hd[0] -eq 0x50 -and $hd[1] -eq 0x4B)
                    if (-not $isMz -and -not ($f.Extension -eq '' ) ) { continue }
                    if ($isPk) { continue }
                }
                $esSeen[$f.FullName.ToLower()] = 1
                [void]$esFiles.Add($f)
            }
        }
        $esFiles = @($esFiles | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 400)
        Log ('   ' + $esFiles.Count + ' dosya Echo Strings ile taranacak (son 14 gun; uzantisiz/MZ imzali/exe-dll-sys).') 'DarkGray'
        $en = 0
        $esBudget = [Diagnostics.Stopwatch]::StartNew()
        foreach ($f in $esFiles) {
    # (sure siniri kaldirildi)
            $en++
            if (($en % 20) -eq 0) { Set-Frac ([Math]::Min(0.99, $en / [double][Math]::Max(1, $esFiles.Count))) ($f.Name) }
            Invoke-DumpFile $f.FullName 'Echo Strings' $false 80MB 30000
        }
        $esBudget.Stop()
    }
} catch {}
Show-Section

# ---- 38) BAM View ----
Step '[17+/17] 38) BAM View: kullanici bazli BAM zaman cizelgesi, gelecek tarihli kayit, harici surucu, silinmis dosyalar...'
Start-Sec
try {
    $bvRoots = @('HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings', 'HKLM:\SYSTEM\CurrentControlSet\Services\bam\UserSettings')
    $bvAll = New-Object System.Collections.Generic.List[object]
    $bvNow = Get-Date
    $bvSids = 0
    foreach ($br in $bvRoots) {
        foreach ($sk in @(Get-ChildItem -LiteralPath $br -ErrorAction SilentlyContinue)) {
            $bvSids++
            $sid = $sk.PSChildName
            $uname = $sid
            try { $uname = (New-Object System.Security.Principal.SecurityIdentifier($sid)).Translate([System.Security.Principal.NTAccount]).Value } catch {}
            $skt = Get-KeyTime $sk
            foreach ($vn in $sk.GetValueNames()) {
                if ($vn -notmatch '^\\Device\\|^[A-Za-z]:\\') { continue }
                $vb = $sk.GetValue($vn)
                if (-not ($vb -is [byte[]]) -or $vb.Length -lt 8) { continue }
                $t = $null
                try { $t = Hk-Ft ([BitConverter]::ToInt64($vb, 0)) } catch {}
                $rp = Resolve-NtPath $vn
                [void]$bvAll.Add([pscustomobject]@{ Sid = $sid; User = $uname; Raw = $vn; Path = $rp.Path; Exists = $rp.Exists; Removed = $rp.Removed; Time = $t })
            }
            $sk.Close()
        }
    }
    Log ('   ' + $bvAll.Count + ' BAM kaydi, ' + $bvSids + ' kullanici (SID) icin okundu.') 'DarkGray'
    if ($bvAll.Count -eq 0) { Add-Sys 'BAM kullanici kayitlari okunamadi/bos' 25 'BAM UserSettings altinda kayit yok (servis kapali, anahtar silinmis veya yonetici degil).' }
    # gelecek tarihli kayit: saat degistirilerek yapilmis calistirma
    $fut = @($bvAll | Where-Object { $_.Time -and $_.Time -gt $bvNow.AddMinutes(10) })
    if ($fut.Count -gt 0) { Add-Sys ('BAM de GELECEK tarihli ' + $fut.Count + ' kayit var') 55 ('Sistem saati ileri alinip program calistirilmis olabilir. Ornek: ' + $fut[0].Path + ' [' + (Fmt $fut[0].Time) + ']') $fut[0].Time }
    # kullanici bazli son 24 saat / 7 gun ozeti (sistem disi kod dosyalari)
    foreach ($g in @($bvAll | Group-Object -Property User)) {
        $rec = @($g.Group | Where-Object { $_.Time -and $_.Time -gt $bvNow.AddDays(-7) -and $_.Path -match '(?i)\.(exe|jar|bat|cmd|ps1|scr|com|dll)$' -and (Get-Zone $_.Path) -ne 'system' } | Sort-Object -Property Time -Descending)
        if ($rec.Count -gt 0) {
            Log ('   BAM [' + $g.Name + '] son 7 gunde sistem disi ' + $rec.Count + ' program; en yenileri:') 'DarkGray'
            foreach ($r in ($rec | Select-Object -First 12)) { Log ('      ' + (Fmt $r.Time) + '  ' + $r.Path) 'DarkGray' }
        }
    }
    # mevcut kullanici disindaki hesaplar (baska bir hesapla calistirma)
    $curSid = ''
    try { $curSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value } catch {}
    foreach ($g in @($bvAll | Group-Object -Property Sid)) {
        if ($g.Name -match '^S-1-5-21-' -and $curSid -and $g.Name -ne $curSid) {
            $o = @($g.Group | Where-Object { $_.Time -and $_.Time -gt $bvNow.AddDays(-14) -and (Get-Zone $_.Path) -ne 'system' -and $_.Path -match '(?i)\.(exe|jar|bat|scr|com)$' })
            if ($o.Count -gt 0) { Add-Sys ('BAM: baska bir hesapta (' + $g.Group[0].User + ') son 14 gunde ' + $o.Count + ' sistem disi program') 20 ('Bu hesap uzerinden calistirilan programlar: ' + (($o | Select-Object -First 5 | ForEach-Object { Split-Path -Leaf $_.Path }) -join ', ')) $o[0].Time }
        }
    }
    # BAM kayitlari icin isim/konum/harici surucu analizi (step 5 ye ek: zamani olmayan ve baska SID ler dahil)
    $bvSeen = @{}
    foreach ($r in $bvAll) {
        if (-not $r.Path) { continue }
        $k = ($r.Sid + '|' + $r.Path).ToLower()
        if ($bvSeen.ContainsKey($k)) { continue }
        $bvSeen[$k] = 1
        if ($curSid -and $r.Sid -eq $curSid) { continue }
        Eval-Exec -Kaynak 'BAM View (diger kullanici)' -Path $r.Path -Exists $r.Exists -Removed $r.Removed -Last $r.Time -Note ('hesap: ' + $r.User)
    }
    # BAM anahtari son degisim zamani ile en yeni kayit karsilastirmasi (anahtar sonradan duzenlenmis mi)
    $newest = $null
    foreach ($r in $bvAll) { if ($r.Time -and (-not $newest -or $r.Time -gt $newest)) { $newest = $r.Time } }
    $stk = $null
    try { $stk = Get-Item -LiteralPath $bvRoots[0] -ErrorAction Stop } catch {}
    if ($stk) {
        $stt = Get-KeyTime $stk
        $stk.Close()
        if ($stt -and $newest -and $stt -lt $newest.AddHours(-1)) { Add-Sys 'BAM anahtari son degisim zamani en yeni kayittan ESKI' 15 ('Anahtarin son yazma zamani (' + (Fmt $stt) + '), icindeki en yeni calistirma kaydindan (' + (Fmt $newest) + ') once gorunuyor; zaman damgalari tutarsiz (saat degisikligi veya elle duzenleme izi olabilir).') $null '' $stt }
    }
} catch {}
Show-Section


Log '' 'Gray'
Close-Bar
# (tani/metin dosyasi olusturma kaldirildi: masaustune hicbir dosya yazilmaz)
$avAns = Read-Host 'TUM DISKTE hile avi (calistirilmamis / yeri bilinmeyen dosyalar dahil) da yapilsin mi? Birkac dakika surer (E/H)'
if ($avAns -match '^[eE]') { Invoke-Hunt }
$dmAns = Read-Host 'Ek: analiz edilecek bir RAM/cokme dokumu (.dmp) veya klasor yolu var mi? (bos birak = atla)'
if ($dmAns -and $dmAns.Trim()) {
    $dmAns = $dmAns.Trim().Trim('"')
    Log '' 'Gray'
    Log 'EK: verilen dump/dosya analizi (MarsPixel Dump Analyzer / Echo Strings mantigi)...' 'Cyan'
    Start-Sec
    try {
        if (-not (Test-Path -LiteralPath $dmAns)) { Log '   yol bulunamadi.' 'Yellow' }
        elseif (-not $script:DumpOk) { Log '   C# modulu derlenemedi, dump taranamadi.' 'Yellow' }
        else {
            $dmItems = @(Get-Item -LiteralPath $dmAns -Force)
            if ($dmItems[0].PSIsContainer) { $dmItems = @(Get-ChildItem -LiteralPath $dmAns -Recurse -File -Force -ErrorAction SilentlyContinue | Select-Object -First 300) }
            foreach ($dmf in $dmItems) { Log ('   taraniyor: ' + $dmf.Name) 'DarkGray'; Invoke-DumpFile $dmf.FullName 'MarsPixel Dump Analyzer (verilen dosya)' $false 4GB 600000 }
        }
    } catch {}
    Show-Section
}
if ($PSCommandPath) { Write-Host ''; Read-Host 'Bitti. Kapatmak icin Enter a bas' | Out-Null }
