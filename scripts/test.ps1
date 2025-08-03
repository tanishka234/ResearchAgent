# Test Watson ML Research Agent
# This script tests the connection and basic functionality

param(
    [Parameter(Position=0)]
    [ValidateSet("python", "node", "java", "scala")]
    [string]$Backend = "python"
)

Write-Host "🧪 Testing Watson ML Research Agent" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

$ports = @{
    "python" = 3000
    "node" = 3001
    "java" = 3002
    "scala" = 3003
}

$port = $ports[$Backend]
$baseUrl = "http://localhost:$port"

Write-Host "Testing $Backend backend on port $port..." -ForegroundColor Yellow
Write-Host ""

# Test 1: Health Check
Write-Host "1. Testing health endpoint..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get -TimeoutSec 5
    if ($healthResponse.status -eq "healthy") {
        Write-Host "   ✅ Health check passed" -ForegroundColor Green
        Write-Host "   Service: $($healthResponse.service)" -ForegroundColor Gray
    } else {
        Write-Host "   ❌ Health check failed" -ForegroundColor Red
        Write-Host "   Response: $($healthResponse | ConvertTo-Json)" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ Health check failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Make sure the $Backend backend is running on port $port" -ForegroundColor Yellow
    exit 1
}

# Test 2: Connection Test
Write-Host ""
Write-Host "2. Testing Watson ML connection..." -ForegroundColor Yellow
try {
    $connectionResponse = Invoke-RestMethod -Uri "$baseUrl/test-connection" -Method Get -TimeoutSec 10
    if ($connectionResponse.status -eq "success") {
        Write-Host "   ✅ Watson ML connection successful" -ForegroundColor Green
        Write-Host "   Message: $($connectionResponse.message)" -ForegroundColor Gray
    } else {
        Write-Host "   ❌ Watson ML connection failed" -ForegroundColor Red
        Write-Host "   Message: $($connectionResponse.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ Connection test failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Check your API key in config.env" -ForegroundColor Yellow
}

# Test 3: Simple Research Query
Write-Host ""
Write-Host "3. Testing research endpoint..." -ForegroundColor Yellow
$testQuery = @{
    query = "What is artificial intelligence?"
    context = "Basic definition for testing"
} | ConvertTo-Json

try {
    $researchResponse = Invoke-RestMethod -Uri "$baseUrl/research" -Method Post -Body $testQuery -ContentType "application/json" -TimeoutSec 30
    if ($researchResponse.status -eq "success") {
        Write-Host "   ✅ Research query successful" -ForegroundColor Green
        Write-Host "   Query: $($researchResponse.query)" -ForegroundColor Gray
        Write-Host "   Response received: $(($researchResponse.response | ConvertTo-Json).Length) characters" -ForegroundColor Gray
    } else {
        Write-Host "   ❌ Research query failed" -ForegroundColor Red
        Write-Host "   Error: $($researchResponse.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ Research test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Chat Endpoint
Write-Host ""
Write-Host "4. Testing chat endpoint..." -ForegroundColor Yellow
$testMessages = @{
    messages = @(
        @{
            role = "system"
            content = "You are a helpful assistant."
        },
        @{
            role = "user"
            content = "Hello, this is a test message."
        }
    )
} | ConvertTo-Json -Depth 3

try {
    $chatResponse = Invoke-RestMethod -Uri "$baseUrl/chat" -Method Post -Body $testMessages -ContentType "application/json" -TimeoutSec 30
    if ($chatResponse.status -eq "success") {
        Write-Host "   ✅ Chat query successful" -ForegroundColor Green
        Write-Host "   Response received: $(($chatResponse.response | ConvertTo-Json).Length) characters" -ForegroundColor Gray
    } else {
        Write-Host "   ❌ Chat query failed" -ForegroundColor Red
        Write-Host "   Error: $($chatResponse.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ Chat test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🏁 Test completed!" -ForegroundColor Cyan
Write-Host ""
Write-Host "If all tests passed, your research agent is ready to use!" -ForegroundColor Green
Write-Host "Open the frontend at http://localhost:3000 (make sure it's running)" -ForegroundColor Yellow
