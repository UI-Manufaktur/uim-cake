


 *


 * @since         2.0.0
  */
module uim.cake.Auth;

import uim.cake.controllers.ComponentRegistry;
import uim.cake.core.InstanceConfigTrait;
import uim.cake.http.ServerRequest;

/**
 * Abstract base authorization adapter for AuthComponent.
 *
 * @see uim.cake.controllers.Component\AuthComponent::$authenticate
 */
abstract class BaseAuthorize
{
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
    public this(ComponentRegistry $registry, array $config = []) {
        _registry = $registry;
        this.setConfig($config);
    }

    /**
     * Checks user authorization.
     *
     * @param \ArrayAccess|array $user Active user data
     * @param uim.cake.http.ServerRequest $request Request instance.
     * @return bool
     */
    abstract bool authorize($user, ServerRequest $request);
}
