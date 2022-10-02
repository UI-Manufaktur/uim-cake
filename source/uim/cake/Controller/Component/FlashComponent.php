module uim.cake.controller\Component;

import uim.cake.controller\Component;
import uim.cake.Http\Exception\InternalErrorException;
import uim.cake.Http\FlashMessage;
import uim.cake.Utility\Inflector;
use Throwable;

/**
 * The CakePHP FlashComponent provides a way for you to write a flash variable
 * to the session from your controllers, to be rendered in a view with the
 * FlashHelper.
 *
 * @method void success(string myMessage, array myOptions = []) Set a message using "success" element
 * @method void error(string myMessage, array myOptions = []) Set a message using "error" element
 */
class FlashComponent : Component
{
    /**
     * Default configuration
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        'key' => 'flash',
        'element' => 'default',
        'params' => [],
        'clear' => false,
        'duplicate' => true,
    ];

    /**
     * Used to set a session variable that can be used to output messages in the view.
     * If you make consecutive calls to this method, the messages will stack (if they are
     * set with the same flash key)
     *
     * In your controller: this.Flash.set('This has been saved');
     *
     * ### Options:
     *
     * - `key` The key to set under the session's Flash key
     * - `element` The element used to render the flash message. Default to 'default'.
     * - `params` An array of variables to make available when using an element
     * - `clear` A bool stating if the current stack should be cleared to start a new one
     * - `escape` Set to false to allow templates to print out HTML content
     *
     * @param \Throwable|string myMessage Message to be flashed. If an instance
     *   of \Throwable the throwable message will be used and code will be set
     *   in params.
     * @param array<string, mixed> myOptions An array of options
     * @return void
     */
    auto set(myMessage, array myOptions = []): void
    {
        if (myMessage instanceof Throwable) {
            this.flash().setExceptionMessage(myMessage, myOptions);
        } else {
            this.flash().set(myMessage, myOptions);
        }
    }

    /**
     * Get flash message utility instance.
     *
     * @return \Cake\Http\FlashMessage
     */
    protected auto flash(): FlashMessage
    {
        return this.getController().getRequest().getFlash();
    }

    /**
     * Proxy method to FlashMessage instance.
     *
     * @param array<string, mixed>|string myKey The key to set, or a complete array of configs.
     * @param mixed|null myValue The value to set.
     * @param bool myMerge Whether to recursively merge or overwrite existing config, defaults to true.
     * @return this
     * @throws \Cake\Core\Exception\CakeException When trying to set a key that is invalid.
     */
    auto setConfig(myKey, myValue = null, myMerge = true)
    {
        this.flash().setConfig(myKey, myValue, myMerge);

        return this;
    }

    /**
     * Proxy method to FlashMessage instance.
     *
     * @param string|null myKey The key to get or null for the whole config.
     * @param mixed $default The return value when the key does not exist.
     * @return mixed Configuration data at the named key or null if the key does not exist.
     */
    auto getConfig(?string myKey = null, $default = null)
    {
        return this.flash().getConfig(myKey, $default);
    }

    /**
     * Proxy method to FlashMessage instance.
     *
     * @param string myKey The key to get.
     * @return mixed Configuration data at the named key
     * @throws \InvalidArgumentException
     */
    auto getConfigOrFail(string myKey)
    {
        return this.flash().getConfigOrFail(myKey);
    }

    /**
     * Proxy method to FlashMessage instance.
     *
     * @param array<string, mixed>|string myKey The key to set, or a complete array of configs.
     * @param mixed|null myValue The value to set.
     * @return this
     */
    function configShallow(myKey, myValue = null)
    {
        this.flash().configShallow(myKey, myValue);

        return this;
    }

    /**
     * Magic method for verbose flash methods based on element names.
     *
     * For example: this.Flash.success('My message') would use the
     * `success.php` element under `templates/element/flash/` for rendering the
     * flash message.
     *
     * If you make consecutive calls to this method, the messages will stack (if they are
     * set with the same flash key)
     *
     * Note that the parameter `element` will be always overridden. In order to call a
     * specific element from a plugin, you should set the `plugin` option in $args.
     *
     * For example: `this.Flash.warning('My message', ['plugin' => 'PluginName'])` would
     * use the `warning.php` element under `plugins/PluginName/templates/element/flash/` for
     * rendering the flash message.
     *
     * @param string myName Element name to use.
     * @param array $args Parameters to pass when calling `FlashComponent::set()`.
     * @return void
     * @throws \Cake\Http\Exception\InternalErrorException If missing the flash message.
     */
    auto __call(string myName, array $args)
    {
        $element = Inflector::underscore(myName);

        if (count($args) < 1) {
            throw new InternalErrorException('Flash message missing.');
        }

        myOptions = ['element' => $element];

        if (!empty($args[1])) {
            if (!empty($args[1]['plugin'])) {
                myOptions = ['element' => $args[1]['plugin'] . '.' . $element];
                unset($args[1]['plugin']);
            }
            myOptions += (array)$args[1];
        }

        this.set($args[0], myOptions);
    }
}
