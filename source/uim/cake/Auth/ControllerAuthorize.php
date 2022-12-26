


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         2.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Auth;

import uim.cake.Controller\ComponentRegistry;
import uim.cake.Controller\Controller;
import uim.cake.cores.Exception\CakeException;
import uim.cake.Http\ServerRequest;

/**
 * An authorization adapter for AuthComponent. Provides the ability to authorize
 * using a controller callback. Your controller"s isAuthorized() method should
 * return a boolean to indicate whether the user is authorized.
 *
 * ```
 *  function isAuthorized($user)
 *  {
 *      if (this.request.getParam("admin")) {
 *          return $user["role"] == "admin";
 *      }
 *      return !empty($user);
 *  }
 * ```
 *
 * The above is simple implementation that would only authorize users of the
 * "admin" role to access admin routing.
 *
 * @see \Cake\Controller\Component\AuthComponent::$authenticate
 */
class ControllerAuthorize : BaseAuthorize
{
    /**
     * Controller for the request.
     *
     * @var \Cake\Controller\Controller
     */
    protected $_Controller;

    /**
     * @inheritDoc
     */
    public this(ComponentRegistry $registry, array $config = []) {
        super(($registry, $config);
        this.controller($registry.getController());
    }

    /**
     * Get/set the controller this authorize object will be working with. Also
     * checks that isAuthorized is implemented.
     *
     * @param \Cake\Controller\Controller|null $controller null to get, a controller to set.
     * @return \Cake\Controller\Controller
     */
    function controller(?Controller $controller = null): Controller
    {
        if ($controller) {
            _Controller = $controller;
        }

        return _Controller;
    }

    /**
     * Checks user authorization using a controller callback.
     *
     * @param \ArrayAccess|array $user Active user data
     * @param \Cake\Http\ServerRequest $request Request instance.
     * @throws \Cake\Core\Exception\CakeException If controller does not have method `isAuthorized()`.
     * @return bool
     */
    function authorize($user, ServerRequest $request): bool
    {
        if (!method_exists(_Controller, "isAuthorized")) {
            throw new CakeException(sprintf(
                "%s does not implement an isAuthorized() method.",
                get_class(_Controller)
            ));
        }

        return (bool)_Controller.isAuthorized($user);
    }
}
