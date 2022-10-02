

/**

 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.TestSuite;

import uim.cake.core.HttpApplicationInterface;
import uim.cake.core.PluginApplicationInterface;
import uim.cake.Http\FlashMessage;
import uim.cake.Http\Server;
import uim.cake.Http\ServerRequest;
import uim.cake.Http\ServerRequestFactory;
import uim.cake.Routing\Router;
import uim.cake.Routing\RoutingApplicationInterface;
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
     * @var \Cake\Core\HttpApplicationInterface
     */
    protected $app;

    /**
     * Constructor
     *
     * @param \Cake\Core\HttpApplicationInterface $app The test case to run.
     */
    this(HttpApplicationInterface $app)
    {
        this.app = $app;
    }

    /**
     * Resolve the provided URL into a string.
     *
     * @param array|string myUrl The URL array/string to resolve.
     * @return string
     */
    function resolveUrl(myUrl): string
    {
        // If we need to resolve a Route URL but there are no routes, load routes.
        if (is_array(myUrl) && count(Router::getRouteCollection().routes()) === 0) {
            return this.resolveRoute(myUrl);
        }

        return Router::url(myUrl);
    }

    /**
     * Convert a URL array into a string URL via routing.
     *
     * @param array myUrl The url to resolve
     * @return string
     */
    protected auto resolveRoute(array myUrl): string
    {
        // Simulate application bootstrap and route loading.
        // We need both to ensure plugins are loaded.
        this.app.bootstrap();
        if (this.app instanceof PluginApplicationInterface) {
            this.app.pluginBootstrap();
        }
        myBuilder = Router::createRouteBuilder('/');

        if (this.app instanceof RoutingApplicationInterface) {
            this.app.routes(myBuilder);
        }
        if (this.app instanceof PluginApplicationInterface) {
            this.app.pluginRoutes(myBuilder);
        }

        $out = Router::url(myUrl);
        Router::resetRoutes();

        return $out;
    }

    /**
     * Create a PSR7 request from the request spec.
     *
     * @param array<string, mixed> $spec The request spec.
     * @return \Cake\Http\ServerRequest
     */
    protected auto _createRequest(array $spec): ServerRequest
    {
        if (isset($spec['input'])) {
            $spec['post'] = [];
            $spec['environment']['CAKEPHP_INPUT'] = $spec['input'];
        }
        $environment = array_merge(
            array_merge($_SERVER, ['REQUEST_URI' => $spec['url']]),
            $spec['environment']
        );
        if (strpos($environment['PHP_SELF'], 'phpunit') !== false) {
            $environment['PHP_SELF'] = '/';
        }
        myRequest = ServerRequestFactory::fromGlobals(
            $environment,
            $spec['query'],
            $spec['post'],
            $spec['cookies'],
            $spec['files']
        );
        myRequest = myRequest
            .withAttribute('session', $spec['session'])
            .withAttribute('flash', new FlashMessage($spec['session']));

        return myRequest;
    }

    /**
     * Run a request and get the response.
     *
     * @param array<string, mixed> myRequestSpec The request spec to execute.
     * @return \Psr\Http\Message\IResponse The generated response.
     * @throws \LogicException
     */
    auto execute(array myRequestSpec): IResponse
    {
        $server = new Server(this.app);

        return $server.run(this._createRequest(myRequestSpec));
    }
}
