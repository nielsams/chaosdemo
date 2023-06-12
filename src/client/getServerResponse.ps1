
$url = "http://mydnsname.region.cloudapp.azure.com"

for() {
    Invoke-WebRequest -Uri $url | Select-Object -ExpandProperty Content
    Start-Sleep -Milliseconds 500
}
 