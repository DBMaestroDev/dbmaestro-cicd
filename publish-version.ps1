# PowerShell script to manage git tags with version parameter

param(
    [Parameter(Mandatory=$false)]
    [string]$VersionTag,
    
    [switch]$Force,
    [switch]$Help
)

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Show-Help {
    Write-Host ""
    Write-ColorOutput Cyan "publish-version.ps1 - Git Tag Management Script"
    Write-Host ""
    Write-ColorOutput Yellow "DESCRIPTION:"
    Write-Host "  Creates and manages version tags in a git repository."
    Write-Host "  This script creates a full version tag (e.g., v1.0.0) and a major"
    Write-Host "  version tag (e.g., v1) pointing to the same commit."
    Write-Host ""
    Write-ColorOutput Yellow "SYNTAX:"
    Write-Host "  ./publish-version.ps1 -VersionTag <string> [[-Force]] [[-Help]]"
    Write-Host ""
    Write-ColorOutput Yellow "PARAMETERS:"
    Write-Host "  -VersionTag <string>"
    Write-Host "    The version tag to create (required unless using -Help)"
    Write-Host "    Format: vX.Y or vX.Y.Z (e.g., v1.0, v1.5, v2.0.1)"
    Write-Host ""
    Write-Host "  -Force"
    Write-Host "    Skip confirmation prompt and execute immediately"
    Write-Host ""
    Write-Host "  -Help"
    Write-Host "    Display this help message and exit"
    Write-Host ""
    Write-ColorOutput Yellow "EXAMPLES:"
    Write-Host "  # Create version tag v1.0.0 with confirmation prompt:"
    Write-Host "  ./publish-version.ps1 -VersionTag v1.0.0"
    Write-Host ""
    Write-Host "  # Create version tag v2.5.1 without confirmation:"
    Write-Host "  ./publish-version.ps1 -VersionTag v2.5.1 -Force"
    Write-Host ""
    Write-Host "  # Display help:"
    Write-Host "  ./publish-version.ps1 -Help"
    Write-Host "  ./publish-version.ps1 -?"
    Write-Host ""
    Write-ColorOutput Yellow "WHAT THIS SCRIPT DOES:"
    Write-Host "  1. Creates a tag with the specified version (e.g., v1.0.0)"
    Write-Host "  2. Deletes the major version tag locally (e.g., v1)"
    Write-Host "  3. Recreates the major version tag pointing to the new version"
    Write-Host "  4. Pushes both tags to the remote repository"
    Write-Host "  5. Verifies both tags point to the same commit"
    Write-Host ""
}

# Show help if -Help flag is set or if no VersionTag is provided
if ($Help -or [string]::IsNullOrWhiteSpace($VersionTag)) {
    Show-Help
    exit 0
}

# Validate version tag format (should be like v1.0, v2.3, etc.)
if ($VersionTag -notmatch '^v\d+\.\d+(\.\d+)?$') {
    Write-ColorOutput Red "Error: Version tag must be in format 'vX.Y' or 'vX.Y.Z' (e.g., v1.0, v2.5, v1.0.0)"
    Write-Host ""
    Write-Host "Run './publish-version.ps1 -Help' for more information."
    exit 1
}

# Extract the major version from the version tag (e.g., v1.0 -> v1, v2.5.1 -> v2)
$MajorTag = $VersionTag -replace '\.\d+(\.\d+)?$', ''

Write-ColorOutput Cyan "Version tag: $VersionTag"
Write-ColorOutput Cyan "Major tag:   $MajorTag"

# Check if we're in a git repository
if (-not (Test-Path ".git")) {
    Write-ColorOutput Red "Error: Not in a git repository root directory!"
    exit 1
}

# Check if remote exists
$remoteExists = git remote 2>$null
if (-not $remoteExists) {
    Write-ColorOutput Yellow "Warning: No remote repository configured. Tags will only be created locally."
    $remoteAvailable = $false
} else {
    $remoteAvailable = $true
}

# Ask for confirmation unless -Force is used
if (-not $Force) {
    Write-ColorOutput Yellow "`nThis script will:"
    Write-ColorOutput Yellow "  - Create tag $VersionTag from current commit"
    Write-ColorOutput Yellow "  - Delete local and remote tag $MajorTag (if exists)"
    Write-ColorOutput Yellow "  - Recreate tag $MajorTag pointing to $VersionTag"
    if ($remoteAvailable) {
        Write-ColorOutput Yellow "  - Push both tags to remote"
    }
    
    $response = Read-Host "`nDo you want to continue? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-ColorOutput Red "Operation cancelled."
        exit 0
    }
}

# Create version tag from current commit
Write-ColorOutput Yellow "`nCreating tag $VersionTag..."
git tag $VersionTag
if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
    Write-ColorOutput Red "Failed to create tag $VersionTag"
    exit 1
}

# Delete major tag locally (if it exists)
if (git tag -l $MajorTag) {
    Write-ColorOutput Yellow "Deleting local tag $MajorTag..."
    git tag -d $MajorTag
}

# Delete major tag on remote (if it exists and remote is available)
if ($remoteAvailable) {
    $remoteTagExists = git ls-remote --tags origin $MajorTag 2>$null
    if ($remoteTagExists) {
        Write-ColorOutput Yellow "Deleting remote tag $MajorTag..."
        git push origin --delete $MajorTag 2>$null
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
            Write-ColorOutput Red "Failed to delete remote tag $MajorTag"
        }
    }
}

# Recreate major tag pointing to version tag
Write-ColorOutput Yellow "Creating tag $MajorTag from $VersionTag..."
git tag $MajorTag $VersionTag
if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
    Write-ColorOutput Red "Failed to create tag $MajorTag"
    exit 1
}

# Push tags to remote
if ($remoteAvailable) {
    Write-ColorOutput Yellow "Pushing tags to remote..."
    git push origin $VersionTag
    git push origin $MajorTag
}

# Verification
Write-ColorOutput Green "`n=== Verification ==="
$version_hash = git rev-parse $VersionTag 2>$null
$major_hash = git rev-parse $MajorTag 2>$null

Write-ColorOutput Cyan "$VersionTag commit: $version_hash"
Write-ColorOutput Cyan "$MajorTag commit:   $major_hash"

if ($version_hash -and $major_hash) {
    if ($version_hash -eq $major_hash) {
        Write-ColorOutput Green "SUCCESS: Both tags point to the same commit!"
    } else {
        Write-ColorOutput Red "ERROR: Tags point to different commits!"
    }
} else {
    Write-ColorOutput Red "ERROR: One or both tags not found!"
}

# Show all tags
Write-ColorOutput Green "`nCurrent tags (showing relevant versions):"
git tag -l "v*" | Sort-Object -Descending | ForEach-Object {
    $tag = $_
    $hash = git rev-parse --short $tag 2>$null
    if ($tag -eq $VersionTag -or $tag -eq $MajorTag) {
        Write-ColorOutput Green "  $tag -> $hash (updated)"
    } else {
        Write-ColorOutput Gray "  $tag -> $hash"
    }
}

Write-ColorOutput Green "`nTag operations completed successfully!"
