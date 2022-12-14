module uim.cake.I18n;

import uim.cake.Chronos\Date as ChronosDate;
use IntlDateFormatter;

/**
 * : the Date class provided by Chronos.
 *
 * Adds handy methods and locale-aware formatting helpers
 *
 * This object provides an immutable variant of {@link uim.cake.I18n\Date}
 */
class FrozenDate : ChronosDate : I18nDateTimeInterface
{
    use DateFormatTrait;

    /**
     * The format to use when formatting a time using `Cake\I18n\Date::i18nFormat()`
     * and `__toString`. This format is also used by `parseDateTime()`.
     *
     * The format should be either the formatting constants from IntlDateFormatter as
     * described in (https://secure.php.net/manual/en/class.intldateformatter.php) or a pattern
     * as specified in (https://unicode-org.github.io/icu-docs/apidoc/released/icu4c/classSimpleDateFormat.html#details)
     *
     * It is possible to provide an array of 2 constants. In this case, the first position
     * will be used for formatting the date part of the object and the second position
     * will be used to format the time part.
     *
     * @var array<int>|string|int
     * @see uim.cake.I18n\DateFormatTrait::i18nFormat()
     */
    protected static _toStringFormat = [IntlDateFormatter::SHORT, -1];

    /**
     * The format to use when converting this object to JSON.
     *
     * The format should be either the formatting constants from IntlDateFormatter as
     * described in (https://secure.php.net/manual/en/class.intldateformatter.php) or a pattern
     * as specified in (https://unicode-org.github.io/icu-docs/apidoc/released/icu4c/classSimpleDateFormat.html#details)
     *
     * It is possible to provide an array of 2 constants. In this case, the first position
     * will be used for formatting the date part of the object and the second position
     * will be used to format the time part.
     *
     * @var \Closure|array<int>|string|int
     * @see uim.cake.I18n\Time::i18nFormat()
     */
    protected static _jsonEncodeFormat = "yyyy-MM-dd";

    /**
     * The format to use when formatting a time using `Cake\I18n\Date::timeAgoInWords()`
     * and the difference is more than `Cake\I18n\Date::$wordEnd`
     *
     * @var array<int>|string|int
     * @see uim.cake.I18n\DateFormatTrait::parseDate()
     */
    static $wordFormat = [IntlDateFormatter::SHORT, IntlDateFormatter::NONE];

    /**
     * The format to use when formatting a time using `Cake\I18n\Date::nice()`
     *
     * The format should be either the formatting constants from IntlDateFormatter as
     * described in (https://secure.php.net/manual/en/class.intldateformatter.php) or a pattern
     * as specified in (https://unicode-org.github.io/icu-docs/apidoc/released/icu4c/classSimpleDateFormat.html#details)
     *
     * It is possible to provide an array of 2 constants. In this case, the first position
     * will be used for formatting the date part of the object and the second position
     * will be used to format the time part.
     *
     * @var array<int>|string|int
     * @see uim.cake.I18n\DateFormatTrait::nice()
     */
    static $niceFormat = [IntlDateFormatter::MEDIUM, IntlDateFormatter::NONE];

    /**
     * The format to use when formatting a time using `Date::timeAgoInWords()`
     * and the difference is less than `Date::$wordEnd`
     *
     * @var array<string>
     * @see uim.cake.I18n\Date::timeAgoInWords()
     */
    static $wordAccuracy = [
        "year": "day",
        "month": "day",
        "week": "day",
        "day": "day",
        "hour": "day",
        "minute": "day",
        "second": "day",
    ];

    /**
     * The end of relative time telling
     *
     * @var string
     * @see uim.cake.I18n\Date::timeAgoInWords()
     */
    static $wordEnd = "+1 month";

    /**
     * Create a new Date instance.
     *
     * You can specify the timezone for the $time parameter. This timezone will
     * not be used in any future modifications to the Date instance.
     *
     * The `$timezone` parameter is ignored if `$time` is a DateTimeInterface
     * instance.
     *
     * Date instances lack time components, however due to limitations in PHP"s
     * internal Datetime object the time will always be set to 00:00:00, and the
     * timezone will always be the server local time. Normalizing the timezone allows for
     * subtraction/addition to have deterministic results.
     *
     * @param \DateTime|\DateTimeImmutable|string|int|null $time Fixed or relative time
     * @param \DateTimeZone|string|null $tz The timezone in which the date is taken.
     *                                  Ignored if `$time` is a DateTimeInterface instance.
     */
    this($time = "now", $tz = null) {
        super(($time, $tz);
    }

    /**
     * Returns either a relative or a formatted absolute date depending
     * on the difference between the current date and this object.
     *
     * ### Options:
     *
     * - `from`: another Date object representing the "now" date
     * - `format`: a fall back format if the relative time is longer than the duration specified by end
     * - `accuracy`: Specifies how accurate the date should be described (array)
     *     - year:   The format if years > 0   (default "day")
     *     - month:  The format if months > 0  (default "day")
     *     - week:   The format if weeks > 0   (default "day")
     *     - day:    The format if weeks > 0   (default "day")
     * - `end`: The end of relative date telling
     * - `relativeString`: The printf compatible string when outputting relative date
     * - `absoluteString`: The printf compatible string when outputting absolute date
     * - `timezone`: The user timezone the timestamp should be formatted in.
     *
     * Relative dates look something like this:
     *
     * - 3 weeks, 4 days ago
     * - 1 day ago
     *
     * Default date formatting is d/M/YY e.g: on 18/2/09. Formatting is done internally using
     * `i18nFormat`, see the method for the valid formatting strings.
     *
     * The returned string includes "ago" or "on" and assumes you"ll properly add a word
     * like "Posted " before the function output.
     *
     * NOTE: If the difference is one week or more, the lowest level of accuracy is day.
     *
     * @param array<string, mixed> $options Array of options.
     * @return string Relative time string.
     */
    string timeAgoInWords(STRINGAA someOptions = null) {
        /** @psalm-suppress UndefinedInterfaceMethod */
        return static::getDiffFormatter().dateAgoInWords(this, $options);
    }
}
