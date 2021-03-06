<#
.SYNOPSIS
Gets the HostedserviceName

.DESCRIPTION
Gets the HostedserviceName

.EXAMPLE
Get-D365InstanceName

.NOTES
General notes
#>
function Get-D365InstanceName
{
    $WebConfigFile = Join-Path $Script:AOSPath $Script:WebConfig
    
    $ServiceNameNode = Select-Xml -XPath "/configuration/appSettings/add[@key='Infrastructure.HostedServiceName']/@value" -Path $WebConfigFile
    $ServiceName = $ServiceNameNode.Node.Value
    $ServiceName
}