$hostname = $env:COMPUTERNAME
$DNSname = $hostname + ".localhost"
$ExpDate = (get-date).AddYears(40)

$ReplicaIP = read-host 'Please enter Replica server IP Address'
$ReplicaDnsName = read-host 'Please enter Replica server DNS name'

$cert = New-SelfSignedCertificate -DnsName $DNSname -CertStoreLocation "Cert:\LocalMachine\My" -TestRoot -NotAfter $ExpDate
$thumb = $cert.Thumbprint

$CertforExport = (Get-ChildItem -Path "Cert:\LocalMachine\My\$thumb")

Add-Content C:\Windows\System32\drivers\etc\hosts -Value "$ReplicaIP $ReplicaDnsName"


Export-Certificate -Cert $CertforExport -FilePath c:\DNSName.cer -Type CERT # import this certificate in a replica server


$pass = ConvertTo-SecureString -String "1" -Force -AsPlainText

Export-pfxCertificate -Cert $CertforExport -FilePath c:\DNSName.pfx -Password $pass # import this certificate in this server


reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization\Replication" /v DisableCertRevocationCheck /d 1 /t REG_DWORD /f

