

/**
 * CakePHP(tm) : Rapid Development Framework (http://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 * @link          http://cakephp.org CakePHP(tm) Project
 * @since         3.6.0
 * @license       http://www.opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.Http\Middleware;

import uim.baklava.Http\Exception\BadRequestException;
import uim.baklava.utikities.Exception\XmlException;
import uim.baklava.utikities.Xml;
use Closure;
use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;

/**
 * Parse encoded request body data.
 *
 * Enables JSON and XML request payloads to be parsed into the request's body.
 * You can also add your own request body parsers using the `addParser()` method.
 */
class BodyParserMiddleware : MiddlewareInterface
{
    /**
     * Registered Parsers
     *
     * @var array<\Closure>
     */
    protected $parsers = [];

    /**
     * The HTTP methods to parse data on.
     *
     * @var array<string>
     */
    protected $methods = ['PUT', 'POST', 'PATCH', 'DELETE'];

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
    this(array myOptions = []) {
        myOptions += ['json' => true, 'xml' => false, 'methods' => null];
        if (myOptions['json']) {
            this.addParser(
                ['application/json', 'text/json'],
                Closure::fromCallable([this, 'decodeJson'])
            );
        }
        if (myOptions['xml']) {
            this.addParser(
                ['application/xml', 'text/xml'],
                Closure::fromCallable([this, 'decodeXml'])
            );
        }
        if (myOptions['methods']) {
            this.setMethods(myOptions['methods']);
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
    auto getMethods(): array
    {
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
     * $parser.addParser(['text/csv'], function ($body) {
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
    auto getParsers(): array
    {
        return this.parsers;
    }

    /**
     * Apply the middleware.
     *
     * Will modify the request adding a parsed body if the content-type is known.
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The request.
     * @param \Psr\Http\Server\RequestHandlerInterface $handler The request handler.
     * @return \Psr\Http\Message\IResponse A response.
     */
    function process(IServerRequest myRequest, RequestHandlerInterface $handler): IResponse
    {
        if (!in_array(myRequest.getMethod(), this.methods, true)) {
            return $handler.handle(myRequest);
        }
        [myType] = explode(';', myRequest.getHeaderLine('Content-Type'));
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
     * @param string $body The request body to decode
     * @return array|null
     */
    protected auto decodeJson(string $body) {
        if ($body === '') {
            return [];
        }
        $decoded = json_decode($body, true);
        if (json_last_error() === JSON_ERROR_NONE) {
            return (array)$decoded;
        }

        return null;
    }

    /**
     * Decode XML into an array.
     *
     * @param string $body The request body to decode
     * @return array
     */
    protected auto decodeXml(string $body): array
    {
        try {
            $xml = Xml::build($body, ['return' => 'domdocument', 'readFile' => false]);
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
