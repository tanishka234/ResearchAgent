# Run React Frontend
Write-Host "⚛️ Starting React Frontend..." -ForegroundColor Cyan
Write-Host "URL: http://localhost:3000" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Cyan

# Check if we're in the right directory
if (-not (Test-Path "config.env")) {
    Write-Host "❌ Please run this script from the research-agent root directory" -ForegroundColor Red
    exit 1
}

# Check if frontend directory exists
if (-not (Test-Path "frontend/package.json")) {
    Write-Host "❌ Frontend directory not found" -ForegroundColor Red
    exit 1
}

Set-Location "frontend"

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

# Start the React development server
try {
    Write-Host "🚀 Starting React development server..." -ForegroundColor Green
    Write-Host "The browser should open automatically at http://localhost:3000" -ForegroundColor Green
    npm start
} catch {
    Write-Host "❌ Failed to start React server" -ForegroundColor Red
    Write-Host "Make sure dependencies are installed: npm install" -ForegroundColor Yellow
    exit 1
}
