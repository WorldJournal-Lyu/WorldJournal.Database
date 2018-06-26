<#

WorldJournal.Database.psm1

    2018-06-26 Initial creation

#>

Add-Type -Path "C:\Oracle\instantclient_10_2\odp.net\managed\common\Oracle.ManagedDataAccess.dll"

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
    $conn.open()

    if($conn.State -eq "Open"){

        $reader = $cmd.ExecuteReader()

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

            #READER HAS NO ROWS

        }

        $reader.close()

    }else{

        #CONNECTION NOT OPEN

    }

    $conn.Close()

    return $ary

}
