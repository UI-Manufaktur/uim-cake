module uim.caketh;

@safe:
import uim.cake

/* import uim.cakentrollers.componentsRegistry;
import uim.cakentroller\Controller;
import uim.cakere.exceptions\CakeException;
import uim.caketps\ServerRequest;
 */
/**
 * An authorization adapter for AuthComponent. Provides the ability to authorize
 * using a controller callback. Your controller's isAuthorized() method should
 * return a boolean to indicate whether the user is authorized.
 *
 * ```
 *  function isAuthorized(myUser)
 *  {
 *      if (this.request.getParam('admin')) {
 *          return myUser['role'] === 'admin';
 *      }
 *      return !empty(myUser);
 *  }
 * ```
 *
 * The above is simple implementation that would only authorize users of the
 * 'admin' role to access admin routing.
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


    this(ComponentRegistry $registry, array myConfig = []) {
        super.this($registry, myConfig);
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
            this._Controller = $controller;
        }

        return this._Controller;
    }

    /**
     * Checks user authorization using a controller callback.
     *
     * @param \ArrayAccess|array myUser Active user data
     * @param \Cake\Http\ServerRequest myRequest Request instance.
     * @throws \Cake\Core\Exception\CakeException If controller does not have method `isAuthorized()`.
     */
    bool authorize(myUser, ServerRequest myRequest) {
        if (!method_exists(this._Controller, 'isAuthorized')) {
            throw new CakeException(sprintf(
                '%s does not implement an isAuthorized() method.',
                get_class(this._Controller)
            ));
        }

        return (bool)this._Controller.isAuthorized(myUser);
    }
}