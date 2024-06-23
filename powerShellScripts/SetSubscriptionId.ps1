# param (
#     [string]$iac_env,
#     [string]$subscriptionIdDev,
#     [string]$subscriptionIdDrDev
# )

# # Set subscription ID based on environment
# switch ($iac_env) {
#   "Dev" { $subscriptionId = $subscriptionIdDev }
#   "dr_dev" { $subscriptionId = $subscriptionIdDrDev }
#   default {
#     Write-Host "Unknown environment: $iac_env"
#     exit 1
#   }
# }

# # Set the subscription ID as a pipeline variable
# Write-Host "##vso[task.setvariable variable=subscriptionId]$subscriptionId"
# # Print to screen for debugging
# Write-Host "subscriptionId: $subscriptionId"
