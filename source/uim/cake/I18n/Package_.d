

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @copyright     Copyright (c) 2017 Aura for PHP
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.I18n;

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
    protected myMessages = [];

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
     * @var string
     */
    protected $formatter;

    /**
     * Constructor.
     *
     * @param string $formatter The name of the formatter to use.
     * @param string|null $fallback The name of the fallback package to use.
     * @param array<array|string> myMessages The messages in this package.
     */
    this(
        string $formatter = 'default',
        ?string $fallback = null,
        array myMessages = []
    ) {
        this.formatter = $formatter;
        this.fallback = $fallback;
        this.messages = myMessages;
    }

    /**
     * Sets the messages for this package.
     *
     * @param array<array|string> myMessages The messages for this package.
     * @return void
     */
    auto setMessages(array myMessages): void
    {
        this.messages = myMessages;
    }

    /**
     * Adds one message for this package.
     *
     * @param string myKey the key of the message
     * @param array|string myMessage the actual message
     * @return void
     */
    function addMessage(string myKey, myMessage): void
    {
        this.messages[myKey] = myMessage;
    }

    /**
     * Adds new messages for this package.
     *
     * @param array<array|string> myMessages The messages to add in this package.
     * @return void
     */
    function addMessages(array myMessages): void
    {
        this.messages = array_merge(this.messages, myMessages);
    }

    /**
     * Gets the messages for this package.
     *
     * @return array<array|string>
     */
    auto getMessages(): array
    {
        return this.messages;
    }

    /**
     * Gets the message of the given key for this package.
     *
     * @param string myKey the key of the message to return
     * @return array|string|false The message translation, or false if not found.
     */
    auto getMessage(string myKey) {
        return this.messages[myKey] ?? false;
    }

    /**
     * Sets the formatter name for this package.
     *
     * @param string $formatter The formatter name for this package.
     * @return void
     */
    auto setFormatter(string $formatter): void
    {
        this.formatter = $formatter;
    }

    /**
     * Gets the formatter name for this package.
     *
     * @return string
     */
    string getFormatter() {
        return this.formatter;
    }

    /**
     * Sets the fallback package name.
     *
     * @param string|null $fallback The fallback package name.
     * @return void
     */
    auto setFallback(?string $fallback): void
    {
        this.fallback = $fallback;
    }

    /**
     * Gets the fallback package name.
     *
     * @return string|null
     */
    auto getFallback(): ?string
    {
        return this.fallback;
    }
}
