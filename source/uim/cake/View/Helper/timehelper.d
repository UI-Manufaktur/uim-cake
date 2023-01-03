


 *


 * @since         0.10.0
  */module uim.cake.View\Helper;

import uim.cake.I18n\FrozenTime;
import uim.cake.View\Helper;
import uim.cake.View\StringTemplateTrait;
use DateTimeInterface;
use Exception;

/**
 * Time Helper class for easy use of time data.
 *
 * Manipulation of time data.
 *
 * @link https://book.cakephp.org/4/en/views/helpers/time.html
 * @see uim.cake.I18n\Time
 */
class TimeHelper : Helper
{
    use StringTemplateTrait;

    /**
     * Config options
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        "outputTimezone": null,
    ];

    /**
     * Get a timezone.
     *
     * Will use the provided timezone, or default output timezone if defined.
     *
     * @param \DateTimeZone|string|null $timezone The override timezone if applicable.
     * @return \DateTimeZone|string|null The chosen timezone or null.
     */
    protected function _getTimezone($timezone) {
        if ($timezone) {
            return $timezone;
        }

        return this.getConfig("outputTimezone");
    }

    /**
     * Returns a UNIX timestamp, given either a UNIX timestamp or a valid strtotime() date string.
     *
     * @param \DateTimeInterface|string|int $dateString UNIX timestamp, strtotime() valid string or DateTime object
     * @param \DateTimeZone|string|null $timezone User"s timezone string or DateTimeZone object
     * @return uim.cake.I18n\FrozenTime
     */
    function fromString($dateString, $timezone = null): FrozenTime
    {
        $time = new FrozenTime($dateString);
        if ($timezone != null) {
            $time = $time.timezone($timezone);
        }

        return $time;
    }

    /**
     * Returns a nicely formatted date string for given Datetime string.
     *
     * @param \DateTimeInterface|string|int|null $dateString UNIX timestamp, strtotime() valid string or DateTime object
     * @param \DateTimeZone|string|null $timezone User"s timezone string or DateTimeZone object
     * @param string|null $locale Locale string.
     * @return string Formatted date string
     */
    string nice($dateString = null, $timezone = null, ?string $locale = null) {
        $timezone = _getTimezone($timezone);

        return (new FrozenTime($dateString)).nice($timezone, $locale);
    }

    /**
     * Returns true, if the given datetime string is today.
     *
     * @param \DateTimeInterface|string|int $dateString UNIX timestamp, strtotime() valid string or DateTime object
     * @param \DateTimeZone|string|null $timezone User"s timezone string or DateTimeZone object
     * @return bool True if the given datetime string is today.
     */
    bool isToday($dateString, $timezone = null) {
        return (new FrozenTime($dateString, $timezone)).isToday();
    }

    /**
     * Returns true, if the given datetime string is in the future.
     *
     * @param \DateTimeInterface|string|int $dateString UNIX timestamp, strtotime() valid string or DateTime object
     * @param \DateTimeZone|string|null $timezone User"s timezone string or DateTimeZone object
     * @return bool True if the given datetime string lies in the future.
     */
    bool isFuture($dateString, $timezone = null) {
        return (new FrozenTime($dateString, $timezone)).isFuture();
    }

    /**
     * Returns true, if the given datetime string is in the past.
     *
     * @param \DateTimeInterface|string|int $dateString UNIX timestamp, strtotime() valid string or DateTime object
     * @param \DateTimeZone|string|null $timezone User"s timezone string or DateTimeZone object
     * @return bool True if the given datetime string lies in the past.
     */
    bool isPast($dateString, $timezone = null) {
        return (new FrozenTime($dateString, $timezone)).isPast();
    }

    /**
     * Returns true if given datetime string is within this week.
     *
     * @param \DateTimeInterface|string|int $dateString UNIX timestamp, strtotime() valid string or DateTime object
     * @param \DateTimeZone|string|null $timezone User"s timezone string or DateTimeZone object
     * @return bool True if datetime string is within current week
     */
    bool isThisWeek($dateString, $timezone = null) {
        return (new FrozenTime($dateString, $timezone)).isThisWeek();
    }

    /**
     * Returns true if given datetime string is within this month
     *
     * @param \DateTimeInterface|string|int $dateString UNIX timestamp, strtotime() valid string or DateTime object
     * @param \DateTimeZone|string|null $timezone User"s timezone string or DateTimeZone object
     * @return bool True if datetime string is within the current month
     */
    bool isThisMonth($dateString, $timezone = null) {
        return (new FrozenTime($dateString, $timezone)).isThisMonth();
    }

    /**
     * Returns true if given datetime string is within the current year.
     *
     * @param \DateTimeInterface|string|int $dateString UNIX timestamp, strtotime() valid string or DateTime object
     * @param \DateTimeZone|string|null $timezone User"s timezone string or DateTimeZone object
     * @return bool True if datetime string is within current year
     */
    bool isThisYear($dateString, $timezone = null) {
        return (new FrozenTime($dateString, $timezone)).isThisYear();
    }

    /**
     * Returns true if given datetime string was yesterday.
     *
     * @param \DateTimeInterface|string|int $dateString UNIX timestamp, strtotime() valid string or DateTime object
     * @param \DateTimeZone|string|null $timezone User"s timezone string or DateTimeZone object
     * @return bool True if datetime string was yesterday
     */
    function wasYesterday($dateString, $timezone = null) {
        return (new FrozenTime($dateString, $timezone)).isYesterday();
    }

    /**
     * Returns true if given datetime string is tomorrow.
     *
     * @param \DateTimeInterface|string|int $dateString UNIX timestamp, strtotime() valid string or DateTime object
     * @param \DateTimeZone|string|null $timezone User"s timezone string or DateTimeZone object
     * @return bool True if datetime string was yesterday
     */
    bool isTomorrow($dateString, $timezone = null) {
        return (new FrozenTime($dateString, $timezone)).isTomorrow();
    }

    /**
     * Returns the quarter
     *
     * @param \DateTimeInterface|string|int $dateString UNIX timestamp, strtotime() valid string or DateTime object
     * @param bool $range if true returns a range in Y-m-d format
     * @return array<string>|int 1, 2, 3, or 4 quarter of year or array if $range true
     * @see uim.cake.I18n\Time::toQuarter()
     */
    function toQuarter($dateString, $range = false) {
        return (new FrozenTime($dateString)).toQuarter($range);
    }

    /**
     * Returns a UNIX timestamp from a textual datetime description.
     *
     * @param \DateTimeInterface|string|int $dateString UNIX timestamp, strtotime() valid string or DateTime object
     * @param \DateTimeZone|string|null $timezone User"s timezone string or DateTimeZone object
     * @return string UNIX timestamp
     * @see uim.cake.I18n\Time::toUnix()
     */
    string toUnix($dateString, $timezone = null) {
        return (new FrozenTime($dateString, $timezone)).toUnixString();
    }

    /**
     * Returns a date formatted for Atom RSS feeds.
     *
     * @param \DateTimeInterface|string|int $dateString UNIX timestamp, strtotime() valid string or DateTime object
     * @param \DateTimeZone|string|null $timezone User"s timezone string or DateTimeZone object
     * @return string Formatted date string
     * @see uim.cake.I18n\Time::toAtom()
     */
    string toAtom($dateString, $timezone = null) {
        $timezone = _getTimezone($timezone) ?: date_default_timezone_get();

        return (new FrozenTime($dateString)).timezone($timezone).toAtomString();
    }

    /**
     * Formats date for RSS feeds
     *
     * @param \DateTimeInterface|string|int $dateString UNIX timestamp, strtotime() valid string or DateTime object
     * @param \DateTimeZone|string|null $timezone User"s timezone string or DateTimeZone object
     * @return string Formatted date string
     */
    string toRss($dateString, $timezone = null) {
        $timezone = _getTimezone($timezone) ?: date_default_timezone_get();

        return (new FrozenTime($dateString)).timezone($timezone).toRssString();
    }

    /**
     * Formats a date into a phrase expressing the relative time.
     *
     * ### Additional options
     *
     * - `element` - The element to wrap the formatted time in.
     *   Has a few additional options:
     *   - `tag` - The tag to use, defaults to "span".
     *   - `class` - The class name to use, defaults to `time-ago-in-words`.
     *   - `title` - Defaults to the $dateTime input.
     *
     * @param \DateTimeInterface|string|int $dateTime UNIX timestamp, strtotime() valid
     *   string or DateTime object.
     * @param array<string, mixed> $options Default format if timestamp is used in $dateString
     * @return string Relative time string.
     * @see uim.cake.I18n\Time::timeAgoInWords()
     */
    string timeAgoInWords($dateTime, array $options = []) {
        $element = null;
        $options += [
            "element": null,
            "timezone": null,
        ];
        $options["timezone"] = _getTimezone($options["timezone"]);
        /** @psalm-suppress UndefinedInterfaceMethod */
        if ($options["timezone"] && $dateTime instanceof DateTimeInterface) {
            $dateTime = $dateTime.setTimezone($options["timezone"]);
            unset($options["timezone"]);
        }

        if (!empty($options["element"])) {
            $element = [
                "tag": "span",
                "class": "time-ago-in-words",
                "title": $dateTime,
            ];

            if (is_array($options["element"])) {
                $element = $options["element"] + $element;
            } else {
                $element["tag"] = $options["element"];
            }
            unset($options["element"]);
        }
        $relativeDate = (new FrozenTime($dateTime)).timeAgoInWords($options);

        if ($element) {
            $relativeDate = sprintf(
                "<%s%s>%s</%s>",
                $element["tag"],
                this.templater().formatAttributes($element, ["tag"]),
                $relativeDate,
                $element["tag"]
            );
        }

        return $relativeDate;
    }

    /**
     * Returns true if specified datetime was within the interval specified, else false.
     *
     * @param string $timeInterval the numeric value with space then time type.
     *    Example of valid types: 6 hours, 2 days, 1 minute.
     * @param \DateTimeInterface|string|int $dateString UNIX timestamp, strtotime() valid string or DateTime object
     * @param \DateTimeZone|string|null $timezone User"s timezone string or DateTimeZone object
     * @return bool
     * @see uim.cake.I18n\Time::wasWithinLast()
     */
    function wasWithinLast(string $timeInterval, $dateString, $timezone = null) {
        return (new FrozenTime($dateString, $timezone)).wasWithinLast($timeInterval);
    }

    /**
     * Returns true if specified datetime is within the interval specified, else false.
     *
     * @param string $timeInterval the numeric value with space then time type.
     *    Example of valid types: 6 hours, 2 days, 1 minute.
     * @param \DateTimeInterface|string|int $dateString UNIX timestamp, strtotime() valid string or DateTime object
     * @param \DateTimeZone|string|null $timezone User"s timezone string or DateTimeZone object
     * @return bool
     * @see uim.cake.I18n\Time::wasWithinLast()
     */
    bool isWithinNext(string $timeInterval, $dateString, $timezone = null) {
        return (new FrozenTime($dateString, $timezone)).isWithinNext($timeInterval);
    }

    /**
     * Returns gmt as a UNIX timestamp.
     *
     * @param \DateTimeInterface|string|int|null $string UNIX timestamp, strtotime() valid string or DateTime object
     * @return string UNIX timestamp
     * @see uim.cake.I18n\Time::gmt()
     */
    string gmt($string = null) {
        return (new FrozenTime($string)).toUnixString();
    }

    /**
     * Returns a formatted date string, given either a Time instance,
     * UNIX timestamp or a valid strtotime() date string.
     *
     * This method is an alias for TimeHelper::i18nFormat().
     *
     * @param \DateTimeInterface|string|int|null $date UNIX timestamp, strtotime() valid string
     *   or DateTime object (or a date format string).
     * @param string|int|null $format date format string (or a UNIX timestamp,
     *   `strtotime()` valid string or DateTime object).
     * @param string|false $invalid Default value to display on invalid dates
     * @param \DateTimeZone|string|null $timezone User"s timezone string or DateTimeZone object
     * @return string|int|false Formatted and translated date string
     * @see uim.cake.I18n\Time::i18nFormat()
     */
    function format($date, $format = null, $invalid = false, $timezone = null) {
        return this.i18nFormat($date, $format, $invalid, $timezone);
    }

    /**
     * Returns a formatted date string, given either a Datetime instance,
     * UNIX timestamp or a valid strtotime() date string.
     *
     * @param \DateTimeInterface|string|int|null $date UNIX timestamp, strtotime() valid string or DateTime object
     * @param string|int|null $format Intl compatible format string.
     * @param string|false $invalid Default value to display on invalid dates
     * @param \DateTimeZone|string|null $timezone User"s timezone string or DateTimeZone object
     * @return string|int|false Formatted and translated date string or value for `$invalid` on failure.
     * @throws \Exception When the date cannot be parsed
     * @see uim.cake.I18n\Time::i18nFormat()
     */
    function i18nFormat($date, $format = null, $invalid = false, $timezone = null) {
        if ($date == null) {
            return $invalid;
        }
        $timezone = _getTimezone($timezone);

        try {
            $time = new FrozenTime($date);

            return $time.i18nFormat($format, $timezone);
        } catch (Exception $e) {
            if ($invalid == false) {
                throw $e;
            }

            return $invalid;
        }
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
}
