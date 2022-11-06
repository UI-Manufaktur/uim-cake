module uim.baklava.I18n;

import uim.baklava.chronos\MutableDateTime;
use IDateTime;
use DateTimeZone;
use IntlDateFormatter;

/**
 * : the built-in DateTime class to provide handy methods and locale-aware
 * formatting helpers
 *
 * @deprecated 4.3.0 Use the immutable alternative `FrozenTime` instead.
 */
class Time : MutableDateTime : I18nIDateTime
{
    use DateFormatTrait;

    /**
     * The format to use when formatting a time using `Cake\I18n\Time::i18nFormat()`
     * and `__toString`. This format is also used by `parseDateTime()`.
     *
     * The format should be either the formatting constants from IntlDateFormatter as
     * described in (https://secure.php.net/manual/en/class.intldateformatter.php) or a pattern
     * as specified in (http://www.icu-project.org/apiref/icu4c/classSimpleDateFormat.html#details)
     *
     * It is possible to provide an array of 2 constants. In this case, the first position
     * will be used for formatting the date part of the object and the second position
     * will be used to format the time part.
     *
     * @var array<int>|string|int
     * @see \Cake\I18n\Time::i18nFormat()
     */
    protected static $_toStringFormat = [IntlDateFormatter::SHORT, IntlDateFormatter::SHORT];

    /**
     * The format to use when converting this object to JSON.
     *
     * The format should be either the formatting constants from IntlDateFormatter as
     * described in (https://secure.php.net/manual/en/class.intldateformatter.php) or a pattern
     * as specified in (http://www.icu-project.org/apiref/icu4c/classSimpleDateFormat.html#details)
     *
     * It is possible to provide an array of 2 constants. In this case, the first position
     * will be used for formatting the date part of the object and the second position
     * will be used to format the time part.
     *
     * @var \Closure|array<int>|string|int
     * @see \Cake\I18n\Time::i18nFormat()
     */
    protected static $_jsonEncodeFormat = "yyyy-MM-dd'T'HH':'mm':'ssxxx";

    /**
     * The format to use when formatting a time using `Cake\I18n\Time::nice()`
     *
     * The format should be either the formatting constants from IntlDateFormatter as
     * described in (https://secure.php.net/manual/en/class.intldateformatter.php) or a pattern
     * as specified in (http://www.icu-project.org/apiref/icu4c/classSimpleDateFormat.html#details)
     *
     * It is possible to provide an array of 2 constants. In this case, the first position
     * will be used for formatting the date part of the object and the second position
     * will be used to format the time part.
     *
     * @var array<int>|string|int
     * @see \Cake\I18n\Time::nice()
     */
    static $niceFormat = [IntlDateFormatter::MEDIUM, IntlDateFormatter::SHORT];

    /**
     * The format to use when formatting a time using `Cake\I18n\Time::timeAgoInWords()`
     * and the difference is more than `Cake\I18n\Time::$wordEnd`
     *
     * @var array<int>|string|int
     * @see \Cake\I18n\Time::timeAgoInWords()
     */
    static $wordFormat = [IntlDateFormatter::SHORT, IntlDateFormatter::NONE];

    /**
     * The format to use when formatting a time using `Time::timeAgoInWords()`
     * and the difference is less than `Time::$wordEnd`
     *
     * @var array<string>
     * @see \Cake\I18n\Time::timeAgoInWords()
     */
    static $wordAccuracy = [
        'year' => 'day',
        'month' => 'day',
        'week' => 'day',
        'day' => 'hour',
        'hour' => 'minute',
        'minute' => 'minute',
        'second' => 'second',
    ];

    /**
     * The end of relative time telling
     *
     * @var string
     * @see \Cake\I18n\Time::timeAgoInWords()
     */
    static $wordEnd = '+1 month';

    /**
     * serialise the value as a Unix Timestamp
     *
     * @var string
     */
    public const UNIX_TIMESTAMP_FORMAT = 'unixTimestampFormat';

    /**
     * Create a new mutable time instance.
     *
     * @param \IDateTime|string|int|null $time Fixed or relative time
     * @param \DateTimeZone|string|null $tz The timezone for the instance
     */
    this($time = null, $tz = null) {
        deprecationWarning(
            'The `Time` class has been deprecated. Use the immutable alternative `FrozenTime` instead',
            0
        );

        if ($time instanceof IDateTime) {
            $tz = $time.getTimezone();
            $time = $time.format('Y-m-d H:i:s.u');
        }

        if (is_numeric($time)) {
            $time = '@' . $time;
        }
        super.this($time, $tz);
    }

    /**
     * Returns a nicely formatted date string for this object.
     *
     * The format to be used is stored in the static property `Time::niceFormat`.
     *
     * @param \DateTimeZone|string|null $timezone Timezone string or DateTimeZone object
     * in which the date will be displayed. The timezone stored for this object will not
     * be changed.
     * @param string|null $locale The locale name in which the date should be displayed (e.g. pt-BR)
     * @return string Formatted date string
     */
    function nice($timezone = null, $locale = null): string
    {
        return (string)this.i18nFormat(static::$niceFormat, $timezone, $locale);
    }

    /**
     * Returns true if this object represents a date within the current week
     *
     * @return bool
     */
    function isThisWeek(): bool
    {
        return static::now(this.getTimezone()).format('W o') === this.format('W o');
    }

    /**
     * Returns true if this object represents a date within the current month
     *
     * @return bool
     */
    function isThisMonth(): bool
    {
        return static::now(this.getTimezone()).format('m Y') === this.format('m Y');
    }

    /**
     * Returns true if this object represents a date within the current year
     *
     * @return bool
     */
    function isThisYear(): bool
    {
        return static::now(this.getTimezone()).format('Y') === this.format('Y');
    }

    /**
     * Returns the quarter
     *
     * @param bool $range Range.
     * @return array<string>|int 1, 2, 3, or 4 quarter of year, or array if $range true
     */
    function toQuarter(bool $range = false) {
        $quarter = (int)ceil((int)this.format('m') / 3);
        if ($range === false) {
            return $quarter;
        }

        $year = this.format('Y');
        switch ($quarter) {
            case 1:
                return [$year . '-01-01', $year . '-03-31'];
            case 2:
                return [$year . '-04-01', $year . '-06-30'];
            case 3:
                return [$year . '-07-01', $year . '-09-30'];
        }

        // 4th quarter
        return [$year . '-10-01', $year . '-12-31'];
    }

    /**
     * Returns a UNIX timestamp.
     *
     * @return string UNIX timestamp
     */
    function toUnixString(): string
    {
        return this.format('U');
    }

    /**
     * Returns either a relative or a formatted absolute date depending
     * on the difference between the current time and this object.
     *
     * ### Options:
     *
     * - `from` => another Time object representing the "now" time
     * - `format` => a fall back format if the relative time is longer than the duration specified by end
     * - `accuracy` => Specifies how accurate the date should be described (array)
     *     - year =>   The format if years > 0   (default "day")
     *     - month =>  The format if months > 0  (default "day")
     *     - week =>   The format if weeks > 0   (default "day")
     *     - day =>    The format if weeks > 0   (default "hour")
     *     - hour =>   The format if hours > 0   (default "minute")
     *     - minute => The format if minutes > 0 (default "minute")
     *     - second => The format if seconds > 0 (default "second")
     * - `end` => The end of relative time telling
     * - `relativeString` => The `printf` compatible string when outputting relative time
     * - `absoluteString` => The `printf` compatible string when outputting absolute time
     * - `timezone` => The user timezone the timestamp should be formatted in.
     *
     * Relative dates look something like this:
     *
     * - 3 weeks, 4 days ago
     * - 15 seconds ago
     *
     * Default date formatting is d/M/YY e.g: on 18/2/09. Formatting is done internally using
     * `i18nFormat`, see the method for the valid formatting strings
     *
     * The returned string includes 'ago' or 'on' and assumes you'll properly add a word
     * like 'Posted ' before the function output.
     *
     * NOTE: If the difference is one week or more, the lowest level of accuracy is day
     *
     * @param array<string, mixed> myOptions Array of options.
     * @return string Relative time string.
     */
    function timeAgoInWords(array myOptions = []): string
    {
        /** @psalm-suppress UndefinedInterfaceMethod */
        return static::getDiffFormatter().timeAgoInWords(this, myOptions);
    }

    /**
     * Get list of timezone identifiers
     *
     * @param string|int|null $filter A regex to filter identifier
     *   Or one of DateTimeZone class constants
     * @param string|null myCountry A two-letter ISO 3166-1 compatible country code.
     *   This option is only used when $filter is set to DateTimeZone::PER_COUNTRY
     * @param array<string, mixed>|bool myOptions If true (default value) groups the identifiers list by primary region.
     *   Otherwise, an array containing `group`, `abbr`, `before`, and `after`
     *   keys. Setting `group` and `abbr` to true will group results and append
     *   timezone abbreviation in the display value. Set `before` and `after`
     *   to customize the abbreviation wrapper.
     * @return array List of timezone identifiers
     * @since 2.2
     */
    static function listTimezones($filter = null, Nullable!string myCountry = null, myOptions = []): array
    {
        if (is_bool(myOptions)) {
            myOptions = [
                'group' => myOptions,
            ];
        }
        $defaults = [
            'group' => true,
            'abbr' => false,
            'before' => ' - ',
            'after' => null,
        ];
        myOptions += $defaults;
        myGroup = myOptions['group'];

        $regex = null;
        if (is_string($filter)) {
            $regex = $filter;
            $filter = null;
        }
        if ($filter === null) {
            $filter = DateTimeZone::ALL;
        }
        myIdentifiers = DateTimeZone::listIdentifiers($filter, (string)myCountry) ?: [];

        if ($regex) {
            foreach (myIdentifiers as myKey => $tz) {
                if (!preg_match($regex, $tz)) {
                    unset(myIdentifiers[myKey]);
                }
            }
        }

        if (myGroup) {
            myGroupedIdentifiers = [];
            $now = time();
            $before = myOptions['before'];
            $after = myOptions['after'];
            foreach (myIdentifiers as $tz) {
                $abbr = '';
                if (myOptions['abbr']) {
                    $dateTimeZone = new DateTimeZone($tz);
                    $trans = $dateTimeZone.getTransitions($now, $now);
                    $abbr = isset($trans[0]['abbr']) ?
                        $before . $trans[0]['abbr'] . $after :
                        '';
                }
                $item = explode('/', $tz, 2);
                if (isset($item[1])) {
                    myGroupedIdentifiers[$item[0]][$tz] = $item[1] . $abbr;
                } else {
                    myGroupedIdentifiers[$item[0]] = [$tz => $item[0] . $abbr];
                }
            }

            return myGroupedIdentifiers;
        }

        return array_combine(myIdentifiers, myIdentifiers);
    }
}