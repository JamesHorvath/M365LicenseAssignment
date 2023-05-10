<#
Azure AD PoSH for Graph Module is being deprecated Please see MS Graph PoSH SDK
.SYNOPSIS
    Removes and assigns an M365 license (Direct Assignment)
.DESCRIPTION
    Parses Users.csv for license change
.NOTES
    String IDs for M365 Service plans can be found at the following uRL
    https://docs.microsoft.com/en-us/azure/active-directory/users-groups-roles/licensing-service-plan-reference
    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    This script parses Users.csv unnassign a subscription. csv must be in the format
Email
fred@domain.com
.LINK
    
.EXAMPLE
    .\M365RemoveAssignLicense.ps1
#>


$RemoveLicense="ENTERPRISEPACK"
$AssignLicense="SPE_E3"

$RemovedSuccessReport= $RemoveLicense + '-RemovalSucessReport.txt'
$RemovedFailReport= $RemoveLicense + '-RemovalFailReport.txt'
$AssignmentSuccessReport= $AssignLicense + '-AssignmentSuccessReport.txt'
$AssignmentFailReport= $AssignLicense + '-AssignmentFailReport.txt'

Import-csv Users.csv | foreach { 
	$userUPN = $_.email 

    # Assign usage location United States if field UsageLocation empty
    $userObject = Get-azureaduser -ObjectId $userUPN

    if($userObject -ne $null){

    if($userObject.UsageLocation -eq $null){
        try{
            Set-AzureADUser -ObjectId $userUPN -UsageLocation "US"
            Write-Host "Usage Location for user $($userUPN) was not set. Added Usage Location US to the user!" -ForegroundColor "Yellow"
        }catch{
            Write-Host "Unable to set usage location for the user $($userUPN)" -ForegroundColor "Red"
            continue
        }
    }

    $license = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
    $licenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
    $license.SkuId = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value $AssignLicense -EQ).SkuID
    $licenses.AddLicenses = $license
#Remove License
    try{
        $licenses.RemoveLicenses =  (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value $RemoveLicense -EQ).SkuID
        Write-Host "Removed ($RemoveLicense) license for ($userUPN)"
        $userUPN | Out-File -FilePath $RemovedSuccessReport -Append
     }catch{
         Write-Host "Unable to remove ($RemoveLicense) from ($userUPN)"
         $userUPN | Out-File -FilePath $RemovedFailReport -Append
         continue
     } 

#Sleep for one second to allow license removal to time to update     
Start-Sleep -Seconds 1
#Assign License

    try{
        Set-AzureADUserLicense -ObjectId $userUPN -AssignedLicenses $licenses  
        $licenses.AddLicenses = @()
        Write-Host "Added ($AssignLicense) license for ($userUPN)"
        $userUPN | Out-File -FilePath $AssignmentSuccessReport -Append
    }catch{
        Write-Host "Unable to assign ($AssignLicense) from ($userUPN)"
        $userUPN | Out-File -FilePath $AssignmentFailReport -Append
        continue
    }
    }
}