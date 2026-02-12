# PowerShell Script: Prepare Local Files for Deployment
# Run this on your Windows computer before uploading to server

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SCCDMS Local File Preparation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Write-Host "Project Root: $ProjectRoot" -ForegroundColor Yellow
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "$ProjectRoot\index.php")) {
    Write-Host "ERROR: index.php not found. Please run this script from the SCCDMS2 directory." -ForegroundColor Red
    exit 1
}

# Create deployment directory
$DeployDir = "$ProjectRoot\deploy\files_to_upload"
if (Test-Path $DeployDir) {
    Write-Host "Cleaning old deployment directory..." -ForegroundColor Yellow
    Remove-Item -Path $DeployDir -Recurse -Force
}
New-Item -ItemType Directory -Path $DeployDir -Force | Out-Null

Write-Host "Step 1: Copying files..." -ForegroundColor Green

# Files and directories to include
$IncludeItems = @(
    "actions",
    "api",
    "assets",
    "auth",
    "components",
    "config",
    "cron",
    "database",
    "includes",
    "pages",
    "profiles",
    "scripts",
    "storage",
    "temp",
    "uploads",
    "vendor",
    "views",
    "websocket",
    ".htaccess",
    "composer.json",
    "index.php"
)

# Copy files
foreach ($item in $IncludeItems) {
    $sourcePath = Join-Path $ProjectRoot $item
    if (Test-Path $sourcePath) {
        Write-Host "  Copying: $item" -ForegroundColor Gray
        Copy-Item -Path $sourcePath -Destination $DeployDir -Recurse -Force
    } else {
        Write-Host "  Skipping (not found): $item" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Step 2: Removing development files..." -ForegroundColor Green

# Files and directories to exclude
$ExcludePatterns = @(
    "*.log",
    "*.bak",
    "*.original",
    "*_debug.php",
    "*_test.php",
    "test_*.php",
    "debug_*.php",
    "fix_*.php",
    "emergency_*.php",
    "direct_*.php",
    "simple_*.php",
    "temp_qrcodes",
    "php_errors.log"
)

foreach ($pattern in $ExcludePatterns) {
    Get-ChildItem -Path $DeployDir -Recurse -Filter $pattern -ErrorAction SilentlyContinue | Remove-Item -Force
}

Write-Host ""
Write-Host "Step 3: Creating .env template..." -ForegroundColor Green

# Create .env template
$envTemplate = @"
# Production Environment Configuration
# Update these values with your actual production credentials

# Database Configuration
DB_HOST=localhost
DB_USERNAME=sccdms_user
DB_PASSWORD=CHANGE_THIS_PASSWORD
DB_NAME=scc_dms

# Application Settings
APP_TIMEZONE=Asia/Manila

# API Keys (Optional - can be set later)
GEMINI_API_KEY=
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REDIRECT_URI=

# Security Settings
SESSION_LIFETIME=28800
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION=900

# File Upload Settings
MAX_FILE_SIZE=10485760
ALLOWED_FILE_TYPES=pdf,doc,docx,txt,rtf

# System Settings
DEBUG_MODE=false
LOG_LEVEL=error
"@

$envTemplate | Out-File -FilePath "$DeployDir\.env.example" -Encoding UTF8

Write-Host ""
Write-Host "Step 4: Creating deployment info file..." -ForegroundColor Green

$deployInfo = @"
SCCDMS Deployment Package
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Source: $ProjectRoot
"@

$deployInfo | Out-File -FilePath "$DeployDir\DEPLOYMENT_INFO.txt" -Encoding UTF8

Write-Host ""
Write-Host "Step 5: Verifying critical files..." -ForegroundColor Green

$criticalFiles = @(
    "index.php",
    "composer.json",
    "includes\config.php",
    "database\scc_dms.sql"
)

$allFound = $true
foreach ($file in $criticalFiles) {
    $filePath = Join-Path $DeployDir $file
    if (Test-Path $filePath) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file (MISSING!)" -ForegroundColor Red
        $allFound = $false
    }
}

Write-Host ""
if ($allFound) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Preparation Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Files ready for upload in:" -ForegroundColor Cyan
    Write-Host "$DeployDir" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Upload all files from '$DeployDir' to your server" -ForegroundColor White
    Write-Host "2. Copy .env.example to .env and update with your credentials" -ForegroundColor White
    Write-Host "3. Run the server setup script on your DigitalOcean droplet" -ForegroundColor White
} else {
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "WARNING: Some critical files are missing!" -ForegroundColor Red
    Write-Host "Please check the errors above." -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    exit 1
}

Write-Host ""

