/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.auth;

@safe:
import uim.cake;

/**
 * An authorization adapter for AuthComponent. Provides the ability to authorize
 * using a controller callback. Your controller"s isAuthorized() method should
 * return a boolean to indicate whether the user is authorized.
 *
 * ```
 *  function isAuthorized(myUser)
 *  {
 *      if (this.request.getParam("admin")) {
 *          return myUser["role"] == "admin";
 *      }
 *      return !empty(myUser);
 *  }
 * ```
 *
 * The above is simple implementation that would only authorize users of the
 * "admin" role to access admin routing.
 *
 * @see uim.cake.controllers.Component\AuthComponent::$authenticate
 */
class ControllerAuthorize : BaseAuthorize {
    // Controller for the request.
    protected Controller _Controller;

    this(ComponentRegistry $registry, array myConfig = []) {
        super.this($registry, myConfig);
        this.controller($registry.getController());
    }

    /**
     * Get/set the controller this authorize object will be working with. Also
     * checks that isAuthorized is implemented.
     *
     * @param uim.cake.Controller\Controller|null $controller null to get, a controller to set.
     * @return uim.cake.Controller\Controller
     */
    Controller controller(?Controller $controller = null) {
        if ($controller) {
            _Controller = $controller;
        }

        return _Controller;
    }

    /**
     * Checks user authorization using a controller callback.
     *
     * @param \ArrayAccess|array myUser Active user data
     * @param uim.cake.Http\ServerRequest myRequest Request instance.
     * @throws uim.cake.Core\Exception\CakeException If controller does not have method `isAuthorized()`.
     */
    bool authorize(myUser, ServerRequest myRequest) {
        if (!method_exists(_Controller, "isAuthorized")) {
            throw new CakeException(sprintf(
                "%s does not implement an isAuthorized() method.",
                get_class(_Controller)
            ));
        }

        return (bool)_Controller.isAuthorized(myUser);
    }
}
