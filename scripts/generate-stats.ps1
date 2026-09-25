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
        $outer = '#0b111a'; $panel = '#101923'; $top = '#162231'; $border = '#2d3b4c'
        $text = '#dce6f2'; $muted = '#7f93a9'; $blue = '#8fc9ff'; $yellow = '#eabb52'
    }
    else {
        $outer = '#eef4fa'; $panel = '#ffffff'; $top = '#f5f8fc'; $border = '#cdd8e4'
        $text = '#334155'; $muted = '#718399'; $blue = '#1765a5'; $yellow = '#d79a1f'
    }

    return @"
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="190" viewBox="0 0 1200 190" role="img" aria-labelledby="title desc">
<title id="title">Live GitHub snapshot for $username</title>
<desc id="desc">Public repository, follower, star, and fork counts for $username.</desc>
<rect width="1200" height="190" rx="20" fill="$outer"/>
<rect x="24" y="18" width="1152" height="154" rx="15" fill="$panel" stroke="$border"/>
<rect x="25" y="19" width="1150" height="38" rx="14" fill="$top"/>
<path d="M25 57H1175" stroke="$border"/>
<rect x="45" y="28" width="18" height="18" rx="4" fill="#1677c8"/>
<text x="54" y="41" text-anchor="middle" font-family="Consolas,monospace" font-size="7.5" font-weight="700" fill="#fff">PS</text>
<text x="76" y="42" font-family="Consolas,monospace" font-size="12" fill="$text">PS Dev:\&gt; Get-GitHubSnapshot</text>
<g font-family="Consolas,ui-monospace,monospace">
  <text x="82" y="103" font-size="28" font-weight="700" fill="$blue">$($user.public_repos)</text>
  <text x="82" y="130" font-size="11" fill="$muted" letter-spacing="1.2">PUBLIC REPOS</text>
  <text x="354" y="103" font-size="28" font-weight="700" fill="$blue">$($user.followers)</text>
  <text x="354" y="130" font-size="11" fill="$muted" letter-spacing="1.2">FOLLOWERS</text>
  <text x="626" y="103" font-size="28" font-weight="700" fill="$yellow">$totalStars</text>
  <text x="626" y="130" font-size="11" fill="$muted" letter-spacing="1.2">PUBLIC STARS</text>
  <text x="898" y="103" font-size="28" font-weight="700" fill="$yellow">$totalForks</text>
  <text x="898" y="130" font-size="11" fill="$muted" letter-spacing="1.2">PUBLIC FORKS</text>
</g>
</svg>
"@
}

New-Item -ItemType Directory -Path $assetsPath -Force | Out-Null
Set-Content -Path (Join-Path $assetsPath 'live-stats-dark.svg') -Value (New-StatsSvg -Theme dark) -Encoding utf8NoBOM
Set-Content -Path (Join-Path $assetsPath 'live-stats-light.svg') -Value (New-StatsSvg -Theme light) -Encoding utf8NoBOM

Write-Host "Generated live GitHub stats for $username."
