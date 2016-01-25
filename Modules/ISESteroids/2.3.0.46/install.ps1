﻿Write-Host -Object 'Installing ISESteroids'

$version = $PSVersionTable.PSVersion.Major

if ($version -lt 3)
{
  Write-Warning 'ISESteroids requires PowerShell 3 or better.'
  Write-Warning "Your current PowerShell version is $version."
  return
}

$isepath = Join-Path -Path $pshome -ChildPath 'powershell_ise.exe'
$iseExists = Test-Path -Path $isepath

if (!$iseExists)
{
  Write-Warning 'The built-in PowerShell ISE editor is not available on your system.'
  Write-Warning 'You may have to enable it in Windows Features first.'
}


$currentFolder = $PSScriptRoot

# running as script?
if ($currentFolder -eq '')
{
  Write-Warning -Message 'You need to run this code as a script. Make sure you opened the script from inside the unpacked ISESteroids ZIP folder!'
  return
}

# is in extracted zip folder?
$binaryExists = Test-Path -Path "$currentFolder\isesteroids.dll"
if (!$binaryExists)
{
  Write-Warning -Message 'Do not copy this script elsewhere! Run it from inside the extracted ZIP folder!'
  return
}

# unblock content of extracted zip folder
Get-ChildItem -Path $currentFolder -Recurse | Unblock-File

# copy module to user profile
$PSUserProfile = Split-Path $profile
$ModulesFolder = Join-Path -Path $PSUserProfile -ChildPath 'Modules'
$DestinationFolder = Join-Path -Path $ModulesFolder -ChildPath 'ISESteroids'

# create folder if not present
$exists = Test-Path -Path $DestinationFolder
if (!$exists)
{
  $null = New-Item -Path $DestinationFolder -Force -ItemType Directory
}

# current and destination folder identical?
if ($currentFolder -eq $DestinationFolder)
{
  Write-Host 'ISESteroids is installed already.' -ForegroundColor DarkYellow
  Write-Host 'Run "Start-Steroids" from inside the ISE editor to load ISESteroids.' -ForegroundColor DarkYellow
  return
}

Copy-Item -Path $currentFolder\* -Destination $DestinationFolder -Recurse -Force -ErrorVariable copyErrors -ErrorAction SilentlyContinue

if ($copyErrors.Count -gt 0)
{
  Write-Host 'There was a problem copying the module files onto your computer:' -ForegroundColor Yellow
  $copyErrors | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }
  Write-Host 'Make sure you are not running another version of ISESteroids while installing.' -ForegroundColor Yellow
  Write-Host 'Run this script again once you solved the issue.'
}
else
{
  Write-Host -Object 'ISESteroids successfully installed.' -ForegroundColor Green
  Write-Host -Object 'To run, launch ISE editor:' -ForegroundColor Green
  Write-Host -Object ''
  Write-Host -Object 'ise'
  Write-Host -Object ''
  Write-Host -Object 'From inside the ISE editor, run:' -ForegroundColor Green
  Write-Host -Object ''
  Write-Host -Object 'Start-Steroids'
  Write-Host -Object ''
  Write-Host -Object ''
  Write-Host -Object 'Run "Start-Steroids" from INSIDE THE ISE EDITOR, not from here!' -ForegroundColor Green
  Write-Host -Object ''
  Write-Host -Object ''

 
}


# SIG # Begin signature block
# MIIccwYJKoZIhvcNAQcCoIIcZDCCHGACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUqMZStpFuitU9VzE2OMADzZ0m
# 0A6ggheiMIIFKzCCBBOgAwIBAgIQDAyWMuxo4McpK2ZsZduuOjANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE1MDYwNTAwMDAwMFoXDTE2MDYw
# ODEyMDAwMFowcjELMAkGA1UEBhMCREUxFjAUBgNVBAgTDU5pZWRlcnNhY2hzZW4x
# ETAPBgNVBAcTCEhhbm5vdmVyMRswGQYDVQQKExJUb2JpYXMgRHIuIFdlbHRuZXIx
# GzAZBgNVBAMTElRvYmlhcyBEci4gV2VsdG5lcjCCASIwDQYJKoZIhvcNAQEBBQAD
# ggEPADCCAQoCggEBALabCRA1BSY9Fo7B/2TEJ3E0bcJYa7vcOWPckJQrRw5j3P+0
# XXqgKF/7E03vnLsD6auAWJuo4o2BHqgqOHIDeLlC+tcTMezF/pbWDbANVAJY3aSG
# 6rzwU4kTx6uLbR6boBwPIR2kWDCjbdHh6S5Zv81iT23yrR6qSNPVRrRsMqKGcCaW
# VxKA0cU6f6L3EBaRHVx7ewevup9FN+dATh6uOUpb3OgGv72lZ8+G78DvM6aA6Luh
# K2YRpbB3nYMWSA92KrSkaN52vUV3AxK/ufD/bnoRfiqr8rnuv+beaR21SkmReSaA
# DoCckTT1eBgItVhpnZAXW1qTKI3eFSYBIr61OrMCAwEAAaOCAbswggG3MB8GA1Ud
# IwQYMBaAFFrEuXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBSbHoFAoQ4cCasB
# 2bRzH2S1CR7jyDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMw
# dwYDVR0fBHAwbjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTIt
# YXNzdXJlZC1jcy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNv
# bS9zaGEyLWFzc3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMB
# MCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQG
# CCsGAQUFBwEBBHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQu
# Y29tME4GCCsGAQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGln
# aUNlcnRTSEEyQXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIw
# ADANBgkqhkiG9w0BAQsFAAOCAQEASaIGYvcGlRc4Wse6pymPbU98W3ohT4zCSsja
# 2VzagbT4xMhHzNlRGzZAD2GwEePHq1uVU3pC3qa80qCfCXEWju5cjc/nZNuv4T0J
# PYypm+xQRgRebJ4PSdyyHHhKm+iz4womMnstxk641EcYt1GnuscwamUlf9LlatlL
# VM7KScvemzQjIoiVm+JELdEVrtknAEJQYjlHePcff0YZbPW4H+mJ7qRErJCSSvQs
# oSjl0vtMhlcSoqYIrOYe5ft8ArHQC6/m9KRPRt9Npy2yFH/XAVE/zkfGeij+eKCw
# zqrfUnA1VnOCIthZ9ipmT0ZAUiiaAjKCS027UmS9DWNtupDgyDCCBTAwggQYoAMC
# AQICEAQJGBtf1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMC
# VVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0
# LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEz
# MTAyMjEyMDAwMFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8G
# A1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCC
# ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP
# 0PtFmbE620T1f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6
# funRZ9PG+yknx9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQt
# oaPpiCwgla4cSocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ry
# CuRXu0q16XTmK/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKW
# wfIPEvTFjg/BougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9EC
# AwEAAaOCAc0wggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGG
# MBMGA1UdJQQMMAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcw
# AYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8v
# Y2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0
# MIGBBgNVHR8EejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGln
# aUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYw
# OAYKYIZIAYb9bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2Vy
# dC5jb20vQ1BTMAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32
# ZXUOWDAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0B
# AQsFAAOCAQEAPuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v9
# 7yrfIFU3sOH20ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZO
# XP+QsRsHDpEV+7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+b
# p1wgXNlxsQyPu6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd
# 6fp0ZGuy62ZD2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92Ju
# oVP6EpQYhS6SkepobEQysmah5xikmmRR7zCCBmowggVSoAMCAQICEAMBmgI6/1ix
# a9bV6uYX8GYwDQYJKoZIhvcNAQEFBQAwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoT
# DERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UE
# AxMYRGlnaUNlcnQgQXNzdXJlZCBJRCBDQS0xMB4XDTE0MTAyMjAwMDAwMFoXDTI0
# MTAyMjAwMDAwMFowRzELMAkGA1UEBhMCVVMxETAPBgNVBAoTCERpZ2lDZXJ0MSUw
# IwYDVQQDExxEaWdpQ2VydCBUaW1lc3RhbXAgUmVzcG9uZGVyMIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAo2Rd/Hyz4II14OD2xirmSXU7zG7gU6mfH2RZ
# 5nxrf2uMnVX4kuOe1VpjWwJJUNmDzm9m7t3LhelfpfnUh3SIRDsZyeX1kZ/GFDms
# JOqoSyyRicxeKPRktlC39RKzc5YKZ6O+YZ+u8/0SeHUOplsU/UUjjoZEVX0YhgWM
# VYd5SEb3yg6Np95OX+Koti1ZAmGIYXIYaLm4fO7m5zQvMXeBMB+7NgGN7yfj95rw
# TDFkjePr+hmHqH7P7IwMNlt6wXq4eMfJBi5GEMiN6ARg27xzdPpO2P6qQPGyznBG
# g+naQKFZOtkVCVeZVjCT88lhzNAIzGvsYkKRrALA76TwiRGPdwIDAQABo4IDNTCC
# AzEwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYI
# KwYBBQUHAwgwggG/BgNVHSAEggG2MIIBsjCCAaEGCWCGSAGG/WwHATCCAZIwKAYI
# KwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwggFkBggrBgEF
# BQcCAjCCAVYeggFSAEEAbgB5ACAAdQBzAGUAIABvAGYAIAB0AGgAaQBzACAAQwBl
# AHIAdABpAGYAaQBjAGEAdABlACAAYwBvAG4AcwB0AGkAdAB1AHQAZQBzACAAYQBj
# AGMAZQBwAHQAYQBuAGMAZQAgAG8AZgAgAHQAaABlACAARABpAGcAaQBDAGUAcgB0
# ACAAQwBQAC8AQwBQAFMAIABhAG4AZAAgAHQAaABlACAAUgBlAGwAeQBpAG4AZwAg
# AFAAYQByAHQAeQAgAEEAZwByAGUAZQBtAGUAbgB0ACAAdwBoAGkAYwBoACAAbABp
# AG0AaQB0ACAAbABpAGEAYgBpAGwAaQB0AHkAIABhAG4AZAAgAGEAcgBlACAAaQBu
# AGMAbwByAHAAbwByAGEAdABlAGQAIABoAGUAcgBlAGkAbgAgAGIAeQAgAHIAZQBm
# AGUAcgBlAG4AYwBlAC4wCwYJYIZIAYb9bAMVMB8GA1UdIwQYMBaAFBUAEisTmLKZ
# B+0e36K+Vw0rZwLNMB0GA1UdDgQWBBRhWk0ktkkynUoqeRqDS/QeicHKfTB9BgNV
# HR8EdjB0MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRB
# c3N1cmVkSURDQS0xLmNybDA4oDagNIYyaHR0cDovL2NybDQuZGlnaWNlcnQuY29t
# L0RpZ2lDZXJ0QXNzdXJlZElEQ0EtMS5jcmwwdwYIKwYBBQUHAQEEazBpMCQGCCsG
# AQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQQYIKwYBBQUHMAKGNWh0
# dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRENBLTEu
# Y3J0MA0GCSqGSIb3DQEBBQUAA4IBAQCdJX4bM02yJoFcm4bOIyAPgIfliP//sdRq
# LDHtOhcZcRfNqRu8WhY5AJ3jbITkWkD73gYBjDf6m7GdJH7+IKRXrVu3mrBgJupp
# VyFdNC8fcbCDlBkFazWQEKB7l8f2P+fiEUGmvWLZ8Cc9OB0obzpSCfDscGLTYkuw
# 4HOmksDTjjHYL+NtFxMG7uQDthSr849Dp3GdId0UyhVdkkHa+Q+B0Zl0DSbEDn8b
# tfWg8cZ3BigV6diT5VUW8LsKqxzbXEgnZsijiwoc5ZXarsQuWaBh3drzbaJh6YoL
# bewSGL33VVRAA5Ira8JRwgpIr7DUbuD0FAo6G+OPPcqvao173NhEMIIGzTCCBbWg
# AwIBAgIQBv35A5YDreoACus/J7u6GzANBgkqhkiG9w0BAQUFADBlMQswCQYDVQQG
# EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNl
# cnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcN
# MDYxMTEwMDAwMDAwWhcNMjExMTEwMDAwMDAwWjBiMQswCQYDVQQGEwJVUzEVMBMG
# A1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEw
# HwYDVQQDExhEaWdpQ2VydCBBc3N1cmVkIElEIENBLTEwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQDogi2Z+crCQpWlgHNAcNKeVlRcqcTSQQaPyTP8TUWR
# XIGf7Syc+BZZ3561JBXCmLm0d0ncicQK2q/LXmvtrbBxMevPOkAMRk2T7It6NggD
# qww0/hhJgv7HxzFIgHweog+SDlDJxofrNj/YMMP/pvf7os1vcyP+rFYFkPAyIRaJ
# xnCI+QWXfaPHQ90C6Ds97bFBo+0/vtuVSMTuHrPyvAwrmdDGXRJCgeGDboJzPyZL
# FJCuWWYKxI2+0s4Grq2Eb0iEm09AufFM8q+Y+/bOQF1c9qjxL6/siSLyaxhlscFz
# rdfx2M8eCnRcQrhofrfVdwonVnwPYqQ/MhRglf0HBKIJAgMBAAGjggN6MIIDdjAO
# BgNVHQ8BAf8EBAMCAYYwOwYDVR0lBDQwMgYIKwYBBQUHAwEGCCsGAQUFBwMCBggr
# BgEFBQcDAwYIKwYBBQUHAwQGCCsGAQUFBwMIMIIB0gYDVR0gBIIByTCCAcUwggG0
# BgpghkgBhv1sAAEEMIIBpDA6BggrBgEFBQcCARYuaHR0cDovL3d3dy5kaWdpY2Vy
# dC5jb20vc3NsLWNwcy1yZXBvc2l0b3J5Lmh0bTCCAWQGCCsGAQUFBwICMIIBVh6C
# AVIAQQBuAHkAIAB1AHMAZQAgAG8AZgAgAHQAaABpAHMAIABDAGUAcgB0AGkAZgBp
# AGMAYQB0AGUAIABjAG8AbgBzAHQAaQB0AHUAdABlAHMAIABhAGMAYwBlAHAAdABh
# AG4AYwBlACAAbwBmACAAdABoAGUAIABEAGkAZwBpAEMAZQByAHQAIABDAFAALwBD
# AFAAUwAgAGEAbgBkACAAdABoAGUAIABSAGUAbAB5AGkAbgBnACAAUABhAHIAdAB5
# ACAAQQBnAHIAZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgAIABsAGkAbQBpAHQAIABs
# AGkAYQBiAGkAbABpAHQAeQAgAGEAbgBkACAAYQByAGUAIABpAG4AYwBvAHIAcABv
# AHIAYQB0AGUAZAAgAGgAZQByAGUAaQBuACAAYgB5ACAAcgBlAGYAZQByAGUAbgBj
# AGUALjALBglghkgBhv1sAxUwEgYDVR0TAQH/BAgwBgEB/wIBADB5BggrBgEFBQcB
# AQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggr
# BgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNz
# dXJlZElEUm9vdENBLmNydDCBgQYDVR0fBHoweDA6oDigNoY0aHR0cDovL2NybDMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDA6oDigNoY0
# aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENB
# LmNybDAdBgNVHQ4EFgQUFQASKxOYspkH7R7for5XDStnAs0wHwYDVR0jBBgwFoAU
# Reuir/SSy4IxLVGLp6chnfNtyA8wDQYJKoZIhvcNAQEFBQADggEBAEZQPsm3KCSn
# OB22WymvUs9S6TFHq1Zce9UNC0Gz7+x1H3Q48rJcYaKclcNQ5IK5I9G6OoZyrTh4
# rHVdFxc0ckeFlFbR67s2hHfMJKXzBBlVqefj56tizfuLLZDCwNK1lL1eT7EF0g49
# GqkUW6aGMWKoqDPkmzmnxPXOHXh2lCVz5Cqrz5x2S+1fwksW5EtwTACJHvzFebxM
# Elf+X+EevAJdqP77BzhPDcZdkbkPZ0XN1oPt55INjbFpjE/7WeAjD9KqrgB87pxC
# Ds+R1ye3Fu4Pw718CqDuLAhVhSK46xgaTfwqIa1JMYNHlXdx3LEbS0scEJx3FMGd
# Ty9alQgpECYxggQ7MIIENwIBATCBhjByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMM
# RGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQD
# EyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBAhAMDJYy
# 7GjgxykrZmxl2646MAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKACgACh
# AoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAM
# BgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBTGR1Xn66uc3Q4r1CzOFDp6f4GW
# hTANBgkqhkiG9w0BAQEFAASCAQBEsRAw4KXYkAMwt3UjQ6LEFs8YD1buHRoKBk4K
# wm2UDYorY/h/KBfoNE1V3roubLNWtKNd9grA58FRUHvt6prY6hBLnLwd5uDIm0WA
# WCUfDV3nrnd3SYotU+GzsgRA3YfI2xpAM9Du4UiA9pJl8sXhv7F7n6Lt4pa2nBYH
# LB6DeRByIoeeF94HicYEJXegdEKqvoWDkUUh0czfT6fLIA/5qGkp9dUviIu+7WpW
# mvr3DN2mdOA5eHPE3TCX/vTfafn3n/+MnbArt845SPKaQ2nMpQME336dhltgT5Yi
# 2yJV7FcMvo/zp8Vy5UsH1ul257v+OlkQ0wVTEaRugPpWnVIzoYICDzCCAgsGCSqG
# SIb3DQEJBjGCAfwwggH4AgEBMHYwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERp
# Z2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMY
# RGlnaUNlcnQgQXNzdXJlZCBJRCBDQS0xAhADAZoCOv9YsWvW1ermF/BmMAkGBSsO
# AwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEP
# Fw0xNTA4MjQwODM5MzhaMCMGCSqGSIb3DQEJBDEWBBTxkHhSVfRk3NFs+UBK871P
# mDKcqzANBgkqhkiG9w0BAQEFAASCAQBMEhAk6h30lRiPZhJWXrqQ2foQ5lsJqbIU
# laQ2k6WBxsz9+6R56m5jQsw5dOOr4SbIfq7w4PQsE+yYKgAi+3gaobMqFXoTUOkV
# x1V7+OxRKYSruht+Sz7el/tNnuQCP/q+QMmQCrFBhMdPxE/9G5ocz54poIrlAVPE
# dt1edDJX5GPm7wT0nBNtBafo0hs3y/D731X9BsZnJJTu8wj1zjafEhYYewF5JnoL
# lgIr5Td4kbf1RZA1LHBD6iFDS/3GI4dPQdNt0OONHWVqQcKOYwE9J1QSPcBK5pbo
# bfUUzWNXaxJ4xo9ORzC1D9qZewuD32/Tzae9+hNWO7QtZNKP46JA
# SIG # End signature block
