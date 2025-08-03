import scalaj.http.{Http, HttpOptions}
import scala.util.{Success, Failure, Try}
import play.api.libs.json._
import java.util.Properties
import java.io.FileInputStream
import com.sun.net.httpserver.{HttpServer, HttpHandler, HttpExchange}
import java.net.InetSocketAddress
import java.io.{OutputStream, BufferedReader, InputStreamReader}
import scala.io.Source

object WatsonResearchAgentScala {
  
  case class Config(
    apiKey: String,
    deploymentId: String,
    watsonMlUrl: String,
    iamUrl: String,
    version: String,
    port: Int
  )
  
  object Config {
    def load(): Config = {
      Try {
        val props = new Properties()
        props.load(new FileInputStream("../config.env"))
        Config(
          apiKey = props.getProperty("API_KEY"),
          deploymentId = props.getProperty("DEPLOYMENT_ID"),
          watsonMlUrl = props.getProperty("WATSON_ML_URL"),
          iamUrl = props.getProperty("IAM_URL"),
          version = props.getProperty("VERSION"),
          port = props.getProperty("PORT", "3003").toInt
        )
      } match {
        case Success(config) => config
        case Failure(_) => 
          // Fallback to default values
          Config(
            apiKey = "cpd-apikey-IBMid-69800101GE-2025-07-31T10:43:16Z",
            deploymentId = "275686b4-2797-49eb-a5e6-9f6fddbf92ae",
            watsonMlUrl = "https://us-south.ml.cloud.ibm.com/ml/v4/deployments",
            iamUrl = "https://iam.cloud.ibm.com/identity/token",
            version = "2021-05-01",
            port = 3003
          )
      }
    }
  }
  
  class WatsonMLClient(config: Config) {
    private var token: Option[String] = None
    
    def getToken(): Try[String] = {
      Try {
        val response = Http(config.iamUrl)
          .header("Content-Type", "application/x-www-form-urlencoded")
          .header("Accept", "application/json")
          .postForm(Seq(
            "grant_type" -> "urn:ibm:params:oauth:grant-type:apikey",
            "apikey" -> config.apiKey
          ))
          .asString
          
        if (response.code == 200) {
          val json: JsValue = Json.parse(response.body)
          val accessToken = (json \ "access_token").as[String]
          token = Some(accessToken)
          accessToken
        } else {
          throw new RuntimeException(s"Failed to get token: ${response.code}")
        }
      }
    }
    
    def queryWatson(messages: JsArray): Try[JsValue] = {
      if (token.isEmpty) {
        getToken() match {
          case Failure(ex) => return Failure(ex)
          case _ =>
        }
      }
      
      val payload = Json.obj("messages" -> messages)
      val scoringUrl = s"${config.watsonMlUrl}/${config.deploymentId}/ai_service_stream?version=${config.version}"
      
      Try {
        val response = Http(scoringUrl)
          .postData(Json.stringify(payload))
          .header("Content-Type", "application/json")
          .header("Authorization", s"Bearer ${token.get}")
          .option(HttpOptions.connTimeout(10000))
          .option(HttpOptions.readTimeout(50000))
          .asString
          
        if (response.code == 200) {
          Json.parse(response.body)
        } else if (response.code == 401) {
          // Token expired, get new token and retry
          getToken() match {
            case Success(_) => queryWatson(messages).get
            case Failure(ex) => throw ex
          }
        } else {
          throw new RuntimeException(s"Watson query failed: ${response.code} - ${response.body}")
        }
      }
    }
  }
  
  class ResearchHandler(client: WatsonMLClient) extends HttpHandler {
    override def handle(exchange: HttpExchange): Unit = {
      // Enable CORS
      exchange.getResponseHeaders.add("Access-Control-Allow-Origin", "*")
      exchange.getResponseHeaders.add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
      exchange.getResponseHeaders.add("Access-Control-Allow-Headers", "Content-Type")
      
      if (exchange.getRequestMethod == "OPTIONS") {
        exchange.sendResponseHeaders(200, 0)
        exchange.close()
        return
      }
      
      if (exchange.getRequestMethod == "POST") {
        try {
          val requestBody = Source.fromInputStream(exchange.getRequestBody).mkString
          val requestJson = Json.parse(requestBody)
          
          val query = (requestJson \ "query").as[String]
          val context = (requestJson \ "context").asOpt[String].getOrElse("")
          
          val messages = Json.arr(
            Json.obj(
              "role" -> "system",
              "content" -> "You are a helpful research assistant. Provide comprehensive, accurate, and well-structured responses based on the user's query."
            ),
            Json.obj(
              "role" -> "user",
              "content" -> s"Research Query: $query\nContext: $context"
            )
          )
          
          client.queryWatson(messages) match {
            case Success(watsonResponse) =>
              val response = Json.obj(
                "query" -> query,
                "response" -> watsonResponse,
                "status" -> "success"
              )
              
              val responseString = Json.stringify(response)
              exchange.getResponseHeaders.add("Content-Type", "application/json")
              exchange.sendResponseHeaders(200, responseString.getBytes.length)
              
              val os = exchange.getResponseBody
              os.write(responseString.getBytes)
              os.close()
              
            case Failure(ex) =>
              val errorResponse = Json.obj(
                "error" -> ex.getMessage,
                "status" -> "error"
              )
              
              val errorString = Json.stringify(errorResponse)
              exchange.getResponseHeaders.add("Content-Type", "application/json")
              exchange.sendResponseHeaders(500, errorString.getBytes.length)
              
              val os = exchange.getResponseBody
              os.write(errorString.getBytes)
              os.close()
          }
          
        } catch {
          case ex: Exception =>
            val errorResponse = Json.obj(
              "error" -> ex.getMessage,
              "status" -> "error"
            )
            
            val errorString = Json.stringify(errorResponse)
            exchange.getResponseHeaders.add("Content-Type", "application/json")
            exchange.sendResponseHeaders(500, errorString.getBytes.length)
            
            val os = exchange.getResponseBody
            os.write(errorString.getBytes)
            os.close()
        }
      } else {
        exchange.sendResponseHeaders(405, 0)
      }
      exchange.close()
    }
  }
  
  class HealthHandler extends HttpHandler {
    override def handle(exchange: HttpExchange): Unit = {
      exchange.getResponseHeaders.add("Access-Control-Allow-Origin", "*")
      exchange.getResponseHeaders.add("Content-Type", "application/json")
      
      val response = Json.obj(
        "status" -> "healthy",
        "service" -> "Watson ML Research Agent (Scala)"
      )
      
      val responseString = Json.stringify(response)
      exchange.sendResponseHeaders(200, responseString.getBytes.length)
      
      val os = exchange.getResponseBody
      os.write(responseString.getBytes)
      os.close()
      exchange.close()
    }
  }
  
  def main(args: Array[String]): Unit = {
    val config = Config.load()
    val client = new WatsonMLClient(config)
    
    val server = HttpServer.create(new InetSocketAddress(config.port), 0)
    server.createContext("/health", new HealthHandler())
    server.createContext("/research", new ResearchHandler(client))
    
    server.start()
    println(s"Scala Research Agent server running on port ${config.port}")
  }
}
