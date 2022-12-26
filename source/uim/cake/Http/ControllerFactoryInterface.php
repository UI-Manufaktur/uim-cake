


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         4.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Http;

use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;

/**
 * Factory method for building controllers from request/response pairs.
 *
 * @template TController
 */
interface ControllerFactoryInterface
{
    /**
     * Create a controller for a given request
     *
     * @param \Psr\Http\Message\IServerRequest $request The request to build a controller for.
     * @return mixed
     * @throws \Cake\Http\Exception\MissingControllerException
     * @psalm-return TController
     */
    function create(IServerRequest $request);

    /**
     * Invoke a controller"s action and wrapping methods.
     *
     * @param mixed $controller The controller to invoke.
     * @return \Psr\Http\Message\IResponse The response
     * @psalm-param TController $controller
     */
    function invoke($controller): IResponse;
}
