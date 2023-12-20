$ErrorActionPreference = "Stop"

$outfolder = "pack"
Remove-Item -Recurse $outfolder -ErrorAction Ignore
New-Item -ItemType Directory -Force -Path $outfolder | Out-Null
robocopy ./ pack/ /s /xd pack /xd .* /xf .gitignore /xf *.md /xf *.ps1 /xf *.gma /xf *license.txt /nfl /ndl
..\..\..\bin\gmad.exe create -folder $outfolder -out "packed.gma"