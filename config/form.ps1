
#Permission Admin
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
  $arguments = "& '" + $myinvocation.mycommand.definition + "'"
  Start-Process powershell -Verb runAs -ArgumentList $arguments
  Break
}

########### Get data from JSON ###########
$DATA_JSON = Get-Content "$PSScriptRoot\data.json" -Raw | ConvertFrom-Json


########### Params ###########
$domainName = "transimperial"
$nameRDP = "RDP-TI"
$pathFolderRDP = "C:\Users\" + $env:UserName + "\Desktop\"

$nameVPN = "TI-VPN"
$IP_VPN_GW = "86.57.234.78"

#Params from file data.json
$userTransimperial = $DATA_JSON.data.user
$IP_REMOTE_PC = $DATA_JSON.data.ip



############# Create FORM #############

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'RDP'
$form.Size = New-Object System.Drawing.Size(300, 240)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'Fixed3D'
$form.MaximizeBox = $false


$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75, 160)
$okButton.Size = New-Object System.Drawing.Size(75, 23)
$okButton.Text = 'OK'
$okButton.Enabled = $true
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton

$form.Controls.Add($okButton)


$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150, 160)
$cancelButton.Size = New-Object System.Drawing.Size(75, 23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)


########### userName ###########
#Label
$userNameLabel = New-Object System.Windows.Forms.Label
$userNameLabel.Location = New-Object System.Drawing.Point(10, 10)
$userNameLabel.Size = New-Object System.Drawing.Size(280, 20)
$userNameLabel.Text = 'User name (Example i.ivanov)'
$form.Controls.Add($userNameLabel)
#TextBox
$userNameTextBox = New-Object System.Windows.Forms.TextBox
$userNameTextBox.Location = New-Object System.Drawing.Point(10, 30)
$userNameTextBox.Size = New-Object System.Drawing.Size(260, 20)

$userNameTextBox.Text = $userTransimperial

$form.Controls.Add($userNameTextBox)



########### userPasswordTextBox ###########
#Label
$userPasswordLabel = New-Object System.Windows.Forms.Label
$userPasswordLabel.Location = New-Object System.Drawing.Point(10, 60)
$userPasswordLabel.Size = New-Object System.Drawing.Size(280, 20)
$userPasswordLabel.Text = 'Password'
$form.Controls.Add($userPasswordLabel)
#TextBox
$userPasswordTextBox = New-Object System.Windows.Forms.TextBox
$userPasswordTextBox.PasswordChar = '*'
$userPasswordTextBox.Location = New-Object System.Drawing.Point(10, 80)
$userPasswordTextBox.Size = New-Object System.Drawing.Size(260, 20)

$userPasswordTextBox.Text = ""

$form.Controls.Add($userPasswordTextBox)



########### IpTextBox ###########
#Label
$IpLabel = New-Object System.Windows.Forms.Label
$IpLabel.Location = New-Object System.Drawing.Point(10, 110)
$IpLabel.Size = New-Object System.Drawing.Size(280, 20)
$IpLabel.Text = 'IP your work computer (Example 192.168.0.114)'
$form.Controls.Add($IpLabel)
#TextBox
$IpTextBox = New-Object System.Windows.Forms.TextBox
$IpTextBox.Location = New-Object System.Drawing.Point(10, 130)
$IpTextBox.Size = New-Object System.Drawing.Size(260, 20)


$IpTextBox.Text = $IP_REMOTE_PC
#$IpTextBox.Text = "192.168.0.252"


$form.Controls.Add($IpTextBox)


$form.Topmost = $true
$form.Add_Shown({ $userNameTextBox.Select() })

$result = $form.ShowDialog()

function isNotEmptyFields {
  return ($userPasswordTextBox.Text.Length > 0) -and ($userNameTextBox.Text.Length > 0) -and ($IpTextBox.Text.Length > 0)
}



function createVPN {
  rasdial $nameVPN /disconnect
  Remove-VpnConnection -Name $nameVPN -PassThru -AllUserConnection -Force
  Add-VpnConnection -Name $nameVPN -ServerAddress $IP_VPN_GW -TunnelType "Pptp" -EncryptionLevel "NoEncryption"  -AuthenticationMethod MSChapv2 -AllUserConnection -RememberCredential -PassThru -Force

  Install-Module -Name VPNCredentialsHelper -Force

  Set-VpnConnectionUsernamePassword -connectionname $nameVPN -username $($userNameTextBox.Text) -password $($userPasswordTextBox.Text)
  rasdial $nameVPN $userNameTextBox.Text $userPasswordTextBox.Text
}

function autoConnectRDP {
  $domainName = $domainName + "\" + $userNameTextBox.Text
  $ip = $IpTextBox.Text
  cmdkey /generic:$ip /user:$domainName  /pass:$userPasswordTextBox.Text
  mstsc /v:$ip
}

function saveConfigData {

  $DATA_JSON.data.user = $userNameTextBox.Text
  $DATA_JSON.data.ip = $IpTextBox.Text

  Clear-Content "$PSScriptRoot\data.json"
  $DATA_JSON | ConvertTo-Json -Depth 4 | Out-File "$PSScriptRoot\data.json"
}


########### Create RDP FILE ###########
function createRdpFile {
  $domain_user = "$domainName\$($userNameTextBox.Text)"
  $pathRdpWithUserName = "$pathFolderRDP\$nameRDP-$($userNameTextBox.Text).rdp"

  $baseFolder = (get-item $PSScriptRoot).parent.FullName
  $localCopyRdp = "$baseFolder\$nameRDP-$($userNameTextBox.Text).rdp"

  $rdp = "screen mode id:i:2
            use multimon:i:0
            desktopwidth:i:1920
            desktopheight:i:1080
            session bpp:i:16
            winposstr:s:0,3,0,0,800,600
            compression:i:1
            keyboardhook:i:2
            audiocapturemode:i:0
            videoplaybackmode:i:1
            connection type:i:7
            networkautodetect:i:1
            bandwidthautodetect:i:1
            displayconnectionbar:i:1
            username:s:$domain_user
            enableworkspacereconnect:i:0
            disable wallpaper:i:0
            allow font smoothing:i:0
            allow desktop composition:i:0
            disable full window drag:i:1
            disable menu anims:i:1
            disable themes:i:0
            disable cursor setting:i:0
            bitmapcachepersistenable:i:1
            full address:s:$($IpTextBox.Text)
            audiomode:i:0
            redirectprinters:i:0
            redirectcomports:i:0
            redirectsmartcards:i:1
            redirectclipboard:i:1
            redirectposdevices:i:0
            drivestoredirect:s:
            autoreconnection enabled:i:1
            authentication level:i:2
            prompt for credentials:i:0
            negotiate security layer:i:1
            remoteapplicationmode:i:0
            alternate shell:s:
            shell working directory:s:
            gatewayhostname:s:
            gatewayusagemethod:i:4
            gatewaycredentialssource:i:4
            gatewayprofileusagemethod:i:0
            promptcredentialonce:i:0
            gatewaybrokeringtype:i:0
            use redirection server name:i:0
            rdgiskdcproxy:i:0
            kdcproxyname:s:
            redirectwebauthn:i:1
            enablerdsaadauth:i:0
    "

  $rdp -f $nameRDP | Out-File -FilePath $pathRdpWithUserName
  $rdp -f $nameRDP | Out-File -FilePath $localCopyRdp

}


#function formSubmit{
#    if (isNotEmptyFields) {
#            saveConfigData
#            #Create_RDP_FILE
#            CreateVPN
#            autoConnectRDP
#            $form.Close()
#
#    } else {
#        [System.Windows.Forms.MessageBox]::Show("Error")
#    }
#}



if (($result -eq [System.Windows.Forms.DialogResult]::OK) ) {
  createRdpFile
  createVPN
  autoConnectRDP
  saveConfigData
}