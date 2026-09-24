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
    if ($null -ne $repo.stargazers_count) {
        $totalStars += [int]$repo.stargazers_count
    }

    if ($null -ne $repo.forks_count) {
        $totalForks += [int]$repo.forks_count
    }
}

function New-StatsSvg {
    param(
        [Parameter(Mandatory)] [ValidateSet('dark','light')] [string]$Theme
    )

    if ($Theme -eq 'dark') {
        $bg1 = '#0b1018'; $bg2 = '#131927'; $border = '#2b3548'
        $title = '#f2f5fa'; $label = '#7f8da5'; $number = '#9db7ff'; $accent = '#a78bfa'
    }
    else {
        $bg1 = '#f8fbff'; $bg2 = '#f5f2ff'; $border = '#cad5e6'
        $title = '#172033'; $label = '#69768b'; $number = '#356fe3'; $accent = '#7650c7'
    }

    return @"
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="220" viewBox="0 0 1200 220" role="img" aria-labelledby="title desc">
<title id="title">Live GitHub snapshot for $username</title>
<desc id="desc">Public repository, follower, star, and fork counts for $username.</desc>
<defs>
  <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop stop-color="$bg1"/><stop offset="1" stop-color="$bg2"/></linearGradient>
</defs>
<rect width="1200" height="220" rx="24" fill="url(#bg)"/>
<rect x="34" y="30" width="1132" height="160" rx="16" fill="none" stroke="$border"/>
<g font-family="ui-monospace,SFMono-Regular,Menlo,Consolas,monospace">
  <text x="64" y="66" font-size="13" fill="$label" letter-spacing="2">LIVE GITHUB SNAPSHOT // $username</text>

  <text x="92" y="125" font-size="32" font-weight="700" fill="$number">$($user.public_repos)</text>
  <text x="92" y="151" font-size="13" fill="$label">PUBLIC REPOS</text>

  <text x="363" y="125" font-size="32" font-weight="700" fill="$number">$($user.followers)</text>
  <text x="363" y="151" font-size="13" fill="$label">FOLLOWERS</text>

  <text x="636" y="125" font-size="32" font-weight="700" fill="$accent">$totalStars</text>
  <text x="636" y="151" font-size="13" fill="$label">PUBLIC STARS</text>

  <text x="905" y="125" font-size="32" font-weight="700" fill="$accent">$totalForks</text>
  <text x="905" y="151" font-size="13" fill="$label">PUBLIC FORKS</text>
</g>
</svg>
"@
}

New-Item -ItemType Directory -Path $assetsPath -Force | Out-Null
Set-Content -Path (Join-Path $assetsPath 'live-stats-dark.svg') -Value (New-StatsSvg -Theme dark) -Encoding utf8NoBOM
Set-Content -Path (Join-Path $assetsPath 'live-stats-light.svg') -Value (New-StatsSvg -Theme light) -Encoding utf8NoBOM

Write-Host "Generated live GitHub stats for $username."
