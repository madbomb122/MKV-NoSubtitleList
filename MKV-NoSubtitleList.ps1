#change This to path of the folder(s) you want searched
$SearchPath = 'M:\Movies'

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

$List = @(Get-ChildItem -Path "$SearchPath\*.mkv" -Recurse | Select-Object -ExpandProperty FullName)
Foreach($File in $List) {
	$tmp = Get-MKVTrackInfo $File
	If('subtitles' -NotIn $tmp.tracktype){ $File }
}

Read-Host 'Done'
