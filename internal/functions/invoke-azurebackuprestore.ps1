Function Invoke-AzureBackupRestore ($DatabaseServer, $DatabaseName, $SqlUser, $SqlPwd, $NewDatabaseName) {
    $StartTime = Get-Date

    $sqlCommand = Get-SQLCommand $DatabaseServer $DatabaseName $SqlUser $SqlPwd
    
    $commandText = (Get-Content "$script:PSModuleRoot\internal\sql\newazuredbfromcopy.sql") -join [Environment]::NewLine
    
    $commandText = $commandText.Replace('@CurrentDatabase', $DatabaseName)
    $commandText = $commandText.Replace('@NewName', $NewDatabaseName)

    $sqlCommand.CommandText = $commandText

    Write-Verbose "NewDatabaseName: $NewDatabaseName"

    $sqlCommand.CommandTimeout = 0

    $sqlCommand.Connection.Open()

    Write-Verbose $sqlCommand.CommandText
    
    $null = $sqlCommand.ExecuteNonQuery()

    $sqlCommand.Dispose()

    $sqlCommand = Get-SQLCommand $DatabaseServer "master" $SqlUser $SqlPwd

    $commandText = (Get-Content "$script:PSModuleRoot\internal\sql\checkfornewazuredb.sql") -join [Environment]::NewLine

    $sqlCommand.CommandText = $commandText

    $null = $sqlCommand.Parameters.Add("@NewName", $NewDatabaseName)
    $null = $sqlCommand.Parameters.Add("@Time", $StartTime)

    $sqlCommand.Connection.Open()
        
    Write-Verbose $sqlCommand.CommandText

    $operation_row_count = 0
    #Loop every minute until we get a row, if we get a row copy is done
    while($operation_row_count -eq 0){
        Write-Verbose "$(Get-Date) - Waiting for the creation of the copy."
        $Reader = $sqlCommand.ExecuteReader()
        $Datatable = New-Object System.Data.DataTable
        $Datatable.Load($Reader)
        $operation_row_count = $Datatable.Rows.Count
        Start-Sleep -s 60
    }

    $Reader.Close()
    $sqlCommand.Dispose()
    $Datatable.Dispose()

    $EndTime = Get-Date

    $TimeSpan = New-TimeSpan -End $EndTime -Start $StartTime

    Write-Host "Time Taken inside: Invoke-AzureBackup" -ForegroundColor Green
    Write-Host "$TimeSpan" -ForegroundColor Green
}