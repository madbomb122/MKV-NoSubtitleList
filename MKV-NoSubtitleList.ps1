#change This to path of the folder(s) you want searched
$SearchPath = 'M:'

#In the function change the path of mkvinfo
$MkvToolPath = 'D:\mkvtoolnix'

Function Get-MKVTrackInfo {
	[CmdletBinding()]
	Param ([Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)][Alias('FullName')] [string] $Path)
	
	Process {
		$info = & "$MkvToolPath\mkvinfo.exe" $Path  | Where-Object -FilterScript { ($_ -like '*Track number*') -or ($_ -like '*Track type*') }
		$info = $info | ForEach-Object -Process { $_.replace('|  + ','') }
		$info = $info | ForEach-Object -Process { $_.replace('(track ID for mkvmerge & mkvextract: ',':') } 
		$info = $info | ForEach-Object -Process { $_.replace(')','') }
		$info = $info | ForEach-Object -Process { $_.replace(': ',':') }
		$info = $info | ForEach-Object -Process { $_.replace(' :',':') }
		$info = $info | ForEach-Object -Process { $_.replace('Track number:','') }
		$info = $info | ForEach-Object -Process { $_.replace('Track type:','') }
		For ($index = 0;$index -lt $info.count;$index = $index + 2) {
			$tmpArray = $info[$index].Split(':')
			$hash = @{
				Track	 = $tmpArray[1]
				TrackType = $info[$index+1]
				Path	  = (Get-ChildItem -Path $Path).FullName
			}
			New-Object -TypeName PsObject -Property $hash
		}
	}
}
$Pathlen = $SearchPath.Length
If($SearchPath.Substring($Pathlen -1,1) -eq '\'){ $SearchPath = $SearchPath.Substring(0,$Pathlen -1) }
$Pathlen = $MkvToolPath.Length
If($MkvToolPath.Substring($Pathlen -1,1) -eq '\'){ $MkvToolPath = $MkvToolPath.Substring(0,$Pathlen -1) }
$Subdir1 = ''
$MissingSubArr = @()

Write-Host "Getting list of all MKVs in " -ForegroundColor 'Red' -BackgroundColor 'Black' -NoNewLine
Write-Host $SearchPath -ForegroundColor 'Green' -BackgroundColor 'Black'
		
$List = @(Get-ChildItem -Path "$SearchPath\*.mkv" -Recurse | Select-Object -ExpandProperty FullName)
Foreach($FilePath in $List) {
	$Subdir2 = Split-Path $FilePath
	If($Subdir1 -ne $Subdir2) {
		Write-Host "Checking MKVs in: " -ForegroundColor 'Red' -BackgroundColor 'Black' -NoNewLine
		Write-Host $Subdir2 -ForegroundColor 'Green' -BackgroundColor 'Black'
		$Subdir1 = $Subdir2
	}
	$tmp = Get-MKVTrackInfo $FilePath
	If('subtitles' -NotIn $tmp.tracktype){ $MissingSubArr += $FilePath }
}

Write-Host

If($MissingSubArr.Count -ne 0) {
	Write-Host "Files with no subtitles:" -ForegroundColor 'Red' -BackgroundColor 'Black' 
	$MissingSubArr
} Else {
	Write-Host "All MKVs in " -ForegroundColor 'Red' -BackgroundColor 'Black' -NoNewLine
	Write-Host $SearchPath -ForegroundColor 'Green' -BackgroundColor 'Black' -NoNewLine
	Write-Host " have subtitles" -ForegroundColor 'Red' -BackgroundColor 'Black'
}

Write-Host
Read-Host "Done, press 'Enter' to close"
