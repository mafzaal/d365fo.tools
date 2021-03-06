<#
.SYNOPSIS

Syncs like Visual Studio

.DESCRIPTION
Uses SyncEngine for syncing D365fo

.PARAMETER LogPath
The path where the log file will be saved

.PARAMETER SyncMode
The sync mode the sync engine will use

.PARAMETER Verbosity
Used in the SyncEngine.

.EXAMPLE
Invoke-D365DBSync

.NOTES
#>
function Invoke-D365DBSync {
    param(
        [Parameter(Mandatory = $false, Position = 1)]
        [string]$DatabaseServer = $Script:DatabaseServer,
        [Parameter(Mandatory = $false, Position = 2)]
        [string]$DatabaseName = $Script:DatabaseName,
        [Parameter(Mandatory = $false, Position = 3)]
        [string]$SqlUser = $Script:DatabaseUserName,
        [Parameter(Mandatory = $false, Position = 4)]
        [string]$SqlPwd = $Script:DatabaseUserPassword,
        [Parameter(Mandatory = $false, Position = 5)]
        [string]$LogPath = "C:\temp\D365FO-Tool\Sync",
        [Parameter(Mandatory = $false, Position = 6)]
        #[ValidateSet('None', 'PartialList','InitialSchema','FullIds','PreTableViewSyncActions','FullTablesAndViews','PostTableViewSyncActions','KPIs','AnalysisEnums','DropTables','FullSecurity','PartialSecurity','CleanSecurity','ADEs','FullAll','Bootstrap','LegacyIds','Diag')]
        [string]$SyncMode = 'FullAll',
        [Parameter(Mandatory = $false, Position = 7)]
        [ValidateSet('Normal', 'Quiet', 'Minimal', 'Normal', 'Detailed', 'Diagnostic')]
        [string]$Verbosity = 'Normal'
    )

    if (!$script:IsAdminRuntime -and !($PSBoundParameters.ContainsKey("SqlPwd"))) {
        Write-Host "It seems that you ran this cmdlet non-elevated and without the -SqlPwd parameter. If you don't want to supply the -SqlPwd you must run the cmdlet elevated (Run As Administrator) or simply use the -SqlPwd parameter" -ForegroundColor Yellow
        Write-Error "Running non-elevated and without the -SqlPwd parameter. Please run elevated or supply the -SqlPwd parameter." -ErrorAction Stop
    }

    $command = "$Script:BinDir\bin\SyncEngine.exe"

    $param = " -syncmode=$($SyncMode.ToLower())"
    $param += " -verbosity=$($Verbosity.ToLower())"
    $param += " -metadatabinaries=`"$Script:BinDir`""
    $param += " -connect=`"server=$DatabaseServer;Database=$DatabaseName;Trusted_Connection=false; User Id=$DatabaseUserName;Password=$DatabaseUserPassword;`""

    Write-Verbose "CommandFile $command"
    Write-Verbose "Parameters $param"

    if ( -not (Test-Path $LogPath.Trim())) {
        Write-Verbose "Creating $LogPath"
        $null = New-Item -Path $LogPath -ItemType directory -Force -ErrorAction Stop
    }

    $syncEngine = get-process -name "SyncEngine" -ErrorAction SilentlyContinue
    if ($null -ne $syncEngine) {

        write-Error "A instance of SyncEngine is already running"
        return

    }


    $process = Start-Process -FilePath $command -ArgumentList  $param -PassThru  -RedirectStandardOutput "$LogPath\output.log" -RedirectStandardError "$LogPath\error.log" -WindowStyle "Hidden"

    $lineTotalCount = 0
    $lineCount = 0
    Write-Verbose "Process Started"
    Write-Verbose $process

    $StartTime = Get-Date


    while ($process.HasExited -eq $false) {
        foreach ($line in Get-Content "$LogPath\output.log") {
            $lineCount++
            if ($lineCount -gt $lineTotalCount) {
                Write-Verbose $line
                $lineTotalCount++
            }
        }
        $lineCount = 0
        Start-Sleep -Seconds 2

    }

    foreach ($line in Get-Content "$LogPath\output.log") {
        $lineCount++
        if ($lineCount -gt $lineTotalCount) {
            Write-Verbose $line
            $lineTotalCount++
        }
    }


    foreach ($line in Get-Content "$LogPath\error.log") {
        Write-Error $line
    }

    $EndTime = Get-Date

    $TimeSpan = New-TimeSpan -End $EndTime -Start $StartTime

    Write-Host "Time Taken for sync:" -ForegroundColor Green
    Write-Host "$TimeSpan" -ForegroundColor Green


}