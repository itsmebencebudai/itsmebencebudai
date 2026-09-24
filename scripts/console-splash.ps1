# Self-contained PowerShell startup art; the frame reveal needs no external modules.
[CmdletBinding()]
param(
    [switch]$NoAnimation
)

$ErrorActionPreference = 'Stop'

$script:Escape = [char]27
$script:CanColor = -not [Console]::IsOutputRedirected -and [string]::IsNullOrEmpty($env:NO_COLOR)
$script:CanAnimate = -not $NoAnimation -and -not [Console]::IsOutputRedirected

if ($script:CanColor) {
    $script:Reset = "$($script:Escape)[0m"
    $script:Bold = "$($script:Escape)[1m"
    $script:Mint = "$($script:Escape)[38;2;110;231;183m"
    $script:Blue = "$($script:Escape)[38;2;137;180;250m"
    $script:Gold = "$($script:Escape)[38;2;249;201;115m"
    $script:Bright = "$($script:Escape)[38;2;238;242;247m"
    $script:Muted = "$($script:Escape)[38;2;139;151;169m"
    $script:Border = "$($script:Escape)[38;2;63;78;99m"
}
else {
    $script:Reset = ''
    $script:Bold = ''
    $script:Mint = ''
    $script:Blue = ''
    $script:Gold = ''
    $script:Bright = ''
    $script:Muted = ''
    $script:Border = ''
}

$windowWidth = 100
try {
    if ([Console]::WindowWidth -gt 0) {
        $windowWidth = [Console]::WindowWidth
    }
}
catch {
    # Keep the default width when the current host does not expose a console size.
}

$script:BoxWidth = [Math]::Min(82, [Math]::Max(36, $windowWidth - 2))
$script:IsCompact = $script:BoxWidth -lt 66
$script:LeftWidth = if ($script:IsCompact) { 12 } else { 16 }
$script:RightWidth = $script:BoxWidth - $script:LeftWidth - 7
$script:RuleWidth = $script:BoxWidth - 2
$script:Rule = '─' * $script:RuleWidth

function Write-FrameRule {
    param(
        [Parameter(Mandatory)] [string]$Left,
        [Parameter(Mandatory)] [string]$Right
    )

    [Console]::WriteLine("$($script:Border)$Left$($script:Rule)$Right$($script:Reset)")
    if ($script:CanAnimate) {
        Start-Sleep -Milliseconds 20
    }
}

function Write-FrameRow {
    param(
        [AllowEmptyString()] [string]$LeftText = '',
        [AllowEmptyString()] [string]$RightText = '',
        [string]$LeftColor = $script:Muted,
        [string]$RightColor = $script:Bright,
        [switch]$Reveal,
        [switch]$TypeRight
    )

    if ($LeftText.Length -gt $script:LeftWidth) {
        $LeftText = $LeftText.Substring(0, $script:LeftWidth)
    }
    if ($RightText.Length -gt $script:RightWidth) {
        $RightText = $RightText.Substring(0, $script:RightWidth)
    }

    $leftColumn = $LeftText.PadRight($script:LeftWidth)
    $rowStart = "$($script:Border)│$($script:Reset) $LeftColor$leftColumn$($script:Reset) $($script:Border)│$($script:Reset) $RightColor"
    $rowEnd = " $($script:Border)│$($script:Reset)"

    if ($TypeRight -and $script:CanAnimate) {
        [Console]::Write($rowStart)
        foreach ($character in $RightText.ToCharArray()) {
            [Console]::Write($character)
            Start-Sleep -Milliseconds 13
        }
        [Console]::Write((' ' * ($script:RightWidth - $RightText.Length)))
        [Console]::WriteLine("$($script:Reset)$rowEnd")
    }
    else {
        $rightColumn = $RightText.PadRight($script:RightWidth)
        [Console]::WriteLine("$rowStart$rightColumn$($script:Reset)$rowEnd")
    }

    if ($Reveal -and -not $TypeRight -and $script:CanAnimate) {
        Start-Sleep -Milliseconds 25
    }
}

[Console]::WriteLine()
Write-FrameRule -Left '╭' -Right '╮'
Write-FrameRow -LeftText 'BB / DEV' -RightText 'POWERSHELL 7  /  SYSTEMS CONSOLE' -LeftColor $script:Mint -RightColor $script:Muted -Reveal
Write-FrameRule -Left '├' -Right '┤'

$logo = @(
    '████    ████',
    '█   █   █   █',
    '████    ████',
    '█   █   █   █',
    '████    ████'
)

$identity = @(
    @{ Text = 'BUDAI BENCE'; Color = $script:Bright },
    @{ Text = 'SOFTWARE DEVELOPER'; Color = $script:Blue },
    @{ Text = $(if ($script:IsCompact) { 'Backend · automation' } else { 'Backend · automation · infrastructure' }); Color = $script:Muted },
    @{ Text = 'Budapest · Hungary'; Color = $script:Muted },
    @{ Text = ''; Color = $script:Muted }
)

for ($index = 0; $index -lt $logo.Count; $index++) {
    $markColor = if ($index % 2 -eq 0) { $script:Mint } else { $script:Blue }
    if ($index -eq 0) {
        Write-FrameRow -LeftText $logo[$index] -RightText $identity[$index].Text -LeftColor $markColor -RightColor $identity[$index].Color -TypeRight
    }
    else {
        Write-FrameRow -LeftText $logo[$index] -RightText $identity[$index].Text -LeftColor $markColor -RightColor $identity[$index].Color -Reveal
    }
}

Write-FrameRule -Left '├' -Right '┤'
$backendLabel = if ($script:IsCompact) { '01 / API' } else { '01 / BACKEND' }
$automationLabel = if ($script:IsCompact) { '02 / AUTO' } else { '02 / AUTOMATE' }
$operationsLabel = if ($script:IsCompact) { '03 / HOST' } else { '03 / OPERATE' }
$backendStack = if ($script:IsCompact) { 'C# · .NET · APIs' } else { 'C# · .NET · ASP.NET Core · SQL Server' }
$automationStack = if ($script:IsCompact) { 'PowerShell · Actions' } else { 'PowerShell · GitHub Actions' }
$operationsStack = if ($script:IsCompact) { 'Windows · Docker · VPN' } else { 'Windows · Docker · Tailscale' }
$labStack = if ($script:IsCompact) { 'Self-host · local AI · MCP' } else { 'Self-hosting · local AI · MCP' }
Write-FrameRow -LeftText $backendLabel -RightText $backendStack -LeftColor $script:Blue -RightColor $script:Bright -Reveal
Write-FrameRow -LeftText $automationLabel -RightText $automationStack -LeftColor $script:Mint -RightColor $script:Bright -Reveal
Write-FrameRow -LeftText $operationsLabel -RightText $operationsStack -LeftColor $script:Gold -RightColor $script:Bright -Reveal
Write-FrameRow -LeftText 'IN THE LAB' -RightText $labStack -LeftColor $script:Blue -RightColor $script:Bright -Reveal
Write-FrameRule -Left '├' -Right '┤'
Write-FrameRow -LeftText 'READY' -RightText 'BUILD  →  AUTOMATE  →  IMPROVE' -LeftColor $script:Mint -RightColor $script:Gold -Reveal
Write-FrameRule -Left '╰' -Right '╯'
[Console]::WriteLine()
