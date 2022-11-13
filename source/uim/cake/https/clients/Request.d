module uim.cake.https.clients;

use Laminas\Diactoros\RequestTrait;
use Laminas\Diactoros\Stream;
use Psr\Http\Message\RequestInterface;

/**
 * : methods for HTTP requests.
 *
 * Used by Cake\Http\Client to contain request information
 * for making requests.
 */
class Request : Message : RequestInterface
{
    use RequestTrait;

    /**
     * Constructor
     *
     * Provides backwards compatible defaults for some properties.
     *
     * @phpstan-param array<non-empty-string, non-empty-string> $headers
     * @param string myUrl The request URL
     * @param string $method The HTTP method to use.
     * @param array $headers The HTTP headers to set.
     * @param array|string|null myData The request body to use.
     */
    this(string myUrl = "", string $method = self::METHOD_GET, array $headers = [], myData = null) {
        this.setMethod($method);
        this.uri = this.createUri(myUrl);
        $headers += [
            "Connection" => "close",
            "User-Agent" => ini_get("user_agent") ?: "CakePHP",
        ];
        this.addHeaders($headers);

        if (myData === null) {
            this.stream = new Stream("php://memory", "rw");
        } else {
            this.setContent(myData);
        }
    }

    /**
     * Add an array of headers to the request.
     *
     * @phpstan-param array<non-empty-string, non-empty-string> $headers
     * @param array<string, string> $headers The headers to add.
     * @return void
     */
    protected auto addHeaders(array $headers): void
    {
        foreach ($headers as myKey => $val) {
            $normalized = strtolower(myKey);
            this.headers[myKey] = (array)$val;
            this.headerNames[$normalized] = myKey;
        }
    }

    /**
     * Set the body/payload for the message.
     *
     * Array data will be serialized with {@link \Cake\Http\FormData},
     * and the content-type will be set.
     *
     * @param array|string myContents The body for the request.
     * @return this
     */
    protected auto setContent(myContents) {
        if (is_array(myContents)) {
            $formData = new FormData();
            $formData.addMany(myContents);
            /** @phpstan-var array<non-empty-string, non-empty-string> $headers */
            $headers = ["Content-Type" => $formData.contentType()];
            this.addHeaders($headers);
            myContents = (string)$formData;
        }

        $stream = new Stream("php://memory", "rw");
        $stream.write(myContents);
        this.stream = $stream;

        return this;
    }
}
