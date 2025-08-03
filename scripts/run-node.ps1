# Run Node.js Express Backend
Write-Host "🟢 Starting Node.js Express Backend..." -ForegroundColor Cyan
Write-Host "Port: 3001" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Cyan

# Check if we're in the right directory
if (-not (Test-Path "config.env")) {
    Write-Host "❌ Please run this script from the research-agent root directory" -ForegroundColor Red
    exit 1
}

# Check if backend directory exists
if (-not (Test-Path "backend/package.json")) {
    Write-Host "❌ Backend directory not found" -ForegroundColor Red
    exit 1
}

Set-Location "backend"

# Check if Node.js is available
try {
    node --version | Out-Null
} catch {
    Write-Host "❌ Node.js not found. Please install Node.js 16+" -ForegroundColor Red
    exit 1
}

# Check if dependencies are installed
if (-not (Test-Path "node_modules")) {
    Write-Host "⚠️ Dependencies not installed. Running npm install..." -ForegroundColor Yellow
    npm install
}

# Start the Node.js server
try {
    Write-Host "🚀 Starting server..." -ForegroundColor Green
    node node_server.js
} catch {
    Write-Host "❌ Failed to start Node.js server" -ForegroundColor Red
    Write-Host "Make sure dependencies are installed: npm install" -ForegroundColor Yellow
    exit 1
}
