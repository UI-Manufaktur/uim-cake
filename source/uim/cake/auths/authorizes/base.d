/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.auths.baseauthorize;

@safe:
import uim.cake;

/**
 * Abstract base authorization adapter for AuthComponent.
 *
 * @see uim.cake.controllers.components.AuthComponent::$authenticate
 */
abstract class BaseAuthorize {
    use InstanceConfigTrait;

    /**
     * ComponentRegistry instance for getting more components.
     *
     * @var uim.cake.controllers.ComponentRegistry
     */
    protected $_registry;

    /**
     * Default config for authorize objects.
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [];

    /**
     * Constructor
     *
     * @param uim.cake.controllers.ComponentRegistry $registry The controller for this request.
     * @param array<string, mixed> $config An array of config. This class does not use any config.
     */
    this(ComponentRegistry $registry, Json aConfig = []) {
        _registry = $registry;
        this.setConfig($config);
    }

    /**
     * Checks user authorization.
     *
     * @param \ArrayAccess|array $user Active user data
     * @param uim.cake.http.ServerRequest myServerRequest Request instance.
     * @return bool
     */
    abstract bool authorize($user, ServerRequest myServerRequest);
}
