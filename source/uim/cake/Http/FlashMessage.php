module uim.cake.Http;

import uim.cake.core.InstanceConfigTrait;
use Throwable;

/**
 * The FlashMessage class provides a way for you to write a flash variable
 * to the session, to be rendered in a view with the FlashHelper.
 */
class FlashMessage
{
    use InstanceConfigTrait;

    /**
     * Default configuration
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        'key' => 'flash',
        'element' => 'default',
        'plugin' => null,
        'params' => [],
        'clear' => false,
        'duplicate' => true,
    ];

    /**
     * @var \Cake\Http\Session
     */
    protected $session;

    /**
     * Constructor
     *
     * @param \Cake\Http\Session $session Session instance.
     * @param array<string, mixed> myConfig Config array.
     * @see FlashMessage::set() For list of valid config keys.
     */
    this(Session $session, array myConfig = [])
    {
        this.session = $session;
        this.setConfig(myConfig);
    }

    /**
     * Store flash messages that can be output in the view.
     *
     * If you make consecutive calls to this method, the messages will stack
     * (if they are set with the same flash key)
     *
     * ### Options:
     *
     * - `key` The key to set under the session's Flash key.
     * - `element` The element used to render the flash message. You can use
     *     `'SomePlugin.name'` style value for flash elements from a plugin.
     * - `plugin` Plugin name to use element from.
     * - `params` An array of variables to be made available to the element.
     * - `clear` A bool stating if the current stack should be cleared to start a new one.
     * - `escape` Set to false to allow templates to print out HTML content.
     *
     * @param string myMessage Message to be flashed.
     * @param array<string, mixed> myOptions An array of options
     * @return void
     * @see FlashMessage::$_defaultConfig For default values for the options.
     */
    auto set(myMessage, array myOptions = []): void
    {
        myOptions += (array)this.getConfig();

        if (isset(myOptions['escape']) && !isset(myOptions['params']['escape'])) {
            myOptions['params']['escape'] = myOptions['escape'];
        }

        [myPlugin, $element] = pluginSplit(myOptions['element']);
        if (myOptions['plugin']) {
            myPlugin = myOptions['plugin'];
        }

        if (myPlugin) {
            myOptions['element'] = myPlugin . '.flash/' . $element;
        } else {
            myOptions['element'] = 'flash/' . $element;
        }

        myMessages = [];
        if (!myOptions['clear']) {
            myMessages = (array)this.session.read('Flash.' . myOptions['key']);
        }

        if (!myOptions['duplicate']) {
            foreach (myMessages as $existingMessage) {
                if ($existingMessage['message'] === myMessage) {
                    return;
                }
            }
        }

        myMessages[] = [
            'message' => myMessage,
            'key' => myOptions['key'],
            'element' => myOptions['element'],
            'params' => myOptions['params'],
        ];

        this.session.write('Flash.' . myOptions['key'], myMessages);
    }

    /**
     * Set an exception's message as flash message.
     *
     * The following options will be set by default if unset:
     * ```
     * 'element' => 'error',
     * `params' => ['code' => myException.getCode()]
     * ```
     *
     * @param \Throwable myException Exception instance.
     * @param array<string, mixed> myOptions An array of options.
     * @return void
     * @see FlashMessage::set() For list of valid options
     */
    auto setExceptionMessage(Throwable myException, array myOptions = []): void
    {
        myOptions['element'] = myOptions['element'] ?? 'error';
        myOptions['params']['code'] = myOptions['params']['code'] ?? myException.getCode();

        myMessage = myException.getMessage();
        this.set(myMessage, myOptions);
    }

    /**
     * Get the messages for given key and remove from session.
     *
     * @param string myKey The key for get messages for.
     * @return array|null
     */
    function consume(string myKey): ?array
    {
        return this.session.consume("Flash.{myKey}");
    }

    /**
     * Set a success message.
     *
     * The `'element'` option will be set to  `'success'`.
     *
     * @param string myMessage Message to flash.
     * @param array<string, mixed> myOptions An array of options.
     * @return void
     * @see FlashMessage::set() For list of valid options
     */
    function success(string myMessage, array myOptions = []): void
    {
        myOptions['element'] = 'success';
        this.set(myMessage, myOptions);
    }

    /**
     * Set an success message.
     *
     * The `'element'` option will be set to  `'error'`.
     *
     * @param string myMessage Message to flash.
     * @param array<string, mixed> myOptions An array of options.
     * @return void
     * @see FlashMessage::set() For list of valid options
     */
    function error(string myMessage, array myOptions = []): void
    {
        myOptions['element'] = 'error';
        this.set(myMessage, myOptions);
    }

    /**
     * Set a warning message.
     *
     * The `'element'` option will be set to  `'warning'`.
     *
     * @param string myMessage Message to flash.
     * @param array<string, mixed> myOptions An array of options.
     * @return void
     * @see FlashMessage::set() For list of valid options
     */
    function warning(string myMessage, array myOptions = []): void
    {
        myOptions['element'] = 'warning';
        this.set(myMessage, myOptions);
    }

    /**
     * Set an info message.
     *
     * The `'element'` option will be set to  `'info'`.
     *
     * @param string myMessage Message to flash.
     * @param array<string, mixed> myOptions An array of options.
     * @return void
     * @see FlashMessage::set() For list of valid options
     */
    function info(string myMessage, array myOptions = []): void
    {
        myOptions['element'] = 'info';
        this.set(myMessage, myOptions);
    }
}
