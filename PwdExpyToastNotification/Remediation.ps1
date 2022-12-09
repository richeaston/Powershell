# Displays password expiry toast notifcation if pwd expiry 14 days or 5
# Written by Richard Easton
# requires the following modules on the endpoint MSOnline, Azure
# so make sure they present in "c:\program files\Windows Powershell\Modules"
# and make sure you tick the "Run this script using the logged-on credentials"
# and "run script in 64-bit Powershell" otherwise it will error as x86 stores the mdoules in a different location


Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Confirm:$false -force 

cls
function Display-ToastNotification() {
    $Load = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    $Load = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
    # Load the notification into the required format
    $ToastXML = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
    $ToastXML.LoadXml($Toast.OuterXml)
        
    # Display the toast notification
    try {
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($App).Show($ToastXml)
    }
    catch { 
        Write-Output -Message 'Something went wrong when displaying the toast notification' -Level Warn
        Write-Output -Message 'Make sure the script is running as the logged on user' -Level Warn     
    }
}
 

try
{
    Get-MsolDomain -ErrorAction Stop > $null
}
catch 
{
    if ($cred -eq $null) {
    if ($cred -eq $null) {
    $username = "[read only service account]"  
    $KeyFile = "[path to AES key file]"  #can be read only blob storage
    $Key = Get-Content $KeyFile
    $creds = "[path to encrypted password]"  #can be read only blob storage
    $pwd = Get-Content $creds | ConvertTo-SecureString -Key $Key
    $cred = new-object System.Management.Automation.PSCredential ( $username , $pwd )
    #you can use azure key vault for this ;)
    
}
    Write-Output "Connecting to Office 365..."
    Connect-MsolService -Credential $cred
}


$maxpwdage = 90
$user = Get-MsolUser -SearchString $env:USERNAME -erroraction SilentlyContinue | select DisplayName, LastPasswordChangeTimeStamp,@{Name=”PasswordAge”;Expression={(Get-Date)-$_.LastPasswordChangeTimeStamp}}  | sort-object PasswordAge -descending
$expirydays = ($maxpwdage - $($user.PasswordAge.Days))
$integer = $expirydays -replace "-",""
$days = [int]$integer



$Hour = (Get-Date).TimeOfDay.Hours
if ($Hour -ge 0 -and $Hour -lt 12){
	$Greeting = "Good Morning $($user.DisplayName)"
} elseif ($Hour -ge 12 -and $Hour -lt 16) {
	$Greeting = "Good Afternoon $($user.DisplayName)"
} else {
	$Greeting = "Good Evening $($user.DisplayName)"
}
$Greeting = $Greeting
# Setting image variables
$LogoImageUri = "[path to logo image]" #can be read only blob storage
$HeroImageUri = "[path to hero header image]" #can be read only blob storage
$LogoImage = "$env:TEMP\ToastLogoImage.png"
$HeroImage = "$env:TEMP\ToastHeroImage.png"

#Fetching images from uri
Invoke-WebRequest -Uri $LogoImageUri -OutFile $LogoImage
Invoke-WebRequest -Uri $HeroImageUri -OutFile $HeroImage

$Scenario = 'reminder' # <!-- Possible values are: reminder | short | long -->

# Load Toast Notification text
$AttributionText = "[your company here]"
$HeaderText = "$($greeting), Your password will expire in $($days) days!"
$TitleText = "Your password will expire in $($days) days."
$Text_AppName = "Password Expiry Notification"
$BodyText1 = "To prevent any interuptions to your working environment, please change your password at your earliest convenience."
$BodyText2 = "You can facilitate this by clicking the `'Change Password`' button below."
    

# Check for required entries in registry for when using Powershell as application for the toast
# Register the AppID in the registry for use with the Action Center, if required
$RegPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings'
$App =  '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'

# Creating registry entries if they don't exists
if (-NOT(Test-Path -Path "$RegPath\$App")) {
    New-Item -Path "$RegPath\$App" -Force
    New-ItemProperty -Path "$RegPath\$App" -Name 'ShowInActionCenter' -Value 0 -PropertyType 'DWORD'
}

# Make sure the app used with the action center is enabled
if ((Get-ItemProperty -Path "$RegPath\$App" -Name 'ShowInActionCenter' -ErrorAction SilentlyContinue).ShowInActionCenter -ne '1') {
    New-ItemProperty -Path "$RegPath\$App" -Name 'ShowInActionCenter' -Value 1 -PropertyType 'DWORD' -Force
}

if ($($days) -le 14) {
 

if ($($days) -gt 5) {
# Formatting the toast notification XML
[xml]$Toast =
@"
<toast scenario="$Scenario">
<visual>
    <binding template="ToastGeneric">
        <image placement="hero" src="$HeroImage"/>
        <image id="1" placement="appLogoOverride" hint-crop="square" src="$LogoImage"/>
        <Text_AppName>$Text_AppName</Text_AppName>			
	    <text placement="attribution">$AttributionText</text>
        <text>$HeaderText</text>
        <group>
            <subgroup>     
                <text hint-style="body" hint-wrap="true" >$BodyText1</text>
            </subgroup>
        </group>
        <group>
            <subgroup>     
                <text hint-style="body" hint-wrap="true" >$BodyText2</text>
            </subgroup>
        </group>
    </binding>
</visual>
<actions>
    <action activationType=`"Protocol`" arguments=`"MSPWDToastNotification:`" content=`"Change Password`"/>
    <action activationType=`"system`" arguments=`"dismiss`" content=`"$DismissButtonContent`"/>
    <audio src=`"ms-winsoundevent:Notification.Default`" />
</actions>
</toast>
"@

}

if ($($days) -le 5) {
[xml]$Toast =
@"
<toast scenario="$Scenario">
<visual>
    <binding template="ToastGeneric">
        <image placement="hero" src="$HeroImage"/>
        <image id="1" placement="appLogoOverride" hint-crop="square" src="$LogoImage"/>
        <text placement="attribution">$AttributionText</text>
        <text>$HeaderText</text>
        <group>
            <subgroup>     
                <text hint-style="body" hint-wrap="true" >$BodyText1</text>
            </subgroup>
        </group>
        <group>
            <subgroup>     
                <text hint-style="body" hint-wrap="true" >$BodyText2</text>
            </subgroup>
        </group>
    </binding>
</visual>
<actions>
    <input id=`"snoozeTime`" type=`"selection`" defaultInput=`"15`">
        <selection id=`"15`" content=`"15 minutes`"/>
        <selection id=`"30`" content=`"30 minutes`"/>
        <selection id=`"60`" content=`"1 hour`"/>
    </input>
        <action activationType=`"Protocol`" arguments=`"MSPWDToastNotification:`" content=`"Change Password`"/>
        <action activationType=`"system`" arguments=`"snooze`" hint-inputId=`"snoozeTime`" content=`"Snooze`" />
</actions>
</toast>
"@


}

#Send the notification
Display-ToastNotification
Write-output "Password notification sent to $($user.Displayname), $($days) days left."
[Microsoft.Online.Administration.Automation.ConnectMsolService]::ClearUserSessionState()
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy restricted -Confirm:$false -force 

exit 0
} Else {
    Write-output "$($user.Displayname)'s password fine, $($days) days left, last set $(get-date($($user.LastPasswordChangeTimestamp)) -format "dd/MM/yyyy HH:mm:ss")"
    [Microsoft.Online.Administration.Automation.ConnectMsolService]::ClearUserSessionState()
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy restricted -Confirm:$false -force 
        exit 0
}

