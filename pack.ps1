$ErrorActionPreference = "Stop"

$outfolder = "pack"
Remove-Item -Recurse $outfolder -ErrorAction Ignore
New-Item -ItemType Directory -Force -Path $outfolder | Out-Null
robocopy ./ pack/ /s /xd pack /xd .* /xf .gitignore /xf README.md /xf *.ps1 /xf *.gma /nfl /ndl
..\..\..\bin\gmad.exe create -folder $outfolder -out "murder.gma"