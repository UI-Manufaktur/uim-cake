

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *

 * @since         3.3.0
  */
module uim.cake.TestSuite;

import uim.cake.core.IHttpApplication;
import uim.cake.core.IPluginApplication;
import uim.cake.http.FlashMessage;
import uim.cake.http.Server;
import uim.cake.http.ServerRequest;
import uim.cake.http.ServerRequestFactory;
import uim.cake.Routing\Router;
import uim.cake.Routing\IRoutingApplication;
use Psr\Http\Message\IResponse;

/**
 * Dispatches a request capturing the response for integration
 * testing purposes into the Cake\Http stack.
 *
 * @internal
 */
class MiddlewareDispatcher
{
    /**
     * The application that is being dispatched.
     *
     * @var uim.cake.Core\IHttpApplication
     */
    protected $app;

    /**
     * Constructor
     *
     * @param uim.cake.Core\IHttpApplication $app The test case to run.
     */
    this(IHttpApplication $app) {
        this.app = $app;
    }

    /**
     * Resolve the provided URL into a string.
     *
     * @param array|string $url The URL array/string to resolve.
     * @return string
     */
    string resolveUrl($url): string
    {
        // If we need to resolve a Route URL but there are no routes, load routes.
        if (is_array($url) && count(Router::getRouteCollection().routes()) == 0) {
            return this.resolveRoute($url);
        }

        return Router::url($url);
    }

    /**
     * Convert a URL array into a string URL via routing.
     *
     * @param array $url The url to resolve
     * @return string
     */
    protected function resolveRoute(array $url): string
    {
        // Simulate application bootstrap and route loading.
        // We need both to ensure plugins are loaded.
        this.app.bootstrap();
        if (this.app instanceof IPluginApplication) {
            this.app.pluginBootstrap();
        }
        $builder = Router::createRouteBuilder("/");

        if (this.app instanceof IRoutingApplication) {
            this.app.routes($builder);
        }
        if (this.app instanceof IPluginApplication) {
            this.app.pluginRoutes($builder);
        }

        $out = Router::url($url);
        Router::resetRoutes();

        return $out;
    }

    /**
     * Create a PSR7 request from the request spec.
     *
     * @param array<string, mixed> $spec The request spec.
     * @return uim.cake.http.ServerRequest
     */
    protected function _createRequest(array $spec): ServerRequest
    {
        if (isset($spec["input"])) {
            $spec["post"] = [];
            $spec["environment"]["CAKEPHP_INPUT"] = $spec["input"];
        }
        $environment = array_merge(
            array_merge($_SERVER, ["REQUEST_URI": $spec["url"]]),
            $spec["environment"]
        );
        if (strpos($environment["PHP_SELF"], "phpunit") != false) {
            $environment["PHP_SELF"] = "/";
        }
        $request = ServerRequestFactory::fromGlobals(
            $environment,
            $spec["query"],
            $spec["post"],
            $spec["cookies"],
            $spec["files"]
        );

        return $request
            .withAttribute("session", $spec["session"])
            .withAttribute("flash", new FlashMessage($spec["session"]));
    }

    /**
     * Run a request and get the response.
     *
     * @param array<string, mixed> $requestSpec The request spec to execute.
     * @return \Psr\Http\Message\IResponse The generated response.
     * @throws \LogicException
     */
    function execute(array $requestSpec): IResponse
    {
        $server = new Server(this.app);

        return $server.run(_createRequest($requestSpec));
    }
}
