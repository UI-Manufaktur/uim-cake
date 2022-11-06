

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.3.12
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.I18n;

/**
 * Translator to translate the message.
 *
 * @internal
 */
class Translator
{
    /**
     * @var string
     */
    public const PLURAL_PREFIX = 'p:';

    /**
     * A fallback translator.
     *
     * @var \Cake\I18n\Translator|null
     */
    protected $fallback;

    /**
     * The formatter to use when translating messages.
     *
     * @var \Cake\I18n\IFormatter
     */
    protected $formatter;

    /**
     * The locale being used for translations.
     *
     * @var string
     */
    protected $locale;

    /**
     * The Package containing keys and translations.
     *
     * @var \Cake\I18n\Package
     */
    protected $package;

    /**
     * Constructor
     *
     * @param string $locale The locale being used.
     * @param \Cake\I18n\Package $package The Package containing keys and translations.
     * @param \Cake\I18n\IFormatter $formatter A message formatter.
     * @param \Cake\I18n\Translator|null $fallback A fallback translator.
     */
    this(
        string $locale,
        Package $package,
        IFormatter $formatter,
        ?Translator $fallback = null
    ) {
        this.locale = $locale;
        this.package = $package;
        this.formatter = $formatter;
        this.fallback = $fallback;
    }

    /**
     * Gets the message translation by its key.
     *
     * @param string myKey The message key.
     * @return mixed The message translation string, or false if not found.
     */
    protected auto getMessage(string myKey) {
        myMessage = this.package.getMessage(myKey);
        if (myMessage) {
            return myMessage;
        }

        if (this.fallback) {
            myMessage = this.fallback.getMessage(myKey);
            if (myMessage) {
                this.package.addMessage(myKey, myMessage);

                return myMessage;
            }
        }

        return false;
    }

    /**
     * Translates the message formatting any placeholders
     *
     * @param string myKey The message key.
     * @param array $tokensValues Token values to interpolate into the
     *   message.
     * @return string The translated message with tokens replaced.
     */
    function translate(string myKey, array $tokensValues = []): string
    {
        if (isset($tokensValues['_count'])) {
            myMessage = this.getMessage(static::PLURAL_PREFIX . myKey);
            if (!myMessage) {
                myMessage = this.getMessage(myKey);
            }
        } else {
            myMessage = this.getMessage(myKey);
            if (!myMessage) {
                myMessage = this.getMessage(static::PLURAL_PREFIX . myKey);
            }
        }

        if (!myMessage) {
            // Fallback to the message key
            myMessage = myKey;
        }

        // Check for missing/invalid context
        if (is_array(myMessage) && isset(myMessage['_context'])) {
            myMessage = this.resolveContext(myKey, myMessage, $tokensValues);
            unset($tokensValues['_context']);
        }

        if (empty($tokensValues)) {
            // Fallback for plurals that were using the singular key
            if (is_array(myMessage)) {
                return array_values(myMessage + [''])[0];
            }

            return myMessage;
        }

        // Singular message, but plural call
        if (is_string(myMessage) && isset($tokensValues['_singular'])) {
            myMessage = [$tokensValues['_singular'], myMessage];
        }

        // Resolve plural form.
        if (is_array(myMessage)) {
            myCount = $tokensValues['_count'] ?? 0;
            $form = PluralRules::calculate(this.locale, (int)myCount);
            myMessage = myMessage[$form] ?? (string)end(myMessage);
        }

        if (myMessage == "") {
            myMessage = myKey;
        }

        unset($tokensValues['_count'], $tokensValues['_singular']);

        return this.formatter.format(this.locale, myMessage, $tokensValues);
    }

    /**
     * Resolve a message's context structure.
     *
     * @param string myKey The message key being handled.
     * @param array myMessage The message content.
     * @param array $vars The variables containing the `_context` key.
     * @return array|string
     */
    protected auto resolveContext(string myKey, array myMessage, array $vars) {
        $context = $vars['_context'] ?? null;

        // No or missing context, fallback to the key/first message
        if ($context === null) {
            if (isset(myMessage['_context'][''])) {
                return myMessage['_context'][''] == "" ? myKey : myMessage['_context'][''];
            }

            return current(myMessage['_context']);
        }
        if (!isset(myMessage['_context'][$context])) {
            return myKey;
        }
        if (myMessage['_context'][$context] == "") {
            return myKey;
        }

        return myMessage['_context'][$context];
    }

    /**
     * Returns the translator package
     *
     * @return \Cake\I18n\Package
     */
    auto getPackage(): Package
    {
        return this.package;
    }
}
