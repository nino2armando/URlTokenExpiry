# Environment helper functions

# determine if production environment based on server naming convention
# ie NV(P)-IIS010 - P means Production
function isProductionEnvironment
{
    ($env:ComputerName).SubString(2,1) -eq "P"
}

function getIPv4Addresses
{
    [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | 
        where { $_.NetworkInterfaceType -eq "Ethernet" } | 
            foreach { $_.GetIPProperties().UnicastAddresses } |
                where { $_.Address.AddressFamily -eq "InterNetwork" }
}

# get protected ipv4 string
function getProtectedIpString
{
    getIPv4Addresses | 
        # By convention protected ip addresses have 255.255.255.255 has mask
        where { $_.IPv4Mask -eq "255.255.255.255" } | 
            foreach { $_.Address.IPAddressToString } | 
                sort | 
                    select -first 1
}

# get unprotected ipv4 string
function getUnprotectedIpString
{
    getIPv4Addresses | 
        # By convention protected ip addresses have 255.255.255.255 has mask
        where { $_.IPv4Mask -ne "255.255.255.255" } | 
            foreach { $_.Address.IPAddressToString } | 
                sort | 
                    select -first 1
}
