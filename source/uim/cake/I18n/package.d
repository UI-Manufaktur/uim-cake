


 *

 * @copyright     Copyright (c) 2017 Aura for PHP

 * @since         4.2.0
  */module uim.cake.I18n;

/**
 * Message Catalog
 */
class Package
{
    /**
     * Message keys and translations in this package.
     *
     * @var array<array|string>
     */
    protected $messages = [];

    /**
     * The name of a fallback package to use when a message key does not
     * exist.
     *
     * @var string|null
     */
    protected $fallback;

    /**
     * The name of the formatter to use when formatting translated messages.
     *
     */
    protected string $formatter;

    /**
     * Constructor.
     *
     * @param string $formatter The name of the formatter to use.
     * @param string|null $fallback The name of the fallback package to use.
     * @param array<array|string> $messages The messages in this package.
     */
    this(
        string $formatter = "default",
        ?string $fallback = null,
        array $messages = []
    ) {
        this.formatter = $formatter;
        this.fallback = $fallback;
        this.messages = $messages;
    }

    /**
     * Sets the messages for this package.
     *
     * @param array<array|string> $messages The messages for this package.
     */
    void setMessages(array $messages): void
    {
        this.messages = $messages;
    }

    /**
     * Adds one message for this package.
     *
     * @param string aKey the key of the message
     * @param array|string $message the actual message
     */
    void addMessage(string aKey, $message): void
    {
        this.messages[$key] = $message;
    }

    /**
     * Adds new messages for this package.
     *
     * @param array<array|string> $messages The messages to add in this package.
     */
    void addMessages(array $messages): void
    {
        this.messages = array_merge(this.messages, $messages);
    }

    /**
     * Gets the messages for this package.
     *
     * @return array<array|string>
     */
    function getMessages(): array
    {
        return this.messages;
    }

    /**
     * Gets the message of the given key for this package.
     *
     * @param string aKey the key of the message to return
     * @return array|string|false The message translation, or false if not found.
     */
    function getMessage(string aKey) {
        return this.messages[$key] ?? false;
    }

    /**
     * Sets the formatter name for this package.
     *
     * @param string $formatter The formatter name for this package.
     */
    void setFormatter(string $formatter): void
    {
        this.formatter = $formatter;
    }

    /**
     * Gets the formatter name for this package.
     */
    string getFormatter(): string
    {
        return this.formatter;
    }

    /**
     * Sets the fallback package name.
     *
     * @param string|null $fallback The fallback package name.
     */
    void setFallback(?string $fallback): void
    {
        this.fallback = $fallback;
    }

    /**
     * Gets the fallback package name.
     *
     * @return string|null
     */
    function getFallback(): ?string
    {
        return this.fallback;
    }
}
