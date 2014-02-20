# simple-quota user functions
function Get-UserHomeDirectory {
    [CmdletBinding()]

    param (
        [Parameter(Mandatory=$true)]
        $Username
    )

    begin {}

    process {
        try {
            $user = Get-Aduser -Identity $Username -Property Homedirectory 
        }
        catch 
        {
            Write-Error "Could not find user" -ErrorAction Stop
        }

        $user.HomeDirectory
    }

    end {}
}

function Get-UserProfileDirectory {

    [CmdletBinding()]

    param (
        [Parameter(Mandatory=$true)]
        $Username
    )

    begin {}

    process {
        try {
            $user = Get-Aduser -Identity $Username -Property ProfilePath 
        }
        catch 
        {
            Write-Error "Could not find user" -ErrorAction Stop
        }

        $user.Profilepath
    }

    end {}
}