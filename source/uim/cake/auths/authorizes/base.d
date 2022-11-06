module uim.caketh;

@safe:
import uim.cake

/* import uim.cakentrollers.componentsRegistry;
import uim.cakere.InstanceConfigTrait;
import uim.caketps\ServerRequest;
 */
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
