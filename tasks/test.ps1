    # Get the inputs.

    param (
    [string]$msDeployPath,
    [string]$password,
    [string]$username,
    [string]$serverName,
    [string]$siteName,
    [string]$source,
    [bool]$takeOffline)

        Write-Host 'Deploy init.'

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