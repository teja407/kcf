$RG = "df"
$DFname = "adfv10322"

$runStartDateTimeUTC = (Get-Date).AddDays(-1)


#Get-AzureRmDataFactory -ResourceGroupName $RG

#Get-AzureRmDataFactory -ResourceGroupName $RG -Name $DFname

# Find the Data Factory
$df= Get-AzureRmDataFactory -ResourceGroupName $RG -Name $DFname
if ($df -eq $null) { Write-Host "Data Factory " $DFname " cannot be found. Check spelling and resource group name. Error: " $_ -BackgroundColor:Red }

$setime = Get-AzureRmDataFactoryActivityWindow -DataFactoryName $DFname -ResourceGroupName $RG -RunStart $runStartDateTimeUTC | SELECT PipelineName, ActivityName,WindowStart,WindowEnd,ActivityType,WindowState, PercentComplete `
| ? {$PSItem.WindowState -eq 'Failed'} 

$sdt = $setime.WindowStart | Get-Unique
#write-host($sdt)
#$sdt.GetType()
$edt = $setime.WindowEnd | Get-Unique


#$sdt =(Get-Date).AddDays(-1)
#$sdt.GetType()

#$edt = Get-Date

#write-host $sdt $edt




# List all DataSets in the data factory - Add the LIKE filter by name instead of * if needed such as *output*
$DataSets = Get-AzureRmDataFactoryDataset -DataFactory $df | Where {$_.DatasetName -like "*"}  #| Sort-Object DatasetName

# Loop over matching named DataSets
$i = 1
ForEach($DS in $DataSets)
{
Write-Host $DS.DataFactoryName "--> " $DS.DatasetName -ForegroundColor:Yellow 

# List slices
#$Slices = Get-AzureRmDataFactorySlice -DataFactory $df -DatasetName $DS.DatasetName -StartDateTime 2019-03-20T10:00:00.0000000 -EndDateTime 2019-03-21T11:00:00.0000000

$Slices = Get-AzureRmDataFactorySlice -DataFactory $df -DatasetName $DS.DatasetName -StartDateTime $sdt -EndDateTime $edt



#write-host($Slices)

# Reset all slices to status Waiting for the given dataset, in case there are multiple
ForEach($S in $Slices) 
{
write-host "my output" $S
$outcome=$false
#Write-Host $i ":" $DS.DataFactoryName "--> " $DS.DatasetName "--> Slice Start:["$S.Start"] End:["$S.End"] State:"$S.State $S.SubState -ForegroundColor:Cyan


#Get-AzureRmDataFactoryActivityWindow  -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -RunStart $runStartDateTimeUTC | ? {$PSItem.WindowState -eq 'Failed'

Try {
$outcome=Set-AzureRmDataFactorySliceStatus -DataFactory $df -DatasetName $DS.DatasetName -Status Waiting -StartDateTime $sdt -EndDateTime $edt

#Write-Host $i ":" $DS.DataFactoryName "--> " $DS.DatasetName "--> Slice Start:["$S.Start"] End:["$S.End"] State:"$S.State $S.SubState -ForegroundColor:Cyan

Write-Host " Slice status reset to Waiting so it will run again:" $outcome -ForegroundColor:Green

}
Catch
{
Write-Host " Slice status reset has failed. Error: " $_ -ForegroundColor:Red
}
$i++
}
}




