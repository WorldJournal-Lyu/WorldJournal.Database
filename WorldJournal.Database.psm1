<#

WorldJournal.Database.psm1

    2018-06-26 Initial creation

#>

Add-Type -Path "C:\Oracle\instantclient_10_2\odp.net\managed\common\Oracle.ManagedDataAccess.dll"
$xmlPath = (Split-Path (Split-Path (Split-Path ($MyInvocation.MyCommand.Path) -Parent) -Parent) -Parent)+"\_DoNotRepository\"+(($MyInvocation.MyCommand.Name) -replace '.psm1', '.xml')
[xml]$xml = Get-Content $xmlPath -Encoding UTF8




function Get-WJDatabase() {
    [CmdletBinding()]
    Param ()
    DynamicParam {

        $paramDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary

        $attributes = New-Object System.Management.Automation.ParameterAttribute
        $attributes.Mandatory = $false
        $attributes.ParameterSetName = '__AllParameterSets'
        $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $attributeCollection.Add($attributes)
        $values = $xml.Root.Database.Name | Select-Object -Unique
        $validateSet = New-Object System.Management.Automation.ValidateSetAttribute($values)    
        $attributeCollection.Add($validateSet)
        $dynamicParam = New-Object -Type System.Management.Automation.RuntimeDefinedParameter(
            "Name", [string], $attributeCollection
        )

        $paramDictionary.Add("Name", $dynamicParam)

        return $paramDictionary

    }

    begin {}
    process {

        $Name = $PSBoundParameters.Name
    
        $whereArray = @()
        if ($Name -ne $null) { $whereArray += '$_.Name -eq $Name' }
        $whereString = $whereArray -Join " -and "  
        $whereBlock = [scriptblock]::Create( $whereString )

        if ($PSBoundParameters.Count -ne 0) {
            $xml.Root.Database | Where-Object -FilterScript $whereBlock | Select-Object Name, Username, Password, Datasource
        }
        else {
            $xml.Root.Database | Select-Object Name, Username, Password, Datasource
        }

    }
    end {}
}








Function Query-Database{

    Param(
        [Parameter(Mandatory=$true)][string]$Username,
        [Parameter(Mandatory=$true)][string]$Password,
        [Parameter(Mandatory=$true)][string]$Datasource,
        [Parameter(Mandatory=$true)][string]$Query
    )

    $ary = @()

    $connString      = 'User Id=' + $Username + ';Password=' + $Password + ';Data Source=' + $Datasource
    $conn            = New-Object Oracle.ManagedDataAccess.Client.OracleConnection($connString)
    $cmd             = $conn.CreateCommand()
    $cmd.CommandText = ($Query -replace '(^\s+|\s+$)','' -replace '\s+',' ')
    
    try{

        $conn.open()

    }catch{

        return "CONNECTION ERROR"

    }

    if($conn.State -eq "Open"){

        try{

            $reader = $cmd.ExecuteReader()

        }catch{

            return "READER ERROR"
        
        }

        if($reader.HasRows){

            while ($reader.Read()) {

                $obj = New-Object System.Object

                for($i = 0; $i -lt $reader.FieldCount; $i++){

                    $obj | Add-Member -Type NoteProperty -Name $reader.GetName($i) -Value $reader.GetValue($i)

                }

                $ary += $obj

            }

            $reader.Close()

        }else{

            return "READER HAS NO ROWS"

        }

        $reader.close()

    }else{

        return "CONNECTION NOT OPEN"

    }

    $conn.Close()

    return $ary

}
