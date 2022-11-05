

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         0.10.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.I18n;

use NumberFormatter;

/**
 * Number helper library.
 *
 * Methods to make numbers more readable.
 *
 * @link https://book.cakephp.org/4/en/core-libraries/number.html
 */
class Number
{
    /**
     * Default locale
     *
     * @var string
     */
    public const DEFAULT_LOCALE = 'en_US';

    /**
     * Format type to format as currency
     *
     * @var string
     */
    public const FORMAT_CURRENCY = 'currency';

    /**
     * Format type to format as currency, accounting style (negative numbers in parentheses)
     *
     * @var string
     */
    public const FORMAT_CURRENCY_ACCOUNTING = 'currency_accounting';

    /**
     * ICU Constant for accounting format; not yet widely supported by INTL library.
     * This will be able to go away once CakePHP minimum PHP requirement is 7.4.1 or higher.
     * See UNUM_CURRENCY_ACCOUNTING in https://unicode-org.github.io/icu-docs/apidoc/released/icu4c/unum_8h.html
     *
     * @var int
     */
    public const CURRENCY_ACCOUNTING = 12;

    /**
     * A list of number formatters indexed by locale and type
     *
     * @var array<string, array<int, mixed>>
     */
    protected static $_formatters = [];

    /**
     * Default currency used by Number::currency()
     *
     * @var string|null
     */
    protected static $_defaultCurrency;

    /**
     * Default currency format used by Number::currency()
     *
     * @var string|null
     */
    protected static $_defaultCurrencyFormat;

    /**
     * Formats a number with a level of precision.
     *
     * Options:
     *
     * - `locale`: The locale name to use for formatting the number, e.g. fr_FR
     *
     * @param string|float myValue A floating point number.
     * @param int $precision The precision of the returned number.
     * @param array<string, mixed> myOptions Additional options
     * @return string Formatted float.
     * @link https://book.cakephp.org/4/en/core-libraries/number.html#formatting-floating-point-numbers
     */
    static function precision(myValue, int $precision = 3, array myOptions = []): string
    {
        $formatter = static::formatter(['precision' => $precision, 'places' => $precision] + myOptions);

        return $formatter.format(myValue);
    }

    /**
     * Returns a formatted-for-humans file size.
     *
     * @param string|int $size Size in bytes
     * @return string Human readable size
     * @link https://book.cakephp.org/4/en/core-libraries/number.html#interacting-with-human-readable-values
     */
    static function toReadableSize($size): string
    {
        $size = (int)$size;

        switch (true) {
            case $size < 1024:
                return __dn('cake', '{0,number,integer} Byte', '{0,number,integer} Bytes', $size, $size);
            case round($size / 1024) < 1024:
                return __d('cake', '{0,number,#,###.##} KB', $size / 1024);
            case round($size / 1024 / 1024, 2) < 1024:
                return __d('cake', '{0,number,#,###.##} MB', $size / 1024 / 1024);
            case round($size / 1024 / 1024 / 1024, 2) < 1024:
                return __d('cake', '{0,number,#,###.##} GB', $size / 1024 / 1024 / 1024);
            default:
                return __d('cake', '{0,number,#,###.##} TB', $size / 1024 / 1024 / 1024 / 1024);
        }
    }

    /**
     * Formats a number into a percentage string.
     *
     * Options:
     *
     * - `multiply`: Multiply the input value by 100 for decimal percentages.
     * - `locale`: The locale name to use for formatting the number, e.g. fr_FR
     *
     * @param string|float myValue A floating point number
     * @param int $precision The precision of the returned number
     * @param array<string, mixed> myOptions Options
     * @return string Percentage string
     * @link https://book.cakephp.org/4/en/core-libraries/number.html#formatting-percentages
     */
    static function toPercentage(myValue, int $precision = 2, array myOptions = []): string
    {
        myOptions += ['multiply' => false, 'type' => NumberFormatter::PERCENT];
        if (!myOptions['multiply']) {
            myValue = (float)myValue / 100;
        }

        return static::precision(myValue, $precision, myOptions);
    }

    /**
     * Formats a number into the correct locale format
     *
     * Options:
     *
     * - `places` - Minimum number or decimals to use, e.g 0
     * - `precision` - Maximum Number of decimal places to use, e.g. 2
     * - `pattern` - An ICU number pattern to use for formatting the number. e.g #,##0.00
     * - `locale` - The locale name to use for formatting the number, e.g. fr_FR
     * - `before` - The string to place before whole numbers, e.g. '['
     * - `after` - The string to place after decimal numbers, e.g. ']'
     *
     * @param string|float myValue A floating point number.
     * @param array<string, mixed> myOptions An array with options.
     * @return string Formatted number
     */
    static function format(myValue, array myOptions = []): string
    {
        $formatter = static::formatter(myOptions);
        myOptions += ['before' => '', 'after' => ''];

        return myOptions['before'] . $formatter.format((float)myValue) . myOptions['after'];
    }

    /**
     * Parse a localized numeric string and transform it in a float point
     *
     * Options:
     *
     * - `locale` - The locale name to use for parsing the number, e.g. fr_FR
     * - `type` - The formatter type to construct, set it to `currency` if you need to parse
     *    numbers representing money.
     *
     * @param string myValue A numeric string.
     * @param array<string, mixed> myOptions An array with options.
     * @return float point number
     */
    static function parseFloat(string myValue, array myOptions = []): float
    {
        $formatter = static::formatter(myOptions);

        return (float)$formatter.parse(myValue, NumberFormatter::TYPE_DOUBLE);
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
     *
     * @param string|float myValue A floating point number
     * @param array<string, mixed> myOptions Options list.
     * @return string formatted delta
     */
    static function formatDelta(myValue, array myOptions = []): string
    {
        myOptions += ['places' => 0];
        myValue = number_format((float)myValue, myOptions['places'], '.', '');
        $sign = myValue > 0 ? '+' : '';
        myOptions['before'] = isset(myOptions['before']) ? myOptions['before'] . $sign : $sign;

        return static::format(myValue, myOptions);
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
     *
     * @param string|float myValue Value to format.
     * @param string|null $currency International currency name such as 'USD', 'EUR', 'JPY', 'CAD'
     * @param array<string, mixed> myOptions Options list.
     * @return string Number formatted as a currency.
     */
    static function currency(myValue, Nullable!string $currency = null, array myOptions = []): string
    {
        myValue = (float)myValue;
        $currency = $currency ?: static::getDefaultCurrency();

        if (isset(myOptions['zero']) && !myValue) {
            return myOptions['zero'];
        }

        $formatter = static::formatter(['type' => static::getDefaultCurrencyFormat()] + myOptions);
        $abs = abs(myValue);
        if (!empty(myOptions['fractionSymbol']) && $abs > 0 && $abs < 1) {
            myValue *= 100;
            $pos = myOptions['fractionPosition'] ?? 'after';

            return static::format(myValue, ['precision' => 0, $pos => myOptions['fractionSymbol']]);
        }

        $before = myOptions['before'] ?? '';
        $after = myOptions['after'] ?? '';
        myValue = $formatter.formatCurrency(myValue, $currency);

        return $before . myValue . $after;
    }

    /**
     * Getter/setter for default currency. This behavior is *deprecated* and will be
     * removed in future versions of CakePHP.
     *
     * @deprecated 3.9.0 Use {@link getDefaultCurrency()} and {@link setDefaultCurrency()} instead.
     * @param string|false|null $currency Default currency string to be used by {@link currency()}
     * if $currency argument is not provided. If boolean false is passed, it will clear the
     * currently stored value
     * @return string|null Currency
     */
    static function defaultCurrency($currency = null): Nullable!string
    {
        deprecationWarning(
            'Number::defaultCurrency() is deprecated. ' .
            'Use Number::setDefaultCurrency()/getDefaultCurrency() instead.'
        );

        if ($currency === false) {
            static::setDefaultCurrency(null);

            // This doesn't seem like a useful result to return, but it's what the old version did.
            // Retaining it for backward compatibility.
            return null;
        }
        if ($currency !== null) {
            static::setDefaultCurrency($currency);
        }

        return static::getDefaultCurrency();
    }

    /**
     * Getter for default currency
     *
     * @return string Currency
     */
    static auto getDefaultCurrency(): string
    {
        if (static::$_defaultCurrency === null) {
            $locale = ini_get('intl.default_locale') ?: static::DEFAULT_LOCALE;
            $formatter = new NumberFormatter($locale, NumberFormatter::CURRENCY);
            static::$_defaultCurrency = $formatter.getTextAttribute(NumberFormatter::CURRENCY_CODE);
        }

        return static::$_defaultCurrency;
    }

    /**
     * Setter for default currency
     *
     * @param string|null $currency Default currency string to be used by {@link currency()}
     * if $currency argument is not provided. If null is passed, it will clear the
     * currently stored value
     * @return void
     */
    static auto setDefaultCurrency(Nullable!string $currency = null): void
    {
        static::$_defaultCurrency = $currency;
    }

    /**
     * Getter for default currency format
     *
     * @return string Currency Format
     */
    static auto getDefaultCurrencyFormat(): string
    {
        if (static::$_defaultCurrencyFormat === null) {
            static::$_defaultCurrencyFormat = static::FORMAT_CURRENCY;
        }

        return static::$_defaultCurrencyFormat;
    }

    /**
     * Setter for default currency format
     *
     * @param string|null $currencyFormat Default currency format to be used by currency()
     * if $currencyFormat argument is not provided. If null is passed, it will clear the
     * currently stored value
     * @return void
     */
    static auto setDefaultCurrencyFormat($currencyFormat = null): void
    {
        static::$_defaultCurrencyFormat = $currencyFormat;
    }

    /**
     * Returns a formatter object that can be reused for similar formatting task
     * under the same locale and options. This is often a speedier alternative to
     * using other methods in this class as only one formatter object needs to be
     * constructed.
     *
     * ### Options
     *
     * - `locale` - The locale name to use for formatting the number, e.g. fr_FR
     * - `type` - The formatter type to construct, set it to `currency` if you need to format
     *    numbers representing money or a NumberFormatter constant.
     * - `places` - Number of decimal places to use. e.g. 2
     * - `precision` - Maximum Number of decimal places to use, e.g. 2
     * - `pattern` - An ICU number pattern to use for formatting the number. e.g #,##0.00
     * - `useIntlCode` - Whether to replace the currency symbol with the international
     *   currency code.
     *
     * @param array<string, mixed> myOptions An array with options.
     * @return \NumberFormatter The configured formatter instance
     */
    static function formatter(array myOptions = []): NumberFormatter
    {
        $locale = myOptions['locale'] ?? ini_get('intl.default_locale');

        if (!$locale) {
            $locale = static::DEFAULT_LOCALE;
        }

        myType = NumberFormatter::DECIMAL;
        if (!empty(myOptions['type'])) {
            myType = myOptions['type'];
            if (myOptions['type'] === static::FORMAT_CURRENCY) {
                myType = NumberFormatter::CURRENCY;
            } elseif (myOptions['type'] === static::FORMAT_CURRENCY_ACCOUNTING) {
                if (defined('NumberFormatter::CURRENCY_ACCOUNTING')) {
                    myType = NumberFormatter::CURRENCY_ACCOUNTING;
                } else {
                    myType = static::CURRENCY_ACCOUNTING;
                }
            }
        }

        if (!isset(static::$_formatters[$locale][myType])) {
            static::$_formatters[$locale][myType] = new NumberFormatter($locale, myType);
        }

        /** @var \NumberFormatter $formatter */
        $formatter = static::$_formatters[$locale][myType];

        // PHP 8.0.0 - 8.0.6 throws an exception when cloning NumberFormatter after a failed parse
        if (version_compare(PHP_VERSION, '8.0.6', '>') || version_compare(PHP_VERSION, '8.0.0', '<')) {
            myOptions = array_intersect_key(myOptions, [
                'places' => null,
                'precision' => null,
                'pattern' => null,
                'useIntlCode' => null,
            ]);
            if (empty(myOptions)) {
                return $formatter;
            }
        }

        $formatter = clone $formatter;

        return static::_setAttributes($formatter, myOptions);
    }

    /**
     * Configure formatters.
     *
     * @param string $locale The locale name to use for formatting the number, e.g. fr_FR
     * @param int myType The formatter type to construct. Defaults to NumberFormatter::DECIMAL.
     * @param array<string, mixed> myOptions See Number::formatter() for possible options.
     * @return void
     */
    static function config(string $locale, int myType = NumberFormatter::DECIMAL, array myOptions = []): void
    {
        static::$_formatters[$locale][myType] = static::_setAttributes(
            new NumberFormatter($locale, myType),
            myOptions
        );
    }

    /**
     * Set formatter attributes
     *
     * @param \NumberFormatter $formatter Number formatter instance.
     * @param array<string, mixed> myOptions See Number::formatter() for possible options.
     * @return \NumberFormatter
     */
    protected static auto _setAttributes(NumberFormatter $formatter, array myOptions = []): NumberFormatter
    {
        if (isset(myOptions['places'])) {
            $formatter.setAttribute(NumberFormatter::MIN_FRACTION_DIGITS, myOptions['places']);
        }

        if (isset(myOptions['precision'])) {
            $formatter.setAttribute(NumberFormatter::MAX_FRACTION_DIGITS, myOptions['precision']);
        }

        if (!empty(myOptions['pattern'])) {
            $formatter.setPattern(myOptions['pattern']);
        }

        if (!empty(myOptions['useIntlCode'])) {
            // One of the odd things about ICU is that the currency marker in patterns
            // is denoted with ¤, whereas the international code is marked with ¤¤,
            // in order to use the code we need to simply duplicate the character wherever
            // it appears in the pattern.
            $pattern = trim(str_replace('¤', '¤¤ ', $formatter.getPattern()));
            $formatter.setPattern($pattern);
        }

        return $formatter;
    }

    /**
     * Returns a formatted integer as an ordinal number string (e.g. 1st, 2nd, 3rd, 4th, [...])
     *
     * ### Options
     *
     * - `type` - The formatter type to construct, set it to `currency` if you need to format
     *    numbers representing money or a NumberFormatter constant.
     *
     * For all other options see formatter().
     *
     * @param float|int myValue An integer
     * @param array<string, mixed> myOptions An array with options.
     * @return string
     */
    static function ordinal(myValue, array myOptions = []): string
    {
        return static::formatter(['type' => NumberFormatter::ORDINAL] + myOptions).format(myValue);
    }
}
