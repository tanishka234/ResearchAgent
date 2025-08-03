# Watson ML Research Agent

A comprehensive research agent powered by IBM Watson ML with multiple backend implementations and a modern React frontend.

## Features

- 🔬 AI-powered research assistant using IBM Watson ML
- 🚀 Multiple backend implementations (Python, Node.js, Java, Scala)
- 💬 Two interaction modes: Simple Research & Chat Mode
- 🎨 Modern, responsive React frontend
- 🔄 Real-time connection testing
- 📱 Mobile-friendly design

## Project Structure

```
research-agent/
├── config.env                 # Configuration file
├── backend/
│   ├── python_server.py       # Python Flask backend
│   ├── requirements.txt       # Python dependencies
│   ├── node_server.js         # Node.js Express backend
│   ├── package.json           # Node.js dependencies
│   ├── WatsonResearchAgent.java # Java backend
│   └── WatsonResearchAgentScala.scala # Scala backend
├── frontend/
│   ├── package.json           # React dependencies
│   ├── public/
│   │   └── index.html
│   └── src/
│       ├── index.js
│       ├── index.css
│       └── App.js
├── scripts/
│   ├── setup.ps1             # PowerShell setup script
│   ├── run-python.ps1        # Run Python backend
│   ├── run-node.ps1          # Run Node.js backend
│   └── run-frontend.ps1      # Run React frontend
└── README.md
```
##SCREENSHOTS

<img width="1920" height="1080" alt="Screenshot (28)" src="https://github.com/user-attachments/assets/500cfa5b-fd52-4b87-aefb-f93ab035eaf8" />
<img width="1920" height="1080" alt="Screenshot (29)" src="https://github.com/user-attachments/assets/200c5eb2-b385-4e87-a0a3-d8a8f421c805" />
<img width="1920" height="1080" alt="Screenshot (30)" src="https://github.com/user-attachments/assets/c6cfe98d-2e6f-44a2-bdda-3f231f569bee" />
<img width="1920" height="1080" alt="Screenshot (31)" src="https://github.com/user-attachments/assets/2a94b0ab-c7cd-4278-8d77-48e043092916" />
<img width="1920" height="1080" alt="Screenshot (32)" src="https://github.com/user-attachments/assets/0a694e33-1d3e-4b04-955d-7421174a6ad3" />
<img width="1920" height="1080" alt="Screenshot (33)" src="https://github.com/user-attachments/assets/4941102d-5d3c-4ef2-bdc2-45ce654c67b8" />
<img width="1920" height="1080" alt="Screenshot (34)" src="https://github.com/user-attachments/assets/29669f8e-0e5b-4966-a5ce-c71c531695d0" />
<img width="1920" height="1080" alt="Screenshot (35)" src="https://github.com/user-attachments/assets/159a9ac3-8064-416a-bb39-05af4dcc6e96" />
<img width="1920" height="1080" alt="Screenshot (36)" src="https://github.com/user-attachments/assets/507d5532-f39d-4c66-8681-ff5799ea25d3" />


## Setup Instructions

### Prerequisites

- Python 3.8+ with pip
- Node.js 16+ with npm
- Java 11+ (for Java backend)
- Scala 2.13+ (for Scala backend)
- PowerShell (Windows)

### Quick Setup

1. **Configure your API key**:
   Edit `config.env` and replace the API_KEY value with your actual IBM Cloud API key.

2. **Run the setup script**:
   ```powershell
   .\scripts\setup.ps1
   ```

### Manual Setup

#### Backend Setup

**Python Backend (Port 3000):**
```powershell
cd backend
pip install -r requirements.txt
python python_server.py
```

**Node.js Backend (Port 3001):**
```powershell
cd backend
npm install
node node_server.js
```

**Java Backend (Port 3002):**
```powershell
cd backend
# Add required dependencies (Gson, etc.) to classpath
javac -cp "gson.jar" WatsonResearchAgent.java
java -cp ".:gson.jar" WatsonResearchAgent
```

**Scala Backend (Port 3003):**
```powershell
cd backend
# Compile with required dependencies
scalac -cp "scalaj-http.jar:play-json.jar" WatsonResearchAgentScala.scala
scala -cp ".:scalaj-http.jar:play-json.jar" WatsonResearchAgentScala
```

#### Frontend Setup

```powershell
cd frontend
npm install
npm start
```

The frontend will be available at http://localhost:3000

## Usage

1. **Start your chosen backend(s)**
2. **Start the frontend**
3. **Open http://localhost:3000 in your browser**
4. **Select your backend** from the interface
5. **Test the connection** to ensure everything is working
6. **Start researching!**

### Simple Research Mode
- Enter a research question
- Optionally add context
- Get comprehensive AI-powered responses

### Chat Mode
- Have conversational interactions
- Maintains conversation history
- More interactive research experience

## API Endpoints

All backends expose the same REST API:

- `GET /health` - Health check
- `POST /research` - Simple research query
- `POST /chat` - Chat conversation
- `GET /test-connection` - Test Watson ML connection

## Configuration

Edit `config.env` to configure:
- `API_KEY` - Your IBM Cloud API key
- `DEPLOYMENT_ID` - Watson ML deployment ID
- `WATSON_ML_URL` - Watson ML service URL
- `IAM_URL` - IBM IAM service URL
- `PORT` - Default backend port

## Troubleshooting

### Connection Issues
- Verify your API key is correct
- Check if the backend server is running
- Ensure no firewall is blocking the ports
- Test the /health endpoint directly

### Backend-Specific Issues

**Python:**
- Install dependencies: `pip install -r requirements.txt`
- Check Python version: `python --version`

**Node.js:**
- Install dependencies: `npm install`
- Check Node version: `node --version`

**Java:**
- Ensure Java 11+ is installed
- Add required JAR files to classpath
- Check JAVA_HOME environment variable

**Scala:**
- Ensure Scala 2.13+ is installed
- Add required JAR dependencies
- Check Scala version: `scala -version`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with all backends
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review the IBM Watson ML documentation
3. Open an issue on GitHub
