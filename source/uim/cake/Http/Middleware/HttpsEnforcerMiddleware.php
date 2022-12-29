
module uim.cake.http.Middleware;

import uim.cake.core.Configure;
import uim.cake.http.exceptions.BadRequestException;
use Laminas\Diactoros\Response\RedirectResponse;
use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;
use Psr\Http\Server\IMiddleware;
use Psr\Http\Server\RequestHandlerInterface;
use UnexpectedValueException;

/**
 * Enforces use of HTTPS (SSL) for requests.
 */
class HttpsEnforcerMiddleware : IMiddleware
{
    /**
     * Configuration.
     *
     * ### Options
     *
     * - `redirect` - If set to true (default) redirects GET requests to same URL with https.
     * - `statusCode` - Status code to use in case of redirect, defaults to 301 - Permanent redirect.
     * - `headers` - Array of response headers in case of redirect.
     * - `disableOnDebug` - Whether HTTPS check should be disabled when debug is on. Default `true`.
     * - "hsts" - Strict-Transport-Security header for HTTPS response configuration. Defaults to `null`.
     *    If enabled, an array of config options:
     *
     *        - "maxAge" - `max-age` directive value in seconds.
     *        - "includeSubDomains" - Whether to include `includeSubDomains` directive. Defaults to `false`.
     *        - "preload" - Whether to include "preload" directive. Defauls to `false`.
     *
     * @var array<string, mixed>
     */
    protected $config = [
        "redirect": true,
        "statusCode": 301,
        "headers": [],
        "disableOnDebug": true,
        "hsts": null,
    ];

    /**
     * Constructor
     *
     * @param array<string, mixed> $config The options to use.
     * @see uim.cake.http.Middleware\HttpsEnforcerMiddleware::$config
     */
    this(array $config = []) {
        this.config = $config + this.config;
    }

    /**
     * Check whether request has been made using HTTPS.
     *
     * Depending on the configuration and request method, either redirects to
     * same URL with https or throws an exception.
     *
     * @param \Psr\Http\Message\IServerRequest $request The request.
     * @param \Psr\Http\Server\RequestHandlerInterface $handler The request handler.
     * @return \Psr\Http\Message\IResponse A response.
     * @throws uim.cake.http.exceptions.BadRequestException
     */
    function process(IServerRequest $request, RequestHandlerInterface $handler): IResponse
    {
        if (
            $request.getUri().getScheme() == "https"
            || (this.config["disableOnDebug"]
                && Configure::read("debug"))
        ) {
            $response = $handler.handle($request);
            if (this.config["hsts"]) {
                $response = this.addHsts($response);
            }

            return $response;
        }

        if (this.config["redirect"] && $request.getMethod() == "GET") {
            $uri = $request.getUri().withScheme("https");
            $base = $request.getAttribute("base");
            if ($base) {
                $uri = $uri.withPath($base . $uri.getPath());
            }

            return new RedirectResponse(
                $uri,
                this.config["statusCode"],
                this.config["headers"]
            );
        }

        throw new BadRequestException(
            "Requests to this URL must be made with HTTPS."
        );
    }

    /**
     * Adds Strict-Transport-Security header to response.
     *
     * @param \Psr\Http\Message\IResponse $response Response
     * @return \Psr\Http\Message\IResponse
     */
    protected function addHsts(IResponse $response): IResponse
    {
        $config = this.config["hsts"];
        if (!is_array($config)) {
            throw new UnexpectedValueException("The `hsts` config must be an array.");
        }

        $value = "max-age=" . $config["maxAge"];
        if ($config["includeSubDomains"] ?? false) {
            $value .= "; includeSubDomains";
        }
        if ($config["preload"] ?? false) {
            $value .= "; preload";
        }

        return $response.withHeader("strict-transport-security", $value);
    }
}
