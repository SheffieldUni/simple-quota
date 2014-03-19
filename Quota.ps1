# simple-quota quota functions
function Resolve-UNCPath {

    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true)]
        [Alias('UNC','UNCPath')]
        $Path
    )

    begin {}

    process {
        if ($Path -match '^\\\\(?<server>\w+)\\(?<share>\w+)') {
            try {
                (Get-SmbShare -Name $matches.share -CimSession $matches.server).Path
            }
            catch {
                Write-Error "Problem querying server or path not found" -ErrorAction stop
            }
        } else {
            Write-Error "UNC path format not valid"
        }
    }

    end {}
}

function Get-UNCQuota {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true)]
        [Alias('UNC','UNCPath')]
        $Path
    )

    begin {}

    process {
        try {
            $local_path = Resolve-UNCPath -Path $Path
        }
        catch {
            Write-Error "Could not resolve UNC to local path" -ErrorAction Stop
        }

        if ($Path -match '^\\\\(?<server>\w+)\\(?<share>\w+)(?<relative_path>.+)?') {
            try {
                if ($matches.relative_path) {
                    #$local_path = Join-Path -Path $local_path -ChildPath $matches.relative_path
                    $local_path = [IO.Path]::GetFullPath("$local_path`\$($matches.relative_path)")
                }
                
                Get-fsrmquota -path $local_path -CimSession $matches.server
            }
            catch {
                Write-Error "Problem querying server or path not found" -ErrorAction stop
            }
        } else {
            Write-Error "UNC path format not valid"
        }
    }

    end {}
}

function Set-UNCQuota {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true)]
        [Alias('UNC','UNCPath')]
        $Path,
        [Parameter(Mandatory=$true)]
        $Size
    )

    begin {}

    process {
        $current_quota = Get-UNCQuota -Path $Path

        if ($current_quota.Usage -gt $Size) {
            Write-Error "Current usage is greater than requested quota" -ErrorAction Stop
        } else {
            try {
                Set-FSRMQuota -Path $current_quota.Path -Cimsession $current_quota.PSComputername -Size $Size
            }
            catch {
                Write-Error "Error setting FSRM quota" -ErrorAction Stop
            }

            $new_quota = Get-UNCQuota -Path $Path

            if ($new_quota.Size -eq $Size) {
                $new_quota
            } else {
                Write-Error "The new quota and requested size do not match" -ErrorAction Stop
            }
        }
    }

    end {}

}

function New-UNCQuota {
    [CmdletBinding()]

    param(
        [Parameter(Mandatory=$true)]
        [Alias('UNC','UNCPath')]
        $Path,
        [Parameter(Mandatory=$true)]
        $Template    
    )
    
    begin {}

    process {
        $current_quota = Get-UNCQuota -Path $Path 

        if ($current_quota) {
            Write-Error "A quota already exists for $Path"
        } else {
            $local_path = Resolve-UNCPath -Path $Path

            if (-not $local_path) {
                Write-Error "Cannot resolve UNC path"
            } else {
            
                if ($Path -match '^\\\\(?<server>\w+)\\(?<share>\w+)(?<relative_path>.+)?') {
                    try {
                        $local_path = [IO.Path]::GetFullPath("$local_path`\$($matches.relative_path)")
                        New-FSRMQuota -Path $local_path -CimSession $matches.server -Template $Template
                    }
                    catch {
                        Write-Error "Cannot create quota"
                    }
                }
            }
        }
    }

    end {}

}