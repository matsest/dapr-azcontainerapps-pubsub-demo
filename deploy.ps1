$ErrorActionPreference = 'Stop'

$params = @{
    Name                     = "dapr-pubsub-$(Get-Date -Format "yyMMdd-HHmm")"
    Location                 = "canadacentral"
    TemplateFile             = "main.bicep"
    rgName                   = "dapr-pubsub-containerapps-demo"
    LocationFromTemplate     = "canadacentral"
    containerEnvironmentName = "dapr-pubsub-containerapps-env"
}

Write-Host "`nđ Deploying container apps...(this will take a few minutes)"
$deploy = New-AzSubscriptionDeployment @params

if ($deploy.ProvisioningState -ne "Succeeded"){
    Write-Host "$($deploy | Out-String)"
    Write-Error "Something went wrong in deploy. Please revise"
}

Write-Host "`nâď¸  Deploy succeeded! React Web App url:"
$uri = "https://$($deploy.Outputs.uri.Value)"
Write-Host $uri