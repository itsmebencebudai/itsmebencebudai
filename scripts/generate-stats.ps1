Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$profilePath = Join-Path $root 'data/profile.json'
$assetsPath = Join-Path $root 'assets'
$profile = Get-Content -Raw -Path $profilePath | ConvertFrom-Json
$username = [string]$profile.username

$headers = @{
    Accept = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
}

if ($env:GITHUB_TOKEN) {
    $headers.Authorization = "Bearer $($env:GITHUB_TOKEN)"
}

$user = Invoke-RestMethod -Uri "https://api.github.com/users/$username" -Headers $headers
$repos = @(Invoke-RestMethod -Uri "https://api.github.com/users/$username/repos?per_page=100&type=owner&sort=updated" -Headers $headers)

$totalStars = 0
$totalForks = 0

foreach ($repo in $repos) {
    if ($null -ne $repo.stargazers_count) { $totalStars += [int]$repo.stargazers_count }
    if ($null -ne $repo.forks_count) { $totalForks += [int]$repo.forks_count }
}

function New-StatsSvg {
    param([Parameter(Mandatory)] [ValidateSet('dark','light')] [string]$Theme)

    if ($Theme -eq 'dark') {
        $bg = '#0e1623'; $panel = '#141f2e'; $border = '#2b3b50'
        $title = '#f0f5fb'; $label = '#7f91a7'; $number = '#83b6ff'; $accent = '#9b8cff'
    }
    else {
        $bg = '#f3f7fc'; $panel = '#ffffff'; $border = '#d4deea'
        $title = '#1c2939'; $label = '#718197'; $number = '#2f78c8'; $accent = '#6657d8'
    }

    return @"
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="190" viewBox="0 0 1200 190" role="img" aria-labelledby="title desc">
<title id="title">GitHub overview for $username</title>
<desc id="desc">Public repository, follower, star, and fork counts for $username.</desc>
<rect width="1200" height="190" rx="20" fill="$bg"/>
<rect x="24" y="20" width="1152" height="150" rx="16" fill="$panel" stroke="$border"/>
<g font-family="Segoe UI,Arial,sans-serif">
  <text x="54" y="55" font-size="13" font-weight="700" fill="$title" letter-spacing="1.8">GITHUB OVERVIEW</text>
  <text x="54" y="78" font-size="11" fill="$label">Automatically refreshed from public GitHub data</text>
  <text x="82" y="127" font-size="31" font-weight="740" fill="$number">$($user.public_repos)</text>
  <text x="82" y="150" font-size="11" fill="$label" letter-spacing="1.1">PUBLIC REPOS</text>
  <text x="352" y="127" font-size="31" font-weight="740" fill="$number">$($user.followers)</text>
  <text x="352" y="150" font-size="11" fill="$label" letter-spacing="1.1">FOLLOWERS</text>
  <text x="622" y="127" font-size="31" font-weight="740" fill="$accent">$totalStars</text>
  <text x="622" y="150" font-size="11" fill="$label" letter-spacing="1.1">PUBLIC STARS</text>
  <text x="892" y="127" font-size="31" font-weight="740" fill="$accent">$totalForks</text>
  <text x="892" y="150" font-size="11" fill="$label" letter-spacing="1.1">PUBLIC FORKS</text>
</g>
</svg>
"@
}

New-Item -ItemType Directory -Path $assetsPath -Force | Out-Null
Set-Content -Path (Join-Path $assetsPath 'live-stats-dark.svg') -Value (New-StatsSvg -Theme dark) -Encoding utf8NoBOM
Set-Content -Path (Join-Path $assetsPath 'live-stats-light.svg') -Value (New-StatsSvg -Theme light) -Encoding utf8NoBOM

Write-Host "Generated live GitHub stats for $username."
