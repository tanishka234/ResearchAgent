import React, { useState, useEffect, useRef } from 'react';
import axios from 'axios';

const App = () => {
  const [selectedBackend, setSelectedBackend] = useState('python');
  const [connectionStatus, setConnectionStatus] = useState('disconnected');
  const [messages, setMessages] = useState([]);
  const [query, setQuery] = useState('');
  const [context, setContext] = useState('');
  const [loading, setLoading] = useState(false);
  const [activeTab, setActiveTab] = useState('simple');
  const chatContainerRef = useRef(null);

  const backends = {
    python: { name: 'Python Flask', port: 3000, description: 'Fast and reliable Python backend' },
    node: { name: 'Node.js Express', port: 3001, description: 'JavaScript-based backend' },
    java: { name: 'Java HTTP Server', port: 3002, description: 'Enterprise Java backend' },
    scala: { name: 'Scala HTTP Server', port: 3003, description: 'Functional programming backend' }
  };

  const getBackendUrl = () => `http://localhost:${backends[selectedBackend].port}`;

  const testConnection = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${getBackendUrl()}/health`, {
        timeout: 5000
      });
      if (response.data.status === 'healthy') {
        setConnectionStatus('connected');
        addMessage('system', `Connected to ${backends[selectedBackend].name} successfully!`);
      }
    } catch (error) {
      setConnectionStatus('disconnected');
      addMessage('error', `Failed to connect to ${backends[selectedBackend].name}: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const addMessage = (type, content, data = null) => {
    const message = {
      id: Date.now(),
      type,
      content,
      data,
      timestamp: new Date().toLocaleTimeString()
    };
    setMessages(prev => [...prev, message]);
  };

  const scrollToBottom = () => {
    if (chatContainerRef.current) {
      chatContainerRef.current.scrollTop = chatContainerRef.current.scrollHeight;
    }
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  useEffect(() => {
    setConnectionStatus('disconnected');
    setMessages([]);
  }, [selectedBackend]);

  const handleSimpleResearch = async () => {
    if (!query.trim()) return;

    setLoading(true);
    addMessage('user', query);

    try {
      const response = await axios.post(`${getBackendUrl()}/research`, {
        query: query.trim(),
        context: context.trim()
      }, {
        timeout: 30000
      });

      if (response.data.status === 'success') {
        addMessage('assistant', 'Research completed successfully!', response.data);
      } else {
        addMessage('error', 'Research failed: ' + (response.data.error || 'Unknown error'));
      }
    } catch (error) {
      addMessage('error', `Research failed: ${error.message}`);
    } finally {
      setLoading(false);
      setQuery('');
    }
  };

  const handleChatMessage = async () => {
    if (!query.trim()) return;

    setLoading(true);
    const userMessage = { role: 'user', content: query.trim() };
    addMessage('user', query);

    // Get recent conversation history
    const recentMessages = messages
      .filter(msg => msg.type === 'user' || msg.type === 'assistant')
      .slice(-5) // Last 5 messages
      .map(msg => ({
        role: msg.type === 'user' ? 'user' : 'assistant',
        content: msg.type === 'assistant' && msg.data ? 
          JSON.stringify(msg.data.response) : msg.content
      }));

    const conversationMessages = [
      {
        role: 'system',
        content: 'You are a helpful research assistant. Provide comprehensive, accurate, and well-structured responses.'
      },
      ...recentMessages,
      userMessage
    ];

    try {
      const response = await axios.post(`${getBackendUrl()}/chat`, {
        messages: conversationMessages
      }, {
        timeout: 30000
      });

      if (response.data.status === 'success') {
        addMessage('assistant', 'Response received', response.data);
      } else {
        addMessage('error', 'Chat failed: ' + (response.data.error || 'Unknown error'));
      }
    } catch (error) {
      addMessage('error', `Chat failed: ${error.message}`);
    } finally {
      setLoading(false);
      setQuery('');
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      if (activeTab === 'simple') {
        handleSimpleResearch();
      } else {
        handleChatMessage();
      }
    }
  };

  const clearMessages = () => {
    setMessages([]);
  };

  const renderMessage = (message) => {
    if (message.type === 'system') {
      return (
        <div key={message.id} className="message system">
          <div style={{ fontSize: '0.9rem', opacity: 0.8 }}>
            {message.timestamp} - System
          </div>
          <div>{message.content}</div>
        </div>
      );
    }

    if (message.type === 'error') {
      return (
        <div key={message.id} className="message error">
          <div style={{ fontSize: '0.9rem', opacity: 0.8 }}>
            {message.timestamp} - Error
          </div>
          <div>{message.content}</div>
        </div>
      );
    }

    if (message.type === 'user') {
      return (
        <div key={message.id} className="message user">
          <div style={{ fontSize: '0.9rem', opacity: 0.8, marginBottom: '0.5rem' }}>
            {message.timestamp} - You
          </div>
          <div>{message.content}</div>
        </div>
      );
    }

    if (message.type === 'assistant') {
      return (
        <div key={message.id} className="message assistant">
          <div style={{ fontSize: '0.9rem', opacity: 0.8, marginBottom: '0.5rem' }}>
            {message.timestamp} - Assistant
          </div>
          <div>{message.content}</div>
          {message.data && (
            <div className="response-content">
              <h4>Watson ML Response:</h4>
              <pre>{JSON.stringify(message.data.response, null, 2)}</pre>
            </div>
          )}
        </div>
      );
    }

    return null;
  };

  return (
    <div className="app">
      <header className="header">
        <h1>🔬 Watson ML Research Agent</h1>
        <p>AI-Powered Research Assistant with Multiple Backend Options</p>
      </header>

      <main className="main-content">
        <section className="backend-selector">
          <h3>Choose Backend Implementation:</h3>
          <div className="backend-options">
            {Object.entries(backends).map(([key, backend]) => (
              <div
                key={key}
                className={`backend-option ${selectedBackend === key ? 'active' : ''}`}
                onClick={() => setSelectedBackend(key)}
              >
                <div>{backend.name}</div>
                <div style={{ fontSize: '0.8rem', opacity: 0.8 }}>
                  Port {backend.port} • {backend.description}
                </div>
              </div>
            ))}
          </div>
          
          <div className={`connection-status ${connectionStatus}`}>
            Status: {connectionStatus === 'connected' ? '🟢 Connected' : '🔴 Disconnected'}
            {connectionStatus === 'disconnected' && (
              <button 
                className="button" 
                onClick={testConnection}
                disabled={loading}
                style={{ marginLeft: '1rem', padding: '0.5rem 1rem', fontSize: '0.9rem' }}
              >
                {loading ? 'Testing...' : 'Test Connection'}
              </button>
            )}
          </div>
        </section>

        <section className="research-interface">
          <div className="tabs">
            <button 
              className={`tab ${activeTab === 'simple' ? 'active' : ''}`}
              onClick={() => setActiveTab('simple')}
            >
              Simple Research
            </button>
            <button 
              className={`tab ${activeTab === 'chat' ? 'active' : ''}`}
              onClick={() => setActiveTab('chat')}
            >
              Chat Mode
            </button>
          </div>

          <div className="chat-container" ref={chatContainerRef}>
            {messages.length === 0 ? (
              <div style={{ textAlign: 'center', opacity: 0.6, marginTop: '2rem' }}>
                <h3>Welcome to Watson ML Research Agent!</h3>
                <p>
                  {activeTab === 'simple' 
                    ? 'Enter your research query below to get started.'
                    : 'Start a conversation with the AI assistant.'
                  }
                </p>
                <p>Make sure to test the connection to your chosen backend first.</p>
              </div>
            ) : (
              messages.map(renderMessage)
            )}
          </div>

          {activeTab === 'simple' && (
            <textarea
              className="context-input"
              placeholder="Optional: Add context or background information for your research..."
              value={context}
              onChange={(e) => setContext(e.target.value)}
            />
          )}

          <div className="input-container">
            <input
              type="text"
              className="query-input"
              placeholder={
                activeTab === 'simple' 
                  ? "Enter your research question..." 
                  : "Type your message..."
              }
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyPress={handleKeyPress}
              disabled={loading || connectionStatus === 'disconnected'}
            />
            <button
              className="button"
              onClick={activeTab === 'simple' ? handleSimpleResearch : handleChatMessage}
              disabled={loading || !query.trim() || connectionStatus === 'disconnected'}
            >
              {loading ? (
                <div className="loading">
                  <div className="loading-spinner"></div>
                  Processing...
                </div>
              ) : (
                activeTab === 'simple' ? 'Research' : 'Send'
              )}
            </button>
          </div>

          <div style={{ textAlign: 'center', marginTop: '1rem' }}>
            <button 
              className="button" 
              onClick={clearMessages}
              style={{ background: '#6c757d', fontSize: '0.9rem', padding: '0.5rem 1rem' }}
            >
              Clear Messages
            </button>
          </div>
        </section>
      </main>
    </div>
  );
};

export default App;
