


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Http;

import uim.cake.Core\IHttpApplication;
use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;

/**
 * Base class for standalone HTTP applications
 *
 * Provides a base class to inherit from for applications using
 * only the http package. This class defines a fallback handler
 * that renders a simple 404 response.
 *
 * You can overload the `handle` method to provide your own logic
 * to run when no middleware generates a response.
 */
abstract class MiddlewareApplication : IHttpApplication
{
    /**
     * @inheritDoc
     */
    abstract function bootstrap(): void;

    /**
     * @inheritDoc
     */
    abstract function middleware(MiddlewareQueue $middlewareQueue): MiddlewareQueue;

    /**
     * Generate a 404 response as no middleware handled the request.
     *
     * @param \Psr\Http\Message\IServerRequest $request The request
     * @return \Psr\Http\Message\IResponse
     */
    function handle(
        IServerRequest $request
    ): IResponse {
        return new Response(["body": "Not found", "status": 404]);
    }
}
