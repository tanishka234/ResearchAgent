# Watson ML Research Agent - Complete Startup Script
# This script will help you start the research agent with your preferred backend

param(
    [Parameter(Position=0)]
    [ValidateSet("python", "node", "java", "scala", "all")]
    [string]$Backend = "python",
    
    [switch]$SetupOnly,
    [switch]$FrontendOnly,
    [switch]$Help
)

if ($Help) {
    Write-Host "Watson ML Research Agent Startup Script" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\scripts\start.ps1 [backend] [options]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Backend options:" -ForegroundColor Yellow
    Write-Host "  python    - Start Python Flask backend (default)" -ForegroundColor White
    Write-Host "  node      - Start Node.js Express backend" -ForegroundColor White
    Write-Host "  java      - Start Java HTTP server backend" -ForegroundColor White
    Write-Host "  scala     - Start Scala HTTP server backend" -ForegroundColor White
    Write-Host "  all       - Show instructions for all backends" -ForegroundColor White
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -SetupOnly     - Only run setup, don't start servers" -ForegroundColor White
    Write-Host "  -FrontendOnly  - Only start the React frontend" -ForegroundColor White
    Write-Host "  -Help         - Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\scripts\start.ps1                    # Start with Python backend" -ForegroundColor Gray
    Write-Host "  .\scripts\start.ps1 node              # Start with Node.js backend" -ForegroundColor Gray
    Write-Host "  .\scripts\start.ps1 -SetupOnly        # Just run setup" -ForegroundColor Gray
    Write-Host "  .\scripts\start.ps1 -FrontendOnly     # Just start frontend" -ForegroundColor Gray
    exit 0
}

Write-Host "🔬 Watson ML Research Agent" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# Check if we're in the right directory
if (-not (Test-Path "config.env")) {
    Write-Host "❌ Please run this script from the research-agent root directory" -ForegroundColor Red
    exit 1
}

# Setup phase
if (-not $FrontendOnly) {
    Write-Host "🛠️ Running setup..." -ForegroundColor Yellow
    & ".\scripts\setup.ps1"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Setup failed. Please check the errors above." -ForegroundColor Red
        exit 1
    }
}

if ($SetupOnly) {
    Write-Host "✅ Setup completed. You can now start the servers manually." -ForegroundColor Green
    exit 0
}

# Display API key reminder
Write-Host ""
Write-Host "⚠️ IMPORTANT: Make sure you've set your IBM Watson ML API key in config.env" -ForegroundColor Yellow
Write-Host "Current API_KEY in config.env:" -ForegroundColor Gray
$apiKeyLine = Get-Content "config.env" | Where-Object { $_ -like "API_KEY=*" }
if ($apiKeyLine) {
    $apiKey = $apiKeyLine.Split('=')[1]
    if ($apiKey -eq "<your API key>" -or $apiKey -eq "") {
        Write-Host "❌ API key not set! Edit config.env first." -ForegroundColor Red
        exit 1
    } else {
        Write-Host "✅ API key is configured" -ForegroundColor Green
    }
} else {
    Write-Host "❌ API_KEY not found in config.env" -ForegroundColor Red
    exit 1
}

Write-Host ""

if ($FrontendOnly) {
    Write-Host "🚀 Starting React frontend only..." -ForegroundColor Green
    & ".\scripts\run-frontend.ps1"
    exit 0
}

if ($Backend -eq "all") {
    Write-Host "📋 Instructions for all backends:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Python Backend (Port 3000):" -ForegroundColor Yellow
    Write-Host "   .\scripts\run-python.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Node.js Backend (Port 3001):" -ForegroundColor Yellow
    Write-Host "   .\scripts\run-node.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Java Backend (Port 3002):" -ForegroundColor Yellow
    Write-Host "   cd backend" -ForegroundColor Gray
    Write-Host "   # Download required JARs: gson.jar" -ForegroundColor Gray
    Write-Host "   javac -cp gson.jar WatsonResearchAgent.java" -ForegroundColor Gray
    Write-Host "   java -cp .:gson.jar WatsonResearchAgent" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. Scala Backend (Port 3003):" -ForegroundColor Yellow
    Write-Host "   cd backend" -ForegroundColor Gray
    Write-Host "   # Download required JARs: scalaj-http.jar, play-json.jar" -ForegroundColor Gray
    Write-Host "   scalac -cp scalaj-http.jar:play-json.jar WatsonResearchAgentScala.scala" -ForegroundColor Gray
    Write-Host "   scala -cp .:scalaj-http.jar:play-json.jar WatsonResearchAgentScala" -ForegroundColor Gray
    Write-Host ""
    Write-Host "5. Frontend:" -ForegroundColor Yellow
    Write-Host "   .\scripts\run-frontend.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Choose one backend and run it, then start the frontend in a new terminal." -ForegroundColor Green
    exit 0
}

# Start the selected backend
Write-Host "🚀 Starting $Backend backend..." -ForegroundColor Green

switch ($Backend) {
    "python" {
        Write-Host "Starting Python Flask backend on port 3000..." -ForegroundColor Yellow
        Write-Host "Open a new terminal and run: .\scripts\run-frontend.ps1" -ForegroundColor Cyan
        Write-Host ""
        & ".\scripts\run-python.ps1"
    }
    "node" {
        Write-Host "Starting Node.js Express backend on port 3001..." -ForegroundColor Yellow
        Write-Host "Open a new terminal and run: .\scripts\run-frontend.ps1" -ForegroundColor Cyan
        Write-Host ""
        & ".\scripts\run-node.ps1"
    }
    "java" {
        Write-Host "Java backend requires manual compilation. See instructions:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "1. Download gson.jar to the backend directory" -ForegroundColor White
        Write-Host "2. cd backend" -ForegroundColor Gray
        Write-Host "3. javac -cp gson.jar WatsonResearchAgent.java" -ForegroundColor Gray
        Write-Host "4. java -cp .:gson.jar WatsonResearchAgent" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Then run: .\scripts\run-frontend.ps1" -ForegroundColor Cyan
    }
    "scala" {
        Write-Host "Scala backend requires manual compilation. See instructions:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "1. Download scalaj-http.jar and play-json.jar to the backend directory" -ForegroundColor White
        Write-Host "2. cd backend" -ForegroundColor Gray
        Write-Host "3. scalac -cp scalaj-http.jar:play-json.jar WatsonResearchAgentScala.scala" -ForegroundColor Gray
        Write-Host "4. scala -cp .:scalaj-http.jar:play-json.jar WatsonResearchAgentScala" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Then run: .\scripts\run-frontend.ps1" -ForegroundColor Cyan
    }
}
