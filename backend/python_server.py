import requests
import json
import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import logging

# Load environment variables
load_dotenv('../config.env')

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class WatsonMLClient:
    def __init__(self):
        self.api_key = os.getenv('API_KEY')
        self.deployment_id = os.getenv('DEPLOYMENT_ID')
        self.watson_ml_url = os.getenv('WATSON_ML_URL')
        self.iam_url = os.getenv('IAM_URL')
        self.version = os.getenv('VERSION')
        self.token = None
        
        # Debug output
        logger.info(f"Loaded API_KEY: {self.api_key[:20] if self.api_key else 'None'}...")
        logger.info(f"Loaded IAM_URL: {self.iam_url}")
        logger.info(f"Demo mode: {'YES' if self.api_key == 'DEMO_MODE' else 'NO'}")
        
    def get_token(self):
        """Get IBM Cloud IAM token"""
        try:
            # Add demo mode for testing
            if self.api_key == "DEMO_MODE":
                self.token = "demo_token_12345"
                return self.token
            
            # Check if this is a Cloud Pak for Data API key
            if self.api_key.startswith("cpd-apikey"):
                # For CPD, we might need to use different authentication
                token_response = requests.post(
                    self.iam_url,
                    data={
                        "apikey": self.api_key,
                        "grant_type": 'urn:ibm:params:oauth:grant-type:apikey',
                        "response_type": "cloud_iam"
                    },
                    headers={
                        "Content-Type": "application/x-www-form-urlencoded",
                        "Accept": "application/json"
                    }
                )
            else:
                # Standard IBM Cloud authentication
                token_response = requests.post(
                    self.iam_url,
                    data={
                        "apikey": self.api_key,
                        "grant_type": 'urn:ibm:params:oauth:grant-type:apikey'
                    },
                    headers={
                        "Content-Type": "application/x-www-form-urlencoded",
                        "Accept": "application/json"
                    }
                )
            
            if token_response.status_code != 200:
                logger.error(f"Token request failed with status {token_response.status_code}")
                logger.error(f"Response: {token_response.text}")
                
            token_response.raise_for_status()
            response_data = token_response.json()
            self.token = response_data["access_token"]
            logger.info(f"Successfully obtained token: {self.token[:20]}...")
            return self.token
        except Exception as e:
            logger.error(f"Error getting token: {e}")
            raise
    
    def query_watson(self, messages):
        """Send query to Watson ML"""
        if not self.token:
            self.get_token()
        
        # Demo mode for testing - only run if explicitly in demo mode
        if self.api_key == "DEMO_MODE":
            import time
            time.sleep(1)  # Simulate API delay
            
            user_query = ""
            for msg in messages:
                if msg.get("role") == "user":
                    user_query = msg.get("content", "")
                    break
            
            # Generate a demo response based on the query
            demo_responses = {
                "artificial intelligence": "Artificial Intelligence (AI) refers to computer systems that can perform tasks typically requiring human intelligence, such as learning, reasoning, and problem-solving.",
                "quantum computing": "Quantum computing leverages quantum mechanical phenomena to process information in ways that classical computers cannot, potentially solving complex problems exponentially faster.",
                "machine learning": "Machine learning is a subset of AI that enables computers to learn and improve from experience without being explicitly programmed for every task.",
                "default": f"This is a demo response for your query. In production, this would be processed by IBM Watson ML to provide comprehensive research insights about your topic."
            }
            
            # Find the most relevant demo response
            query_lower = user_query.lower()
            for key in demo_responses:
                if key in query_lower:
                    return {"generated_text": demo_responses[key], "demo_mode": True}
            
            return {"generated_text": demo_responses["default"], "demo_mode": True}
            
        # Real Watson ML API call
        headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {self.token}'
        }
        
        payload = {
            "messages": messages
        }
        
        scoring_url = f"{self.watson_ml_url}/{self.deployment_id}/ai_service?version={self.version}"
        
        try:
            logger.info(f"Making request to Watson ML: {scoring_url}")
            response = requests.post(scoring_url, json=payload, headers=headers, timeout=30)
            response.raise_for_status()
            result = response.json()
            logger.info(f"Watson ML response received: {len(str(result))} characters")
            return result
        except requests.exceptions.HTTPError as e:
            if response.status_code == 401:
                # Token might be expired, get a new one
                logger.info("Token expired, getting new token...")
                self.get_token()
                headers['Authorization'] = f'Bearer {self.token}'
                response = requests.post(scoring_url, json=payload, headers=headers, timeout=30)
                response.raise_for_status()
                result = response.json()
                logger.info(f"Watson ML response received after token refresh: {len(str(result))} characters")
                return result
            else:
                logger.error(f"HTTP error: {e}")
                logger.error(f"Response content: {response.text if response else 'No response'}")
                return {"error": f"HTTP error: {e}"}
        except Exception as e:
            logger.error(f"Error querying Watson: {e}")
            return {"error": str(e)}

# Initialize Watson ML client
watson_client = WatsonMLClient()

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "service": "Watson ML Research Agent"})

@app.route('/research', methods=['POST'])
def research_query():
    """Main research endpoint"""
    try:
        data = request.json
        if not data or 'query' not in data:
            return jsonify({"error": "Query is required"}), 400
        
        query = data['query']
        context = data.get('context', '')
        
        # Prepare messages for Watson ML
        messages = [
            {
                "role": "system",
                "content": "You are a helpful research assistant. Provide comprehensive, accurate, and well-structured responses based on the user's query."
            },
            {
                "role": "user", 
                "content": f"Research Query: {query}\nContext: {context}"
            }
        ]
        
        # Query Watson ML
        result = watson_client.query_watson(messages)
        
        return jsonify({
            "query": query,
            "response": result,
            "status": "success"
        })
        
    except Exception as e:
        logger.error(f"Error in research query: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/chat', methods=['POST'])
def chat():
    """Chat endpoint for conversational research"""
    try:
        data = request.json
        if not data or 'messages' not in data:
            return jsonify({"error": "Messages are required"}), 400
        
        messages = data['messages']
        
        # Query Watson ML
        result = watson_client.query_watson(messages)
        
        return jsonify({
            "response": result,
            "status": "success"
        })
        
    except Exception as e:
        logger.error(f"Error in chat: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/test-connection', methods=['GET'])
def test_connection():
    """Test Watson ML connection"""
    try:
        token = watson_client.get_token()
        return jsonify({
            "status": "success",
            "message": "Successfully connected to Watson ML",
            "token_preview": token[:20] + "..." if token else None
        })
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": f"Connection failed: {str(e)}"
        }), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 3000))
    app.run(debug=True, host='0.0.0.0', port=port)
