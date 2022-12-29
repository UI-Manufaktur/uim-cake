module uim.cake.https;

use Psr\Http\messages.IResponse;
use Psr\Http\messages.IServerRequest;

/**
 * Factory method for building controllers from request/response pairs.
 *
 * @template TController
 */
interface IControllerFactory
{
    /**
     * Create a controller for a given request
     *
     * @param \Psr\Http\messages.IServerRequest myRequest The request to build a controller for.
     * @return mixed
     * @throws uim.cake.http.exceptions.MissingControllerException
     * @psalm-return TController
     */
    function create(IServerRequest myRequest);

    /**
     * Invoke a controller"s action and wrapping methods.
     *
     * @param mixed $controller The controller to invoke.
     * @return \Psr\Http\messages.IResponse The response
     * @psalm-param TController $controller
     */
    function invoke($controller): IResponse;
}
