

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         0.10.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.View\Helper;

import uim.cake.core.App;
import uim.cake.core.Exception\CakeException;
import uim.cake.I18n\Number;
import uim.cake.View\Helper;
import uim.cake.View\View;

/**
 * Number helper library.
 *
 * Methods to make numbers more readable.
 *
 * @link https://book.cakephp.org/4/en/views/helpers/number.html
 * @see \Cake\I18n\Number
 */
class NumberHelper : Helper
{
    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        'engine' => Number::class,
    ];

    /**
     * Cake\I18n\Number instance
     *
     * @var \Cake\I18n\Number
     */
    protected $_engine;

    /**
     * Default Constructor
     *
     * ### Settings:
     *
     * - `engine` Class name to use to replace Cake\I18n\Number functionality
     *            The class needs to be placed in the `Utility` directory.
     *
     * @param \Cake\View\View $view The View this helper is being attached to.
     * @param array<string, mixed> myConfig Configuration settings for the helper
     * @throws \Cake\Core\Exception\CakeException When the engine class could not be found.
     */
    this(View $view, array myConfig = [])
    {
        super.this($view, myConfig);

        myConfig = this._config;

        /** @psalm-var class-string<\Cake\I18n\Number>|null $engineClass */
        $engineClass = App::className(myConfig['engine'], 'Utility');
        if ($engineClass === null) {
            throw new CakeException(sprintf('Class for %s could not be found', myConfig['engine']));
        }

        this._engine = new $engineClass(myConfig);
    }

    /**
     * Call methods from Cake\I18n\Number utility class
     *
     * @param string $method Method to invoke
     * @param array myParams Array of params for the method.
     * @return mixed Whatever is returned by called method, or false on failure
     */
    auto __call(string $method, array myParams)
    {
        return this._engine.{$method}(...myParams);
    }

    /**
     * Formats a number with a level of precision.
     *
     * @param string|float $number A floating point number.
     * @param int $precision The precision of the returned number.
     * @param array<string, mixed> myOptions Additional options.
     * @return string Formatted float.
     * @see \Cake\I18n\Number::precision()
     * @link https://book.cakephp.org/4/en/views/helpers/number.html#formatting-floating-point-numbers
     */
    function precision($number, int $precision = 3, array myOptions = []): string
    {
        return this._engine.precision($number, $precision, myOptions);
    }

    /**
     * Returns a formatted-for-humans file size.
     *
     * @param string|int $size Size in bytes
     * @return string Human readable size
     * @see \Cake\I18n\Number::toReadableSize()
     * @link https://book.cakephp.org/4/en/views/helpers/number.html#interacting-with-human-readable-values
     */
    function toReadableSize($size): string
    {
        return this._engine.toReadableSize($size);
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
     * @param array<string, mixed> myOptions Options
     * @return string Percentage string
     * @see \Cake\I18n\Number::toPercentage()
     * @link https://book.cakephp.org/4/en/views/helpers/number.html#formatting-percentages
     */
    function toPercentage($number, int $precision = 2, array myOptions = []): string
    {
        return this._engine.toPercentage($number, $precision, myOptions);
    }

    /**
     * Formats a number into the correct locale format
     *
     * Options:
     *
     * - `places` - Minimum number or decimals to use, e.g 0
     * - `precision` - Maximum Number of decimal places to use, e.g. 2
     * - `locale` - The locale name to use for formatting the number, e.g. fr_FR
     * - `before` - The string to place before whole numbers, e.g. '['
     * - `after` - The string to place after decimal numbers, e.g. ']'
     * - `escape` - Whether to escape html in resulting string
     *
     * @param string|float $number A floating point number.
     * @param array<string, mixed> myOptions An array with options.
     * @return string Formatted number
     * @link https://book.cakephp.org/4/en/views/helpers/number.html#formatting-numbers
     */
    function format($number, array myOptions = []): string
    {
        $formatted = this._engine.format($number, myOptions);
        myOptions += ['escape' => true];

        return myOptions['escape'] ? h($formatted) : $formatted;
    }

    /**
     * Formats a number into a currency format.
     *
     * ### Options
     *
     * - `locale` - The locale name to use for formatting the number, e.g. fr_FR
     * - `fractionSymbol` - The currency symbol to use for fractional numbers.
     * - `fractionPosition` - The position the fraction symbol should be placed
     *    valid options are 'before' & 'after'.
     * - `before` - Text to display before the rendered number
     * - `after` - Text to display after the rendered number
     * - `zero` - The text to use for zero values, can be a string or a number. e.g. 0, 'Free!'
     * - `places` - Number of decimal places to use. e.g. 2
     * - `precision` - Maximum Number of decimal places to use, e.g. 2
     * - `pattern` - An ICU number pattern to use for formatting the number. e.g #,##0.00
     * - `useIntlCode` - Whether to replace the currency symbol with the international
     *   currency code.
     * - `escape` - Whether to escape html in resulting string
     *
     * @param string|float $number Value to format.
     * @param string|null $currency International currency name such as 'USD', 'EUR', 'JPY', 'CAD'
     * @param array<string, mixed> myOptions Options list.
     * @return string Number formatted as a currency.
     */
    function currency($number, ?string $currency = null, array myOptions = []): string
    {
        $formatted = this._engine.currency($number, $currency, myOptions);
        myOptions += ['escape' => true];

        return myOptions['escape'] ? h($formatted) : $formatted;
    }

    /**
     * Formats a number into the correct locale format to show deltas (signed differences in value).
     *
     * ### Options
     *
     * - `places` - Minimum number or decimals to use, e.g 0
     * - `precision` - Maximum Number of decimal places to use, e.g. 2
     * - `locale` - The locale name to use for formatting the number, e.g. fr_FR
     * - `before` - The string to place before whole numbers, e.g. '['
     * - `after` - The string to place after decimal numbers, e.g. ']'
     * - `escape` - Set to false to prevent escaping
     *
     * @param string|float myValue A floating point number
     * @param array<string, mixed> myOptions Options list.
     * @return string formatted delta
     */
    function formatDelta(myValue, array myOptions = []): string
    {
        $formatted = this._engine.formatDelta(myValue, myOptions);
        myOptions += ['escape' => true];

        return myOptions['escape'] ? h($formatted) : $formatted;
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
    function defaultCurrency($currency): ?string
    {
        deprecationWarning(
            'NumberHelper::defaultCurrency() is deprecated. Use setDefaultCurrency() and getDefaultCurrency() instead.'
        );

        return this._engine.defaultCurrency($currency);
    }

    /**
     * Event listeners.
     *
     * @return array<string, mixed>
     */
    function implementedEvents(): array
    {
        return [];
    }

    /**
     * Formats a number into locale specific ordinal suffix.
     *
     * @param float|int myValue An integer
     * @param array<string, mixed> myOptions An array with options.
     * @return string formatted number
     */
    function ordinal(myValue, array myOptions = []): string
    {
        return this._engine.ordinal(myValue, myOptions);
    }
}
