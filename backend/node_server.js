const express = require('express');
const cors = require('cors');
const axios = require('axios');
require('dotenv').config({ path: '../config.env' });

const app = express();
app.use(cors());
app.use(express.json());

class WatsonMLClient {
    constructor() {
        this.apiKey = process.env.API_KEY;
        this.deploymentId = process.env.DEPLOYMENT_ID;
        this.watsonMlUrl = process.env.WATSON_ML_URL;
        this.iamUrl = process.env.IAM_URL;
        this.version = process.env.VERSION;
        this.token = null;
    }

    async getToken() {
        try {
            // Add demo mode for testing
            if (this.apiKey === "DEMO_MODE") {
                this.token = "demo_token_12345";
                return this.token;
            }
            
            const response = await axios.post(this.iamUrl, new URLSearchParams({
                'grant_type': 'urn:ibm:params:oauth:grant-type:apikey',
                'apikey': this.apiKey
            }), {
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'Accept': 'application/json'
                }
            });
            
            this.token = response.data.access_token;
            return this.token;
        } catch (error) {
            console.error('Error getting token:', error.message);
            throw error;
        }
    }

    async queryWatson(messages) {
        if (!this.token) {
            await this.getToken();
        }

        // Demo mode for testing
        if (this.apiKey === "DEMO_MODE") {
            await new Promise(resolve => setTimeout(resolve, 1000)); // Simulate API delay
            
            let userQuery = "";
            for (const msg of messages) {
                if (msg.role === "user") {
                    userQuery = msg.content || "";
                    break;
                }
            }
            
            // Generate a demo response based on the query
            const demoResponses = {
                "artificial intelligence": "Artificial Intelligence (AI) refers to computer systems that can perform tasks typically requiring human intelligence, such as learning, reasoning, and problem-solving.",
                "quantum computing": "Quantum computing leverages quantum mechanical phenomena to process information in ways that classical computers cannot, potentially solving complex problems exponentially faster.",
                "machine learning": "Machine learning is a subset of AI that enables computers to learn and improve from experience without being explicitly programmed for every task.",
                "research": "Research is a systematic investigation process designed to discover new knowledge, verify existing knowledge, or solve specific problems through organized data collection and analysis.",
                "default": `This is a demo response for your query. In production, this would be processed by IBM Watson ML to provide comprehensive research insights about your topic.`
            };
            
            // Find the most relevant demo response
            const queryLower = userQuery.toLowerCase();
            for (const key in demoResponses) {
                if (queryLower.includes(key)) {
                    return { generated_text: demoResponses[key], demo_mode: true };
                }
            }
            
            return { generated_text: demoResponses.default, demo_mode: true };
        }

        const headers = {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.token}`,
            'Accept': 'application/json'
        };

        const payload = {
            messages: messages
        };

        const scoringUrl = `${this.watsonMlUrl}/${this.deploymentId}/ai_service?version=${this.version}`;

        try {
            const response = await axios.post(scoringUrl, payload, { headers });
            return response.data;
        } catch (error) {
            if (error.response && error.response.status === 401) {
                // Token might be expired, get a new one
                await this.getToken();
                headers.Authorization = `Bearer ${this.token}`;
                const retryResponse = await axios.post(scoringUrl, payload, { headers });
                return retryResponse.data;
            } else {
                console.error('Error querying Watson:', error.message);
                throw error;
            }
        }
    }
}

const watsonClient = new WatsonMLClient();

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', service: 'Watson ML Research Agent (Node.js)' });
});

// Research endpoint
app.post('/research', async (req, res) => {
    try {
        const { query, context = '' } = req.body;
        
        if (!query) {
            return res.status(400).json({ error: 'Query is required' });
        }

        const messages = [
            {
                role: 'system',
                content: 'You are a helpful research assistant. Provide comprehensive, accurate, and well-structured responses based on the user\'s query.'
            },
            {
                role: 'user',
                content: `Research Query: ${query}\nContext: ${context}`
            }
        ];

        const result = await watsonClient.queryWatson(messages);

        res.json({
            query,
            response: result,
            status: 'success'
        });
    } catch (error) {
        console.error('Error in research query:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// Chat endpoint
app.post('/chat', async (req, res) => {
    try {
        const { messages } = req.body;
        
        if (!messages || !Array.isArray(messages)) {
            return res.status(400).json({ error: 'Messages array is required' });
        }

        const result = await watsonClient.queryWatson(messages);

        res.json({
            response: result,
            status: 'success'
        });
    } catch (error) {
        console.error('Error in chat:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// Test connection endpoint
app.get('/test-connection', async (req, res) => {
    try {
        const token = await watsonClient.getToken();
        res.json({
            status: 'success',
            message: 'Successfully connected to Watson ML',
            tokenPreview: token ? token.substring(0, 20) + '...' : null
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: `Connection failed: ${error.message}`
        });
    }
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
    console.log(`Node.js Research Agent server running on port ${PORT}`);
});
