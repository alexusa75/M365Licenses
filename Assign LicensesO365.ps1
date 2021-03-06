#######################################################################################################
#                                                                                                     #
# Name:        Assign LicensesO365.ps1                                                                #
#                                                                                                     #
# Version:     1.1                                                                                    #
#                                                                                                     #
# Description: With this script, you going to be able to assign licenses on Office 365 in a very easy #
#			   way. You can assign licenses base on a csv file or base on a MsolGroup. If needed you  # 
#              can disable some services to the users. The attached document has more details about   #
#			   the process.																			  #		
#																									  # 	
# Author:      Alexander Hurtado                                                                      #
#                                                                                                     #
#                                                                                                     #
# Disclaimer: WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT					  #	
#			  LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS					  # 	
#			  FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR                  #
#			  RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.								  #
#																									  # 	
#			  * * * Please test in a lab environment prior to production use. * * * 				  #	
#																									  # 	
#######################################################################################################

##### Disclaimer #####
[void] [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")
$disclaimer = "WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS	FOR A PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR RESULTS FROM THE USE OF THIS CODE REMAINS WITH YOU. DO YOU AGREE ??"

$result = [Microsoft.VisualBasic.Interaction]::MsgBox($disclaimer,'YesNo,Question,SystemModal,Question',"Modify user's licenses") 


if ($result -eq 'No') {
	Write-Host " Script ended without actions " -ForegroundColor Yellow -BackgroundColor Black
	Exit
}

#### Checking Execution Policy #####


$execut = Get-ExecutionPolicy -Scope LocalMachine

If($execut -ne 'UnRestricted'){
    
    Write-Host " We are setting your Execution Policy value from $execut to Unrestricted " -ForegroundColor Green
    $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $IsAdmin){
        
        Start-Process powershell -verb runas -argument {Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force} -ErrorAction SilentlyContinue
    }else{
        
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
    
    }
}



#Checking prerequisites 
[void] [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")

if ([System.Environment]::Is64BitProcess) {

} else {

    $testNo64bit = " You have to run this script in 64 bit Operating System "
    $NoAzure = [Microsoft.VisualBasic.Interaction]::MsgBox($testNo64bit,'OkOnly,Critical,SystemModal,Exclamation',"Assign Licenses Requirement")
    exit 
}

$DesktopPath = [Environment]::GetFolderPath("Desktop")


$signin = Get-module -Name MSOnline
If(!$signin){
    Write-Host "Installing MSOnline Module..." -ForegroundColor Yellow
    try{
        Install-Module MSOnline
        Write-Host "We installed the MSOnline Module successfully" -ForegroundColor Green
    }catch{
        Write-Host "We coudn't installed the MSOnline Module" -ForegroundColor Red
    }
    
}

Import-Module MSOnline

Connect-MsolService

#### Create array variable for Licenses and ServicesName


$licenses = @{}
$licenses.Add('AAD_BASIC','Azure Active Directory Basic')
$licenses.Add('AAD_PREMIUM','Azure Active Directory Premium')
$licenses.Add('RIGHTSMANAGEMENT','Azure Active Directory Rights')
$licenses.Add('RIGHTSMANAGEMENT_FACULTY','Azure Active Directory Rights for Faculty')
$licenses.Add('RIGHTSMANAGEMENT_GOV','Azure Active Directory Rights for Government')
$licenses.Add('RIGHTSMANAGEMENT_STUDENT','Azure Active Directory Rights for Students')
$licenses.Add('MFA_STANDALONE','Azure Multi-Factor Authentication Premium Standalone')
$licenses.Add('EMS','Microsoft Enterprise Mobility + Security Suite')
$licenses.Add('EXCHANGESTANDARD_FACULTY','Exchange (Plan 1) for Faculty')
$licenses.Add('EXCHANGESTANDARD_STUDENT','Exchange (Plan 1) for Students')
$licenses.Add('EXCHANGEENTERPRISE_FACULTY','Exchange (Plan 2) for Faculty')
$licenses.Add('EXCHANGEENTERPRISE_STUDENT','Exchange (Plan 2) for Students')
$licenses.Add('EXCHANGEARCHIVE','Exchange Archiving')
$licenses.Add('EXCHANGEARCHIVE_FACULTY','Exchange Archiving for Faculty')
$licenses.Add('EXCHANGEARCHIVE_GOV','Exchange Archiving for Government')
$licenses.Add('EXCHANGEARCHIVE_STUDENT','Exchange Archiving for Students')
$licenses.Add('EXCHANGESTANDARD_GOV','Exchange for Government (Plan 1G)')
$licenses.Add('EXCHANGEENTERPRISE_GOV','Exchange for Government (Plan 2G)')
$licenses.Add('EXCHANGEDESKLESS','Exchange Kiosk')
$licenses.Add('EXCHANGEDESKLESS_GOV','Exchange Kiosk for Government')
$licenses.Add('EXCHANGESTANDARD','Exchange Plan 1')
$licenses.Add('EXCHANGEENTERPRISE','Exchange Plan 2')
$licenses.Add('EOP_ENTERPRISE_FACULTY','Exchange Protection for Faculty')
$licenses.Add('EOP_ENTERPRISE_GOV','Exchange Protection for Government')
$licenses.Add('EOP_ENTERPRISE_STUDENT','Exchange Protection for Student')
$licenses.Add('EXCHANGE_ONLINE_WITH_ONEDRIVE_LITE','Exchange with OneDrive for Business')
$licenses.Add('INTUNE_A','Intune')
$licenses.Add('MCOIMP_FACULTY','Lync (Plan 1) for Faculty')
$licenses.Add('MCOIMP_STUDENT','Lync (Plan 1) for Students')
$licenses.Add('MCOSTANDARD_FACULTY','Lync (Plan 2) for Faculty')
$licenses.Add('MCOSTANDARD_STUDENT','Lync (Plan 2) for Students')
$licenses.Add('MCOVOICECONF','Lync (Plan 3)')
$licenses.Add('MCOIMP_GOV','Lync for Government (Plan 1G)')
$licenses.Add('MCOSTANDARD_GOV','Lync for Government (Plan 2G)')
$licenses.Add('MCOVOICECONF_GOV','Lync for Government (Plan 3G)')
$licenses.Add('MCOINTERNAL','Lync Internal Incubation and Corp to Cloud')
$licenses.Add('MCOIMP','Lync Plan 1')
$licenses.Add('MCOSTANDARD','Lync Plan 2')
$licenses.Add('MCOVOICECONF_FACULTY','Lync Plan 3 for Faculty')
$licenses.Add('MCOVOICECONF_STUDENT','Lync Plan 3 for Students')
$licenses.Add('CRMENTERPRISE','Microsoft Dynamics CRM Online Enterprise')
$licenses.Add('CRMSTANDARD_GCC','Microsoft Dynamics CRM Online Government Professional')
$licenses.Add('CRMSTANDARD','Microsoft Dynamics CRM Online Professional')
$licenses.Add('DMENTERPRISE','Microsoft Dynamics Marketing Online Enterprise')
$licenses.Add('INTUNE_O365_STANDALONE','Mobile Device Management for Office 365')
$licenses.Add('OFFICE_BASIC','Office 365 Basic')
$licenses.Add('O365_BUSINESS','Office 365 Business')
$licenses.Add('O365_BUSINESS_ESSENTIALS','Office 365 Business Essentials')
$licenses.Add('O365_BUSINESS_PREMIUM','Office 365 Business Premium')
$licenses.Add('DEVELOPERPACK','Office 365 Developer')
$licenses.Add('DEVELOPERPACK_GOV','Office 365 Developer for Government')
$licenses.Add('EDUPACK_FACULTY','Office 365 Education for Faculty')
$licenses.Add('EDUPACK_STUDENT','Office 365 Education for Students')
$licenses.Add('EOP_ENTERPRISE','Office 365 Exchange Protection Enterprise')
$licenses.Add('EOP_ENTERPRISE_PREMIUM','Office 365 Exchange Protection Premium')
$licenses.Add('STANDARDPACK_GOV','Office 365 for Government (Plan G1)')
$licenses.Add('STANDARDWOFFPACK_GOV','Office 365 for Government (Plan G2)')
$licenses.Add('ENTERPRISEPACK_GOV','Office 365 for Government (Plan G3)')
$licenses.Add('ENTERPRISEWITHSCAL_GOV','Office 365 for Government (Plan G4)')
$licenses.Add('DESKLESSPACK_GOV','Office 365 for Government (Plan K1G)')
$licenses.Add('STANDARDPACK_FACULTY','Office 365 Plan A1 for Faculty')
$licenses.Add('STANDARDPACK_STUDENT','Office 365 Plan A1 for Students')
$licenses.Add('STANDARDWOFFPACK_FACULTY','Office 365 Plan A2 for Faculty')
$licenses.Add('STANDARDWOFFPACK_STUDENT','Office 365 Plan A2 for Students')
$licenses.Add('ENTERPRISEPACK_FACULTY','Office 365 Plan A3 for Faculty')
$licenses.Add('ENTERPRISEPACK_STUDENT','Office 365 Plan A3 for Students')
$licenses.Add('ENTERPRISEWITHSCAL_FACULTY','Office 365 Plan A4 for Faculty')
$licenses.Add('ENTERPRISEWITHSCAL_STUDENT','Office 365 Plan A4 for Students')
$licenses.Add('STANDARDPACK','Office 365 Plan E1')
$licenses.Add('STANDARDWOFFPACK','Office 365 Plan E2')
$licenses.Add('ENTERPRISEPACK','Office 365 Plan E3')
$licenses.Add('ENTERPRISEWITHSCAL','Office 365 Plan E4')
$licenses.Add('DESKLESSPACK','Office 365 Plan K1')
$licenses.Add('DESKLESSPACK_YAMMER','Office 365 Plan K1 with Yammer')
$licenses.Add('OFFICESUBSCRIPTION','Office Professional Plus')
$licenses.Add('OFFICESUBSCRIPTION_FACULTY','Office Professional Plus for Faculty')
$licenses.Add('OFFICESUBSCRIPTION_GOV','Office Professional Plus for Government')
$licenses.Add('OFFICESUBSCRIPTION_STUDENT','Office Professional Plus for Students')
$licenses.Add('WACSHAREPOINTSTD_FACULTY','Office Web Apps (Plan 1) For Faculty')
$licenses.Add('WACSHAREPOINTSTD_STUDENT','Office Web Apps (Plan 1) For Students')
$licenses.Add('WACSHAREPOINTSTD_GOV','Office Web Apps (Plan 1G) for Government')
$licenses.Add('WACSHAREPOINTENT_FACULTY','Office Web Apps (Plan 2) For Faculty')
$licenses.Add('WACSHAREPOINTENT_STUDENT','Office Web Apps (Plan 2) For Students')
$licenses.Add('WACSHAREPOINTENT_GOV','Office Web Apps (Plan 2G) for Government')
$licenses.Add('WACSHAREPOINTSTD','Office Web Apps with SharePoint Plan 1')
$licenses.Add('WACSHAREPOINTENT','Office Web Apps with SharePoint Plan 2')
$licenses.Add('ONEDRIVESTANDARD','OneDrive for Business')
$licenses.Add('ONEDRIVESTANDARD_GOV','OneDrive for Business for Government (Plan 1G)')
$licenses.Add('WACONEDRIVESTANDARD','OneDrive for Business with Office Web Apps')
$licenses.Add('WACONEDRIVESTANDARD_GOV','OneDrive for Business with Office Web Apps for Government')
$licenses.Add('PARATURE_ENTERPRISE','Parature Enterprise')
$licenses.Add('PARATURE_ENTERPRISE_GOV','Parature Enterprise for Government')
$licenses.Add('POWER_BI_STANDARD','Power BI')
$licenses.Add('POWER_BI_STANDALONE','Power BI for Office 365')
$licenses.Add('POWER_BI_STANDALONE_FACULTY','Power BI for Office 365 for Faculty')
$licenses.Add('POWER_BI_STANDALONE_STUDENT','Power BI for Office 365 for Students')
$licenses.Add('PROJECTESSENTIALS','Project Essentials')
$licenses.Add('PROJECTESSENTIALS_GOV','Project Essentials for Government')
$licenses.Add('PROJECTONLINE_PLAN_1','Project Plan 1')
$licenses.Add('PROJECTONLINE_PLAN_1_FACULTY','Project Plan 1 for Faculty')
$licenses.Add('PROJECTONLINE_PLAN_1_GOV','Project Plan 1for Government')
$licenses.Add('PROJECTONLINE_PLAN_1_STUDENT','Project Plan 1 for Students')
$licenses.Add('PROJECTONLINE_PLAN_2','Project Plan 2')
$licenses.Add('PROJECTONLINE_PLAN_2_FACULTY','Project Plan 2 for Faculty')
$licenses.Add('PROJECTONLINE_PLAN_2_GOV','Project Plan 2 for Government')
$licenses.Add('PROJECTONLINE_PLAN_2_STUDENT','Project Plan 2 for Students')
$licenses.Add('PROJECTCLIENT','Project Pro for Office 365')
$licenses.Add('PROJECTCLIENT_FACULTY','Project Pro for Office 365 for Faculty')
$licenses.Add('PROJECTCLIENT_GOV','Project Pro for Office 365 for Government')
$licenses.Add('PROJECTCLIENT_STUDENT','Project Pro for Office 365 for Students')
$licenses.Add('SHAREPOINTSTANDARD_FACULTY','SharePoint (Plan 1) for Faculty')
$licenses.Add('SHAREPOINTSTANDARD_STUDENT','SharePoint (Plan 1) for Students')
$licenses.Add('SHAREPOINTSTANDARD_YAMMER','SharePoint (Plan 1) with Yammer')
$licenses.Add('SHAREPOINTENTERPRISE_FACULTY','SharePoint (Plan 2) for Faculty')
$licenses.Add('SHAREPOINTENTERPRISE_STUDENT','SharePoint (Plan 2) for Students')
$licenses.Add('SHAREPOINTENTERPRISE_YAMMER','SharePoint (Plan 2) with Yammer')
$licenses.Add('SHAREPOINTSTANDARD_GOV','SharePoint for Government (Plan 1G)')
$licenses.Add('SHAREPOINTENTERPRISE_GOV','SharePoint for Government (Plan 2G)')
$licenses.Add('SHAREPOINTDESKLESS','SharePoint Kiosk')
$licenses.Add('SHAREPOINTSTANDARD','SharePoint Plan 1')
$licenses.Add('SHAREPOINTENTERPRISE','SharePoint Plan 2')
$licenses.Add('SMB_BUSINESS','SMB Business')
$licenses.Add('SMB_BUSINESS_ESSENTIALS','SMB Business Essentials')
$licenses.Add('SMB_BUSINESS_PREMIUM','SMB Business Premium')
$licenses.Add('VISIOCLIENT','Visio Pro for Office 365')
$licenses.Add('VISIOCLIENT_FACULTY','Visio Pro for Office 365 for Faculty')
$licenses.Add('VISIOCLIENT_GOV','Visio Pro for Office 365 for Government')
$licenses.Add('VISIOCLIENT_STUDENT','Visio Pro for Office 365 for Students')
$licenses.Add('YAMMER_ENTERPRISE_STANDALONE','Yammer Enterprise Standalone')

$licenses.Add('RIGHTSMANAGEMENT_ADHOC','Azure Rights Management Service')
$licenses.Add('ENTERPRISEPREMIUM','Office 365 Enterprise E5')


$services = @{}
$services.Add('AAD_BASIC','Azure Active Directory Basic')
$services.Add('AAD_PREMIUM','Azure Active Directory Premium')
$services.Add('MFA_PREMIUM','Azure Multi-Factor Authentication')
$services.Add('RMS_S_ENTERPRISE','Azure Information Protection')
$services.Add('RMS_S_ENTERPRISE_GOV','Azure Information Protection for Government')
$services.Add('SHAREPOINT_DUET_EDU','Duet Online for Academics')
$services.Add('SHAREPOINT_DUET_GOV','Duet Online for Government')
$services.Add('EXCHANGE_S_STANDARD','Exchange Online (Plan 1)')
$services.Add('EXCHANGE_S_STANDARD_GOV','Exchange Online (Plan 1) for Government')
$services.Add('EXCHANGE_S_ENTERPRISE','Exchange Online (Plan 2)')
$services.Add('EXCHANGE_S_ENTERPRISE_GOV','Exchange Online (Plan 2) for Government')
$services.Add('EXCHANGE_S_ARCHIVE','Exchange Online Archiving')
$services.Add('EXCHANGE_S_ARCHIVE_GOV','Exchange Online Archiving for Government')
$services.Add('EXCHANGE_S_DESKLESS','Exchange Online Kiosk')
$services.Add('EXCHANGE_S_DESKLESS_GOV','Exchange Online Kiosk for Government')
$services.Add('EOP_ENTERPRISE','Exchange Online Protection')
$services.Add('EOP_ENTERPRISE_GOV','Exchange Online Protection for Government')
$services.Add('INTUNE_A','Intune')
$services.Add('MCOIMP','Skype for Business Online (formerly Lync Online) (Plan 1)')
$services.Add('MCOIMP_GOV','Skype for Business Online (Plan 1) for Government')
$services.Add('MCOSTANDARD','Skype for Business Online (Plan 2)')
$services.Add('MCOSTANDARD_GOV','Skype for Business Online (Plan 2) for Government')
$services.Add('MCOVOICECONF','Skype for Business Online (Plan 3)')
$services.Add('MCOVOICECONF_GOV','Skype for Business Online (Plan 3) for Government')
$services.Add('CRMENTERPRISE','Microsoft Dynamics CRM Online Enterprise')
$services.Add('CRMSTANDARD_GCC','Microsoft Dynamics CRM Online Government Professional')
$services.Add('CRMSTANDARD','Microsoft Dynamics CRM Online Professional')
$services.Add('DMENTERPRISE','Microsoft Dynamics Marketing Online Enterprise')
$services.Add('MDM_SALES_COLLABORATION','Microsoft Dynamics Marketing Sales Collaboration')
$services.Add('SQL_IS_SSIM','Microsoft Power BI Information Services Plan 1')
$services.Add('BI_AZURE_P1','Microsoft Power BI Reporting and Analytics Plan 1')
$services.Add('BI_AZURE_P2','Microsoft Power BI Reporting and Analytics Plan 2')
$services.Add('NBENTERPRISE','Microsoft Social Listening Enterprise')
$services.Add('NBPROFESSIONALFORCRM','Microsoft Social Listening Professional')
$services.Add('INTUNE_O365','Mobile Device Management for Office 365')
$services.Add('OFFICE_BUSINESS','Office 365 Business')
$services.Add('OFFICESUBSCRIPTION','Office 365 ProPlus')
$services.Add('OFFICESUBSCRIPTION_GOV','Office 365 ProPlus for Government')
$services.Add('OFFICE_PRO_PLUS_SUBSCRIPTION_SMBIZ','Office 365 Small Business Subscription')
$services.Add('SHAREPOINTWAC','Office Online')
$services.Add('SHAREPOINTWAC_DEVELOPER','Office Online Developer')
$services.Add('SHAREPOINTWAC_EDU','Office Online EDU')
$services.Add('SHAREPOINTWAC_DEVELOPER_GOV','Office Online for Government Developer')
$services.Add('SHAREPOINTWAC_GOV','Office Online for Government')
$services.Add('ONEDRIVESTANDARD','OneDrive for Business (Plan 1)')
$services.Add('ONEDRIVESTANDARD_GOV','OneDrive for Business (Plan 1) for Government')
$services.Add('ONEDRIVELITE','OneDrive for Business Lite')
$services.Add('PARATURE_ENTERPRISE','Parature Enterprise')
$services.Add('PARATURE_ENTERPRISE_GOV','Parature Enterprise for Government')
$services.Add('BI_AZURE_P0','Power BI')
$services.Add('PROJECT_ESSENTIALS','Project Lite')
$services.Add('PROJECT_ESSENTIALS_GOV','Project Lite for Government')
$services.Add('SHAREPOINT_PROJECT','Project Online')
$services.Add('SHAREPOINT_PROJECT_EDU','Project Online for Academics')
$services.Add('SHAREPOINT_PROJECT_GOV','Project Online for Government')
$services.Add('PROJECT_CLIENT_SUBSCRIPTION','Project Pro for Office 365')
$services.Add('PROJECT_CLIENT_SUBSCRIPTION_GOV','Project Pro for Office 365 for Government')
$services.Add('SHAREPOINTSTANDARD','SharePoint Online (Plan 1)')
$services.Add('SHAREPOINTSTANDARD_EDU','SharePoint Online (Plan 1) for Academics')
$services.Add('SHAREPOINTSTANDARD_GOV','SharePoint Online (Plan 1) for Government')
$services.Add('SHAREPOINTENTERPRISE','SharePoint Online (Plan 2)')
$services.Add('SHAREPOINTENTERPRISE_EDU','SharePoint Online (Plan 2) for Academics')
$services.Add('SHAREPOINTENTERPRISE_GOV','SharePoint Online (Plan 2) for Government')
$services.Add('SHAREPOINT_S_DEVELOPER','SharePoint Online for Developer')
$services.Add('SHAREPOINT_S_DEVELOPER_GOV','SharePoint Online for Government Developer')
$services.Add('SHAREPOINTDESKLESS','SharePoint Online Kiosk')
$services.Add('SHAREPOINTDESKLESS_GOV','SharePoint Online Kiosk for Government')
$services.Add('VISIO_CLIENT_SUBSCRIPTION','Visio Pro for Office 365')
$services.Add('VISIO_CLIENT_SUBSCRIPTION_GOV','Visio Pro for Office 365 for Government')
$services.Add('YAMMER_ENTERPRISE','Yammer Enterprise')
$services.Add('YAMMER_EDU','Yammer for Academic For Academics')

$services.Add('FLOW_O365_P2','Flow for Office 365 P2')
$services.Add('POWERAPPS_O365_P2','PowerApps for Office 365 P2')
$services.Add('TEAMS1','Microsoft Teams')
$services.Add('PROJECTWORKMANAGEMENT','Microsoft Planner')
$services.Add('SWAY','SWAY')
$services.Add('Deskless','Microsoft StaffHub')

$services.Add('FLOW_O365_P3','Flow for Office 365 P3')
$services.Add('POWERAPPS_O365_P3','PowerApps for Office 365 P3')
$services.Add('ADALLOM_S_O365','Office 365 Advanced Security Management')
$services.Add('EQUIVIO_ANALYTICS','Office 365 Advanced eDiscovery')
$services.Add('LOCKBOX_ENTERPRISE','Customer Lockbox')
$services.Add('EXCHANGE_ANALYTICS','Microsoft MyAnalytics')
$services.Add('ATP_ENTERPRISE','Exchange Online Advanced Threat Protection (These licenses do not need to be individually assigned)')
$services.Add('MCOEV','Skype for Business Cloud PBX')
$services.Add('MCOMEETADV','Skype for Business PSTN Conferencing')


 #Functions
[void] [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic") 

function Return-DropDown {
 $script:Choice = $DropDown.SelectedItem.ToString()
 $Form.Close()
}


function GetMSOID {
 
	$iDomain = Get-MsolDomain | where {$_.isinitial -eq $true}
 
	return $iDomain.name
}


#Variables
[array]$DropDownArray = (Get-MsolAccountSku |select AccountSkuId).AccountSkuId
$csv = ""
$testing = $true
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$outpath = 	$DesktopPath + "\assigned licenses.csv"  
$sMSOID = ""
$sMSOID = GetMSOID($null)
$location=$(get-msolcompanyinformation).CountryLetterCode
$check = @()
$ser = @()
$x = @()
$xDomain = $sMSOID.split(".")
$sTenant = $xdomain[0]
$myArray = @()
$myArray += "UserPrincipalName" + "," + "Comment"
$currentDate =  (Get-Date -Format "yyyy-MM-dd_HHmm").ToString()
$company = (Get-MsolCompanyInformation).DisplayName
$cancelform = $false


############### Form GUI ##############################


    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

    $Form = New-Object System.Windows.Forms.Form
    $Icon = [system.drawing.icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")
    $Form.Icon = $Icon
    $Form.width = 640
    $Form.height = 350
    $Form.Text = ”Assigning Licenses”
    $form.TopMost = $true
    $Form.AutoScroll = $True
    $Form.StartPosition = "CenterScreen"

    $Form.KeyPreview = $True
    $Form.Add_KeyDown({if ($_.KeyCode -eq "Escape"){$Form.Close()}})

    $Font = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Regular)
    $Form.Font = $Font

    $CompanyLabel = new-object System.Windows.Forms.Label
    $CompanyLabel.Location = new-object System.Drawing.Size(10,10) 
    $CompanyLabel.size = new-object System.Drawing.Size(140,25) 
    $CompanyLabel.Text = "Company Name:"
    $CompanyLabel.Font = new-object system.drawing.font("Arial",12,[system.drawing.fontstyle]::bold)
    $Form.Controls.Add($CompanyLabel)

    $CompanyLabelName = new-object System.Windows.Forms.Label
    $CompanyLabelName.Location = new-object System.Drawing.Size(150,10) 
    $CompanyLabelName.size = new-object System.Drawing.Size(320,25) 
    $CompanyLabelName.Text = $Company
    $CompanyLabelName.Font = new-object system.drawing.font("Arial Rounded MT Bold",12,[system.drawing.fontstyle]::bold)
    $CompanyLabelName.ForeColor = "Blue"
    
    $Form.Controls.Add($CompanyLabelName)


    $tenantLabel = new-object System.Windows.Forms.Label
    $tenantLabel.Location = new-object System.Drawing.Size(10,40) 
    $tenantLabel.size = new-object System.Drawing.Size(140,26) 
    $tenantLabel.Text = "Tenant Domain:"
    $tenantLabel.Font = new-object system.drawing.font("Arial",12,[system.drawing.fontstyle]::bold)
    $Form.Controls.Add($tenantLabel)

    $tenantLabelTenant = new-object System.Windows.Forms.Label
    $tenantLabelTenant.Location = new-object System.Drawing.Size(150,40) 
    $tenantLabelTenant.size = new-object System.Drawing.Size(320,26) 
    $tenantLabelTenant.Text = $sMSOID
    $tenantLabelTenant.ForeColor = "Blue"
    $tenantLabelTenant.Font = new-object system.drawing.font("Arial Rounded MT Bold",12,[system.drawing.fontstyle]::bold)
    $Form.Controls.Add($tenantLabelTenant)


    $DropDown = new-object System.Windows.Forms.ComboBox
    $DropDown.Location = new-object System.Drawing.Size(140,140)
    $DropDown.Size = new-object System.Drawing.Size(300,30)
    
    
    ForEach ($Item in $DropDownArray) {
        $ite = ""
        $ite = $Item.split(":")[1]
        $te = $licenses.GetEnumerator()|?{$_.Key -eq $ite}
            if($te.Value){
                [void] $DropDown.Items.Add($te.Value)
                
            }else{
                [void] $DropDown.Items.Add($ite)
                
            }
       
     }
    
    $DropDown.SelectedItem = $DropDown.Items[0]
    $Form.Controls.Add($DropDown)

    $DropDownLabel = new-object System.Windows.Forms.Label
    $DropDownLabel.Location = new-object System.Drawing.Size(70,140) 
    $DropDownLabel.size = new-object System.Drawing.Size(120,20) 
    $DropDownLabel.Text = "Licenses"
    $Form.Controls.Add($DropDownLabel)

    $DropDownchangedsub = {
     [void]$objListbox.Items.Clear()
     [void]$CheckedListBox.Items.Clear()
     $CheckedListBox.Items.Add("Select All") > $null
     
     $te1licenses = $licenses.GetEnumerator()|?{$_.Value -eq $DropDown.SelectedItem}
     If($te1licenses.Value){
        $tempsku = $sTenant + ":" + $te1licenses.Key
     }else{
        $tempsku = $sTenant + ":" + $DropDown.SelectedItem
     }       
     
     $ser = @()
     $ser = (((Get-MsolAccountSku |?{$_.AccountSkuId -eq $tempsku }).ServiceStatus).ServicePlan).ServiceName
     
        ForEach ($Item in $ser) {
        
         $teserv = $services.GetEnumerator()|?{$_.Key -eq $Item}
            if($teserv.Value){
                [void] $CheckedListBox.Items.Add($teserv.Value)
                
            }else{
                [void] $CheckedListBox.Items.Add($Item)
                
            }
       
       }

     }
    
    $DropDown.add_SelectedIndexChanged($DropDownchangedsub)


    $textBox1 = New-Object System.Windows.Forms.TextBox 
    $textBox1.Location = New-Object System.Drawing.Point(140,70) 
    $textBox1.Size = New-Object System.Drawing.Size(400,20) 
    $form.Controls.Add($textBox1) 


    $Button1 = new-object System.Windows.Forms.Button
    $Button1.Location = new-object System.Drawing.Size(10,70)
    $Button1.Size = new-object System.Drawing.Size(120,25)
    $Button1.Text = "Select a CSV File "
    $button1.Font = "Arial,9.5"
    $Button1.ForeColor = 'Red'
    $Button1.Add_Click({ 
                         Add-Type -AssemblyName System.Windows.Forms
                         $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
                         Multiselect = $false
                         InitialDirectory = $home
                         DefaultExt = '.csv'
                         Filter = 'CSV Files|*.csv|All Files|*.*'
                         FilterIndex = 0
                         RestoreDirectory = $true
                         Title = "Select a CSV file"
                         ValidateNames = $true
                         }
                         [void]$FileBrowser.ShowDialog()
                         $script:csv = $FileBrowser.FileNames
                         $textBox1.Text = $csv
                         })
    $form.Controls.Add($Button1)

    
    ### Groups ####


    $DropDowngroup = new-object System.Windows.Forms.ComboBox
    $DropDowngroup.Location = new-object System.Drawing.Size(140,70)
    $DropDowngroup.Size = new-object System.Drawing.Size(400,20)

    $groupmsol = @()
    $groupmsol = Get-MsolGroup -all |sort DisplayName
    

    ForEach ($Item in $groupmsol) {[void] $DropDowngroup.Items.Add($Item.DisplayName)}
    
    $DropDowngroup.SelectedItem = $DropDowngroup.Items[0]
           
    $Form.Controls.Add($DropDowngroup)

    $DropDowngroupLabel = new-object System.Windows.Forms.Label
    $DropDowngroupLabel.Location = new-object System.Drawing.Size(10,70) 
    $DropDowngroupLabel.size = new-object System.Drawing.Size(120,25) 
    $DropDowngroupLabel.Text = "   Select a Group:"
    $DropDowngroupLabel.Font = "Arial,9.5"
    $DropDowngroupLabel.ForeColor = 'Red'
    $DropDowngroupLabel.BackColor = 'lightGray'
    $DropDowngroupLabel.TextAlign = "MiddleLeft"
    $Form.Controls.Add($DropDowngroupLabel)



    ###############
    
        
    $Button = new-object System.Windows.Forms.Button
    $Button.Location = new-object System.Drawing.Size(70,250)
    $Button.Size = new-object System.Drawing.Size(110,30)
    $Button.Text = "Assign licences"
    $Button.Add_Click({
                        $lic = ""
                        $feat = @()
                        $te2 = $licenses.GetEnumerator()|?{$_.Value -eq $DropDown.SelectedItem}
                         If($te2.Value){
                            $tempsku1 = $sTenant + ":" + $te2.Key
                         }else{
                            $tempsku1 = $sTenant + ":" + $DropDown.SelectedItem
                         }
                        
                        $script:lic = $tempsku1
                        
                        $servicfinal = $objListbox.Items
                        
                        $Script:feat = @()  
                                            
                        
                       ForEach ($Itefinal in $servicfinal) {
        
                         $teservicfinal = $services.GetEnumerator()|?{$_.Value -eq $Itefinal}
                         
                         
                        If($teservicfinal.Value){
                                                      
                            $script:feat += $teservicfinal.Key
                            
                        }else{
                            
                            $script:feat += $Itefinal
                            
                         }
                            
                       }
                       $script:gr = $checkbox3.Checked
                       

                       $form.Close()
                        })
    $form.Controls.Add($Button)

    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Point(400,250)
    $CancelButton.Size = New-Object System.Drawing.Size(75,30)
    $CancelButton.Text = "Cancel"
    $CancelButton.Add_Click({ 
                            $x = "Cancel"
                            $form.Close()
                            $script:cancelform = $true
                            })
    $form.Controls.Add($CancelButton)

    
    $CheckedListBox = New-Object System.Windows.Forms.CheckedListBox
    $CheckedListBox.Location = New-Object System.Drawing.Size(30,220)
    $CheckedListBox.size = New-Object System.Drawing.Size(300,300)
    $CheckedListBox.CheckOnClick = $true
    $CheckedListBox.Items.Add("Select All") > $null
    $CheckedListBox.ClearSelected()
    $CheckedListBox.CheckOnClick = $true
    $CheckedListBox.Hide()
   
   
   $te1 = $licenses.GetEnumerator()|?{$_.Value -eq $DropDown.SelectedItem}
     If($te1){
        $tempsku2 = $sTenant + ":" + $te1.Key
     }else{
        $tempsku2 = $sTenant + ":" + $DropDown.SelectedItem
     }       
     
     $ser = @()
     $ser = (((Get-MsolAccountSku |?{$_.AccountSkuId -eq $tempsku2 }).ServiceStatus).ServicePlan).ServiceName
     $Item = ""  
        ForEach ($Item in $ser) {
        
         $teserv = $services.GetEnumerator()|?{$_.Key -eq $Item}
            if($teserv){
                [void] $CheckedListBox.Items.Add($teserv.Value)
                
            }else{
                [void] $CheckedListBox.Items.Add($Item)
                
            }
       
       }


    Function event_handler (){
    $item = $checkedlistbox.SelectedItem

    If ($_.NewValue -eq 'Checked'){
        
        If($CheckedListBox.SelectedIndex -eq 0){}
        
        else{
            $objListbox.Items.Add( $item );
        }
    }
    else {
    
        If($CheckedListBox.SelectedIndex -eq 0){
            $objListbox.Items.Clear()
        }
        else{
            $objListbox.Items.Remove( $item );
            }    
    }
    }

    $CheckedListBox.Add_click({
        If($this.selecteditem -eq 'Select All'){
            If ($checkedlistbox.checkeditems[0] -eq "Select All"){$checked=$false}else{$checked=$true}
            For($i=1;$i -lt $CheckedListBox.Items.Count; $i++){
                $CheckedListBox.SetItemChecked($i,$checked)
            }
            $objListbox.Items.Clear()
            $check = $CheckedListBox.CheckedItems
            ForEach($ch in $check){
            [void] $objListbox.Items.Add($ch)
        }
        } 
    })

    $CheckedListBox.Add_ItemCheck({event_handler})

    $Form.Controls.Add($CheckedListBox)

    $ListboxLabel = New-Object System.Windows.Forms.Label
    $ListboxLabel.Location = New-Object System.Drawing.Size(40,195) 
    $ListboxLabel.Size = New-Object System.Drawing.Size(280,20) 
    $ListboxLabel.Text = "Please make a selection from the list below:"
    $ListboxLabel.Hide()
    $Form.Controls.Add($ListboxLabel) 

    $objListbox = New-Object System.Windows.Forms.Listbox 
    $objListbox.Location = New-Object System.Drawing.Size(350,220) 
    $objListbox.Size = New-Object System.Drawing.Size(300,400) 
    $objListbox.Items.Clear()
    $objlistbox.Hide()
    $objListbox.Height = 300
    $Form.Controls.Add($objListbox)
    
    $checkbox1 = new-object System.Windows.Forms.checkbox
    $checkbox1.Location = new-object System.Drawing.Size(30,160)
    $checkbox1.Size = new-object System.Drawing.Size(250,50)
    $checkbox1.Text = " Disable some Services "
    $checkbox1.Checked = $false
    $Form.Controls.Add($checkbox1) 

   
    $checkbox1.Add_CheckStateChanged({
        if($checkbox1.Checked -eq $true) {
            $objListbox.Enabled = $checkbox1.Checked
            $ListboxLabel.Enabled = $checkbox1.Checked 
            $CheckedListBox.Enabled = $checkbox1.Checked
            $opti = $true
            $checkbox1.ForeColor = "Red"
            $ListboxLabel.Visible = $true
            $objListbox.Visible = $true
            $CheckedListBox.Visible = $true
            $Form.width = 700
            $Form.height = 650
            $Button.Location = new-object System.Drawing.Size(120,540)
            $CancelButton.Location = New-Object System.Drawing.Point(460,540)
            
        }
        ElseIf($checkbox1.Checked-eq $false) {
            $objListbox.Enabled = $checkbox1.Checked
            $ListboxLabel.Enabled = $checkbox1.Checked
            $CheckedListBox.Enabled = $checkbox1.Checked
            $checkbox1.ForeColor = "Black"
            $opti = $false
            $ListboxLabel.Hide()
            $objListbox.Hide()
            $CheckedListBox.Hide()
            $Form.width = 600
            $Form.height = 350
            $Button.Location = new-object System.Drawing.Size(70,250)
            $CancelButton.Location = New-Object System.Drawing.Point(400,250)
        }
    
     })
    
    $checkbox2 = new-object System.Windows.Forms.checkbox
    $checkbox2.Location = new-object System.Drawing.Size(450,130)
    $checkbox2.Size = new-object System.Drawing.Size(150,50)
    $checkbox2.Text = " Run a Test"
    $checkbox2.Checked = $True
    $Form.Controls.Add($checkbox2) 

    $checkbox2.Add_CheckStateChanged({
        if($checkbox2.Checked -eq $true) {
            $script:testing = $true
            write-host " Testing mode was enable " -ForegroundColor Yellow
        }
        ElseIf($checkbox2.Checked-eq $false) {
            $script:testing = $False
             write-host " Testing mode was disable " -ForegroundColor Red
        }
    })


    $checkbox3 = new-object System.Windows.Forms.checkbox
    $checkbox3.Location = new-object System.Drawing.Size(450,90)
    $checkbox3.Size = new-object System.Drawing.Size(150,50)
    $checkbox3.Text = " Assign per Group "
    $checkbox3.Checked = $False
    $Form.Controls.Add($checkbox3) 

    
    $checkbox3.Add_CheckStateChanged({
        if($checkbox3.Checked -eq $true) {
          $textBox1.Enabled = $false
          $Button1.Enabled = $false
          $textBox1.Visible = $false
          $Button1.Visible = $false
          $DropDowngroup.Enabled = $true
          $DropDowngroupLabel.Enabled = $true
          $DropDowngroup.Visible = $true
          $DropDowngroupLabel.Visible = $true
        }
        ElseIf($checkbox3.Checked-eq $false) {
          $textBox1.Enabled = $true
          $Button1.Enabled = $true
          $textBox1.Visible = $true
          $Button1.Visible = $true
          $DropDowngroup.Enabled = $false
          $DropDowngroupLabel.Enabled = $false
          $DropDowngroup.Visible = $false
          $DropDowngroupLabel.Visible = $false
        }
    })

#>

$Form.Add_Shown({$Form.Activate()})
[void] $Form.ShowDialog()

If($cancelform){
    Write-Host "Script was ended without actions " -ForegroundColor Yellow -BackgroundColor Red
    exit
}

########## End Form GUI ################



## Variables II

$file = $csv
$sLicString = $lic
$LO = ""
$LO = "New-MsolLicenseOptions -AccountSkuId $sLicString"
$can = $feat.Count

#if($lic){
#$licpure = $lic.split(":")[1]
#}

$licpure = $DropDown.SelectedItem
$lic_Services = $objlistbox.Items
$lic_Services_Final = ""


if($gr -eq $false){

    if (($csv -eq $null) -or ($csv -eq "") ){
        write-host " You have to select a csv file" -ForegroundColor Red
        exit
    }
    $us=@()
    $us=Import-Csv $csv
    
    }else{
    $selec = $DropDowngroup.SelectedItem
    
    $endgroup = $groupmsol |?{$_.DisplayName -ceq $selec}|select ObjectId

    $membersIS = Get-MsolGroupMember -GroupObjectId $endgroup.ObjectId |?{$_.GroupMemberType -eq 'User'} |select DisplayName, ObjectId 


    $usersmsol = @()

    foreach($mem in $membersIS){
       $usersmsol += Get-MsolUser -ObjectId $mem.ObjectId|select DisplayName, UserPrincipalName
    }
    
    $us=@()
    $us= $usersmsol
    
    }
    


If ( $can -gt 0 ){

    for ($i=0;$i -lt $can;$i++){
        
        
         
        If ($i -eq 0){

            $LO += " -DisabledPlans " + $feat[$i]
            If($lic_Services){ $lic_Services_Final += " Services disabled (" + $lic_Services[$i]}

        } else {

           $LO += "," + $feat[$i]
           If($lic_Services){ $lic_Services_Final += "|" + $lic_Services[$i]}
        }

    }

}

If($lic_Services){ $lic_Services_Final += ")"}

$LO = $ExecutionContext.InvokeCommand.NewScriptBlock($LO)

if ( $opti -eq $false){
                      $LicenseOptions=@()
 } else {$LicenseOptions = & $LO}




#######################################################

$licensetype = Get-MsolAccountSku | Where {($_.AccountSkuId -eq $lic)}

$licount = $us.count

[int]$ava = [int]$licensetype.ActiveUnits - [int]$licensetype.ConsumedUnits

If ($licount -gt $ava){
   
                       $te2 = " You don't have enough licenses to assign, you have " + $ava + " and you want to assign " + $licount + " press OK if you want to assign just your available licenses. The final log will let you know which users were not assigned a license " 

                       $UserResponse= [System.Windows.Forms.MessageBox]::Show($te2 , "No licenses" , 1)

                       if ($UserResponse -eq "OK" ) 
                                        {$iAdminCount =  $ava} 

                                    elseif($UserResponse -eq "Cancel") 

                                        {exit} 
                                    else
                                        {exit}
    
                       }
#######################################################

[int]$d = 0

If($testing -eq $true){Write-Host " ###################### This is a Test, no changes will be made ###################### " -ForegroundColor Green} 

$us | % {
         If($_.userprincipalname){    
         If(Get-MsolUser -UserPrincipalName $_.userprincipalname -ErrorAction SilentlyContinue)
         {          
           $d += 1
                if(($ava -gt $d) -or ($ava -eq $d)){
                
                        $islic = (get-msoluser -UserPrincipalName $_.userprincipalname | select IsLicensed).IsLicensed
        
                        if($islic -eq $False) { Set-MsolUser -UserPrincipalName $_.userprincipalname -UsageLocation $location 
                                if($testing -eq $False){
                                    Set-MsolUserLicense -UserPrincipalName $_.userprincipalname -AddLicenses $lic
                                    Set-MsolUserLicense -UserPrincipalName $_.userprincipalname -LicenseOptions $LicenseOptions
                                }
                                $myArray += $_.userprincipalname + "," + " License assigned (" + $licpure + ')' + $lic_Services_Final
                                Write-Host "This user " $_.userprincipalname " License was assigned successfully" -ForegroundColor Yellow
                
                        } 
                        else 
                        {
                            $licensedetails = (Get-MsolUser -UserPrincipalName $_.userprincipalname).Licenses
                            $count = $licensedetails.Count
                            $i=0
                            $c=0
                            while ($i -lt $count) {
                                                    if ($licensedetails[$i].AccountSkuId -eq $sLicString) {$c +=1}       
                                                    $i +=1 
                         }
                        If ($c -eq 0)
                        {
                            if($testing -eq $false){
                                    Set-MsolUserLicense -UserPrincipalName $_.userprincipalname -AddLicenses $lic
                                    Set-MsolUserLicense -UserPrincipalName $_.userprincipalname -LicenseOptions $LicenseOptions
                                }
                            $myArray += $_.userprincipalname + "," + "This user had other license and we add the one you selected (" + $licpure + ')' + $lic_Services_Final                     
                            Write-Host "This user " $_.userprincipalname " had other license and we have added the one you selected" -ForegroundColor Green
                         } 
                         else 
                         {
                            $d -=1
                             $myArray += $_.userprincipalname + "," + "Not actions; This user had the licenses (" + $licpure + ')' + $lic_Services_Final
                             Write-Host "This user " $_.userprincipalname " had already the license, not actions" -ForegroundColor Magenta
                          }
                       }

                }
                else {
                    $myArray += $_.userprincipalname + "," + " You don't have enough licenses for this user"
                    Write-Host "You don't have enough licenses for " $_.userprincipalname -ForegroundColor Red
                }
    
          }      
          else
           {
            Write-Host "The User " $_.userprincipalname " do not exist on Office 365" -ForegroundColor Red
            $myArray += $_.userprincipalname + "," + " This user do not exist on Office 365"
            }
        
        }               
        }
        
        
$myArray | Out-File -Encoding ascii -FilePath $outpath 
        
Write-Host "Script Execution Completed Successfully. You can check the log at" $outpath -ForegroundColor Green



$relicense = @()
$relicense2 = @()
$relicense = import-csv $outpath 

$relicense2 = $relicense |?{$_.Comment -like '*not actions*'}

$recount = $relicense.Count

if($relicense2){


    $result = [Microsoft.VisualBasic.Interaction]::MsgBox(" We found you have users that already have the license, Do you want to reassing the license to those users? ",'YesNo,Question,SystemModal,Question',"Modify user's licenses") 
 
    switch ($result) { 
        'Yes'{ 
              $myArray += "----------------------,--------------------------------------------"
              $myArray += " UserPrincipalName, These user were relicensed"
              $myArray += "----------------------,--------------------------------------------"  
              ForEach ($uselic in $relicense2){
              if($testing -eq $false){
                    Set-MsolUserLicense -UserPrincipalName $uselic.userprincipalname -LicenseOptions $LicenseOptions
                    }
              $myArray += $uselic.UserPrincipalName + "," + 'License reassigned (' + $licpure + ')' + $lic_Services_Final
              write-host "We have overwritten a license to the user " $uselic.UserPrincipalName -ForegroundColor White
             }  
        
             } 
        'No'{ 
               write-host " Ok not actions " -ForegroundColor Yellow
        
            } 
        }
$myArray | Out-File -Encoding ascii -FilePath $outpath 
}



