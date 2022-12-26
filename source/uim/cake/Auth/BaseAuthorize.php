


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         2.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Auth;

import uim.cake.Controller\ComponentRegistry;
import uim.cake.Core\InstanceConfigTrait;
import uim.cake.Http\ServerRequest;

/**
 * Abstract base authorization adapter for AuthComponent.
 *
 * @see \Cake\Controller\Component\AuthComponent::$authenticate
 */
abstract class BaseAuthorize
{
    use InstanceConfigTrait;

    /**
     * ComponentRegistry instance for getting more components.
     *
     * @var \Cake\Controller\ComponentRegistry
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
     * @param \Cake\Controller\ComponentRegistry $registry The controller for this request.
     * @param array<string, mixed> $config An array of config. This class does not use any config.
     */
    public this(ComponentRegistry $registry, array $config = [])
    {
        _registry = $registry;
        this.setConfig($config);
    }

    /**
     * Checks user authorization.
     *
     * @param \ArrayAccess|array $user Active user data
     * @param \Cake\Http\ServerRequest $request Request instance.
     * @return bool
     */
    abstract function authorize($user, ServerRequest $request): bool;
}
