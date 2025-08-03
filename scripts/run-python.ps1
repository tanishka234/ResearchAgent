# Run Python Flask Backend
Write-Host "🐍 Starting Python Flask Backend..." -ForegroundColor Cyan
Write-Host "Port: 3000" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Cyan

# Check if we're in the right directory
if (-not (Test-Path "config.env")) {
    Write-Host "❌ Please run this script from the research-agent root directory" -ForegroundColor Red
    exit 1
}

# Check if requirements are installed
if (-not (Test-Path "backend/requirements.txt")) {
    Write-Host "❌ Backend directory not found" -ForegroundColor Red
    exit 1
}

Set-Location "backend"

# Check if python is available
try {
    python --version | Out-Null
} catch {
    Write-Host "❌ Python not found. Please install Python 3.8+" -ForegroundColor Red
    exit 1
}

# Start the Python server
try {
    Write-Host "🚀 Starting server..." -ForegroundColor Green
    python python_server.py
} catch {
    Write-Host "❌ Failed to start Python server" -ForegroundColor Red
    Write-Host "Make sure dependencies are installed: pip install -r requirements.txt" -ForegroundColor Yellow
    exit 1
}
