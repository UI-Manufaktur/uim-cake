

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.Mailer;

use BadMethodCallException;
import uim.baklava.core.exceptions\CakeException;
import uim.baklava.core.StaticConfigTrait;
import uim.baklava.datasources\ModelAwareTrait;
import uim.baklava.events\IEventListener;
import uim.baklava.logs\Log;
import uim.baklava.Mailer\Exception\MissingActionException;
import uim.baklava.orm.Locator\LocatorAwareTrait;
import uim.baklava.views\ViewBuilder;
use InvalidArgumentException;

/**
 * Mailer base class.
 *
 * Mailer classes let you encapsulate related Email logic into a reusable
 * and testable class.
 *
 * ## Defining Messages
 *
 * Mailers make it easy for you to define methods that handle email formatting
 * logic. For example:
 *
 * ```
 * class UserMailer : Mailer
 * {
 *     function resetPassword(myUser)
 *     {
 *         this
 *             .setSubject('Reset Password')
 *             .setTo(myUser.email)
 *             .set(['token' => myUser.token]);
 *     }
 * }
 * ```
 *
 * Is a trivial example but shows how a mailer could be declared.
 *
 * ## Sending Messages
 *
 * After you have defined some messages you will want to send them:
 *
 * ```
 * $mailer = new UserMailer();
 * $mailer.send('resetPassword', myUser);
 * ```
 *
 * ## Event Listener
 *
 * Mailers can also subscribe to application event allowing you to
 * decouple email delivery from your application code. By re-declaring the
 * `implementedEvents()` method you can define event handlers that can
 * convert events into email. For example, if your application had a user
 * registration event:
 *
 * ```
 * function implementedEvents(): array
 * {
 *     return [
 *         'Model.afterSave' => 'onRegistration',
 *     ];
 * }
 *
 * function onRegistration(IEvent myEvent, IEntity $entity, ArrayObject myOptions)
 * {
 *     if ($entity.isNew()) {
 *          this.send('welcome', [$entity]);
 *     }
 * }
 * ```
 *
 * The onRegistration method converts the application event into a mailer method.
 * Our mailer could either be registered in the application bootstrap, or
 * in the Table class' initialize() hook.
 *
 * @method this setTo($email, myName = null) Sets "to" address. {@see \Cake\Mailer\Message::setTo()}
 * @method array getTo() Gets "to" address. {@see \Cake\Mailer\Message::getTo()}
 * @method this setFrom($email, myName = null) Sets "from" address. {@see \Cake\Mailer\Message::setFrom()}
 * @method array getFrom() Gets "from" address. {@see \Cake\Mailer\Message::getFrom()}
 * @method this setSender($email, myName = null) Sets "sender" address. {@see \Cake\Mailer\Message::setSender()}
 * @method array getSender() Gets "sender" address. {@see \Cake\Mailer\Message::getSender()}
 * @method this setReplyTo($email, myName = null) Sets "Reply-To" address. {@see \Cake\Mailer\Message::setReplyTo()}
 * @method array getReplyTo() Gets "Reply-To" address. {@see \Cake\Mailer\Message::getReplyTo()}
 * @method this addReplyTo($email, myName = null) Add "Reply-To" address. {@see \Cake\Mailer\Message::addReplyTo()}
 * @method this setReadReceipt($email, myName = null) Sets Read Receipt (Disposition-Notification-To header).
 *   {@see \Cake\Mailer\Message::setReadReceipt()}
 * @method array getReadReceipt() Gets Read Receipt (Disposition-Notification-To header).
 *   {@see \Cake\Mailer\Message::getReadReceipt()}
 * @method this setReturnPath($email, myName = null) Sets return path. {@see \Cake\Mailer\Message::setReturnPath()}
 * @method array getReturnPath() Gets return path. {@see \Cake\Mailer\Message::getReturnPath()}
 * @method this addTo($email, myName = null) Add "To" address. {@see \Cake\Mailer\Message::addTo()}
 * @method this setCc($email, myName = null) Sets "cc" address. {@see \Cake\Mailer\Message::setCc()}
 * @method array getCc() Gets "cc" address. {@see \Cake\Mailer\Message::getCc()}
 * @method this addCc($email, myName = null) Add "cc" address. {@see \Cake\Mailer\Message::addCc()}
 * @method this setBcc($email, myName = null) Sets "bcc" address. {@see \Cake\Mailer\Message::setBcc()}
 * @method array getBcc() Gets "bcc" address. {@see \Cake\Mailer\Message::getBcc()}
 * @method this addBcc($email, myName = null) Add "bcc" address. {@see \Cake\Mailer\Message::addBcc()}
 * @method this setCharset($charset) Charset setter. {@see \Cake\Mailer\Message::setCharset()}
 * @method string getCharset() Charset getter. {@see \Cake\Mailer\Message::getCharset()}
 * @method this setHeaderCharset($charset) HeaderCharset setter. {@see \Cake\Mailer\Message::setHeaderCharset()}
 * @method string getHeaderCharset() HeaderCharset getter. {@see \Cake\Mailer\Message::getHeaderCharset()}
 * @method this setSubject($subject) Sets subject. {@see \Cake\Mailer\Message::setSubject()}
 * @method string getSubject() Gets subject. {@see \Cake\Mailer\Message::getSubject()}
 * @method this setHeaders(array $headers) Sets headers for the message. {@see \Cake\Mailer\Message::setHeaders()}
 * @method this addHeaders(array $headers) Add header for the message. {@see \Cake\Mailer\Message::addHeaders()}
 * @method this getHeaders(array $include = []) Get list of headers. {@see \Cake\Mailer\Message::getHeaders()}
 * @method this setEmailFormat($format) Sets email format. {@see \Cake\Mailer\Message::getHeaders()}
 * @method string getEmailFormat() Gets email format. {@see \Cake\Mailer\Message::getEmailFormat()}
 * @method this setMessageId(myMessage) Sets message ID. {@see \Cake\Mailer\Message::setMessageId()}
 * @method string|bool getMessageId() Gets message ID. {@see \Cake\Mailer\Message::getMessageId()}
 * @method this setDomain($domain) Sets domain. {@see \Cake\Mailer\Message::setDomain()}
 * @method string getDomain() Gets domain. {@see \Cake\Mailer\Message::getDomain()}
 * @method this setAttachments($attachments) Add attachments to the email message. {@see \Cake\Mailer\Message::setAttachments()}
 * @method array getAttachments() Gets attachments to the email message. {@see \Cake\Mailer\Message::getAttachments()}
 * @method this addAttachments($attachments) Add attachments. {@see \Cake\Mailer\Message::addAttachments()}
 * @method array|string getBody(Nullable!string myType = null) Get generated message body as array.
 *   {@see \Cake\Mailer\Message::getBody()}
 */
class Mailer : IEventListener
{
    use ModelAwareTrait;
    use LocatorAwareTrait;
    use StaticConfigTrait;

    /**
     * Mailer's name.
     *
     * @var string
     */
    static myName;

    /**
     * The transport instance to use for sending mail.
     *
     * @var \Cake\Mailer\AbstractTransport|null
     */
    protected $transport;

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
     * Email Renderer
     *
     * @var \Cake\Mailer\Renderer|null
     */
    protected $renderer;

    /**
     * Hold message, renderer and transport instance for restoring after running
     * a mailer action.
     *
     * @var array<string, mixed>
     */
    protected $clonedInstances = [
        'message' => null,
        'renderer' => null,
        'transport' => null,
    ];

    /**
     * Mailer driver class map.
     *
     * @var array<string, string>
     * @psalm-var array<string, class-string>
     */
    protected static $_dsnClassMap = [];

    /**
     * @var array|null
     */
    protected $logConfig = null;

    /**
     * Constructor
     *
     * @param array<string, mixed>|string|null myConfig Array of configs, or string to load configs from app.php
     */
    this(myConfig = null) {
        this.message = new this.messageClass();

        if (this.defaultTable !== null) {
            this.modelClass = this.defaultTable;
        }

        if (myConfig === null) {
            myConfig = static::getConfig('default');
        }

        if (myConfig) {
            this.setProfile(myConfig);
        }
    }

    /**
     * Get the view builder.
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
     * Get message instance.
     *
     * @return \Cake\Mailer\Message
     */
    auto getMessage(): Message
    {
        return this.message;
    }

    /**
     * Set message instance.
     *
     * @param \Cake\Mailer\Message myMessage Message instance.
     * @return this
     */
    auto setMessage(Message myMessage) {
        this.message = myMessage;

        return this;
    }

    /**
     * Magic method to forward method class to Message instance.
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

        return this;
    }

    /**
     * Sets email view vars.
     *
     * @param array|string myKey Variable name or hash of view variables.
     * @param mixed myValue View variable value.
     * @return this
     * @deprecated 4.0.0 Use {@link Mailer::setViewVars()} instead.
     */
    auto set(myKey, myValue = null) {
        deprecationWarning('Mailer::set() is deprecated. Use setViewVars() instead.');

        return this.setViewVars(myKey, myValue);
    }

    /**
     * Sets email view vars.
     *
     * @param array|string myKey Variable name or hash of view variables.
     * @param mixed myValue View variable value.
     * @return this
     */
    auto setViewVars(myKey, myValue = null) {
        this.getRenderer().set(myKey, myValue);

        return this;
    }

    /**
     * Sends email.
     *
     * @param string|null $action The name of the mailer action to trigger.
     *   If no action is specified then all other method arguments will be ignored.
     * @param array $args Arguments to pass to the triggered mailer action.
     * @param array $headers Headers to set.
     * @return array
     * @throws \Cake\Mailer\Exception\MissingActionException
     * @throws \BadMethodCallException
     * @psalm-return array{headers: string, message: string}
     */
    function send(Nullable!string $action = null, array $args = [], array $headers = []): array
    {
        if ($action === null) {
            return this.deliver();
        }

        if (!method_exists(this, $action)) {
            throw new MissingActionException([
                'mailer' => static::class,
                'action' => $action,
            ]);
        }

        this.clonedInstances['message'] = clone this.message;
        this.clonedInstances['renderer'] = clone this.getRenderer();
        if (this.transport !== null) {
            this.clonedInstances['transport'] = clone this.transport;
        }

        this.getMessage().setHeaders($headers);
        if (!this.viewBuilder().getTemplate()) {
            this.viewBuilder().setTemplate($action);
        }

        try {
            this.$action(...$args);

            myResult = this.deliver();
        } finally {
            this.restore();
        }

        return myResult;
    }

    /**
     * Render content and set message body.
     *
     * @param string myContents Content.
     * @return this
     */
    function render(string myContents = '') {
        myContents = this.getRenderer().render(
            myContents,
            this.message.getBodyTypes()
        );

        this.message.setBody(myContents);

        return this;
    }

    /**
     * Render content and send email using configured transport.
     *
     * @param string myContents Content.
     * @return array
     * @psalm-return array{headers: string, message: string}
     */
    function deliver(string myContents = '') {
        this.render(myContents);

        myResult = this.getTransport().send(this.message);
        this.logDelivery(myResult);

        return myResult;
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
            myConfig = static::getConfig(myName);
            if (empty(myConfig)) {
                throw new InvalidArgumentException(sprintf('Unknown email configuration "%s".', myName));
            }
            unset(myName);
        }

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
                this.viewBuilder().{'set' . ucfirst($method)}(myConfig[$method]);
                unset(myConfig[$method]);
            }
        }

        if (array_key_exists('helpers', myConfig)) {
            this.viewBuilder().setHelpers(myConfig['helpers'], false);
            unset(myConfig['helpers']);
        }
        if (array_key_exists('viewRenderer', myConfig)) {
            this.viewBuilder().setClassName(myConfig['viewRenderer']);
            unset(myConfig['viewRenderer']);
        }
        if (array_key_exists('viewVars', myConfig)) {
            this.viewBuilder().setVars(myConfig['viewVars']);
            unset(myConfig['viewVars']);
        }

        if (isset(myConfig['log'])) {
            this.setLogConfig(myConfig['log']);
        }

        this.message.setConfig(myConfig);

        return this;
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
            if (!$transport instanceof AbstractTransport) {
                throw new CakeException('Transport class must extend Cake\Mailer\AbstractTransport');
            }
        } else {
            throw new InvalidArgumentException(sprintf(
                'The value passed for the "myName" argument must be either a string, or an object, %s given.',
                gettype(myName)
            ));
        }

        this.transport = $transport;

        return this;
    }

    /**
     * Gets the transport.
     *
     * @return \Cake\Mailer\AbstractTransport
     */
    auto getTransport(): AbstractTransport
    {
        if (this.transport === null) {
            throw new BadMethodCallException(
                'Transport was not defined. '
                . 'You must set on using setTransport() or set `transport` option in your mailer profile.'
            );
        }

        return this.transport;
    }

    /**
     * Restore message, renderer, transport instances to state before an action was run.
     *
     * @return this
     */
    protected auto restore() {
        foreach (array_keys(this.clonedInstances) as myKey) {
            if (this.clonedInstances[myKey] === null) {
                this.{myKey} = null;
            } else {
                this.{myKey} = clone this.clonedInstances[myKey];
                this.clonedInstances[myKey] = null;
            }
        }

        return this;
    }

    /**
     * Reset all the internal variables to be able to send out a new email.
     *
     * @return this
     */
    function reset() {
        this.message.reset();
        this.getRenderer().reset();
        this.transport = null;
        this.clonedInstances = [
            'message' => null,
            'renderer' => null,
            'transport' => null,
        ];

        return this;
    }

    /**
     * Log the email message delivery.
     *
     * @param array myContentss The content with 'headers' and 'message' keys.
     * @return void
     * @psalm-param array{headers: string, message: string} myContentss
     */
    protected auto logDelivery(array myContentss): void
    {
        if (empty(this.logConfig)) {
            return;
        }

        Log::write(
            this.logConfig['level'],
            PHP_EOL . this.flatten(myContentss['headers']) . PHP_EOL . PHP_EOL . this.flatten(myContentss['message']),
            this.logConfig['scope']
        );
    }

    /**
     * Set logging config.
     *
     * @param array<string, mixed>|string|true $log Log config.
     * @return void
     */
    protected auto setLogConfig($log) {
        myConfig = [
            'level' => 'debug',
            'scope' => 'email',
        ];
        if ($log !== true) {
            if (!is_array($log)) {
                $log = ['level' => $log];
            }
            myConfig = $log + myConfig;
        }

        this.logConfig = myConfig;
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
     * Implemented events.
     *
     * @return array<string, mixed>
     */
    function implementedEvents(): array
    {
        return [];
    }
}
