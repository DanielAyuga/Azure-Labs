$secret = Get-AzKeyVaultSecret -VaultName "kv-security-lab" -Name "test-password"
$ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
$plain = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
Write-Host "El valor del secreto es: $plain"