# Hyper-V-Replica-certificate-for-Workgroup-scenario
```diff
+ Simple guide how to generate and pair self-signed certificate for the Hyper-V replication purposes in a Workgroup scenario
```

There is a time when you need to setup Hyper-V replica in a workgroup scenario. Assigning and pairing certificates is one of the key points. In order to do so, i attached simple script that will do the following : 

1. Create self-sign certificate with 40 Years validity period
```ps1
$hostname = $env:COMPUTERNAME 
$DNSname = $hostname + ".localhost" 
$ExpDate = (get-date).AddYears(40)
```

#### NOTE :  You will be doing this on both servers ( primary and secondary ). Ensure you have same time, otherwise paired certificate timestamps will not match
 
 
  
   
2. Edit your etc Host file with replica IP and name
```ps1
$ReplicaIP = read-host 'Please enter Replica server IP Address' 
$ReplicaDnsName = read-host 'Please enter Replica server DNS name' 
 
Add-Content C:\Windows\System32\drivers\etc\hosts -Value "$ReplicaIP $ReplicaDnsName"
```

3. Create Self sign certificate

```ps1
$cert = New-SelfSignedCertificate -DnsName $DNSname -CertStoreLocation "Cert:\LocalMachine\My" -TestRoot -NotAfter $ExpDate 
$thumb = $cert.Thumbprint 
 
$CertforExport = (Get-ChildItem -Path "Cert:\LocalMachine\My\$thumb")
```


4. Export 2 certificates - cer and pfx to the root of a c:\ directory

certificate c:\DNSName.cer - this is a certificate you will need to import to the Replica server
certificate c:\DNSName.pfx - this is a certificate for this server. See description in next steps

```ps1
Export-Certificate -Cert $CertforExport -FilePath c:\DNSName.cer -Type CERT # import this certificate in a replica server 
 
 
$pass = ConvertTo-SecureString -String "1" -Force -AsPlainText 
Export-pfxCertificate -Cert $CertforExport -FilePath c:\DNSName.pfx -Password $pass # import this certificate in this server
```


5. Edit registry so Hyper-V can use self-sign certificate

```cmd
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization\Replication" /v DisableCertRevocationCheck /d 1 /t REG_DWORD /f
```


### Next Steps
### PRIMARY Server

In order to make this work, you should modify PC name add the DNS suffix .localhost ( or any other ). Once you have ran the script, there are couple more steps you need to do manually in order to pair the certificates : 

 

1. Open up the mmc.exe

2. Select Certificates > add

3. Select Computer account in certificates snap-in

4. Open up the Personal > Certificates and locate certificate issued by CertReq Test Root

![ScreenShot](https://github.com/DKusnir/Hyper-V-Replica-certificate-for-Workgroup-scenario/blob/master/certificate.PNG)

5. You will see that the certificate is not yet trusted

6. That is why we generated 2 certificates -  trust is ensured by .pfx certificate

7. Select Trusted root certification authorities > Certificates > All Tasks > import ...

8. Import PFX certificate and make sure that Include all extended properties checkbox is checked during the wizard

9. You now have 2 new certificates in the Trusted root : 
 
  *  CertReq Test Root 
  *  Your DNSname certificate
 
10. You can safely delete DNSName certificate from the Trusted root certification authorities

11. Check the Personal > Certificate is now trusted

12. Open up the Hyper-V Manager > Hyper-V Settings > Replication Configuration and select the Certificate

13. Copy DNSName.cer to the replica server


### Replica (Secondary) Server

In a replica server, start by replicating all steps above. This will ensure you have propery setup certificate trust, imported self certificate and setup hyper-v. 

Once you replicated all the steps above, dont forget to import DNSName.cer that you copied over from the primary server. This certificate must be imported to the Personal store as well. 

1. Open up the mmc.exe

2. Select Certificates > add

3. Select Computer account in certificates snap-in

4. Open up the Personal > Certificates > Import

5. This certificate is now automatically trusted 
 
 
### Back to Primary Server

Last but not least is to import DNSName.cer from the Replica server to the primary server. 
And since you already make CertReq Test Root trusted publisher, both certificates from primary and secondary server will be trusted. 

#### Final notes

This is all that concern creating self-sign certificates for the Hyper-V replication. 
In order to make the replication work, you will need to open up relevant Firewall ports - including the once not requested by Hyper-V. 
However that is for another topic. 

Please also note Server 2012 may not recognize ps command new-selfsignedcertificate. 
In that case you can use any other Windows PC to generate certificate by manually adjusting the $DNSName. 









