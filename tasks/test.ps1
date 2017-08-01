    # Get the inputs.

    param (
    [string]$msDeployPath,
    [string]$password,
    [string]$username,
    [string]$serverName,
    [string]$siteName,
    [string]$source,
    [string]$skip,
    [bool]$takeOffline)


    function TakeOnline{
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

    function TakeOffline{
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


    if($takeOffline) {
        TakeOffline
    }

    $args = "'-verb:sync' "
    $args +="'-source:iisApp=$source' "
    $args +="'-dest:iisApp=$siteName,computername=$serverName'"


    if ($username) {
        Write-Host 'Adding username to arguments.'
         $args += ",username=$username,password=$password"
    } 

    if($skip){
        Write-Host "Adding skip."
        $args += " -skip:objectName=dirPath,absolutePath=$skip"
    }


    $deployCmd = (Get-Command $msDeployPath).FileVersionInfo.FileName
    $fullDeployCmd = "`"$deployCmd`""

    invoke-expression "&$fullDeployCmd $args"
    Write-Host "Exit code is $LASTEXITCODE"

    if(!$LASTEXITCODE -eq 0) {
        Write-Host 'Something went wrong during release.'
        if($takeOffline)
        {
            TakeOnline
        }
        throw [System.Exception]::new('Deployment failed.','Something went wrong during deployment.')
    }
    
    Write-Host 'Deploy complete.'
    if($takeOffline)
    {
        TakeOnline
    }
    Write-Host 'All done. Have a nice day. ;)'