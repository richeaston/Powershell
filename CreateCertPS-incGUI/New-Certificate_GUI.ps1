<#
.SYNOPSIS
    Simple Certificate Generator GUI
.DESCRIPTION
    A cleaned-up WinForms GUI to generate Self-Signed Certificates.
    Must be run as Administrator.
#>

# --- 1. Admin Check ---
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges to save certificates to LocalMachine."
    $Result = [System.Windows.Forms.MessageBox]::Show("Please run this script as Administrator.`n`nAttempting to continue may result in errors.", "Admin Rights Needed", "OK", "Warning")
}

# --- 2. Load Assemblies ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- 3. Create Form Elements ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Certificate Generator"
$Form.Size = New-Object System.Drawing.Size(460, 400)
$Form.StartPosition = "CenterScreen"
$Form.AutoSizeMode = "GrowAndShrink"

# Group Box
$GrpDetails = New-Object System.Windows.Forms.GroupBox
$GrpDetails.Location = New-Object System.Drawing.Point(12, 12)
$GrpDetails.Size = New-Object System.Drawing.Size(420, 330)
$GrpDetails.Text = "Certificate Details"

# Label
$LabelFQDN = New-Object System.Windows.Forms.Label
$LabelFQDN.Location = New-Object System.Drawing.Point(15, 25)
$LabelFQDN.Size = New-Object System.Drawing.Size(300, 20)
$LabelFQDN.Text = "FQDN (DNS Name):"

# Input Textbox
$InputBox = New-Object System.Windows.Forms.TextBox
$InputBox.Location = New-Object System.Drawing.Point(15, 50)
$InputBox.Size = New-Object System.Drawing.Size(390, 20)

# Output RichTextBox
$OutputBox = New-Object System.Windows.Forms.RichTextBox
$OutputBox.Location = New-Object System.Drawing.Point(15, 85)
$OutputBox.Size = New-Object System.Drawing.Size(390, 230)
$OutputBox.ReadOnly = $True
$OutputBox.BackColor = [System.Drawing.Color]::Black
$OutputBox.ForeColor = [System.Drawing.Color]::LightGreen
$OutputBox.Font = New-Object System.Drawing.Font("Consolas", 9)

# Generate Button
$BtnGenerate = New-Object System.Windows.Forms.Button
$BtnGenerate.Location = New-Object System.Drawing.Point(260, 347)
$BtnGenerate.Size = New-Object System.Drawing.Size(170, 38)
$BtnGenerate.Text = "Generate"
$BtnGenerate.BackColor = [System.Drawing.Color]::LightGray # Default disabled color
$BtnGenerate.Enabled = $False
$BtnGenerate.FlatStyle = "Flat"

# --- 4. Logic & Events ---

# Event: Enable button only when text is typed
$InputBox.Add_TextChanged({
    if (-not [string]::IsNullOrWhiteSpace($InputBox.Text)) {
        $BtnGenerate.Enabled = $True
        $BtnGenerate.BackColor = [System.Drawing.Color]::PaleGreen
    } else {
        $BtnGenerate.Enabled = $False
        $BtnGenerate.BackColor = [System.Drawing.Color]::LightGray
    }
})

# Event: Click Generate
$BtnGenerate.Add_Click({
    $OutputBox.Clear()
    $DnsName = $InputBox.Text

    $OutputBox.AppendText("Processing: $DnsName `n")
    
    try {
        # Create the Certificate
        $CertParams = @{
            DnsName           = $DnsName
            CertStoreLocation = "cert:\LocalMachine\My"
            NotAfter          = (Get-Date).AddYears(1)
            FriendlyName      = "SelfSigned-$DnsName"
        }
        
        $NewCert = New-SelfSignedCertificate @CertParams -ErrorAction Stop

        # Output Success Details
        $OutputBox.ForeColor = [System.Drawing.Color]::LightGreen
        $OutputBox.AppendText("--------------------------------`n")
        $OutputBox.AppendText("SUCCESS! Certificate Created.`n")
        $OutputBox.AppendText("--------------------------------`n")
        $OutputBox.AppendText("Thumbprint : $($NewCert.Thumbprint)`n")
        $OutputBox.AppendText("Subject    : $($NewCert.Subject)`n")
        $OutputBox.AppendText("Expires    : $($NewCert.NotAfter)`n")
        $OutputBox.AppendText("Location   : LocalMachine\My`n")
    }
    catch {
        # Output Error Details
        $OutputBox.SelectionColor = [System.Drawing.Color]::Red
        $OutputBox.AppendText("ERROR: $($_.Exception.Message)`n")
        if ($_.Exception.Message -like "*Access is denied*") {
            $OutputBox.AppendText("HINT: Try running this script as Administrator.`n")
        }
    }
})

# --- 5. Assemble and Show ---
$GrpDetails.Controls.Add($LabelFQDN)
$GrpDetails.Controls.Add($InputBox)
$GrpDetails.Controls.Add($OutputBox)

$Form.Controls.Add($GrpDetails)
$Form.Controls.Add($BtnGenerate)

# Show Dialog
$Form.ShowDialog() | Out-Null
$Form.Dispose()
