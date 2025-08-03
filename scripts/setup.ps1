# Watson ML Research Agent Setup Script
# This script will set up all the dependencies for the research agent

Write-Host "🔬 Setting up Watson ML Research Agent..." -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Check if we're in the right directory
if (-not (Test-Path "config.env")) {
    Write-Host "❌ Please run this script from the research-agent root directory" -ForegroundColor Red
    exit 1
}

# Check Python installation
Write-Host "🐍 Checking Python installation..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✅ Found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Python not found. Please install Python 3.8+ from https://python.org" -ForegroundColor Red
    exit 1
}

# Check Node.js installation
Write-Host "🟢 Checking Node.js installation..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>&1
    Write-Host "✅ Found Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js not found. Please install Node.js 16+ from https://nodejs.org" -ForegroundColor Red
    exit 1
}

# Check npm installation
try {
    $npmVersion = npm --version 2>&1
    Write-Host "✅ Found npm: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ npm not found. Please install npm with Node.js" -ForegroundColor Red
    exit 1
}

# Setup Python backend
Write-Host "🐍 Setting up Python backend..." -ForegroundColor Yellow
Set-Location "backend"
try {
    pip install -r requirements.txt
    Write-Host "✅ Python dependencies installed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to install Python dependencies" -ForegroundColor Red
    Write-Host "Please run manually: pip install -r requirements.txt" -ForegroundColor Yellow
}

# Setup Node.js backend
Write-Host "🟢 Setting up Node.js backend..." -ForegroundColor Yellow
try {
    npm install
    Write-Host "✅ Node.js dependencies installed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to install Node.js dependencies" -ForegroundColor Red
    Write-Host "Please run manually: npm install" -ForegroundColor Yellow
}

# Setup React frontend
Write-Host "⚛️ Setting up React frontend..." -ForegroundColor Yellow
Set-Location "../frontend"
try {
    npm install
    Write-Host "✅ React dependencies installed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to install React dependencies" -ForegroundColor Red
    Write-Host "Please run manually in frontend folder: npm install" -ForegroundColor Yellow
}

Set-Location ".."

Write-Host "" -ForegroundColor White
Write-Host "🎉 Setup completed!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Edit config.env with your IBM Watson ML API key" -ForegroundColor White
Write-Host "2. Run a backend server:" -ForegroundColor White
Write-Host "   - Python: .\scripts\run-python.ps1" -ForegroundColor Gray
Write-Host "   - Node.js: .\scripts\run-node.ps1" -ForegroundColor Gray
Write-Host "3. Run the frontend: .\scripts\run-frontend.ps1" -ForegroundColor White
Write-Host "4. Open http://localhost:3000 in your browser" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "For Java/Scala backends, see README.md for additional setup" -ForegroundColor Yellow
