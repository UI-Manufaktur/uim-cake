/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.https\Middleware;

@safe:
import uim.cake;

// Enforces use of HTTPS (SSL) for requests.
class HttpsEnforcerMiddleware : IMiddleware {
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
     * @see uim.cake.http.Middleware\HttpsEnforcerMiddleware::myConfig
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
     * @param \Psr\Http\messages.IServerRequest myRequest The request.
     * @param \Psr\Http\servers.IRequestHandler $handler The request handler.
     * @return \Psr\Http\messages.IResponse A response.
     * @throws uim.cake.http.exceptions.BadRequestException
     */
    IResponse process(IServerRequest myRequest, IRequestHandler $handler) {
      if (
          myRequest.getUri().getScheme() == "https"
          || (this.config["disableOnDebug"]
              && Configure::read("debug"))
      ) {
          return $handler.handle(myRequest);
      }

      if (this.config["redirect"] && myRequest.getMethod() == "GET") {
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
