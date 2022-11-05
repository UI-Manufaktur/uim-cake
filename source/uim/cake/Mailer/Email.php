module uim.baklava.Mailer;

use BadMethodCallException;
import uim.baklava.Log\Log;
import uim.baklava.views\ViewBuilder;
use InvalidArgumentException;
use JsonSerializable;
use LogicException;
use Serializable;
use SimpleXMLElement;

/**
 * CakePHP Email class.
 *
 * This class is used for sending Internet Message Format based
 * on the standard outlined in https://www.rfc-editor.org/rfc/rfc2822.txt
 *
 * ### Configuration
 *
 * Configuration for Email is managed by Email::config() and Email::configTransport().
 * Email::config() can be used to add or read a configuration profile for Email instances.
 * Once made configuration profiles can be used to re-use across various email messages your
 * application sends.
 *
 * @mixin \Cake\Mailer\Mailer
 * @deprecated 4.0.0 This class will be removed in CakePHP 5.0, use {@link \Cake\Mailer\Mailer} instead.
 */
class Email : JsonSerializable, Serializable
{
    /**
     * Type of message - HTML
     *
     * @var string
     * @deprecated 4.0.0 Use Message::MESSAGE_HTML instead.
     */
    public const MESSAGE_HTML = 'html';

    /**
     * Type of message - TEXT
     *
     * @var string
     * @deprecated 4.0.0 Use Message::MESSAGE_TEXT instead.
     */
    public const MESSAGE_TEXT = 'text';

    /**
     * Type of message - BOTH
     *
     * @var string
     * @deprecated 4.0.0 Use Message::MESSAGE_BOTH instead.
     */
    public const MESSAGE_BOTH = 'both';

    /**
     * Holds the regex pattern for email validation
     *
     * @var string
     * @deprecated 4.0.0 Use Message::EMAIL_PATTERN instead.
     */
    public const EMAIL_PATTERN = '/^((?:[\p{L}0-9.!#$%&\'*+\/=?^_`{|}~-]+)*@[\p{L}0-9-._]+)$/ui';

    /**
     * The transport instance to use for sending mail.
     *
     * @var \Cake\Mailer\AbstractTransport|null
     */
    protected $_transport;

    /**
     * Email Renderer
     *
     * @var \Cake\Mailer\Renderer|null
     */
    protected $renderer;

    /**
     * A copy of the configuration profile for this
     * instance. This copy can be modified with Email::profile().
     *
     * @var array
     */
    protected $_profile = [];

    /**
     * Message class name.
     *
     * @var string
     * @psalm-var class-string<\Cake\Mailer\Message>
     */
    protected myMessageClass = Message::class;

    /**
     * Message instance.
     *
     * @var \Cake\Mailer\Message
     */
    protected myMessage;

    /**
     * Constructor
     *
     * @param array<string, mixed>|string|null myConfig Array of configs, or string to load configs from app.php
     */
    this(myConfig = null) {
        this.message = new this.messageClass();

        if (myConfig === null) {
            myConfig = Mailer::getConfig('default');
        }

        if (myConfig) {
            this.setProfile(myConfig);
        }
    }

    /**
     * Clone Renderer instance when email object is cloned.
     *
     * @return void
     */
    auto __clone() {
        if (this.renderer) {
            this.renderer = clone this.renderer;
        }

        if (this.message !== null) {
            this.message = clone this.message;
        }
    }

    /**
     * Magic method to forward method class to Email instance.
     *
     * @param string $method Method name.
     * @param array $args Method arguments
     * @return this|mixed
     */
    auto __call(string $method, array $args) {
        myResult = this.message.$method(...$args);

        if (strpos($method, 'get') === 0) {
            return myResult;
        }

        $getters = ['message'];
        if (in_array($method, $getters, true)) {
            return myResult;
        }

        return this;
    }

    /**
     * Get message instance.
     *
     * @return \Cake\Mailer\Message
     */
    auto getMessage(): Message
    {
        return this.message;
    }

    /**
     * Sets view class for render.
     *
     * @param string $viewClass View class name.
     * @return this
     */
    auto setViewRenderer(string $viewClass) {
        this.getRenderer().viewBuilder().setClassName($viewClass);

        return this;
    }

    /**
     * Gets view class for render.
     *
     * @return string
     * @psalm-suppress InvalidNullableReturnType
     */
    auto getViewRenderer(): string
    {
        /** @psalm-suppress NullableReturnStatement */
        return this.getRenderer().viewBuilder().getClassName();
    }

    /**
     * Sets variables to be set on render.
     *
     * @param array $viewVars Variables to set for view.
     * @return this
     */
    auto setViewVars(array $viewVars) {
        this.getRenderer().viewBuilder().setVars($viewVars);

        return this;
    }

    /**
     * Gets variables to be set on render.
     *
     * @return array
     */
    auto getViewVars(): array
    {
        return this.getRenderer().viewBuilder().getVars();
    }

    /**
     * Sets the transport.
     *
     * When setting the transport you can either use the name
     * of a configured transport or supply a constructed transport.
     *
     * @param \Cake\Mailer\AbstractTransport|string myName Either the name of a configured
     *   transport, or a transport instance.
     * @return this
     * @throws \LogicException When the chosen transport lacks a send method.
     * @throws \InvalidArgumentException When myName is neither a string nor an object.
     */
    auto setTransport(myName) {
        if (is_string(myName)) {
            $transport = TransportFactory::get(myName);
        } elseif (is_object(myName)) {
            $transport = myName;
        } else {
            throw new InvalidArgumentException(sprintf(
                'The value passed for the "myName" argument must be either a string, or an object, %s given.',
                gettype(myName)
            ));
        }
        if (!method_exists($transport, 'send')) {
            throw new LogicException(sprintf('The "%s" do not have send method.', get_class($transport)));
        }

        this._transport = $transport;

        return this;
    }

    /**
     * Gets the transport.
     *
     * @return \Cake\Mailer\AbstractTransport|null
     */
    auto getTransport(): ?AbstractTransport
    {
        return this._transport;
    }

    /**
     * Get generated message (used by transport classes)
     *
     * @param string|null myType Use MESSAGE_* constants or null to return the full message as array
     * @return array|string String if type is given, array if type is null
     */
    function message(?string myType = null) {
        if (myType === null) {
            return this.message.getBody();
        }

        $method = 'getBody' . ucfirst(myType);

        return this.message.$method();
    }

    /**
     * Sets the configuration profile to use for this instance.
     *
     * @param array<string, mixed>|string myConfig String with configuration name, or
     *    an array with config.
     * @return this
     */
    auto setProfile(myConfig) {
        if (is_string(myConfig)) {
            myName = myConfig;
            myConfig = Mailer::getConfig(myName);
            if (empty(myConfig)) {
                throw new InvalidArgumentException(sprintf('Unknown email configuration "%s".', myName));
            }
            unset(myName);
        }

        this._profile = array_merge(this._profile, myConfig);

        $simpleMethods = [
            'transport',
        ];
        foreach ($simpleMethods as $method) {
            if (isset(myConfig[$method])) {
                this.{'set' . ucfirst($method)}(myConfig[$method]);
                unset(myConfig[$method]);
            }
        }

        $viewBuilderMethods = [
            'template', 'layout', 'theme',
        ];
        foreach ($viewBuilderMethods as $method) {
            if (array_key_exists($method, myConfig)) {
                this.getRenderer().viewBuilder().{'set' . ucfirst($method)}(myConfig[$method]);
                unset(myConfig[$method]);
            }
        }

        if (array_key_exists('helpers', myConfig)) {
            this.getRenderer().viewBuilder().setHelpers(myConfig['helpers'], false);
            unset(myConfig['helpers']);
        }
        if (array_key_exists('viewRenderer', myConfig)) {
            this.getRenderer().viewBuilder().setClassName(myConfig['viewRenderer']);
            unset(myConfig['viewRenderer']);
        }
        if (array_key_exists('viewVars', myConfig)) {
            this.getRenderer().viewBuilder().setVars(myConfig['viewVars']);
            unset(myConfig['viewVars']);
        }

        this.message.setConfig(myConfig);

        return this;
    }

    /**
     * Gets the configuration profile to use for this instance.
     *
     * @return array
     */
    auto getProfile(): array
    {
        return this._profile;
    }

    /**
     * Send an email using the specified content, template and layout
     *
     * @param array<string>|string|null myContents String with message or array with messages
     * @return array
     * @throws \BadMethodCallException
     * @psalm-return array{headers: string, message: string}
     */
    function send(myContents = null): array
    {
        if (is_array(myContents)) {
            myContents = implode("\n", myContents) . "\n";
        }

        this.render(myContents);

        $transport = this.getTransport();
        if (!$transport) {
            $msg = 'Cannot send email, transport was not defined. Did you call transport() or define ' .
                ' a transport in the set profile?';
            throw new BadMethodCallException($msg);
        }
        myContentss = $transport.send(this.message);
        this._logDelivery(myContentss);

        return myContentss;
    }

    /**
     * Render email.
     *
     * @param array<string>|string|null myContents Content array or string
     * @return void
     */
    function render(myContents = null): void
    {
        if (is_array(myContents)) {
            myContents = implode("\n", myContents) . "\n";
        }

        this.message.setBody(
            this.getRenderer().render(
                (string)myContents,
                this.message.getBodyTypes()
            )
        );
    }

    /**
     * Get view builder.
     *
     * @return \Cake\View\ViewBuilder
     */
    function viewBuilder(): ViewBuilder
    {
        return this.getRenderer().viewBuilder();
    }

    /**
     * Get email renderer.
     *
     * @return \Cake\Mailer\Renderer
     */
    auto getRenderer(): Renderer
    {
        if (this.renderer === null) {
            this.renderer = new Renderer();
        }

        return this.renderer;
    }

    /**
     * Set email renderer.
     *
     * @param \Cake\Mailer\Renderer $renderer Render instance.
     * @return this
     */
    auto setRenderer(Renderer $renderer) {
        this.renderer = $renderer;

        return this;
    }

    /**
     * Log the email message delivery.
     *
     * @param array myContentss The content with 'headers' and 'message' keys.
     * @return void
     */
    protected auto _logDelivery(array myContentss): void
    {
        if (empty(this._profile['log'])) {
            return;
        }
        myConfig = [
            'level' => 'debug',
            'scope' => 'email',
        ];
        if (this._profile['log'] !== true) {
            if (!is_array(this._profile['log'])) {
                this._profile['log'] = ['level' => this._profile['log']];
            }
            myConfig = this._profile['log'] + myConfig;
        }
        Log::write(
            myConfig['level'],
            PHP_EOL . this.flatten(myContentss['headers']) . PHP_EOL . PHP_EOL . this.flatten(myContentss['message']),
            myConfig['scope']
        );
    }

    /**
     * Converts given value to string
     *
     * @param array<string>|string myValue The value to convert
     * @return string
     */
    protected auto flatten(myValue): string
    {
        return is_array(myValue) ? implode(';', myValue) : myValue;
    }

    /**
     * Static method to fast create an instance of \Cake\Mailer\Email
     *
     * @param array|string|null $to Address to send ({@see \Cake\Mailer\Email::setTo()}).
     *   If null, will try to use 'to' from transport config
     * @param string|null $subject String of subject or null to use 'subject' from transport config
     * @param array|string|null myMessage String with message or array with variables to be used in render
     * @param array<string, mixed>|string myConfig String to use Email delivery profile from app.php or array with configs
     * @param bool $send Send the email or just return the instance pre-configured
     * @return \Cake\Mailer\Email
     * @throws \InvalidArgumentException
     */
    static function deliver(
        $to = null,
        ?string $subject = null,
        myMessage = null,
        myConfig = 'default',
        bool $send = true
    ) {
        if (is_array(myConfig) && !isset(myConfig['transport'])) {
            myConfig['transport'] = 'default';
        }

        $instance = new static(myConfig);
        if ($to !== null) {
            $instance.getMessage().setTo($to);
        }
        if ($subject !== null) {
            $instance.getMessage().setSubject($subject);
        }
        if (is_array(myMessage)) {
            $instance.setViewVars(myMessage);
            myMessage = null;
        } elseif (myMessage === null) {
            myConfig = $instance.getProfile();
            if (array_key_exists('message', myConfig)) {
                myMessage = myConfig['message'];
            }
        }

        if ($send === true) {
            $instance.send(myMessage);
        }

        return $instance;
    }

    /**
     * Reset all the internal variables to be able to send out a new email.
     *
     * @return this
     */
    function reset() {
        this.message.reset();
        if (this.renderer !== null) {
            this.renderer.reset();
        }
        this._transport = null;
        this._profile = [];

        return this;
    }

    /**
     * Serializes the email object to a value that can be natively serialized and re-used
     * to clone this email instance.
     *
     * @return array Serializable array of configuration properties.
     * @throws \Exception When a view var object can not be properly serialized.
     */
    function jsonSerialize(): array
    {
        $array = this.message.jsonSerialize();
        $array['viewConfig'] = this.getRenderer().viewBuilder().jsonSerialize();

        return $array;
    }

    /**
     * Configures an email instance object from serialized config.
     *
     * @param array<string, mixed> myConfig Email configuration array.
     * @return this
     */
    function createFromArray(array myConfig) {
        if (isset(myConfig['viewConfig'])) {
            this.getRenderer().viewBuilder().createFromArray(myConfig['viewConfig']);
            unset(myConfig['viewConfig']);
        }

        if (this.message === null) {
            this.message = new this.messageClass();
        }
        this.message.createFromArray(myConfig);

        return this;
    }

    /**
     * Serializes the Email object.
     *
     * @return string
     */
    function serialize(): string
    {
        $array = this.__serialize();

        return serialize($array);
    }

    /**
     * Magic method used for serializing the Email object.
     *
     * @return array
     */
    auto __serialize(): array
    {
        $array = this.jsonSerialize();
        array_walk_recursive($array, function (&$item, myKey): void {
            if ($item instanceof SimpleXMLElement) {
                $item = json_decode(json_encode((array)$item), true);
            }
        });

        /** @psalm-var array */
        return $array;
    }

    /**
     * Unserializes the Email object.
     *
     * @param string myData Serialized string.
     * @return void
     */
    function unserialize(myData): void
    {
        this.createFromArray(unserialize(myData));
    }

    /**
     * Magic method used to rebuild the Email object.
     *
     * @param array myData Data array.
     * @return void
     */
    auto __unserialize(array myData): void
    {
        this.createFromArray(myData);
    }

    /**
     * Proxy all static method calls (for methods provided by StaticConfigTrait) to Mailer.
     *
     * @param string myName Method name.
     * @param array $arguments Method argument.
     * @return mixed
     */
    static auto __callStatic(myName, $arguments) {
        return [Mailer::class, myName](...$arguments);
    }
}
