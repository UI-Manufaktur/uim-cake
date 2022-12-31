

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


  */module uim.cake.Mailer;

use BadMethodCallException;
import uim.cake.core.exceptions.CakeException;
import uim.cake.core.StaticConfigTrait;
import uim.cake.datasources.ModelAwareTrait;
import uim.cake.events.IEventListener;
import uim.cake.logs.Log;
import uim.cake.Mailer\exceptions.MissingActionException;
import uim.cake.orm.locators.LocatorAwareTrait;
import uim.cake.View\ViewBuilder;
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
 *     function resetPassword($user)
 *     {
 *         this
 *             .setSubject("Reset Password")
 *             .setTo($user.email)
 *             .set(["token": $user.token]);
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
 * $mailer.send("resetPassword", $user);
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
 *         "Model.afterSave": "onRegistration",
 *     ];
 * }
 *
 * function onRegistration(IEvent $event, EntityInterface $entity, ArrayObject $options)
 * {
 *     if ($entity.isNew()) {
 *          this.send("welcome", [$entity]);
 *     }
 * }
 * ```
 *
 * The onRegistration method converts the application event into a mailer method.
 * Our mailer could either be registered in the application bootstrap, or
 * in the Table class" initialize() hook.
 *
 * @method this setTo($email, $name = null) Sets "to" address. {@see uim.cake.Mailer\Message::setTo()}
 * @method array getTo() Gets "to" address. {@see uim.cake.Mailer\Message::getTo()}
 * @method this setFrom($email, $name = null) Sets "from" address. {@see uim.cake.Mailer\Message::setFrom()}
 * @method array getFrom() Gets "from" address. {@see uim.cake.Mailer\Message::getFrom()}
 * @method this setSender($email, $name = null) Sets "sender" address. {@see uim.cake.Mailer\Message::setSender()}
 * @method array getSender() Gets "sender" address. {@see uim.cake.Mailer\Message::getSender()}
 * @method this setReplyTo($email, $name = null) Sets "Reply-To" address. {@see uim.cake.Mailer\Message::setReplyTo()}
 * @method array getReplyTo() Gets "Reply-To" address. {@see uim.cake.Mailer\Message::getReplyTo()}
 * @method this addReplyTo($email, $name = null) Add "Reply-To" address. {@see uim.cake.Mailer\Message::addReplyTo()}
 * @method this setReadReceipt($email, $name = null) Sets Read Receipt (Disposition-Notification-To header).
 *   {@see uim.cake.Mailer\Message::setReadReceipt()}
 * @method array getReadReceipt() Gets Read Receipt (Disposition-Notification-To header).
 *   {@see uim.cake.Mailer\Message::getReadReceipt()}
 * @method this setReturnPath($email, $name = null) Sets return path. {@see uim.cake.Mailer\Message::setReturnPath()}
 * @method array getReturnPath() Gets return path. {@see uim.cake.Mailer\Message::getReturnPath()}
 * @method this addTo($email, $name = null) Add "To" address. {@see uim.cake.Mailer\Message::addTo()}
 * @method this setCc($email, $name = null) Sets "cc" address. {@see uim.cake.Mailer\Message::setCc()}
 * @method array getCc() Gets "cc" address. {@see uim.cake.Mailer\Message::getCc()}
 * @method this addCc($email, $name = null) Add "cc" address. {@see uim.cake.Mailer\Message::addCc()}
 * @method this setBcc($email, $name = null) Sets "bcc" address. {@see uim.cake.Mailer\Message::setBcc()}
 * @method array getBcc() Gets "bcc" address. {@see uim.cake.Mailer\Message::getBcc()}
 * @method this addBcc($email, $name = null) Add "bcc" address. {@see uim.cake.Mailer\Message::addBcc()}
 * @method this setCharset($charset) Charset setter. {@see uim.cake.Mailer\Message::setCharset()}
 * @method string getCharset() Charset getter. {@see uim.cake.Mailer\Message::getCharset()}
 * @method this setHeaderCharset($charset) HeaderCharset setter. {@see uim.cake.Mailer\Message::setHeaderCharset()}
 * @method string getHeaderCharset() HeaderCharset getter. {@see uim.cake.Mailer\Message::getHeaderCharset()}
 * @method this setSubject($subject) Sets subject. {@see uim.cake.Mailer\Message::setSubject()}
 * @method string getSubject() Gets subject. {@see uim.cake.Mailer\Message::getSubject()}
 * @method this setHeaders(array $headers) Sets headers for the message. {@see uim.cake.Mailer\Message::setHeaders()}
 * @method this addHeaders(array $headers) Add header for the message. {@see uim.cake.Mailer\Message::addHeaders()}
 * @method this getHeaders(array $include = []) Get list of headers. {@see uim.cake.Mailer\Message::getHeaders()}
 * @method this setEmailFormat($format) Sets email format. {@see uim.cake.Mailer\Message::getHeaders()}
 * @method string getEmailFormat() Gets email format. {@see uim.cake.Mailer\Message::getEmailFormat()}
 * @method this setMessageId($message) Sets message ID. {@see uim.cake.Mailer\Message::setMessageId()}
 * @method string|bool getMessageId() Gets message ID. {@see uim.cake.Mailer\Message::getMessageId()}
 * @method this setDomain($domain) Sets domain. {@see uim.cake.Mailer\Message::setDomain()}
 * @method string getDomain() Gets domain. {@see uim.cake.Mailer\Message::getDomain()}
 * @method this setAttachments($attachments) Add attachments to the email message. {@see uim.cake.Mailer\Message::setAttachments()}
 * @method array getAttachments() Gets attachments to the email message. {@see uim.cake.Mailer\Message::getAttachments()}
 * @method this addAttachments($attachments) Add attachments. {@see uim.cake.Mailer\Message::addAttachments()}
 * @method array|string getBody(?string $type = null) Get generated message body as array.
 *   {@see uim.cake.Mailer\Message::getBody()}
 */
#[\AllowDynamicProperties]
class Mailer : IEventListener
{
    use ModelAwareTrait;
    use LocatorAwareTrait;
    use StaticConfigTrait;

    /**
     * Mailer"s name.
     *
     * @var string
     */
    static $name;

    /**
     * The transport instance to use for sending mail.
     *
     * @var uim.cake.Mailer\AbstractTransport|null
     */
    protected $transport;

    /**
     * Message class name.
     *
     * @var string
     * @psalm-var class-string<uim.cake.Mailer\Message>
     */
    protected $messageClass = Message::class;

    /**
     * Message instance.
     *
     * @var uim.cake.Mailer\Message
     */
    protected $message;

    /**
     * Email Renderer
     *
     * @var uim.cake.Mailer\Renderer|null
     */
    protected $renderer;

    /**
     * Hold message, renderer and transport instance for restoring after running
     * a mailer action.
     *
     * @var array<string, mixed>
     */
    protected $clonedInstances = [
        "message": null,
        "renderer": null,
        "transport": null,
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
     * @param array<string, mixed>|string|null $config Array of configs, or string to load configs from app.php
     */
    this($config = null) {
        this.message = new this.messageClass();

        if (this.defaultTable != null) {
            this.modelClass = this.defaultTable;
        }

        if ($config == null) {
            $config = static::getConfig("default");
        }

        if ($config) {
            this.setProfile($config);
        }
    }

    /**
     * Get the view builder.
     *
     * @return uim.cake.View\ViewBuilder
     */
    function viewBuilder(): ViewBuilder
    {
        return this.getRenderer().viewBuilder();
    }

    /**
     * Get email renderer.
     *
     * @return uim.cake.Mailer\Renderer
     */
    function getRenderer(): Renderer
    {
        if (this.renderer == null) {
            this.renderer = new Renderer();
        }

        return this.renderer;
    }

    /**
     * Set email renderer.
     *
     * @param uim.cake.Mailer\Renderer $renderer Render instance.
     * @return this
     */
    function setRenderer(Renderer $renderer) {
        this.renderer = $renderer;

        return this;
    }

    /**
     * Get message instance.
     *
     * @return uim.cake.Mailer\Message
     */
    function getMessage(): Message
    {
        return this.message;
    }

    /**
     * Set message instance.
     *
     * @param uim.cake.Mailer\Message $message Message instance.
     * @return this
     */
    function setMessage(Message $message) {
        this.message = $message;

        return this;
    }

    /**
     * Magic method to forward method class to Message instance.
     *
     * @param string $method Method name.
     * @param array $args Method arguments
     * @return this|mixed
     */
    function __call(string $method, array $args) {
        $result = this.message.$method(...$args);
        if (strpos($method, "get") == 0) {
            return $result;
        }

        return this;
    }

    /**
     * Sets email view vars.
     *
     * @param array|string aKey Variable name or hash of view variables.
     * @param mixed $value View variable value.
     * @return this
     * @deprecated 4.0.0 Use {@link Mailer::setViewVars()} instead.
     */
    function set($key, $value = null) {
        deprecationWarning("Mailer::set() is deprecated. Use setViewVars() instead.");

        return this.setViewVars($key, $value);
    }

    /**
     * Sets email view vars.
     *
     * @param array|string aKey Variable name or hash of view variables.
     * @param mixed $value View variable value.
     * @return this
     */
    function setViewVars($key, $value = null) {
        this.getRenderer().set($key, $value);

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
     * @throws uim.cake.Mailer\exceptions.MissingActionException
     * @throws \BadMethodCallException
     * @psalm-return array{headers: string, message: string}
     */
    function send(?string $action = null, array $args = [], array $headers = []): array
    {
        if ($action == null) {
            return this.deliver();
        }

        if (!method_exists(this, $action)) {
            throw new MissingActionException([
                "mailer": static::class,
                "action": $action,
            ]);
        }

        this.clonedInstances["message"] = clone this.message;
        this.clonedInstances["renderer"] = clone this.getRenderer();
        if (this.transport != null) {
            this.clonedInstances["transport"] = clone this.transport;
        }

        this.getMessage().setHeaders($headers);
        if (!this.viewBuilder().getTemplate()) {
            this.viewBuilder().setTemplate($action);
        }

        try {
            this.$action(...$args);

            $result = this.deliver();
        } finally {
            this.restore();
        }

        return $result;
    }

    /**
     * Render content and set message body.
     *
     * @param string $content Content.
     * @return this
     */
    function render(string $content = "") {
        $content = this.getRenderer().render(
            $content,
            this.message.getBodyTypes()
        );

        this.message.setBody($content);

        return this;
    }

    /**
     * Render content and send email using configured transport.
     *
     * @param string $content Content.
     * @return array
     * @psalm-return array{headers: string, message: string}
     */
    function deliver(string $content = "") {
        this.render($content);

        $result = this.getTransport().send(this.message);
        this.logDelivery($result);

        return $result;
    }

    /**
     * Sets the configuration profile to use for this instance.
     *
     * @param array<string, mixed>|string $config String with configuration name, or
     *    an array with config.
     * @return this
     */
    function setProfile($config) {
        if (is_string($config)) {
            $name = $config;
            $config = static::getConfig($name);
            if (empty($config)) {
                throw new InvalidArgumentException(sprintf("Unknown email configuration "%s".", $name));
            }
            unset($name);
        }

        $simpleMethods = [
            "transport",
        ];
        foreach ($simpleMethods as $method) {
            if (isset($config[$method])) {
                this.{"set" . ucfirst($method)}($config[$method]);
                unset($config[$method]);
            }
        }

        $viewBuilderMethods = [
            "template", "layout", "theme",
        ];
        foreach ($viewBuilderMethods as $method) {
            if (array_key_exists($method, $config)) {
                this.viewBuilder().{"set" . ucfirst($method)}($config[$method]);
                unset($config[$method]);
            }
        }

        if (array_key_exists("helpers", $config)) {
            this.viewBuilder().setHelpers($config["helpers"], false);
            unset($config["helpers"]);
        }
        if (array_key_exists("viewRenderer", $config)) {
            this.viewBuilder().setClassName($config["viewRenderer"]);
            unset($config["viewRenderer"]);
        }
        if (array_key_exists("viewVars", $config)) {
            this.viewBuilder().setVars($config["viewVars"]);
            unset($config["viewVars"]);
        }
        if (isset($config["autoLayout"])) {
            if ($config["autoLayout"] == false) {
                this.viewBuilder().disableAutoLayout();
            }
            unset($config["autoLayout"]);
        }

        if (isset($config["log"])) {
            this.setLogConfig($config["log"]);
        }

        this.message.setConfig($config);

        return this;
    }

    /**
     * Sets the transport.
     *
     * When setting the transport you can either use the name
     * of a configured transport or supply a constructed transport.
     *
     * @param uim.cake.Mailer\AbstractTransport|string aName Either the name of a configured
     *   transport, or a transport instance.
     * @return this
     * @throws \LogicException When the chosen transport lacks a send method.
     * @throws \InvalidArgumentException When $name is neither a string nor an object.
     */
    function setTransport($name) {
        if (is_string($name)) {
            $transport = TransportFactory::get($name);
        } elseif (is_object($name)) {
            $transport = $name;
            if (!$transport instanceof AbstractTransport) {
                throw new CakeException("Transport class must extend Cake\Mailer\AbstractTransport");
            }
        } else {
            throw new InvalidArgumentException(sprintf(
                "The value passed for the "$name" argument must be either a string, or an object, %s given.",
                gettype($name)
            ));
        }

        this.transport = $transport;

        return this;
    }

    /**
     * Gets the transport.
     *
     * @return uim.cake.Mailer\AbstractTransport
     */
    function getTransport(): AbstractTransport
    {
        if (this.transport == null) {
            throw new BadMethodCallException(
                "Transport was not defined. "
                . "You must set on using setTransport() or set `transport` option in your mailer profile."
            );
        }

        return this.transport;
    }

    /**
     * Restore message, renderer, transport instances to state before an action was run.
     *
     * @return this
     */
    protected function restore() {
        foreach (array_keys(this.clonedInstances) as $key) {
            if (this.clonedInstances[$key] == null) {
                this.{$key} = null;
            } else {
                this.{$key} = clone this.clonedInstances[$key];
                this.clonedInstances[$key] = null;
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
            "message": null,
            "renderer": null,
            "transport": null,
        ];

        return this;
    }

    /**
     * Log the email message delivery.
     *
     * @param array $contents The content with "headers" and "message" keys.
     * @return void
     * @psalm-param array{headers: string, message: string} $contents
     */
    protected function logDelivery(array $contents): void
    {
        if (empty(this.logConfig)) {
            return;
        }

        Log::write(
            this.logConfig["level"],
            PHP_EOL . this.flatten($contents["headers"]) . PHP_EOL . PHP_EOL . this.flatten($contents["message"]),
            this.logConfig["scope"]
        );
    }

    /**
     * Set logging config.
     *
     * @param array<string, mixed>|string|true $log Log config.
     */
    protected void setLogConfig($log) {
        $config = [
            "level": "debug",
            "scope": "email",
        ];
        if ($log != true) {
            if (!is_array($log)) {
                $log = ["level": $log];
            }
            $config = $log + $config;
        }

        this.logConfig = $config;
    }

    /**
     * Converts given value to string
     *
     * @param array<string>|string $value The value to convert
     */
    protected string flatten($value): string
    {
        return is_array($value) ? implode(";", $value) : $value;
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
