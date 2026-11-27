$AccountId = aws sts get-caller-identity --profile learn --query Account --output text
$Bucket = "iac-lab-$AccountId"
New-Item -ItemType Directory -Force out | Out-Null

function Expand-Policy($Name) {
    $json = (Get-Content "policies/$Name" -Raw) -replace '<ACCOUNT_ID>', $AccountId -replace '<BUCKET>', $Bucket
    [IO.File]::WriteAllText("$PWD/out/$Name", $json)
    "file://out/$Name"
}

Write-Host "Account: $AccountId"
Write-Host "Bucket:  $Bucket"
