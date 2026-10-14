param(
    [string]$BuildRoot = (Join-Path $env:TEMP 'network-frontend-map-build'),
    [switch]$OverviewOnly
)

$ErrorActionPreference = 'Stop'
$minimumProcessingFreeBytes = 35GB
$maxZoom = if ($OverviewOnly) { 8 } else { 15 }

New-Item -ItemType Directory -Force -Path $BuildRoot | Out-Null
$resolvedBuildRoot = (Resolve-Path $BuildRoot).Path
$driveName = [System.IO.Path]::GetPathRoot($resolvedBuildRoot).Substring(0, 1)

$java = Get-Command java -ErrorAction SilentlyContinue
if (-not $java) {
    $localJava = Get-ChildItem (Join-Path $resolvedBuildRoot 'tools\jdk') `
        -Filter java.exe -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending |
        Select-Object -First 1
    if ($localJava) {
        $java = $localJava
    }
}
if (-not $java) {
    throw "Java 21 or newer was not found in PATH or under $(Join-Path $resolvedBuildRoot 'tools\jdk')."
}

$javaPath = if ($java.Source) { $java.Source } else { $java.FullName }
$javaHome = Split-Path (Split-Path $javaPath -Parent) -Parent
$javaRelease = Get-Content (Join-Path $javaHome 'release') -Raw
if ($javaRelease -notmatch 'JAVA_VERSION="(\d+)') {
    throw 'Could not determine the installed Java version.'
}
if ([int]$Matches[1] -lt 21) {
    throw 'Offline map generation requires Java 21 or newer.'
}

$env:JAVA_HOME = $javaHome
$env:PATH = "$(Join-Path $javaHome 'bin');$env:PATH"

$maven = Get-Command mvn -ErrorAction SilentlyContinue
if (-not $maven) {
    $localMaven = Get-ChildItem (Join-Path $resolvedBuildRoot 'tools\maven') `
        -Filter mvn.cmd -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending |
        Select-Object -First 1
    if ($localMaven) {
        $maven = $localMaven
    }
}
if (-not $maven) {
    throw "Maven was not found in PATH or under $(Join-Path $resolvedBuildRoot 'tools\maven')."
}
$mavenPath = if ($maven.Source) { $maven.Source } else { $maven.FullName }

$git = Get-Command git -ErrorAction Stop
$builderRoot = Join-Path $resolvedBuildRoot 'basemaps'
if (-not (Test-Path (Join-Path $builderRoot '.git'))) {
    & $git.Source clone --depth 1 https://github.com/protomaps/basemaps.git $builderRoot
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not download the Protomaps basemap builder.'
    }
}

$tilesRoot = Join-Path $builderRoot 'tiles'
$jarPath = Join-Path $tilesRoot 'target\protomaps-basemap-HEAD-with-deps.jar'
$activeBuilder = Get-CimInstance Win32_Process -Filter "name = 'java.exe'" |
    Where-Object {
        $_.CommandLine -like '*protomaps-basemap-HEAD-with-deps.jar*'
    } |
    Select-Object -First 1
if ($activeBuilder) {
    throw "A map build is already running (Java process $($activeBuilder.ProcessId)). Let it finish before starting another build."
}

$sourcesRoot = Join-Path $tilesRoot 'data\sources'
New-Item -ItemType Directory -Force -Path $sourcesRoot | Out-Null
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$coveragePath = Join-Path $resolvedBuildRoot 'network-map-coverage.geojson'
if (-not $OverviewOnly) {
    $node = Get-Command node -ErrorAction Stop
    & $node.Source (Join-Path $PSScriptRoot 'create-map-coverage.mjs') $coveragePath
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not create the local 25 km coverage areas.'
    }
}

$qrankPath = Join-Path $sourcesRoot 'qrank.csv.gz'
if (-not (Test-Path $qrankPath)) {
    $stream = [System.IO.File]::Open(
        $qrankPath,
        [System.IO.FileMode]::CreateNew,
        [System.IO.FileAccess]::Write
    )
    try {
        $gzip = [System.IO.Compression.GZipStream]::new(
            $stream,
            [System.IO.Compression.CompressionMode]::Compress
        )
        try {
            $header = [System.Text.Encoding]::UTF8.GetBytes("Entity,QRank`n")
            $gzip.Write($header, 0, $header.Length)
        } finally {
            $gzip.Dispose()
        }
    } finally {
        $stream.Dispose()
    }
}

Push-Location $tilesRoot
try {
    if (-not (Test-Path $jarPath)) {
        & $mavenPath `
            "-Dmaven.repo.local=$(Join-Path $resolvedBuildRoot 'm2')" `
            -B -DskipTests package
        if ($LASTEXITCODE -ne 0) {
            throw 'Could not compile the Protomaps basemap builder.'
        }
    }

    if (-not (Test-Path $jarPath)) {
        throw 'The Protomaps basemap builder JAR was not produced.'
    }
    $jar = Get-Item $jarPath

    Write-Host 'Downloading any missing map sources; completed files in the build cache will be reused.'
    & $javaPath -Xmx4g -jar $jar.FullName `
        --download `
        --only-download `
        --area=russia `
        "--maxzoom=$maxZoom"
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not download the required map sources.'
    }

    $freeBytes = (Get-PSDrive -Name $driveName).Free
    if ($freeBytes -lt $minimumProcessingFreeBytes) {
        $freeGB = [math]::Round($freeBytes / 1GB, 2)
        throw "Map sources are downloaded, but tile generation needs at least 35 GB free on $driveName`:; only $freeGB GB is available. Free disk space and rerun the command."
    }

    Write-Host ('Starting tile generation with {0:N2} GB free.' -f ($freeBytes / 1GB))
    $tileArguments = @(
        '--force',
        '--area=russia',
        "--maxzoom=$maxZoom",
        '--free_osm_after_read=true',
        '--free_ne_after_read=true',
        '--free_osm_water_after_read=true',
        '--free_osm_land_after_read=true',
        '--free_landcover_after_read=true'
    )
    if (-not $OverviewOnly) {
        $tileArguments += "--clip=$coveragePath"
        $tileArguments += '--clip-buffer=0'
    }

    & $javaPath -Xmx4g -jar $jar.FullName @tileArguments
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not generate the clipped PMTiles archive.'
    }
} finally {
    Pop-Location
}

$archive = Join-Path $tilesRoot 'russia.pmtiles'
if (-not (Test-Path $archive) -or (Get-Item $archive).Length -eq 0) {
    throw 'The generated offline PMTiles archive is missing or empty.'
}

$archiveName = if ($OverviewOnly) { 'network-overview.pmtiles' } else { 'network-areas.pmtiles' }
$destination = Join-Path $projectRoot "public\maps\$archiveName"
$destination = [System.IO.Path]::GetFullPath($destination)
$stagingFile = "$destination.partial"
Copy-Item -Path $archive -Destination $stagingFile -Force
Move-Item -Path $stagingFile -Destination $destination -Force

Write-Host "Offline map archive ready: $destination"
Write-Host ('Archive size: {0:N2} GB' -f ((Get-Item $destination).Length / 1GB))
