module uim.cake.Mailer;

use BadMethodCallException;
import uim.cake.logs.Log;
import uim.cake.View\ViewBuilder;
use InvalidArgumentException;
use JsonSerializable;
use LogicException;
use Serializable;
use SimpleXMLElement;

/**
 * UIM Email class.
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
 * @mixin uim.cake.mailers.Mailer
 * @deprecated 4.0.0 This class will be removed in UIM 5.0, use {@link uim.cake.mailers.Mailer} instead.
 */
class Email : JsonSerializable, Serializable
{
    /**
     * Type of message - HTML
     *
     * @var string
     * @deprecated 4.0.0 Use Message::MESSAGE_HTML instead.
     */
    const MESSAGE_HTML = "html";

    /**
     * Type of message - TEXT
     *
     * @var string
     * @deprecated 4.0.0 Use Message::MESSAGE_TEXT instead.
     */
    const MESSAGE_TEXT = "text";

    /**
     * Type of message - BOTH
     *
     * @var string
     * @deprecated 4.0.0 Use Message::MESSAGE_BOTH instead.
     */
    const MESSAGE_BOTH = "both";

    /**
     * Holds the regex pattern for email validation
     *
     * @var string
     * @deprecated 4.0.0 Use Message::EMAIL_PATTERN instead.
     */
    const EMAIL_PATTERN = "/^((?:[\p{L}0-9.!#$%&\"*+\/=?^_`{|}~-]+)*@[\p{L}0-9-._]+)$/ui";

    /**
     * The transport instance to use for sending mail.
     *
     * @var uim.cake.mailers.AbstractTransport|null
     */
    protected _transport;

    /**
     * Email Renderer
     *
     * @var uim.cake.mailers.Renderer|null
     */
    protected $renderer;

    /**
     * A copy of the configuration profile for this
     * instance. This copy can be modified with Email::profile().
     *
     * @var array<string, mixed>
     */
    protected _profile = [];

    /**
     * Message class name.
     *
     * @var string
     * @psalm-var class-string<uim.cake.mailers.Message>
     */
    protected $messageClass = Message::class;

    /**
     * Message instance.
     *
     * @var uim.cake.mailers.Message
     */
    protected $message;

    /**
     * Constructor
     *
     * @param array<string, mixed>|string|null aConfig Array of configs, or string to load configs from app.php
     */
    this(aConfig = null) {
        this.message = new this.messageClass();

        if (aConfig == null) {
            aConfig = Mailer::getConfig("default");
        }

        if (aConfig) {
            this.setProfile(aConfig);
        }
    }

    /**
     * Clone Renderer instance when email object is cloned.
     */
    void __clone() {
        if (this.renderer) {
            this.renderer = clone this.renderer;
        }

        if (this.message != null) {
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
    function __call(string $method, array $args) {
        $result = this.message.$method(...$args);

        if (strpos($method, "get") == 0) {
            return $result;
        }

        $getters = ["message"];
        if (hasAllValues($method, $getters, true)) {
            return $result;
        }

        return this;
    }

    /**
     * Get message instance.
     *
     * @return uim.cake.mailers.Message
     */
    function getMessage(): Message
    {
        return this.message;
    }

    /**
     * Sets view class for render.
     *
     * @param string $viewClass View class name.
     * @return this
     */
    function setViewRenderer(string $viewClass) {
        this.getRenderer().viewBuilder().setClassName($viewClass);

        return this;
    }

    /**
     * Gets view class for render.
     *
     * @return string
     * @psalm-suppress InvalidNullableReturnType
     */
    string getViewRenderer() {
        /** @psalm-suppress NullableReturnStatement */
        return this.getRenderer().viewBuilder().getClassName();
    }

    /**
     * Sets variables to be set on render.
     *
     * @param array<string, mixed> $viewVars Variables to set for view.
     * @return this
     */
    function setViewVars(array $viewVars) {
        this.getRenderer().viewBuilder().setVars($viewVars);

        return this;
    }

    /**
     * Gets variables to be set on render.
     *
     * @return array<string, mixed>
     */
    array getViewVars() {
        return this.getRenderer().viewBuilder().getVars();
    }

    /**
     * Sets the transport.
     *
     * When setting the transport you can either use the name
     * of a configured transport or supply a constructed transport.
     *
     * @param uim.cake.mailers.AbstractTransport|string aName Either the name of a configured
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
        } else {
            throw new InvalidArgumentException(sprintf(
                "The value passed for the "$name" argument must be either a string, or an object, %s given.",
                gettype($name)
            ));
        }
        if (!method_exists($transport, "send")) {
            throw new LogicException(sprintf("The '%s' do not have send method.", get_class($transport)));
        }

        _transport = $transport;

        return this;
    }

    /**
     * Gets the transport.
     *
     * @return uim.cake.mailers.AbstractTransport|null
     */
    function getTransport(): ?AbstractTransport
    {
        return _transport;
    }

    /**
     * Get generated message (used by transport classes)
     *
     * @param string|null $type Use MESSAGE_* constants or null to return the full message as array
     * @return array|string String if type is given, array if type is null
     */
    function message(Nullable!string $type = null) {
        if ($type == null) {
            return this.message.getBody();
        }

        $method = "getBody" ~ ucfirst($type);

        return this.message.$method();
    }

    /**
     * Sets the configuration profile to use for this instance.
     *
     * @param array<string, mixed>|string aConfig String with configuration name, or
     *    an array with config.
     * @return this
     */
    function setProfile(aConfig) {
        if (is_string(aConfig)) {
            $name = aConfig;
            aConfig = Mailer::getConfig($name);
            if (empty(aConfig)) {
                throw new InvalidArgumentException(sprintf("Unknown email configuration '%s'.", $name));
            }
            unset($name);
        }

        _profile = aConfig + _profile;

        $simpleMethods = [
            "transport",
        ];
        foreach ($simpleMethods as $method) {
            if (isset(aConfig[$method])) {
                this.{"set" ~ ucfirst($method)}(aConfig[$method]);
                unset(aConfig[$method]);
            }
        }

        $viewBuilderMethods = [
            "template", "layout", "theme",
        ];
        foreach ($viewBuilderMethods as $method) {
            if (array_key_exists($method, aConfig)) {
                this.getRenderer().viewBuilder().{"set" ~ ucfirst($method)}(aConfig[$method]);
                unset(aConfig[$method]);
            }
        }

        if (array_key_exists("helpers", aConfig)) {
            this.getRenderer().viewBuilder().setHelpers(aConfig["helpers"], false);
            unset(aConfig["helpers"]);
        }
        if (array_key_exists("viewRenderer", aConfig)) {
            this.getRenderer().viewBuilder().setClassName(aConfig["viewRenderer"]);
            unset(aConfig["viewRenderer"]);
        }
        if (array_key_exists("viewVars", aConfig)) {
            this.getRenderer().viewBuilder().setVars(aConfig["viewVars"]);
            unset(aConfig["viewVars"]);
        }

        this.message.setConfig(aConfig);

        return this;
    }

    /**
     * Gets the configuration profile to use for this instance.
     *
     * @return array<string, mixed>
     */
    array getProfile() {
        return _profile;
    }

    /**
     * Send an email using the specified content, template and layout
     *
     * @param array<string>|string|null $content String with message or array with messages
     * @return array
     * @throws \BadMethodCallException
     * @psalm-return array{headers: string, message: string}
     */
    array send($content = null) {
        if (is_array($content)) {
            $content = implode("\n", $content) ~ "\n";
        }

        this.render($content);

        $transport = this.getTransport();
        if (!$transport) {
            $msg = "Cannot send email, transport was not defined. Did you call transport() or define " ~
                " a transport in the set profile?";
            throw new BadMethodCallException($msg);
        }
        $contents = $transport.send(this.message);
        _logDelivery($contents);

        return $contents;
    }

    /**
     * Render email.
     *
     * @param array<string>|string|null $content Content array or string
     */
    void render($content = null) {
        if (is_array($content)) {
            $content = implode("\n", $content) ~ "\n";
        }

        this.message.setBody(
            this.getRenderer().render(
                (string)$content,
                this.message.getBodyTypes()
            )
        );
    }

    /**
     * Get view builder.
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
     * @return uim.cake.mailers.Renderer
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
     * @param uim.cake.mailers.Renderer $renderer Render instance.
     * @return this
     */
    function setRenderer(Renderer $renderer) {
        this.renderer = $renderer;

        return this;
    }

    /**
     * Log the email message delivery.
     *
     * @param array<string, string> $contents The content with "headers" and "message" keys.
     */
    protected void _logDelivery(array $contents) {
        if (empty(_profile["log"])) {
            return;
        }
        aConfig = [
            "level": "debug",
            "scope": "email",
        ];
        if (_profile["log"] != true) {
            if (!is_array(_profile["log"])) {
                _profile["log"] = ["level": _profile["log"]];
            }
            aConfig = _profile["log"] + aConfig;
        }
        Log::write(
            aConfig["level"],
            PHP_EOL . this.flatten($contents["headers"]) . PHP_EOL . PHP_EOL . this.flatten($contents["message"]),
            aConfig["scope"]
        );
    }

    /**
     * Converts given value to string
     *
     * @param array<string>|string aValue The value to convert
     */
    protected string flatten($value) {
        return is_array($value) ? implode(";", $value) : $value;
    }

    /**
     * Static method to fast create an instance of uim.cake.mailers.Email
     *
     * @param array|string|null $to Address to send ({@see uim.cake.mailers.Email::setTo()}).
     *   If null, will try to use "to" from transport config
     * @param string|null $subject String of subject or null to use "subject" from transport config
     * @param array|string|null $message String with message or array with variables to be used in render
     * @param array<string, mixed>|string aConfig String to use Email delivery profile from app.php or array with configs
     * @param bool $send Send the email or just return the instance pre-configured
     * @return uim.cake.mailers.Email
     * @throws \InvalidArgumentException
     */
    static function deliver(
        $to = null,
        Nullable!string $subject = null,
        $message = null,
        aConfig = "default",
        bool $send = true
    ) {
        if (is_array(aConfig) && !isset(aConfig["transport"])) {
            aConfig["transport"] = "default";
        }

        $instance = new static(aConfig);
        if ($to != null) {
            $instance.getMessage().setTo($to);
        }
        if ($subject != null) {
            $instance.getMessage().setSubject($subject);
        }
        if (is_array($message)) {
            $instance.setViewVars($message);
            $message = null;
        } elseif ($message == null) {
            aConfig = $instance.getProfile();
            if (array_key_exists("message", aConfig)) {
                $message = aConfig["message"];
            }
        }

        if ($send == true) {
            $instance.send($message);
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
        if (this.renderer != null) {
            this.renderer.reset();
        }
        _transport = null;
        _profile = [];

        return this;
    }

    /**
     * Serializes the email object to a value that can be natively serialized and re-used
     * to clone this email instance.
     *
     * @return array Serializable array of configuration properties.
     * @throws \Exception When a view var object can not be properly serialized.
     */
    array jsonSerialize() {
        $array = this.message.jsonSerialize();
        $array["viewConfig"] = this.getRenderer().viewBuilder().jsonSerialize();

        return $array;
    }

    /**
     * Configures an email instance object from serialized config.
     *
     * @param array<string, mixed> aConfig Email configuration array.
     * @return this
     */
    function createFromArray(Json aConfig) {
        if (isset(aConfig["viewConfig"])) {
            this.getRenderer().viewBuilder().createFromArray(aConfig["viewConfig"]);
            unset(aConfig["viewConfig"]);
        }

        if (this.message == null) {
            this.message = new this.messageClass();
        }
        this.message.createFromArray(aConfig);

        return this;
    }

    /**
     * Serializes the Email object.
     */
    string serialize() {
        $array = __serialize();

        return serialize($array);
    }

    /**
     * Magic method used for serializing the Email object.
     */
    array __serialize() {
        $array = this.jsonSerialize();
        array_walk_recursive($array, void (&$item, $key) {
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
     * @param string $data Serialized string.
     */
    void unserialize($data) {
        this.createFromArray(unserialize($data));
    }

    /**
     * Magic method used to rebuild the Email object.
     *
     * @param array $data Data array.
     */
    void __unserialize(array $data) {
        this.createFromArray($data);
    }

    /**
     * Proxy all static method calls (for methods provided by StaticConfigTrait) to Mailer.
     *
     * @param string aName Method name.
     * @param array $arguments Method argument.
     * @return mixed
     */
    static function __callStatic($name, $arguments) {
        return [Mailer::class, $name](...$arguments);
    }
}
