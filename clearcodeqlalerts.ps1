# First, replace :owner and :repo with your actual values
$owner = "DevTestPad"
$repo = "CodeQLSamples"

Write-Host "Fetching CodeQL alerts..."

try 
{
    # Get all alerts
    $alerts = gh api "repos/$owner/$repo/code-scanning/alerts" --method GET | ConvertFrom-Json
    
    if ($alerts.Count -eq 0) {
        Write-Host "No alerts found."
        exit
    }
    
    Write-Host "Found $($alerts.Count) alerts. Dismissing..."
    
    foreach ($alert in $alerts) {
        try {
            # Use proper dismissed_reason value with quotes
            gh api "repos/$owner/$repo/code-scanning/alerts/$($alert.number)" --method PATCH --field state=dismissed --field 'dismissed_reason=false positive'
            Write-Host "✓ Dismissed alert #$($alert.number): $($alert.rule.description)"
        }
        catch {
            Write-Host "✗ Failed to dismiss alert #$($alert.number): $($_.Exception.Message)"
        }
    }
    Write-Host "Done!"
}
catch {
    Write-Host "Error fetching alerts: $($_.Exception.Message)"
    Write-Host "Make sure you have the GitHub CLI installed and are authenticated:"
    Write-Host "  gh auth login"
}
