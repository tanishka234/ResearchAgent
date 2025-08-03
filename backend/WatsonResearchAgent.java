import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Properties;
import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.google.gson.JsonArray;
import com.google.gson.JsonParser;
import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpExchange;
import java.net.InetSocketAddress;
import java.util.concurrent.Executors;

public class WatsonResearchAgent {
    
    private static class Config {
        String apiKey;
        String deploymentId;
        String watsonMlUrl;
        String iamUrl;
        String version;
        int port;
        
        public Config() {
            Properties props = new Properties();
            try (InputStream input = new FileInputStream("../config.env")) {
                props.load(input);
                this.apiKey = props.getProperty("API_KEY");
                this.deploymentId = props.getProperty("DEPLOYMENT_ID");
                this.watsonMlUrl = props.getProperty("WATSON_ML_URL");
                this.iamUrl = props.getProperty("IAM_URL");
                this.version = props.getProperty("VERSION");
                this.port = Integer.parseInt(props.getProperty("PORT", "3002"));
            } catch (IOException e) {
                System.err.println("Error loading config: " + e.getMessage());
                // Fallback to default values
                this.apiKey = "cpd-apikey-IBMid-69800101GE-2025-07-31T10:43:16Z";
                this.deploymentId = "275686b4-2797-49eb-a5e6-9f6fddbf92ae";
                this.watsonMlUrl = "https://us-south.ml.cloud.ibm.com/ml/v4/deployments";
                this.iamUrl = "https://iam.cloud.ibm.com/identity/token";
                this.version = "2021-05-01";
                this.port = 3002;
            }
        }
    }
    
    private static class WatsonMLClient {
        private final Config config;
        private String token;
        private final Gson gson;
        
        public WatsonMLClient(Config config) {
            this.config = config;
            this.gson = new Gson();
        }
        
        public String getToken() throws IOException {
            URL tokenUrl = new URL(config.iamUrl);
            HttpURLConnection connection = (HttpURLConnection) tokenUrl.openConnection();
            
            connection.setDoInput(true);
            connection.setDoOutput(true);
            connection.setRequestMethod("POST");
            connection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
            connection.setRequestProperty("Accept", "application/json");
            
            String params = "grant_type=" + URLEncoder.encode("urn:ibm:params:oauth:grant-type:apikey", StandardCharsets.UTF_8) +
                           "&apikey=" + URLEncoder.encode(config.apiKey, StandardCharsets.UTF_8);
            
            try (OutputStreamWriter writer = new OutputStreamWriter(connection.getOutputStream())) {
                writer.write(params);
            }
            
            BufferedReader reader;
            if (connection.getResponseCode() == 200) {
                reader = new BufferedReader(new InputStreamReader(connection.getInputStream()));
            } else {
                reader = new BufferedReader(new InputStreamReader(connection.getErrorStream()));
                throw new IOException("Failed to get token: " + connection.getResponseCode());
            }
            
            StringBuilder response = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                response.append(line);
            }
            reader.close();
            connection.disconnect();
            
            JsonObject tokenResponse = JsonParser.parseString(response.toString()).getAsJsonObject();
            this.token = tokenResponse.get("access_token").getAsString();
            return this.token;
        }
        
        public String queryWatson(String messagesJson) throws IOException {
            if (token == null) {
                getToken();
            }
            
            URL scoringUrl = new URL(config.watsonMlUrl + "/" + config.deploymentId + "/ai_service_stream?version=" + config.version);
            HttpURLConnection connection = (HttpURLConnection) scoringUrl.openConnection();
            
            connection.setDoInput(true);
            connection.setDoOutput(true);
            connection.setRequestMethod("POST");
            connection.setRequestProperty("Accept", "application/json");
            connection.setRequestProperty("Authorization", "Bearer " + token);
            connection.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
            
            try (OutputStreamWriter writer = new OutputStreamWriter(connection.getOutputStream(), StandardCharsets.UTF_8)) {
                writer.write(messagesJson);
            }
            
            BufferedReader reader;
            if (connection.getResponseCode() == 200) {
                reader = new BufferedReader(new InputStreamReader(connection.getInputStream()));
            } else if (connection.getResponseCode() == 401) {
                // Token expired, get new token and retry
                getToken();
                connection.disconnect();
                return queryWatson(messagesJson);
            } else {
                reader = new BufferedReader(new InputStreamReader(connection.getErrorStream()));
            }
            
            StringBuilder response = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                response.append(line);
            }
            reader.close();
            connection.disconnect();
            
            return response.toString();
        }
    }
    
    private static class ResearchHandler implements HttpHandler {
        private final WatsonMLClient client;
        private final Gson gson;
        
        public ResearchHandler(WatsonMLClient client) {
            this.client = client;
            this.gson = new Gson();
        }
        
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            // Enable CORS
            exchange.getResponseHeaders().add("Access-Control-Allow-Origin", "*");
            exchange.getResponseHeaders().add("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
            exchange.getResponseHeaders().add("Access-Control-Allow-Headers", "Content-Type");
            
            if ("OPTIONS".equals(exchange.getRequestMethod())) {
                exchange.sendResponseHeaders(200, 0);
                exchange.close();
                return;
            }
            
            if ("POST".equals(exchange.getRequestMethod())) {
                try {
                    // Read request body
                    BufferedReader reader = new BufferedReader(new InputStreamReader(exchange.getRequestBody()));
                    StringBuilder requestBody = new StringBuilder();
                    String line;
                    while ((line = reader.readLine()) != null) {
                        requestBody.append(line);
                    }
                    reader.close();
                    
                    JsonObject request = JsonParser.parseString(requestBody.toString()).getAsJsonObject();
                    String query = request.get("query").getAsString();
                    String context = request.has("context") ? request.get("context").getAsString() : "";
                    
                    // Create messages
                    JsonArray messages = new JsonArray();
                    JsonObject systemMessage = new JsonObject();
                    systemMessage.addProperty("role", "system");
                    systemMessage.addProperty("content", "You are a helpful research assistant. Provide comprehensive, accurate, and well-structured responses based on the user's query.");
                    messages.add(systemMessage);
                    
                    JsonObject userMessage = new JsonObject();
                    userMessage.addProperty("role", "user");
                    userMessage.addProperty("content", "Research Query: " + query + "\nContext: " + context);
                    messages.add(userMessage);
                    
                    JsonObject payload = new JsonObject();
                    payload.add("messages", messages);
                    
                    String watsonResponse = client.queryWatson(gson.toJson(payload));
                    
                    JsonObject response = new JsonObject();
                    response.addProperty("query", query);
                    response.add("response", JsonParser.parseString(watsonResponse));
                    response.addProperty("status", "success");
                    
                    String responseJson = gson.toJson(response);
                    exchange.getResponseHeaders().add("Content-Type", "application/json");
                    exchange.sendResponseHeaders(200, responseJson.getBytes().length);
                    
                    try (OutputStream os = exchange.getResponseBody()) {
                        os.write(responseJson.getBytes());
                    }
                    
                } catch (Exception e) {
                    JsonObject errorResponse = new JsonObject();
                    errorResponse.addProperty("error", e.getMessage());
                    errorResponse.addProperty("status", "error");
                    
                    String errorJson = gson.toJson(errorResponse);
                    exchange.getResponseHeaders().add("Content-Type", "application/json");
                    exchange.sendResponseHeaders(500, errorJson.getBytes().length);
                    
                    try (OutputStream os = exchange.getResponseBody()) {
                        os.write(errorJson.getBytes());
                    }
                }
            } else {
                exchange.sendResponseHeaders(405, 0);
            }
            exchange.close();
        }
    }
    
    private static class HealthHandler implements HttpHandler {
        private final Gson gson;
        
        public HealthHandler() {
            this.gson = new Gson();
        }
        
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            exchange.getResponseHeaders().add("Access-Control-Allow-Origin", "*");
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            
            JsonObject response = new JsonObject();
            response.addProperty("status", "healthy");
            response.addProperty("service", "Watson ML Research Agent (Java)");
            
            String responseJson = gson.toJson(response);
            exchange.sendResponseHeaders(200, responseJson.getBytes().length);
            
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(responseJson.getBytes());
            }
            exchange.close();
        }
    }
    
    public static void main(String[] args) throws IOException {
        Config config = new Config();
        WatsonMLClient client = new WatsonMLClient(config);
        
        HttpServer server = HttpServer.create(new InetSocketAddress(config.port), 0);
        server.createContext("/health", new HealthHandler());
        server.createContext("/research", new ResearchHandler(client));
        server.setExecutor(Executors.newFixedThreadPool(10));
        
        server.start();
        System.out.println("Java Research Agent server running on port " + config.port);
    }
}
