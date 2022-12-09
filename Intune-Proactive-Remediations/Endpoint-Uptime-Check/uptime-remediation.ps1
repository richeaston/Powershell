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


    $Hour = (Get-Date).TimeOfDay.Hours
	if ($Hour –ge 0 –and $Hour –lt 12){
		$Greeting = "Good Morning"
	}
	elseif ($Hour –ge 12 –and $Hour –lt 16){
		$Greeting = "Good Afternoon"
	}
	else{
		$Greeting = "Good Evening"
	}
	
    #$GivenName = Get-GivenName
	$Greeting = $Greeting


$classpath = "Registry::HKCR:\"
$keyname = "MSUptimeToastReboot"
$keyDefault = "url:MSUptimeToastReboot"
$keyeditflags = "2162688"
$valcontent = 'C:\Windows\System32\shutdown.exe -r -t 60 -c "Your computer will be restarted in 1 minute, please save any work you have open."'

if (!(test-path "HKCR:\")) {
    New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR
}
set-location -path HKCR:\

$classcheck = Get-ChildItem -Path "HKCR:\$($keyname)\" -Recurse -ErrorAction SilentlyContinue
if (!($classcheck)) {
    #create class protocol
    new-item -Path "HKCR:\\" -Name $keyname -ItemType directory -Verbose 
        new-itemproperty -Path "HKCR:\\$keyname" -name "(Default)" -PropertyType "string" -Value $keydefault -Verbose
        new-itemproperty -Path "HKCR:\\$keyname" -name "EditFlags" -PropertyType "DWORD" -Value $keyeditflags -Verbose
        new-itemproperty -Path "HKCR:\\$keyname" -name "URL Protocol" -PropertyType "string" -Value "" -Verbose
    new-item -Path "HKCR:\\$keyname" -Name "Shell" -ItemType directory -Verbose
    new-item -Path "HKCR:\\$keyname\Shell" -Name "Open" -ItemType directory -Verbose
    new-item -Path "HKCR:\\$keyname\Shell\Open" -Name "command" -ItemType directory -Verbose
        new-itemproperty -Path "HKCR:\\$keyname\Shell\Open\command" -name "(Default)" -PropertyType "string" -Value $valcontent -Verbose
}

Remove-PSDrive -Name HKCR -Force     
set-location c:\windows\system32

# Setting image variables
$LogoImageUri = [your logo here]
$HeroImageUri = [your hero here]
$LogoImage = "$env:TEMP\ToastLogoImage.png"
$HeroImage = "$env:TEMP\ToastHeroImage.png"
$Uptime = get-computerinfo | Select-Object OSUptime 


#Fetching images from uri
Invoke-WebRequest -Uri $LogoImageUri -OutFile $LogoImage
Invoke-WebRequest -Uri $HeroImageUri -OutFile $HeroImage

#Defining the Toast notification settings
#ToastNotification Settings
$Scenario = 'reminder' # <!-- Possible values are: reminder | short | long -->
        
# Load Toast Notification text
$AttributionText = "Go-Ahead Group PLC"
$HeaderText = "$($greeting), a reboot is required!"
$TitleText = "Your device has not performed a reboot in the last $($Uptime.OsUptime.Days) days"
$BodyText1 = "For performance and stability reasons we suggest a reboot at least once a week."
$BodyText2 = "Please save your work and restart your device at the earliest convenience."


# Check for required entries in registry for when using Powershell as application for the toast
# Register the AppID in the registry for use with the Action Center, if required
$RegPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings'
$App =  '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'

# Creating registry entries if they don't exists
if (-NOT(Test-Path -Path "$RegPath\$App")) {
    New-Item -Path "$RegPath\$App" -Force
    New-ItemProperty -Path "$RegPath\$App" -Name 'ShowInActionCenter' -Value 1 -PropertyType 'DWORD'
}

# Make sure the app used with the action center is enabled
if ((Get-ItemProperty -Path "$RegPath\$App" -Name 'ShowInActionCenter' -ErrorAction SilentlyContinue).ShowInActionCenter -ne '1') {
    New-ItemProperty -Path "$RegPath\$App" -Name 'ShowInActionCenter' -Value 1 -PropertyType 'DWORD' -Force
}

        
# Formatting the toast notification XML
[xml]$Toast = @"
<toast scenario="$Scenario">
    <visual>
    <binding template="ToastGeneric">
        <image placement="hero" src="$HeroImage"/>
        <image id="1" placement="appLogoOverride" hint-crop="square" src="$LogoImage"/>
        <text placement="attribution">$AttributionText</text>
        <text>$HeaderText</text>
        <group>
            <subgroup>
                <text hint-style="title" hint-wrap="true" >$TitleText</text>
            </subgroup>
        </group>
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
        <action activationType=`"Protocol`" arguments=`"MSUptimeToastReboot:`" content=`"Reboot`"/>
        <action activationType=`"system`" arguments=`"snooze`" hint-inputId=`"snoozeTime`" content=`"Snooze`" />
        <audio src=`"ms-winsoundevent:Notification.Default`" />
    </actions>
</toast>
"@
        
#Send the notification
Display-ToastNotification
Exit 0
