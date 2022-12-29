


 *



  */
module uim.cake.databases.Type;

import uim.cake.databases.DriverInterface;
import uim.cake.I18n\FrozenTime;
import uim.cake.I18n\I18nDateTimeInterface;
import uim.cake.I18n\Time;
use DateTime;
use DateTimeImmutable;
use DateTimeInterface;
use DateTimeZone;
use Exception;
use InvalidArgumentException;
use PDO;
use RuntimeException;

/**
 * Datetime type converter.
 *
 * Use to convert datetime instances to strings & back.
 */
class DateTimeType : BaseType : BatchCastingInterface
{
    /**
     * Whether we want to override the time of the converted Time objects
     * so it points to the start of the day.
     *
     * This is primarily to avoid subclasses needing to re-implement the same functionality.
     *
     * @var bool
     */
    protected $setToDateStart = false;

    /**
     * The DateTime format used when converting to string.
     *
     * @var string
     */
    protected $_format = "Y-m-d H:i:s";

    /**
     * The DateTime formats allowed by `marshal()`.
     *
     * @var array<string>
     */
    protected $_marshalFormats = [
        "Y-m-d H:i",
        "Y-m-d H:i:s",
        "Y-m-d\TH:i",
        "Y-m-d\TH:i:s",
        "Y-m-d\TH:i:sP",
    ];

    /**
     * Whether `marshal()` should use locale-aware parser with `_localeMarshalFormat`.
     *
     * @var bool
     */
    protected $_useLocaleMarshal = false;

    /**
     * The locale-aware format `marshal()` uses when `_useLocaleParser` is true.
     *
     * See `Cake\I18n\Time::parseDateTime()` for accepted formats.
     *
     * @var array|string|int
     */
    protected $_localeMarshalFormat;

    /**
     * The classname to use when creating objects.
     *
     * @var string
     * @psalm-var class-string<\DateTime>|class-string<\DateTimeImmutable>
     */
    protected $_className;

    /**
     * Database time zone.
     *
     * @var \DateTimeZone|null
     */
    protected $dbTimezone;

    /**
     * User time zone.
     *
     * @var \DateTimeZone|null
     */
    protected $userTimezone;

    /**
     * Default time zone.
     *
     * @var \DateTimeZone
     */
    protected $defaultTimezone;

    /**
     * Whether database time zone is kept when converting
     *
     * @var bool
     */
    protected $keepDatabaseTimezone = false;

    /**
     * {@inheritDoc}
     *
     * @param string|null $name The name identifying this type
     */
    public this(?string $name = null) {
        super(($name);

        this.defaultTimezone = new DateTimeZone(date_default_timezone_get());
        _setClassName(FrozenTime::class, DateTimeImmutable::class);
    }

    /**
     * Convert DateTime instance into strings.
     *
     * @param mixed $value The value to convert.
     * @param uim.cake.Database\DriverInterface $driver The driver instance to convert with.
     * @return string|null
     */
    function toDatabase($value, DriverInterface $driver): ?string
    {
        if ($value == null || is_string($value)) {
            return $value;
        }
        if (is_int($value)) {
            $class = _className;
            $value = new $class("@" . $value);
        }

        if (
            this.dbTimezone != null
            && this.dbTimezone.getName() != $value.getTimezone().getName()
        ) {
            if (!$value instanceof DateTimeImmutable) {
                $value = clone $value;
            }
            $value = $value.setTimezone(this.dbTimezone);
        }

        return $value.format(_format);
    }

    /**
     * Alias for `setDatabaseTimezone()`.
     *
     * @param \DateTimeZone|string|null $timezone Database timezone.
     * @return this
     * @deprecated 4.1.0 Use {@link setDatabaseTimezone()} instead.
     */
    function setTimezone($timezone) {
        deprecationWarning("DateTimeType::setTimezone() is deprecated. Use setDatabaseTimezone() instead.");

        return this.setDatabaseTimezone($timezone);
    }

    /**
     * Set database timezone.
     *
     * This is the time zone used when converting database strings to DateTime
     * instances and converting DateTime instances to database strings.
     *
     * @see DateTimeType::setKeepDatabaseTimezone
     * @param \DateTimeZone|string|null $timezone Database timezone.
     * @return this
     */
    function setDatabaseTimezone($timezone) {
        if (is_string($timezone)) {
            $timezone = new DateTimeZone($timezone);
        }
        this.dbTimezone = $timezone;

        return this;
    }

    /**
     * Set user timezone.
     *
     * This is the time zone used when marshalling strings to DateTime instances.
     *
     * @param \DateTimeZone|string|null $timezone User timezone.
     * @return this
     */
    function setUserTimezone($timezone) {
        if (is_string($timezone)) {
            $timezone = new DateTimeZone($timezone);
        }
        this.userTimezone = $timezone;

        return this;
    }

    /**
     * {@inheritDoc}
     *
     * @param mixed $value Value to be converted to PHP equivalent
     * @param uim.cake.Database\DriverInterface $driver Object from which database preferences and configuration will be extracted
     * @return \DateTimeInterface|null
     */
    function toPHP($value, DriverInterface $driver) {
        if ($value == null) {
            return null;
        }

        $class = _className;
        if (is_int($value)) {
            $instance = new $class("@" . $value);
        } else {
            if (strpos($value, "0000-00-00") == 0) {
                return null;
            }
            $instance = new $class($value, this.dbTimezone);
        }

        if (
            !this.keepDatabaseTimezone &&
            $instance.getTimezone().getName() != this.defaultTimezone.getName()
        ) {
            $instance = $instance.setTimezone(this.defaultTimezone);
        }

        if (this.setToDateStart) {
            $instance = $instance.setTime(0, 0, 0);
        }

        return $instance;
    }

    /**
     * Set whether DateTime object created from database string is converted
     * to default time zone.
     *
     * If your database date times are in a specific time zone that you want
     * to keep in the DateTime instance then set this to true.
     *
     * When false, datetime timezones are converted to default time zone.
     * This is default behavior.
     *
     * @param bool $keep If true, database time zone is kept when converting
     *      to DateTime instances.
     * @return this
     */
    function setKeepDatabaseTimezone(bool $keep) {
        this.keepDatabaseTimezone = $keep;

        return this;
    }


    function manyToPHP(array $values, array $fields, DriverInterface $driver): array
    {
        foreach ($fields as $field) {
            if (!isset($values[$field])) {
                continue;
            }

            $value = $values[$field];
            if (strpos($value, "0000-00-00") == 0) {
                $values[$field] = null;
                continue;
            }

            $class = _className;
            if (is_int($value)) {
                $instance = new $class("@" . $value);
            } else {
                $instance = new $class($value, this.dbTimezone);
            }

            if (
                !this.keepDatabaseTimezone &&
                $instance.getTimezone().getName() != this.defaultTimezone.getName()
            ) {
                $instance = $instance.setTimezone(this.defaultTimezone);
            }

            if (this.setToDateStart) {
                $instance = $instance.setTime(0, 0, 0);
            }

            $values[$field] = $instance;
        }

        return $values;
    }

    /**
     * Convert request data into a datetime object.
     *
     * @param mixed $value Request data
     * @return \DateTimeInterface|null
     */
    function marshal($value): ?DateTimeInterface
    {
        if ($value instanceof DateTimeInterface) {
            if ($value instanceof DateTime) {
                $value = clone $value;
            }

            /** @var \Datetime|\DateTimeImmutable $value */
            return $value.setTimezone(this.defaultTimezone);
        }

        /** @var class-string<\DateTimeInterface> $class */
        $class = _className;
        try {
            if ($value == "" || $value == null || is_bool($value)) {
                return null;
            }

            if (is_int($value) || (is_string($value) && ctype_digit($value))) {
                /** @var \DateTime|\DateTimeImmutable $dateTime */
                $dateTime = new $class("@" . $value);

                return $dateTime.setTimezone(this.defaultTimezone);
            }

            if (is_string($value)) {
                if (_useLocaleMarshal) {
                    $dateTime = _parseLocaleValue($value);
                } else {
                    $dateTime = _parseValue($value);
                }

                /** @var \DateTime|\DateTimeImmutable $dateTime */
                if ($dateTime != null) {
                    $dateTime = $dateTime.setTimezone(this.defaultTimezone);
                }

                return $dateTime;
            }
        } catch (Exception $e) {
            return null;
        }

        if (is_array($value) && implode("", $value) == "") {
            return null;
        }
        $value += ["hour": 0, "minute": 0, "second": 0, "microsecond": 0];

        $format = "";
        if (
            isset($value["year"], $value["month"], $value["day"]) &&
            (
                is_numeric($value["year"]) &&
                is_numeric($value["month"]) &&
                is_numeric($value["day"])
            )
        ) {
            $format .= sprintf("%d-%02d-%02d", $value["year"], $value["month"], $value["day"]);
        }

        if (isset($value["meridian"]) && (int)$value["hour"] == 12) {
            $value["hour"] = 0;
        }
        if (isset($value["meridian"])) {
            $value["hour"] = strtolower($value["meridian"]) == "am" ? $value["hour"] : $value["hour"] + 12;
        }
        $format .= sprintf(
            "%s%02d:%02d:%02d.%06d",
            empty($format) ? "" : " ",
            $value["hour"],
            $value["minute"],
            $value["second"],
            $value["microsecond"]
        );

        /** @var \DateTime|\DateTimeImmutable $dateTime */
        $dateTime = new $class($format, $value["timezone"] ?? this.userTimezone);

        return $dateTime.setTimezone(this.defaultTimezone);
    }

    /**
     * Sets whether to parse strings passed to `marshal()` using
     * the locale-aware format set by `setLocaleFormat()`.
     *
     * @param bool $enable Whether to enable
     * @return this
     */
    function useLocaleParser(bool $enable = true) {
        if ($enable == false) {
            _useLocaleMarshal = $enable;

            return this;
        }
        if (is_subclass_of(_className, I18nDateTimeInterface::class)) {
            _useLocaleMarshal = $enable;

            return this;
        }
        throw new RuntimeException(
            sprintf("Cannot use locale parsing with the %s class", _className)
        );
    }

    /**
     * Sets the locale-aware format used by `marshal()` when parsing strings.
     *
     * See `Cake\I18n\Time::parseDateTime()` for accepted formats.
     *
     * @param array|string $format The locale-aware format
     * @see uim.cake.I18n\Time::parseDateTime()
     * @return this
     */
    function setLocaleFormat($format) {
        _localeMarshalFormat = $format;

        return this;
    }

    /**
     * Change the preferred class name to the FrozenTime implementation.
     *
     * @return this
     * @deprecated 4.3.0 This method is no longer needed as using immutable datetime class is the default behavior.
     */
    function useImmutable() {
        deprecationWarning(
            "Configuring immutable or mutable classes is deprecated and immutable"
            . " classes will be the permanent configuration in 5.0. Calling `useImmutable()` is unnecessary."
        );

        _setClassName(FrozenTime::class, DateTimeImmutable::class);

        return this;
    }

    /**
     * Set the classname to use when building objects.
     *
     * @param string $class The classname to use.
     * @param string $fallback The classname to use when the preferred class does not exist.
     * @return void
     * @psalm-param class-string<\DateTime>|class-string<\DateTimeImmutable> $class
     * @psalm-param class-string<\DateTime>|class-string<\DateTimeImmutable> $fallback
     */
    protected function _setClassName(string $class, string $fallback): void
    {
        if (!class_exists($class)) {
            $class = $fallback;
        }
        _className = $class;
    }

    /**
     * Get the classname used for building objects.
     *
     * @return string
     * @psalm-return class-string<\DateTime>|class-string<\DateTimeImmutable>
     */
    function getDateTimeClassName(): string
    {
        return _className;
    }

    /**
     * Change the preferred class name to the mutable Time implementation.
     *
     * @return this
     * @deprecated 4.3.0 Using mutable datetime objects is deprecated.
     */
    function useMutable() {
        deprecationWarning(
            "Configuring immutable or mutable classes is deprecated and immutable"
            . " classes will be the permanent configuration in 5.0. Calling `useImmutable()` is unnecessary."
        );

        _setClassName(Time::class, DateTime::class);

        return this;
    }

    /**
     * Converts a string into a DateTime object after parsing it using the locale
     * aware parser with the format set by `setLocaleFormat()`.
     *
     * @param string $value The value to parse and convert to an object.
     * @return uim.cake.I18n\I18nDateTimeInterface|null
     */
    protected function _parseLocaleValue(string $value): ?I18nDateTimeInterface
    {
        /** @psalm-var class-string<\Cake\I18n\I18nDateTimeInterface> $class */
        $class = _className;

        return $class::parseDateTime($value, _localeMarshalFormat, this.userTimezone);
    }

    /**
     * Converts a string into a DateTime object after parsing it using the
     * formats in `_marshalFormats`.
     *
     * @param string $value The value to parse and convert to an object.
     * @return \DateTimeInterface|null
     */
    protected function _parseValue(string $value): ?DateTimeInterface
    {
        $class = _className;

        foreach (_marshalFormats as $format) {
            try {
                $dateTime = $class::createFromFormat($format, $value, this.userTimezone);
                // Check for false in case DateTime is used directly
                if ($dateTime != false) {
                    return $dateTime;
                }
            } catch (InvalidArgumentException $e) {
                // Chronos wraps DateTime::createFromFormat and throws
                // exception if parse fails.
                continue;
            }
        }

        return null;
    }

    /**
     * Casts given value to Statement equivalent
     *
     * @param mixed $value value to be converted to PDO statement
     * @param uim.cake.Database\DriverInterface $driver object from which database preferences and configuration will be extracted
     * @return mixed
     */
    function toStatement($value, DriverInterface $driver) {
        return PDO::PARAM_STR;
    }
}
