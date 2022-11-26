

/**
 * UIM(tm) : Rapid Development Framework (http://UIM.org)
 * Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 * @link          http://UIM.org UIM(tm) Project
 * @since         4.0.0
 * @license       http://www.opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.https\Middleware;

import uim.cake.core.Configure;
import uim.cake.https\Exception\BadRequestException;
use Laminas\Diactoros\Response\RedirectResponse;
use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;

/**
 * Enforces use of HTTPS (SSL) for requests.
 */
class HttpsEnforcerMiddleware : MiddlewareInterface
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
     *
     * @var array<string, mixed>
     */
    protected myConfig = [
        "redirect":true,
        "statusCode":301,
        "headers":[],
        "disableOnDebug":true,
    ];

    /**
     * Constructor
     *
     * @param array<string, mixed> myConfig The options to use.
     * @see \Cake\Http\Middleware\HttpsEnforcerMiddleware::myConfig
     */
    this(array myConfig = []) {
        this.config = myConfig + this.config;
    }

    /**
     * Check whether request has been made using HTTPS.
     *
     * Depending on the configuration and request method, either redirects to
     * same URL with https or throws an exception.
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The request.
     * @param \Psr\Http\Server\RequestHandlerInterface $handler The request handler.
     * @return \Psr\Http\Message\IResponse A response.
     * @throws \Cake\Http\Exception\BadRequestException
     */
    function process(IServerRequest myRequest, RequestHandlerInterface $handler): IResponse
    {
        if (
            myRequest.getUri().getScheme() === "https"
            || (this.config["disableOnDebug"]
                && Configure::read("debug"))
        ) {
            return $handler.handle(myRequest);
        }

        if (this.config["redirect"] && myRequest.getMethod() === "GET") {
            $uri = myRequest.getUri().withScheme("https");
            $base = myRequest.getAttribute("base");
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
}
