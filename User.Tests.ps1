$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

if (-not (Get-Command -Name get-aduser -ErrorAction SilentlyContinue)) {function get-aduser {}}

Describe "Get-UserHomeDirectory" {
    $real_user = 'user1'
    $broken_user = 'user2'
    $home = '\\server\home\user1'
    $profilepath = '\\server\profile\user1'

    Mock Get-ADUser {
        param($identity)

        if ($identity -eq $real_user) {
            @{
                DistinguishedName = 'CN=User1,OU=blah,DC=something,DC=com'
                Enabled = $true
                GivenName = 'Real'
                Name = 'User1'
                ObjectClass = 'user'
                ObjectGuid = 'jhagsjhgdjhsdgajhsgdjhsgadjasghdghdjashsdgajh'
                HomeDirectory = $home
                SID = 'S-1-1-11-11111111-11111111'
                Surname = 'User'
                UserPrincipalName = 'user1@something.com'
            }
        } else {
            Write-Error "No user found" -ErrorAction Stop
        }
    }

    Context "when called on an existing user" {
    
        $result = Get-UserHomeDirectory -Username $real_user
        It "should return the homedirectory attribute" {
            $result | Should Be $home
        }
    }

    Context "when called on a non-existent user" {
        It "should throw an error" {
            {Get-UserHomeDirectory -Username $broken_user} | Should throw
        }
    }
}

Describe "Get-UserProfileDirectory" {
    $real_user = 'user1'
    $broken_user = 'user2'
    $home = '\\server\home\user1'
    $profilepath = '\\server\profile\user1'

        Mock Get-ADUser {
            param($identity)

            if ($identity -eq $real_user) {
                @{
                    DistinguishedName = 'CN=User1,OU=blah,DC=something,DC=com'
                    Enabled = $true
                    GivenName = 'Real'
                    Name = 'User1'
                    ObjectClass = 'user'
                    ObjectGuid = 'jhagsjhgdjhsdgajhsgdjhsgadjasghdghdjashsdgajh'
                    ProfilePath = $profilepath
                    SID = 'S-1-1-11-11111111-11111111'
                    Surname = 'User'
                    UserPrincipalName = 'user1@something.com'
                }
            } else {
                Write-Error "No user found" -ErrorAction Stop
            }
        }

    Context "when called on an existing user" {
        
        $result = Get-UserProfileDirectory -Username $real_user
        It "should return the profile attribute" {
            $result | Should Be $profilepath
        }
    }
    
    Context "when called on a non-existent user" {
        It "should throw an error" {
            {Get-UserProfileDirectory -Username $broken_user} | Should throw
        }
    }
}