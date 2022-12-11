/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.auths.authorizes.base;

@safe:
import uim.cake

/**
 * Abstract base authorization adapter for AuthComponent.
 *
 * @see \Cake\Controller\Component\AuthComponent::$authenticate
 */
abstract class BaseAuthorize {
    // ComponentRegistry instance for getting more components.
    protected ComponentRegistry _registry;

    /**
     * Default config for authorize objects.
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [];

    /**
     * Constructor
     *
     * @param \Cake\Controller\ComponentRegistry $registry The controller for this request.
     * @param array<string, mixed> myConfig An array of config. This class does not use any config.
     */
    this(ComponentRegistry $registry, array myConfig = []) {
        this._registry = $registry;
        this.setConfig(myConfig);
    }

    /**
     * Checks user authorization.
     *
     * @param \ArrayAccess|array myUser Active user data
     * @param \Cake\Http\ServerRequest myRequest Request instance.
     */
    abstract bool authorize(myUser, ServerRequest myRequest);
}
