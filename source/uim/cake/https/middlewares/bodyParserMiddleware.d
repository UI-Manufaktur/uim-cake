module uim.cake.https\Middleware;

@safe:
import uim.cake

/**
 * Parse encoded request body data.
 *
 * Enables JSON and XML request payloads to be parsed into the request"s body.
 * You can also add your own request body parsers using the `addParser()` method.
 */
class BodyParserMiddleware : IMiddleware
{
    /**
     * Registered Parsers
     *
     * @var array<\Closure>
     */
    protected parsers = null;

    /**
     * The HTTP methods to parse data on.
     *
     * @var array<string>
     */
    protected methods = ["PUT", "POST", "PATCH", "DELETE"];

    /**
     * Constructor
     *
     * ### Options
     *
     * - `json` Set to false to disable JSON body parsing.
     * - `xml` Set to true to enable XML parsing. Defaults to false, as XML
     *   handling requires more care than JSON does.
     * - `methods` The HTTP methods to parse on. Defaults to PUT, POST, PATCH DELETE.
     *
     * @param array<string, mixed> myOptions The options to use. See above.
     */
    this(array myOptions = null) {
        myOptions += ["json":true, "xml":false, "methods":null];
        if (myOptions["json"]) {
            this.addParser(
                ["application/json", "text/json"],
                Closure::fromCallable([this, "decodeJson"])
            );
        }
        if (myOptions["xml"]) {
            this.addParser(
                ["application/xml", "text/xml"],
                Closure::fromCallable([this, "decodeXml"])
            );
        }
        if (myOptions["methods"]) {
            this.setMethods(myOptions["methods"]);
        }
    }

    /**
     * Set the HTTP methods to parse request bodies on.
     *
     * @param array<string> $methods The methods to parse data on.
     * @return this
     */
    auto setMethods(array $methods) {
        this.methods = $methods;

        return this;
    }

    /**
     * Get the HTTP methods to parse request bodies on.
     *
     * @return array<string>
     */
    array getMethods() {
        return this.methods;
    }

    /**
     * Add a parser.
     *
     * Map a set of content-type header values to be parsed by the $parser.
     *
     * ### Example
     *
     * An naive CSV request body parser could be built like so:
     *
     * ```
     * $parser.addParser(["text/csv"], function ($body) {
     *   return str_getcsv($body);
     * });
     * ```
     *
     * @param array<string> myTypes An array of content-type header values to match. eg. application/json
     * @param \Closure $parser The parser function. Must return an array of data to be inserted
     *   into the request.
     * @return this
     */
    function addParser(array myTypes, Closure $parser) {
        foreach (myTypes as myType) {
            myType = strtolower(myType);
            this.parsers[myType] = $parser;
        }

        return this;
    }

    /**
     * Get the current parsers
     *
     * @return array<\Closure>
     */
    array getParsers() {
        return this.parsers;
    }

    /**
     * Apply the middleware.
     *
     * Will modify the request adding a parsed body if the content-type is known.
     *
     * @param \Psr\Http\messages.IServerRequest myRequest The request.
     * @param \Psr\Http\servers.IRequestHandler $handler The request handler.
     * @return \Psr\Http\messages.IResponse A response.
     */
    function process(IServerRequest myRequest, IRequestHandler $handler): IResponse
    {
        if (!hasAllValues(myRequest.getMethod(), this.methods, true)) {
            return $handler.handle(myRequest);
        }
        [myType] = explode(";", myRequest.getHeaderLine("Content-Type"));
        myType = strtolower(myType);
        if (!isset(this.parsers[myType])) {
            return $handler.handle(myRequest);
        }

        $parser = this.parsers[myType];
        myResult = $parser(myRequest.getBody().getContents());
        if (!is_array(myResult)) {
            throw new BadRequestException();
        }
        myRequest = myRequest.withParsedBody(myResult);

        return $handler.handle(myRequest);
    }

    /**
     * Decode JSON into an array.
     *
     * @param string body The request body to decode
     * @return array|null
     */
    protected auto decodeJson(string body) {
      if ($body == "") {
          return [];
      }
      $decoded = json_decode($body, true);
      if (json_last_error() == JSON_ERROR_NONE) {
          return (array)$decoded;
      }

      return null;
    }

    /**
     * Decode XML into an array.
     *
     * @param string body The request body to decode
     * @return array
     */
    protected array decodeXml(string body) {
      try {
        $xml = Xml::build($body, ["return":"domdocument", "readFile":false]);
        // We might not get child nodes if there are nested inline entities.
        if ((int)$xml.childNodes.length > 0) {
            return Xml::toArray($xml);
        }

        return [];
      } catch (XmlException $e) {
          return [];
      }
    }
}
