$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"


# hack for not having the fsrm cmdlets
if (-not (Get-Command -Name get-fsrmquota -ErrorAction SilentlyContinue)) {function get-fsrmquota {}}
if (-not (Get-Command -Name set-fsrmquota -ErrorAction SilentlyContinue)) {function set-fsrmquota {}}

Describe "Resolve-UNCPath" {
    $resolving_share = 'banana'
    $non_resolving_share = 'apple'

    $full_path = 'z:\fruit'

    Mock -verifiable get-smbshare {
        param($cimsession,$name) 

        if ($name -eq $resolving_share) {
            @{
                Name = $name
                Scopename = $cimsession
                Path = $full_path
                Description =''
                PSComputername = $cimsession
            }
        } else {
            throw "get-smbshare : blah blah"
        }

    }

    Context "when called with a valid UNC path" {

        $result = Resolve-UNCPath -Path "\\server\$resolving_share"
        It "should return a local path when the share exists" {
            $result | Should Be $full_path
        }

        It "should throw an error when the path does not resolve" {
        
            {Resolve-UNCPath -Path "\\server\$non_resolving_share"} | Should throw
        }

        It "should call get-smbshare" {
            Assert-VerifiableMocks
        }
    }
}

Describe "Get-UNCQuota" {
    Context "when called with a valid UNC Path" {
        $quota_set_path = 'z:\blah'
        $quota_not_set_path = 'z:\blahblah'
        $quota_set_unc = '\\server\blah'
        $quota_not_set_unc = '\\server\blahblah'

        Mock -verifiable Get-FSRMQuota {
            param($cimsession,$path) 

            if ($path -eq $quota_set_path) {
                'blah'
            } elseif ($path -eq $quota_not_set_path) {
            
            }
        }

        Mock -verifiable resolve-uncpath {
            param($path) 

            if ($path -eq $quota_set_unc) {
                $quota_set_path
            } else {
                $quota_not_set_path
            }
        }

        
        $result = get-uncquota -path $quota_set_unc
       
        It "should return a quota for the path, if one is set" {
            
            $result | Should Not BeNullOrEmpty
        }
        
        $result = get-uncquota -path $quota_not_set_unc
        It "should not return a quota for the path, if one is not set" {
            $result | Should BeNullOrEmpty
        }

        It "should call Get-FSRMQuota, resolve-uncpath" {
            Assert-VerifiableMocks
        }
    }
}

Describe "Set-UNCQuota" {
    Context "when called with a valid UNC Path" {
        
        Mock -verifiable set-fsrmquota {}


        $current_usage = 4gb
        $incorrect_quota = 1gb
        $correct_quota = 4gb 
        $path = '\\server\blah'

        Mock -verifiable get-uncquota {
            @{
                Description = ''
                Disabled = $false
                MatchesTemplate = $true
                Path = $path
                PeakUsage = $current_usage
                Size = $current_usage
                SoftLimit = $false
                Template = '2 GB Limit'
                Threshold = $null
                Usage = $current_usage
                PSComputername = 'server'
            }
        }

        It "should error when size is less than current quota usage" {

            {Set-UNCQuota -Path $path -Size $incorrect_quota} | Should Throw
        }

        It "should not error when size is greater than current quota usage" {
            {Set-UNCQuota -Path $path -Size $correct_quota} | Should Not Throw
        }


        It "should error if the quota response and the new quota do not match" {
            {$result = Set-UNCQuota -Path $path -Size ($correct_quota+1)} | should throw
        }

        $result = Set-UNCQuota -Path $path -Size $correct_quota
        It "should return the new quota" {
            $result | Should Not BeNullOrEmpty
        }

        It "should call get/set fsrmquota" {
        
            Assert-VerifiableMocks
        }
    }
}
