module uim.cake.https;

use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;

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
     * @param \Psr\Http\Message\IServerRequest myRequest The request to build a controller for.
     * @return mixed
     * @throws uim.cake.Http\Exception\MissingControllerException
     * @psalm-return TController
     */
    function create(IServerRequest myRequest);

    /**
     * Invoke a controller"s action and wrapping methods.
     *
     * @param mixed $controller The controller to invoke.
     * @return \Psr\Http\Message\IResponse The response
     * @psalm-param TController $controller
     */
    function invoke($controller): IResponse;
}
