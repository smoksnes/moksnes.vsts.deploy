Trace-VstsEnteringInvocation $MyInvocation
try {
    Import-VstsLocStrings "$PSScriptRoot\task.json"

    # Get the inputs.
    [string]$msDeployPath = Get-VstsInput -Name MsDeployPath -Require
    [string]$password = Get-VstsInput -Name Password
    [string]$username = Get-VstsInput -Name Username
    [string]$serverName = Get-VstsInput -Name ServerName -Require
    [string]$siteName = Get-VstsInput -Name SiteName -Require
    [string]$source = Get-VstsInput -Name Source -Require
    [bool]$takeOffline = Get-VstsInput -Name TakeOffline -Require -AsBool


    if($takeOffline)
    {
        Write-Host 'Will try to take site offline.'

        $pswd = ConvertTo-SecureString -String $password -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential -ArgumentList @($username, $pswd)

        $ScriptBlock = { 
            param($siteName) 
            import-module WebAdministration; 
            Stop-Website $siteName
        }

        Invoke-Command -ComputerName $serverName -Credential $cred  $ScriptBlock -ArgumentList $siteName
        Write-Host 'Finished taking site offline.'
    }

    #Invoke-Expression "& '[path to msdeploy]\msdeploy.exe' --% -verb:sync -source:contentPath=`'$source`' -dest:contentPath=`'$dest`'"
    $args = "--% -verb:sync -source:iisApp=`'$source`' -dest:iisApp=`'$siteName`',computername=`'$serverName`'"


    if ($username) {
        Write-Host 'Adding username to arguments.'
         $args += ",username=`'$username`',password=`'$password`'"
    } 

    $msDeployQuery = "& '$msDeployPath'" + $args

    Invoke-Expression $msDeployQuery
    Write-Host 'Deploy complete.'
    if($takeOffline)
    {
        Write-Host 'Will try to take site online again.'
        $pswd = ConvertTo-SecureString -String $password -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential -ArgumentList @($username, $pswd)

        $ScriptBlock = { 
            param($siteName) 
            import-module WebAdministration; 
            Start-Website $siteName
        }

        Invoke-Command -ComputerName $serverName -Credential $cred  $ScriptBlock -ArgumentList $siteName
        Write-Host 'Finished starting site'
    }
    Write-Host 'All done. Have a nice day. ;)'

    #-verb:sync -source:iisApp="$(System.DefaultWorkingDirectory)/$(ArtifactFolder)" -dest:iisApp="$(IISSiteName)",computername=$(Machine),username=$(AdminUsername),password=$(AdminPassword) -skip:absolutePath="\\NLogs"

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}