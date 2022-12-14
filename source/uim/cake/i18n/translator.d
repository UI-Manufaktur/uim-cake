/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.I18n;
module uim.cake.I18n;

/**
 * Translator to translate the message.
 *
 * @internal
 */
class Translator
{
    /**
     */
    const string PLURAL_PREFIX = "p:";

    /**
     * A fallback translator.
     *
     * @var uim.cake.I18n\Translator|null
     */
    protected $fallback;

    /**
     * The formatter to use when translating messages.
     *
     * @var uim.cake.I18n\IFormatter
     */
    protected $formatter;

    /**
     * The locale being used for translations.
     */
    protected string $locale;

    /**
     * The Package containing keys and translations.
     *
     * @var uim.cake.I18n\Package
     */
    protected $package;

    /**
     * Constructor
     *
     * @param string $locale The locale being used.
     * @param uim.cake.I18n\Package $package The Package containing keys and translations.
     * @param uim.cake.I18n\IFormatter $formatter A message formatter.
     * @param uim.cake.I18n\Translator|null $fallback A fallback translator.
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
     * @param string aKey The message key.
     * @return mixed The message translation string, or false if not found.
     */
    protected function getMessage(string aKey) {
        $message = this.package.getMessage($key);
        if ($message) {
            return $message;
        }

        if (this.fallback) {
            $message = this.fallback.getMessage($key);
            if ($message) {
                this.package.addMessage($key, $message);

                return $message;
            }
        }

        return false;
    }

    /**
     * Translates the message formatting any placeholders
     *
     * @param string aKey The message key.
     * @param array $tokensValues Token values to interpolate into the
     *   message.
     * @return string The translated message with tokens replaced.
     */
    string translate(string aKey, array $tokensValues = null) {
        if (isset($tokensValues["_count"])) {
            $message = this.getMessage(static::PLURAL_PREFIX . $key);
            if (!$message) {
                $message = this.getMessage($key);
            }
        } else {
            $message = this.getMessage($key);
            if (!$message) {
                $message = this.getMessage(static::PLURAL_PREFIX . $key);
            }
        }

        if (!$message) {
            // Fallback to the message key
            $message = $key;
        }

        // Check for missing/invalid context
        if (is_array($message) && isset($message["_context"])) {
            $message = this.resolveContext($key, $message, $tokensValues);
            unset($tokensValues["_context"]);
        }

        if (empty($tokensValues)) {
            // Fallback for plurals that were using the singular key
            if (is_array($message)) {
                return array_values($message + [""])[0];
            }

            return $message;
        }

        // Singular message, but plural call
        if (is_string($message) && isset($tokensValues["_singular"])) {
            $message = [$tokensValues["_singular"], $message];
        }

        // Resolve plural form.
        if (is_array($message)) {
            $count = $tokensValues["_count"] ?? 0;
            $form = PluralRules::calculate(this.locale, (int)$count);
            $message = $message[$form] ?? (string)end($message);
        }

        if ($message == "") {
            $message = $key;

            // If singular haven"t been translated, fallback to the key.
            if (isset($tokensValues["_singular"]) && $tokensValues["_count"] == 1) {
                $message = $tokensValues["_singular"];
            }
        }

        unset($tokensValues["_count"], $tokensValues["_singular"]);

        return this.formatter.format(this.locale, $message, $tokensValues);
    }

    /**
     * Resolve a message"s context structure.
     *
     * @param string aKey The message key being handled.
     * @param array $message The message content.
     * @param array $vars The variables containing the `_context` key.
     * @return array|string
     */
    protected function resolveContext(string aKey, array $message, array $vars) {
        $context = $vars["_context"] ?? null;

        // No or missing context, fallback to the key/first message
        if ($context == null) {
            if (isset($message["_context"][""])) {
                return $message["_context"][""] == "" ? $key : $message["_context"][""];
            }

            return current($message["_context"]);
        }
        if (!isset($message["_context"][$context])) {
            return $key;
        }
        if ($message["_context"][$context] == "") {
            return $key;
        }

        return $message["_context"][$context];
    }

    /**
     * Returns the translator package
     *
     * @return uim.cake.I18n\Package
     */
    function getPackage(): Package
    {
        return this.package;
    }
}
