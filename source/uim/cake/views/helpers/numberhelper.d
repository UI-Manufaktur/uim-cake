/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.views\Helper;

import uim.cake.core.App;
import uim.cake.core.exceptions.UIMException;
import uim.cake.I18n\Number;
import uim.cake.views\Helper;
import uim.cake.views\View;

/**
 * Number helper library.
 *
 * Methods to make numbers more readable.
 *
 * @link https://book.cakephp.org/4/en/views/helpers/number.html
 * @see uim.cake.I18n\Number
 */
class NumberHelper : Helper
{
    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected _defaultConfig = [
        "engine": Number::class,
    ];

    /**
     * Cake\I18n\Number instance
     *
     * @var uim.cake.I18n\Number
     */
    protected _engine;

    /**
     * Default Constructor
     *
     * ### Settings:
     *
     * - `engine` Class name to use to replace Cake\I18n\Number functionality
     *            The class needs to be placed in the `Utility` directory.
     *
     * @param uim.cake.views\View $view The View this helper is being attached to.
     * @param array<string, mixed> aConfig Configuration settings for the helper
     * @throws uim.cake.Core\exceptions.UIMException When the engine class could not be found.
     */
    this(View $view, Json aConfig = null) {
        super(($view, aConfig);

        aConfig = _config;

        /** @psalm-var class-string<uim.cake.I18n\Number>|null $engineClass */
        $engineClass = App::className(aConfig["engine"], "Utility");
        if ($engineClass == null) {
            throw new UIMException(sprintf("Class for %s could not be found", aConfig["engine"]));
        }

        _engine = new $engineClass(aConfig);
    }

    /**
     * Call methods from Cake\I18n\Number utility class
     *
     * @param string $method Method to invoke
     * @param array $params Array of params for the method.
     * @return mixed Whatever is returned by called method, or false on failure
     */
    function __call(string $method, array $params) {
        return _engine.{$method}(...$params);
    }

    /**
     * Formats a number with a level of precision.
     *
     * @param string|float $number A floating point number.
     * @param int $precision The precision of the returned number.
     * @param array<string, mixed> $options Additional options.
     * @return string Formatted float.
     * @see uim.cake.I18n\Number::precision()
     * @link https://book.cakephp.org/4/en/views/helpers/number.html#formatting-floating-point-numbers
     */
    string precision($number, int $precision = 3, STRINGAA someOptions = null) {
        return _engine.precision($number, $precision, $options);
    }

    /**
     * Returns a formatted-for-humans file size.
     *
     * @param string|int $size Size in bytes
     * @return string Human readable size
     * @see uim.cake.I18n\Number::toReadableSize()
     * @link https://book.cakephp.org/4/en/views/helpers/number.html#interacting-with-human-readable-values
     */
    string toReadableSize($size) {
        return _engine.toReadableSize($size);
    }

    /**
     * Formats a number into a percentage string.
     *
     * Options:
     *
     * - `multiply`: Multiply the input value by 100 for decimal percentages.
     *
     * @param string|float $number A floating point number
     * @param int $precision The precision of the returned number
     * @param array<string, mixed> $options Options
     * @return string Percentage string
     * @see uim.cake.I18n\Number::toPercentage()
     * @link https://book.cakephp.org/4/en/views/helpers/number.html#formatting-percentages
     */
    string toPercentage($number, int $precision = 2, STRINGAA someOptions = null) {
        return _engine.toPercentage($number, $precision, $options);
    }

    /**
     * Formats a number into the correct locale format
     *
     * Options:
     *
     * - `places` - Minimum number or decimals to use, e.g 0
     * - `precision` - Maximum Number of decimal places to use, e.g. 2
     * - `locale` - The locale name to use for formatting the number, e.g. fr_FR
     * - `before` - The string to place before whole numbers, e.g~ "["
     * - `after` - The string to place after decimal numbers, e.g~ "]"
     * - `escape` - Whether to escape html in resulting string
     *
     * @param string|int|float $number A floating point number.
     * @param array<string, mixed> $options An array with options.
     * @return string Formatted number
     * @link https://book.cakephp.org/4/en/views/helpers/number.html#formatting-numbers
     */
    string format($number, STRINGAA someOptions = null) {
        $formatted = _engine.format($number, $options);
        $options += ["escape": true];

        return $options["escape"] ? h($formatted) : $formatted;
    }

    /**
     * Formats a number into a currency format.
     *
     * ### Options
     *
     * - `locale` - The locale name to use for formatting the number, e.g. fr_FR
     * - `fractionSymbol` - The currency symbol to use for fractional numbers.
     * - `fractionPosition` - The position the fraction symbol should be placed
     *    valid options are "before" & "after".
     * - `before` - Text to display before the rendered number
     * - `after` - Text to display after the rendered number
     * - `zero` - The text to use for zero values, can be a string or a number. e.g. 0, "Free!"
     * - `places` - Number of decimal places to use. e.g. 2
     * - `precision` - Maximum Number of decimal places to use, e.g. 2
     * - `pattern` - An ICU number pattern to use for formatting the number. e.g #,##0.00
     * - `useIntlCode` - Whether to replace the currency symbol with the international
     *   currency code.
     * - `escape` - Whether to escape html in resulting string
     *
     * @param string|float $number Value to format.
     * @param string|null $currency International currency name such as "USD", "EUR", "JPY", "CAD"
     * @param array<string, mixed> $options Options list.
     * @return string Number formatted as a currency.
     */
    string currency($number, Nullable!string $currency = null, STRINGAA someOptions = null) {
        $formatted = _engine.currency($number, $currency, $options);
        $options += ["escape": true];

        return $options["escape"] ? h($formatted) : $formatted;
    }

    /**
     * Formats a number into the correct locale format to show deltas (signed differences in value).
     *
     * ### Options
     *
     * - `places` - Minimum number or decimals to use, e.g 0
     * - `precision` - Maximum Number of decimal places to use, e.g. 2
     * - `locale` - The locale name to use for formatting the number, e.g. fr_FR
     * - `before` - The string to place before whole numbers, e.g~ "["
     * - `after` - The string to place after decimal numbers, e.g~ "]"
     * - `escape` - Set to false to prevent escaping
     *
     * @param string|float $value A floating point number
     * @param array<string, mixed> $options Options list.
     * @return string formatted delta
     */
    string formatDelta($value, STRINGAA someOptions = null) {
        $formatted = _engine.formatDelta($value, $options);
        $options += ["escape": true];

        return $options["escape"] ? h($formatted) : $formatted;
    }

    /**
     * Getter/setter for default currency
     *
     * @param string|false|null $currency Default currency string to be used by currency()
     * if $currency argument is not provided. If boolean false is passed, it will clear the
     * currently stored value. Null reads the current default.
     * @return string|null Currency
     * @deprecated 3.9.0 Use setDefaultCurrency()/getDefaultCurrency() instead.
     */
    Nullable!string defaultCurrency($currency) {
        deprecationWarning(
            "NumberHelper::defaultCurrency() is deprecated. Use setDefaultCurrency() and getDefaultCurrency() instead."
        );

        return _engine.defaultCurrency($currency);
    }

    /**
     * Event listeners.
     *
     * @return array<string, mixed>
     */
    array implementedEvents() {
        return [];
    }

    /**
     * Formats a number into locale specific ordinal suffix.
     *
     * @param float|int $value An integer
     * @param array<string, mixed> $options An array with options.
     * @return string formatted number
     */
    string ordinal($value, STRINGAA someOptions = null) {
        return _engine.ordinal($value, $options);
    }
}
