/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.validations;

@safe:
import uim.cake;

/**
 * Validation Class. Used for validation of model data
 *
 * Offers different validation methods.
 */
class Validation {
    //  Default locale
    const string DEFAULT_LOCALE = "en_US";

    // Same as operator.
    const string COMPARE_SAME = "==";

    // Not same as comparison operator.
    const string COMPARE_NOT_SAME = "!==";

    // Equal to comparison operator.
    const string COMPARE_EQUAL = "==";

    /**
     * Not equal to comparison operator.
     */
    const string COMPARE_NOT_EQUAL = "!=";

    /**
     * Greater than comparison operator.
     */
    const string COMPARE_GREATER = ">";

    /**
     * Greater than or equal to comparison operator.
     */
    const string COMPARE_GREATER_OR_EQUAL = ">=";

    // Less than comparison operator.
    const string COMPARE_LESS = "<";

    // Less than or equal to comparison operator.
    const string COMPARE_LESS_OR_EQUAL = "<=";

    protected const string[] COMPARE_STRING = [
        self::COMPARE_EQUAL,
        self::COMPARE_NOT_EQUAL,
        self::COMPARE_SAME,
        self::COMPARE_NOT_SAME,
    ];

    // Datetime ISO8601 format
    const string DATETIME_ISO8601 = "iso8601";

    /**
     * Some complex patterns needed in multiple places
     *
     * @var array<string, string>
     */
    protected static _pattern = [
        "hostname": "(?:[_\p{L}0-9][-_\p{L}0-9]*\.)*(?:[\p{L}0-9][-\p{L}0-9]{0,62})\.(?:(?:[a-z]{2}\.)?[a-z]{2,})",
        "latitude": "[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?)",
        "longitude": "[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)",
    ];

    /**
     * Holds an array of errors messages set in this class.
     * These are used for debugging purposes
     *
     * @var array
     */
    static myErrors = [];

    /**
     * Checks that a string contains something other than whitespace
     *
     * Returns true if string contains something other than whitespace
     *
     * @param mixed $check Value to check
     * @return bool Success
     */
    static bool notBlank($check) {
        if (empty($check) && !is_bool($check) && !is_numeric($check)) {
            return false;
        }

        return static::_check($check, "/[^\s]+/m");
    }

    /**
     * Checks that a string contains only integer or letters.
     *
     * This method"s definition of letters and integers includes unicode characters.
     * Use `asciiAlphaNumeric()` if you want to exclude unicode.
     *
     * @param mixed $check Value to check
     * @return bool Success
     */
    static bool alphaNumeric($check) {
        if ((empty($check) && $check != "0") || !is_scalar($check)) {
            return false;
        }

        return self::_check($check, "/^[\p{Ll}\p{Lm}\p{Lo}\p{Lt}\p{Lu}\p{Nd}]+$/Du");
    }

    /**
     * Checks that a doesn"t contain any alpha numeric characters
     *
     * This method"s definition of letters and integers includes unicode characters.
     * Use `notAsciiAlphaNumeric()` if you want to exclude ascii only.
     *
     * @param mixed $check Value to check
     * @return bool Success
     */
    static bool notAlphaNumeric($check) {
        return !static::alphaNumeric($check);
    }

    /**
     * Checks that a string contains only ascii integer or letters.
     *
     * @param mixed $check Value to check
     * @return bool Success
     */
    static bool asciiAlphaNumeric($check) {
        if ((empty($check) && $check != "0") || !is_scalar($check)) {
            return false;
        }

        return self::_check($check, "/^[[:alnum:]]+$/");
    }

    /**
     * Checks that a doesn"t contain any non-ascii alpha numeric characters
     *
     * @param mixed $check Value to check
     * @return bool Success
     */
    static bool notAsciiAlphaNumeric($check) {
        return !static::asciiAlphaNumeric($check);
    }

    /**
     * Checks that a string length is within specified range.
     * Spaces are included in the character count.
     * Returns true if string matches value min, max, or between min and max,
     *
     * @param mixed $check Value to check for length
     * @param int $min Minimum value in range (inclusive)
     * @param int $max Maximum value in range (inclusive)
     * @return bool Success
     */
    static bool lengthBetween($check, int $min, int $max) {
        if (!is_scalar($check)) {
            return false;
        }
        $length = mb_strlen((string)$check);

        return $length >= $min && $length <= $max;
    }

    /**
     * Validation of credit card numbers.
     * Returns true if $check is in the proper credit card format.
     *
     * @param mixed $check credit card number to validate
     * @param array<string>|string myType "all" may be passed as a string, defaults to fast which checks format of
     *     most major credit cards if an array is used only the values of the array are checked.
     *    Example: ["amex", "bankcard", "maestro"]
     * @param bool $deep set to true this will check the Luhn algorithm of the credit card.
     * @param string|null $regex A custom regex, this will be used instead of the defined regex values.
     * @return bool Success
     * @see uim.cake.validations.Validation::luhn()
     */
    static bool creditCard($check, myType = "fast", bool $deep = false, Nullable!string regex = null) {
        if (!(is_string($check) || is_int($check))) {
            return false;
        }

        $check = replace(["-", " "], "", (string)$check);
        if (mb_strlen($check) < 13) {
            return false;
        }

        if ($regex  !is null && static::_check($check, $regex)) {
            return !$deep || static::luhn($check);
        }
        $cards = [
            "all": [
                "amex": "/^3[47]\\d{13}$/",
                "bankcard": "/^56(10\\d\\d|022[1-5])\\d{10}$/",
                "diners": "/^(?:3(0[0-5]|[68]\\d)\\d{11})|(?:5[1-5]\\d{14})$/",
                "disc": "/^(?:6011|650\\d)\\d{12}$/",
                "electron": "/^(?:417500|4917\\d{2}|4913\\d{2})\\d{10}$/",
                "enroute": "/^2(?:014|149)\\d{11}$/",
                "jcb": "/^(3\\d{4}|2131|1800)\\d{11}$/",
                "maestro": "/^(?:5020|6\\d{3})\\d{12}$/",
                "mc": "/^(5[1-5]\\d{14})|(2(?:22[1-9]|2[3-9][0-9]|[3-6][0-9]{2}|7[0-1][0-9]|720)\\d{12})$/",
                "solo": "/^(6334[5-9][0-9]|6767[0-9]{2})\\d{10}(\\d{2,3})?$/",
                // phpcs:ignore Generic.Files.LineLength
                "switch": "/^(?:49(03(0[2-9]|3[5-9])|11(0[1-2]|7[4-9]|8[1-2])|36[0-9]{2})\\d{10}(\\d{2,3})?)|(?:564182\\d{10}(\\d{2,3})?)|(6(3(33[0-4][0-9])|759[0-9]{2})\\d{10}(\\d{2,3})?)$/",
                "visa": "/^4\\d{12}(\\d{3})?$/",
                "voyager": "/^8699[0-9]{11}$/",
            ],
            // phpcs:ignore Generic.Files.LineLength
            "fast": "/^(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|6011[0-9]{12}|3(?:0[0-5]|[68][0-9])[0-9]{11}|3[47][0-9]{13})$/",
        ];

        if (is_array(myType)) {
            foreach (myType as myValue) {
                $regex = $cards["all"][strtolower(myValue)];

                if (static::_check($check, $regex)) {
                    return static::luhn($check);
                }
            }
        } elseif (myType == "all") {
            foreach ($cards["all"] as myValue) {
                $regex = myValue;

                if (static::_check($check, $regex)) {
                    return static::luhn($check);
                }
            }
        } else {
            $regex = $cards["fast"];

            if (static::_check($check, $regex)) {
                return static::luhn($check);
            }
        }

        return false;
    }

    /**
     * Used to check the count of a given value of type array or Countable.
     *
     * @param mixed $check The value to check the count on.
     * @param string operator Can be either a word or operand
     *    is greater >, is less <, greater or equal >=
     *    less or equal <=, is less <, equal to ==, not equal !=
     * @param int $expectedCount The expected count value.
     * @return bool Success
     */
    static bool numElements($check, string operator, int $expectedCount) {
        if (!is_array($check) && !$check instanceof Countable) {
            return false;
        }

        return self::comparison(count($check), $operator, $expectedCount);
    }

    /**
     * Used to compare 2 numeric values.
     *
     * @param string|int $check1 The left value to compare.
     * @param string operator Can be one of following operator strings:
     *   ">", "<", ">=", "<=", "==", "!=", "==" and "!==". You can use one of
     *   the Validation::COMPARE_* constants.
     * @param string|int $check2 The right value to compare.
     * @return bool Success
     */
    static bool comparison($check1, string operator, $check2) {
        if (
            (!is_numeric($check1) || !is_numeric($check2)) &&
            !in_array($operator, static::COMPARE_STRING)
        ) {
            return false;
        }

        switch ($operator) {
            case static::COMPARE_GREATER:
                if ($check1 > $check2) {
                    return true;
                }
                break;
            case static::COMPARE_LESS:
                if ($check1 < $check2) {
                    return true;
                }
                break;
            case static::COMPARE_GREATER_OR_EQUAL:
                if ($check1 >= $check2) {
                    return true;
                }
                break;
            case static::COMPARE_LESS_OR_EQUAL:
                if ($check1 <= $check2) {
                    return true;
                }
                break;
            case static::COMPARE_EQUAL:
                if ($check1 == $check2) {
                    return true;
                }
                break;
            case static::COMPARE_NOT_EQUAL:
                if ($check1 != $check2) {
                    return true;
                }
                break;
            case static::COMPARE_SAME:
                if ($check1 == $check2) {
                    return true;
                }
                break;
            case static::COMPARE_NOT_SAME:
                if ($check1 != $check2) {
                    return true;
                }
                break;
            default:
                static::myErrors[] = "You must define a valid $operator parameter for Validation::comparison()";
        }

        return false;
    }

    /**
     * Compare one field to another.
     *
     * If both fields have exactly the same value this method will return true.
     *
     * @param mixed $check The value to find in myField.
     * @param string myField The field to check $check against. This field must be present in $context.
     * @param array<string, mixed> $context The validation context.
     * @return bool
     */
    static bool compareWith($check, string myField, array $context) {
        return self::compareFields($check, myField, static::COMPARE_SAME, $context);
    }

    /**
     * Compare one field to another.
     *
     * Return true if the comparison matches the expected result.
     *
     * @param mixed $check The value to find in myField.
     * @param string myField The field to check $check against. This field must be present in $context.
     * @param string operator Comparison operator. See Validation::comparison().
     * @param array<string, mixed> $context The validation context.
     * @return bool

     */
    static bool compareFields($check, string myField, string operator, array $context) {
        if (!isset($context["data"]) || !array_key_exists(myField, $context["data"])) {
            return false;
        }

        return static::comparison($check, $operator, $context["data"][myField]);
    }

    /**
     * Checks if a string contains one or more non-alphanumeric characters.
     *
     * Returns true if string contains at least the specified number of non-alphanumeric characters
     *
     * @param mixed $check Value to check
     * @param int myCount Number of non-alphanumerics to check for
     * @return bool Success
     * @deprecated 4.0.0 Use {@link notAlphaNumeric()} instead. Will be removed in 5.0
     */
    static bool containsNonAlphaNumeric($check, int myCount = 1) {
        deprecationWarning("Validation::containsNonAlphaNumeric() is deprecated. Use notAlphaNumeric() instead.");
        if (!is_string($check)) {
            return false;
        }

        $matches = preg_match_all("/[^a-zA-Z0-9]/", $check);

        return $matches >= myCount;
    }

    /**
     * Used when a custom regular expression is needed.
     *
     * @param mixed $check The value to check.
     * @param string|null $regex If $check is passed as a string, $regex must also be set to valid regular expression
     * @return bool Success
     */
    static bool custom($check, Nullable!string regex = null) {
        if (!is_scalar($check)) {
            return false;
        }
        if ($regex is null) {
            static::myErrors[] = "You must define a regular expression for Validation::custom()";

            return false;
        }

        return static::_check($check, $regex);
    }

    /**
     * Date validation, determines if the string passed is a valid date.
     * keys that expect full month, day and year will validate leap years.
     *
     * Years are valid from 0001 to 2999.
     *
     * ### Formats:
     *
     * - `dmy` 27-12-2006 or 27-12-06 separators can be a space, period, dash, forward slash
     * - `mdy` 12-27-2006 or 12-27-06 separators can be a space, period, dash, forward slash
     * - `ymd` 2006-12-27 or 06-12-27 separators can be a space, period, dash, forward slash
     * - `dMy` 27 December 2006 or 27 Dec 2006
     * - `Mdy` December 27, 2006 or Dec 27, 2006 comma is optional
     * - `My` December 2006 or Dec 2006
     * - `my` 12/2006 or 12/06 separators can be a space, period, dash, forward slash
     * - `ym` 2006/12 or 06/12 separators can be a space, period, dash, forward slash
     * - `y` 2006 just the year without any separators
     *
     * @param mixed $check a valid date string/object
     * @param array<string>|string format Use a string or an array of the keys above.
     *    Arrays should be passed as ["dmy", "mdy", ...]
     * @param string|null $regex If a custom regular expression is used this is the only validation that will occur.
     * @return bool Success
     */
    static bool date($check, $format = "ymd", Nullable!string regex = null) {
        if ($check instanceof IDateTime) {
            return true;
        }
        if (is_object($check)) {
            return false;
        }
        if (is_array($check)) {
            $check = static::_getDateString($check);
            $format = "ymd";
        }

        if ($regex  !is null) {
            return static::_check($check, $regex);
        }
        $month = "(0[123456789]|10|11|12)";
        $separator = "([- /.])";
        // Don"t allow 0000, but 0001-2999 are ok.
        $fourDigitYear = "(?:(?!0000)[012]\d{3})";
        $twoDigitYear = "(?:\d{2})";
        $year = "(?:" ~ $fourDigitYear ~ "|" ~ $twoDigitYear ~ ")";

        // phpcs:disable Generic.Files.LineLength
        // 2 or 4 digit leap year sub-pattern
        $leapYear = "(?:(?:(?:(?!0000)[012]\\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00)))";
        // 4 digit leap year sub-pattern
        $fourDigitLeapYear = "(?:(?:(?:(?!0000)[012]\\d)(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00)))";

        $regex["dmy"] = "%^(?:(?:31(\\/|-|\\.|\\x20)(?:0?[13578]|1[02]))\\1|(?:(?:29|30)" ~
            $separator ~ "(?:0?[13-9]|1[0-2])\\2))" ~ $year ~ "$|^(?:29" ~
            $separator ~ "0?2\\3" ~ $leapYear ~ ")$|^(?:0?[1-9]|1\\d|2[0-8])" ~
            $separator ~ "(?:(?:0?[1-9])|(?:1[0-2]))\\4" ~ $year ~ "$%";

        $regex["mdy"] = "%^(?:(?:(?:0?[13578]|1[02])(\\/|-|\\.|\\x20)31)\\1|(?:(?:0?[13-9]|1[0-2])" ~
            $separator ~ "(?:29|30)\\2))" ~ $year ~ "$|^(?:0?2" ~ $separator ~ "29\\3" ~ $leapYear ~ ")$|^(?:(?:0?[1-9])|(?:1[0-2]))" ~
            $separator ~ "(?:0?[1-9]|1\\d|2[0-8])\\4" ~ $year ~ "$%";

        $regex["ymd"] = "%^(?:(?:" ~ $leapYear .
            $separator ~ "(?:0?2\\1(?:29)))|(?:" ~ $year .
            $separator ~ "(?:(?:(?:0?[13578]|1[02])\\2(?:31))|(?:(?:0?[13-9]|1[0-2])\\2(29|30))|(?:(?:0?[1-9])|(?:1[0-2]))\\2(?:0?[1-9]|1\\d|2[0-8]))))$%";

        $regex["dMy"] = "/^((31(?!\\ (Feb(ruary)?|Apr(il)?|June?|(Sep(?=\\b|t)t?|Nov)(ember)?)))|((30|29)(?!\\ Feb(ruary)?))|(29(?=\\ Feb(ruary)?\\ " ~ $fourDigitLeapYear ~ "))|(0?[1-9])|1\\d|2[0-8])\\ (Jan(uary)?|Feb(ruary)?|Ma(r(ch)?|y)|Apr(il)?|Ju((ly?)|(ne?))|Aug(ust)?|Oct(ober)?|(Sep(?=\\b|t)t?|Nov|Dec)(ember)?)\\ " ~ $fourDigitYear ~ "$/";

        $regex["Mdy"] = "/^(?:(((Jan(uary)?|Ma(r(ch)?|y)|Jul(y)?|Aug(ust)?|Oct(ober)?|Dec(ember)?)\\ 31)|((Jan(uary)?|Ma(r(ch)?|y)|Apr(il)?|Ju((ly?)|(ne?))|Aug(ust)?|Oct(ober)?|(Sep)(tember)?|(Nov|Dec)(ember)?)\\ (0?[1-9]|([12]\\d)|30))|(Feb(ruary)?\\ (0?[1-9]|1\\d|2[0-8]|(29(?=,?\\ " ~ $fourDigitLeapYear ~ ")))))\\,?\\ " ~ $fourDigitYear ~ ")$/";

        $regex["My"] = "%^(Jan(uary)?|Feb(ruary)?|Ma(r(ch)?|y)|Apr(il)?|Ju((ly?)|(ne?))|Aug(ust)?|Oct(ober)?|(Sep(?=\\b|t)t?|Nov|Dec)(ember)?)" ~
            $separator . $fourDigitYear ~ "$%";
        // phpcs:enable Generic.Files.LineLength

        $regex["my"] = "%^(" ~ $month . $separator . $year ~ ")$%";
        $regex["ym"] = "%^(" ~ $year . $separator . $month ~ ")$%";
        $regex["y"] = "%^(" ~ $fourDigitYear ~ ")$%";

        $format = is_array($format) ? array_values($format) : [$format];
        foreach ($format as myKey) {
            if (static::_check($check, $regex[myKey]) == true) {
                return true;
            }
        }

        return false;
    }

    /**
     * Validates a datetime value
     *
     * All values matching the "date" core validation rule, and the "time" one will be valid
     *
     * @param mixed $check Value to check
     * @param array|string dateFormat Format of the date part. See Validation::date() for more information.
     *   Or `Validation::DATETIME_ISO8601` to validate an ISO8601 datetime value.
     * @param string|null $regex Regex for the date part. If a custom regular expression is used
     *   this is the only validation that will occur.
     * @return bool True if the value is valid, false otherwise
     * @see uim.cake.validations.Validation::date()
     * @see uim.cake.validations.Validation::time()
     */
    static bool datetime($check, $dateFormat = "ymd", Nullable!string regex = null) {
        if ($check instanceof IDateTime) {
            return true;
        }
        if (is_object($check)) {
            return false;
        }
        if (is_array($dateFormat) && count($dateFormat) == 1) {
            $dateFormat = reset($dateFormat);
        }
        if ($dateFormat == static::DATETIME_ISO8601 && !static::iso8601($check)) {
            return false;
        }

        $valid = false;
        if (is_array($check)) {
            $check = static::_getDateString($check);
            $dateFormat = "ymd";
        }
        $parts = preg_split("/[\sT]+/", $check);
        if (!empty($parts) && count($parts) > 1) {
            $date = rtrim(array_shift($parts), ",");
            $time = implode(" ", $parts);
            if ($dateFormat == static::DATETIME_ISO8601) {
                $dateFormat = "ymd";
                $time = preg_split("/[TZ\-\+\.]/", $time);
                $time = array_shift($time);
            }
            $valid = static::date($date, $dateFormat, $regex) && static::time($time);
        }

        return $valid;
    }

    /**
     * Validates an iso8601 datetime format
     * ISO8601 recognize datetime like 2019 as a valid date. To validate and check date integrity, use @see uim.cake.validations.Validation::datetime()
     *
     * @param mixed $check Value to check
     * @return bool True if the value is valid, false otherwise
     * @see Regex credits: https://www.myintervals.com/blog/2009/05/20/iso-8601-date-validation-that-doesnt-suck/
     */
    static bool iso8601($check) {
        if ($check instanceof IDateTime) {
            return true;
        }
        if (is_object($check)) {
            return false;
        }

        // phpcs:ignore Generic.Files.LineLength
        $regex = "/^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$/";

        return static::_check($check, $regex);
    }

    /**
     * Time validation, determines if the string passed is a valid time.
     * Validates time as 24hr (HH:MM[:SS][.FFFFFF]) or am/pm ([H]H:MM[a|p]m)
     *
     * Seconds and fractional seconds (microseconds) are allowed but optional
     * in 24hr format.
     *
     * @param mixed $check a valid time string/object
     * @return bool Success
     */
    static bool time($check) {
        if ($check instanceof IDateTime) {
            return true;
        }
        if (is_array($check)) {
            $check = static::_getDateString($check);
        }

        if (!is_scalar($check)) {
            return false;
        }

        $meridianClockRegex = "^((0?[1-9]|1[012])(:[0-5]\d){0,2} ?([AP]M|[ap]m))$";
        $standardClockRegex = "^([01]\d|2[0-3])((:[0-5]\d){1,2}|(:[0-5]\d){2}\.\d{0,6})$";

        return static::_check($check, "%" ~ $meridianClockRegex ~ "|" ~ $standardClockRegex ~ "%");
    }

    /**
     * Date and/or time string validation.
     * Uses `I18n::Time` to parse the date. This means parsing is locale dependent.
     *
     * @param mixed $check a date string or object (will always pass)
     * @param string myType Parser type, one out of "date", "time", and "datetime"
     * @param string|int|null $format any format accepted by IntlDateFormatter
     * @return bool Success
     * @throws \InvalidArgumentException when unsupported myType given
     * @see uim.cake.I18n\Time::parseDate()
     * @see uim.cake.I18n\Time::parseTime()
     * @see uim.cake.I18n\Time::parseDateTime()
     */
    static bool localizedTime($check, string myType = "datetime", $format = null) {
        if ($check instanceof IDateTime) {
            return true;
        }
        if (!is_string($check)) {
            return false;
        }
        static $methods = [
            "date": "parseDate",
            "time": "parseTime",
            "datetime": "parseDateTime",
        ];
        if (empty($methods[myType])) {
            throw new InvalidArgumentException("Unsupported parser type given.");
        }
        $method = $methods[myType];

        return FrozenTime::$method($check, $format)  !is null;
    }

    /**
     * Validates if passed value is boolean-like.
     *
     * The list of what is considered to be boolean values, may be set via $booleanValues.
     *
     * @param string|int|bool $check Value to check.
     * @param array $booleanValues List of valid boolean values, defaults to `[true, false, 0, 1, "0", "1"]`.
     * @return bool Success.
     */
    static bool boolean($check, array $booleanValues = []) {
        if (!$booleanValues) {
            $booleanValues = [true, false, 0, 1, "0", "1"];
        }

        return in_array($check, $booleanValues, true);
    }

    /**
     * Validates if given value is truthy.
     *
     * The list of what is considered to be truthy values, may be set via $truthyValues.
     *
     * @param string|int|bool $check Value to check.
     * @param array $truthyValues List of valid truthy values, defaults to `[true, 1, "1"]`.
     * @return bool Success.
     */
    static bool truthy($check, array $truthyValues = []) {
        if (!$truthyValues) {
            $truthyValues = [true, 1, "1"];
        }

        return in_array($check, $truthyValues, true);
    }

    /**
     * Validates if given value is falsey.
     *
     * The list of what is considered to be falsey values, may be set via $falseyValues.
     *
     * @param string|int|bool $check Value to check.
     * @param array $falseyValues List of valid falsey values, defaults to `[false, 0, "0"]`.
     * @return bool Success.
     */
    static bool falsey($check, array $falseyValues = []) {
        if (!$falseyValues) {
            $falseyValues = [false, 0, "0"];
        }

        return in_array($check, $falseyValues, true);
    }

    /**
     * Checks that a value is a valid decimal. Both the sign and exponent are optional.
     *
     * Valid Places:
     *
     * - null: Any number of decimal places, including none. The "." is not required.
     * - true: Any number of decimal places greater than 0, or a float|double. The "." is required.
     * - 1..N: Exactly that many number of decimal places. The "." is required.
     *
     * @param mixed $check The value the test for decimal.
     * @param int|true|null $places Decimal places.
     * @param string|null $regex If a custom regular expression is used, this is the only validation that will occur.
     * @return bool Success
     */
    static bool decimal($check, $places = null, Nullable!string regex = null) {
        if (!is_scalar($check)) {
            return false;
        }

        if ($regex is null) {
            $lnum = "[0-9]+";
            $dnum = "[0-9]*[\.]{$lnum}";
            $sign = "[+-]?";
            $exp = "(?:[eE]{$sign}{$lnum})?";

            if ($places is null) {
                $regex = "/^{$sign}(?:{$lnum}|{$dnum}){$exp}$/";
            } elseif ($places == true) {
                if (is_float($check) && floor($check) == $check) {
                    $check = sprintf("%.1f", $check);
                }
                $regex = "/^{$sign}{$dnum}{$exp}$/";
            } elseif (is_numeric($places)) {
                $places = "[0-9]{" ~ $places ~ "}";
                $dnum = "(?:[0-9]*[\.]{$places}|{$lnum}[\.]{$places})";
                $regex = "/^{$sign}{$dnum}{$exp}$/";
            } else {
                return false;
            }
        }

        // account for localized floats.
        $locale = ini_get("intl.default_locale") ?: static::DEFAULT_LOCALE;
        $formatter = new NumberFormatter($locale, NumberFormatter::DECIMAL);
        $decimalPoint = $formatter.getSymbol(NumberFormatter::DECIMAL_SEPARATOR_SYMBOL);
        myGroupingSep = $formatter.getSymbol(NumberFormatter::GROUPING_SEPARATOR_SYMBOL);

        // There are two types of non-breaking spaces - we inject a space to account for human input
        if (myGroupingSep == "\xc2\xa0" || myGroupingSep == "\xe2\x80\xaf") {
            $check = replace([" ", myGroupingSep, $decimalPoint], ["", "", "."], (string)$check);
        } else {
            $check = replace([myGroupingSep, $decimalPoint], ["", "."], (string)$check);
        }

        return static::_check($check, $regex);
    }

    /**
     * Validates for an email address.
     *
     * Only uses getmxrr() checking for deep validation, or
     * any PHP version on a non-windows distribution
     *
     * @param mixed $check Value to check
     * @param bool $deep Perform a deeper validation (if true), by also checking availability of host
     * @param string|null $regex Regex to use (if none it will use built in regex)
     * @return bool Success
     */
    static bool email($check, ?bool $deep = false, Nullable!string regex = null) {
        if (!is_string($check)) {
            return false;
        }

        if ($regex is null) {
            // phpcs:ignore Generic.Files.LineLength
            $regex = "/^[\p{L}0-9!#$%&\"*+\/=?^_`{|}~-]+(?:\.[\p{L}0-9!#$%&\"*+\/=?^_`{|}~-]+)*@" ~ self::_pattern["hostname"] ~ "$/ui";
        }
        $return = static::_check($check, $regex);
        if ($deep == false || $deep is null) {
            return $return;
        }

        if ($return == true && preg_match("/@(" ~ static::_pattern["hostname"] ~ ")$/i", $check, $regs)) {
            if (function_exists("getmxrr") && getmxrr($regs[1], $mxhosts)) {
                return true;
            }
            if (function_exists("checkdnsrr") && checkdnsrr($regs[1], "MX")) {
                return true;
            }

            return is_array(gethostbynamel($regs[1] ~ "."));
        }

        return false;
    }

    /**
     * Checks that value is exactly $comparedTo.
     *
     * @param mixed $check Value to check
     * @param mixed $comparedTo Value to compare
     * @return bool Success
     */
    static bool equalTo($check, $comparedTo) {
        return $check == $comparedTo;
    }

    /**
     * Checks that value has a valid file extension.
     *
     * @param \Psr\Http\messages.UploadedFileInterface|array|string check Value to check
     * @param $extensions file extensions to allow. By default extensions are "gif", "jpeg", "png", "jpg"
     * @return bool Success
     */
    static function extension($check, string[] $extensions = ["gif", "jpeg", "png", "jpg"]) {
        if ($check instanceof UploadedFileInterface) {
            $check = $check.getClientFilename();
        } elseif (is_array($check) && isset($check["name"])) {
            $check = $check["name"];
        } elseif (is_array($check)) {
            return static::extension(array_shift($check), $extensions);
        }

        if (empty($check)) {
            return false;
        }

        $extension = strtolower(pathinfo($check, PATHINFO_EXTENSION));
        foreach ($extensions as myValue) {
            if ($extension == strtolower(myValue)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Validation of an IP address.
     *
     * @param mixed $check The string to test.
     * @param string myType The IP Protocol version to validate against
     * @return bool Success
     */
    static bool ip($check, string myType = "both") {
        if (!is_string($check)) {
            return false;
        }

        myType = strtolower(myType);
        $flags = 0;
        if (myType == "ipv4") {
            $flags = FILTER_FLAG_IPV4;
        }
        if (myType == "ipv6") {
            $flags = FILTER_FLAG_IPV6;
        }

        return (bool)filter_var($check, FILTER_VALIDATE_IP, ["flags": $flags]);
    }

    /**
     * Checks whether the length of a string (in characters) is greater or equal to a minimal length.
     *
     * @param mixed $check The string to test
     * @param int $min The minimal string length
     * @return bool Success
     */
    static bool minLength($check, int $min) {
        if (!is_scalar($check)) {
            return false;
        }

        return mb_strlen((string)$check) >= $min;
    }

    /**
     * Checks whether the length of a string (in characters) is smaller or equal to a maximal length.
     *
     * @param mixed $check The string to test
     * @param int $max The maximal string length
     * @return bool Success
     */
    static bool maxLength($check, int $max) {
        if (!is_scalar($check)) {
            return false;
        }

        return mb_strlen((string)$check) <= $max;
    }

    /**
     * Checks whether the length of a string (in bytes) is greater or equal to a minimal length.
     *
     * @param mixed $check The string to test
     * @param int $min The minimal string length (in bytes)
     * @return bool Success
     */
    static bool minLengthBytes($check, int $min) {
        if (!is_scalar($check)) {
            return false;
        }

        return strlen((string)$check) >= $min;
    }

    /**
     * Checks whether the length of a string (in bytes) is smaller or equal to a maximal length.
     *
     * @param mixed $check The string to test
     * @param int $max The maximal string length
     * @return bool Success
     */
    static bool maxLengthBytes($check, int $max) {
        if (!is_scalar($check)) {
            return false;
        }

        return strlen((string)$check) <= $max;
    }

    /**
     * Checks that a value is a monetary amount.
     *
     * @param mixed $check Value to check
     * @param string symbolPosition Where symbol is located (left/right)
     * @return bool Success
     */
    static bool money($check, string symbolPosition = "left") {
        $money = "(?!0,?\d)(?:\d{1,3}(?:([, .])\d{3})?(?:\1\d{3})*|(?:\d+))((?!\1)[,.]\d{1,2})?";
        if ($symbolPosition == "right") {
            $regex = "/^" ~ $money ~ "(?<!\x{00a2})\p{Sc}?$/u";
        } else {
            $regex = "/^(?!\x{00a2})\p{Sc}?" ~ $money ~ "$/u";
        }

        return static::_check($check, $regex);
    }

    /**
     * Validates a multiple select. Comparison is case sensitive by default.
     *
     * Valid Options
     *
     * - in: provide a list of choices that selections must be made from
     * - max: maximum number of non-zero choices that can be made
     * - min: minimum number of non-zero choices that can be made
     *
     * @param mixed $check Value to check
     * @param array<string, mixed> myOptions Options for the check.
     * @param bool $caseInsensitive Set to true for case insensitive comparison.
     * @return bool Success
     */
    static bool multiple($check, array myOptions = [], bool $caseInsensitive = false) {
        $defaults = ["in": null, "max": null, "min": null];
        myOptions += $defaults;

        $check = array_filter((array)$check, function (myValue) {
            return myValue || is_numeric(myValue);
        });
        if (empty($check)) {
            return false;
        }
        if (myOptions["max"] && count($check) > myOptions["max"]) {
            return false;
        }
        if (myOptions["min"] && count($check) < myOptions["min"]) {
            return false;
        }
        if (myOptions["in"] && is_array(myOptions["in"])) {
            if ($caseInsensitive) {
                myOptions["in"] = array_map("mb_strtolower", myOptions["in"]);
            }
            foreach ($check as $val) {
                $strict = !is_numeric($val);
                if ($caseInsensitive) {
                    $val = mb_strtolower($val);
                }
                if (!in_array((string)$val, myOptions["in"], $strict)) {
                    return false;
                }
            }
        }

        return true;
    }

    /**
     * Checks if a value is numeric.
     *
     * @param mixed $check Value to check
     * @return bool Success
     */
    static bool numeric($check) {
        return is_numeric($check);
    }

    /**
     * Checks if a value is a natural number.
     *
     * @param mixed $check Value to check
     * @param bool $allowZero Set true to allow zero, defaults to false
     * @return bool Success
     * @see https://en.wikipedia.org/wiki/Natural_number
     */
    static bool naturalNumber($check, bool $allowZero = false) {
        $regex = $allowZero ? "/^(?:0|[1-9][0-9]*)$/" : "/^[1-9][0-9]*$/";

        return static::_check($check, $regex);
    }

    /**
     * Validates that a number is in specified range.
     *
     * If $lower and $upper are set, the range is inclusive.
     * If they are not set, will return true if $check is a
     * legal finite on this platform.
     *
     * @param mixed $check Value to check
     * @param float|null $lower Lower limit
     * @param float|null $upper Upper limit
     * @return bool Success
     */
    static bool range($check, ?float $lower = null, ?float $upper = null) {
        if (!is_numeric($check)) {
            return false;
        }
        if ((float)$check != $check) {
            return false;
        }
        if (isset($lower, $upper)) {
            return $check >= $lower && $check <= $upper;
        }

        return is_finite((float)$check);
    }

    /**
     * Checks that a value is a valid URL according to https://www.w3.org/Addressing/URL/url-spec.txt
     *
     * The regex checks for the following component parts:
     *
     * - a valid, optional, scheme
     * - a valid IP address OR
     *   a valid domain name as defined by section 2.3.1 of https://www.ietf.org/rfc/rfc1035.txt
     *   with an optional port number
     * - an optional valid path
     * - an optional query string (get parameters)
     * - an optional fragment (anchor tag) as defined in RFC 3986
     *
     * @param mixed $check Value to check
     * @param bool $strict Require URL to be prefixed by a valid scheme (one of http(s)/ftp(s)/file/news/gopher)
     * @return bool Success
     * @link https://tools.ietf.org/html/rfc3986
     */
    static bool url($check, bool $strict = false) {
        if (!is_string($check)) {
            return false;
        }

        static::_populateIp();

        $emoji = "\x{1F190}-\x{1F9EF}";
        $alpha = "0-9\p{L}\p{N}" ~ $emoji;
        $hex = "(%[0-9a-f]{2})";
        $subDelimiters = preg_quote("/!"$&\"()*+,-.@_:;=~[]", "/");
        myPath = "([" ~ $subDelimiters . $alpha ~ "]|" ~ $hex ~ ")";
        $fragmentAndQuery = "([\?" ~ $subDelimiters . $alpha ~ "]|" ~ $hex ~ ")";
        // phpcs:disable Generic.Files.LineLength
        $regex = "/^(?:(?:https?|ftps?|sftp|file|news|gopher):\/\/)" ~ ($strict ? "" : "?") .
            "(?:" ~ static::_pattern["IPv4"] ~ "|\[" ~ static::_pattern["IPv6"] ~ "\]|" ~ static::_pattern["hostname"] ~ ")(?::[1-9][0-9]{0,4})?" ~
            "(?:\/" ~ myPath ~ "*)?" ~
            "(?:\?" ~ $fragmentAndQuery ~ "*)?" ~
            "(?:#" ~ $fragmentAndQuery ~ "*)?$/iu";
        // phpcs:enable Generic.Files.LineLength

        return static::_check($check, $regex);
    }

    /**
     * Checks if a value is in a given list. Comparison is case sensitive by default.
     *
     * @param mixed $check Value to check.
     * @param $list List to check against.
     * @param bool $caseInsensitive Set to true for case insensitive comparison.
     * @return bool Success.
     */
    static bool inList($check, string[] $list, bool $caseInsensitive = false) {
        if (!is_scalar($check)) {
            return false;
        }
        if ($caseInsensitive) {
            $list = array_map("mb_strtolower", $list);
            $check = mb_strtolower((string)$check);
        } else {
            $list = array_map("strval", $list);
        }

        return in_array((string)$check, $list, true);
    }

    /**
     * Checks that a value is a valid UUID - https://tools.ietf.org/html/rfc4122
     *
     * @param mixed $check Value to check
     * @return bool Success
     */
    static bool uuid($check) {
        $regex = "/^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[0-5][a-fA-F0-9]{3}-[089aAbB][a-fA-F0-9]{3}-[a-fA-F0-9]{12}$/";

        return self::_check($check, $regex);
    }

    /**
     * Runs a regular expression match.
     *
     * @param mixed $check Value to check against the $regex expression
     * @param string regex Regular expression
     * @return bool Success of match
     */
    protected static bool _check($check, string regex) {
        return is_scalar($check) && preg_match($regex, (string)$check);
    }

    /**
     * Luhn algorithm
     *
     * @param mixed $check Value to check.
     * @return bool Success
     * @see https://en.wikipedia.org/wiki/Luhn_algorithm
     */
    static bool luhn($check) {
        if (!is_scalar($check) || (int)$check == 0) {
            return false;
        }
        $sum = 0;
        $check = (string)$check;
        $length = strlen($check);

        for ($position = 1 - ($length % 2); $position < $length; $position += 2) {
            $sum += (int)$check[$position];
        }

        for ($position = $length % 2; $position < $length; $position += 2) {
            $number = (int)$check[$position] * 2;
            $sum += $number < 10 ? $number : $number - 9;
        }

        return $sum % 10 == 0;
    }

    /**
     * Checks the mime type of a file.
     *
     * Will check the mimetype of files/UploadedFileInterface instances
     * by checking the using finfo on the file, not relying on the content-type
     * sent by the client.
     *
     * @param \Psr\Http\messages.UploadedFileInterface|array|string check Value to check.
     * @param array|string mimeTypes Array of mime types or regex pattern to check.
     * @return bool Success
     * @throws \RuntimeException when mime type can not be determined.
     * @throws \LogicException when ext/fileinfo is missing
     */
    static bool mimeType($check, $mimeTypes = []) {
        myfile = static::getFilename($check);
        if (myfile == false) {
            return false;
        }

        if (!function_exists("finfo_open")) {
            throw new LogicException("ext/fileinfo is required for validating file mime types");
        }

        if (!is_file(myfile)) {
            throw new RuntimeException("Cannot validate mimetype for a missing file");
        }

        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $mime = finfo_file($finfo, myfile);

        if (!$mime) {
            throw new RuntimeException("Can not determine the mimetype.");
        }

        if (is_string($mimeTypes)) {
            return self::_check($mime, $mimeTypes);
        }

        foreach ($mimeTypes as myKey: $val) {
            $mimeTypes[myKey] = strtolower($val);
        }

        return in_array(strtolower($mime), $mimeTypes, true);
    }

    /**
     * Helper for reading the file out of the various file implementations
     * we accept.
     *
     * @param mixed $check The data to read a filename out of.
     * @return string|false Either the filename or false on failure.
     */
    protected static auto getFilename($check) {
        if ($check instanceof UploadedFileInterface) {
            // Uploaded files throw exceptions on upload errors.
            try {
                $uri = $check.getStream().getMetadata("uri");
                if (is_string($uri)) {
                    return $uri;
                }

                return false;
            } catch (RuntimeException $e) {
                return false;
            }
        }
        if (is_array($check) && isset($check["tmp_name"])) {
            return $check["tmp_name"];
        }

        if (is_string($check)) {
            return $check;
        }

        return false;
    }

    /**
     * Checks the filesize
     *
     * Will check the filesize of files/UploadedFileInterface instances
     * by checking the filesize() on disk and not relying on the length
     * reported by the client.
     *
     * @param \Psr\Http\messages.UploadedFileInterface|array|string check Value to check.
     * @param string operator See `Validation::comparison()`.
     * @param string|int $size Size in bytes or human readable string like "5MB".
     * @return bool Success
     */
    static bool fileSize($check, string operator, $size) {
        myfile = static::getFilename($check);
        if (myfile == false) {
            return false;
        }

        if (is_string($size)) {
            $size = Text::parseFileSize($size);
        }
        myfilesize = filesize(myfile);

        return static::comparison(myfilesize, $operator, $size);
    }

    /**
     * Checking for upload errors
     *
     * @param \Psr\Http\messages.UploadedFileInterface|array|string check Value to check.
     * @param bool $allowNoFile Set to true to allow UPLOAD_ERR_NO_FILE as a pass.
     * @return bool
     * @see https://secure.php.net/manual/en/features.file-upload.errors.php
     */
    static bool uploadError($check, bool $allowNoFile = false) {
        if ($check instanceof UploadedFileInterface) {
            $code = $check.getError();
        } elseif (is_array($check) && isset($check["error"])) {
            $code = $check["error"];
        } else {
            $code = $check;
        }
        if ($allowNoFile) {
            return in_array((int)$code, [UPLOAD_ERR_OK, UPLOAD_ERR_NO_FILE], true);
        }

        return (int)$code == UPLOAD_ERR_OK;
    }

    /**
     * Validate an uploaded file.
     *
     * Helps join `uploadError`, `fileSize` and `mimeType` into
     * one higher level validation method.
     *
     * ### Options
     *
     * - `types` - An array of valid mime types. If empty all types
     *   will be accepted. The `type` will not be looked at, instead
     *   the file type will be checked with ext/finfo.
     * - `minSize` - The minimum file size in bytes. Defaults to not checking.
     * - `maxSize` - The maximum file size in bytes. Defaults to not checking.
     * - `optional` - Whether this file is optional. Defaults to false.
     *   If true a missing file will pass the validator regardless of other constraints.
     *
     * @param mixed myfile The uploaded file data from PHP.
     * @param array<string, mixed> myOptions An array of options for the validation.
     * @return bool
     */
    static bool uploadedFile(myfile, array myOptions = []) {
        myOptions += [
            "minSize": null,
            "maxSize": null,
            "types": null,
            "optional": false,
        ];
        if (!is_array(myfile) && !(myfile instanceof UploadedFileInterface)) {
            return false;
        }
        myError = $isUploaded = false;
        if (myfile instanceof UploadedFileInterface) {
            myError = myfile.getError();
            $isUploaded = true;
        }
        if (is_array(myfile)) {
            myKeys = ["error", "name", "size", "tmp_name", "type"];
            ksort(myfile);
            if (array_keys(myfile) != myKeys) {
                return false;
            }
            myError = (int)myfile["error"];
            $isUploaded = is_uploaded_file(myfile["tmp_name"]);
        }

        if (!static::uploadError(myfile, myOptions["optional"])) {
            return false;
        }
        if (myOptions["optional"] && myError == UPLOAD_ERR_NO_FILE) {
            return true;
        }
        if (
            isset(myOptions["minSize"])
            && !static::fileSize(myfile, static::COMPARE_GREATER_OR_EQUAL, myOptions["minSize"])
        ) {
            return false;
        }
        if (
            isset(myOptions["maxSize"])
            && !static::fileSize(myfile, static::COMPARE_LESS_OR_EQUAL, myOptions["maxSize"])
        ) {
            return false;
        }
        if (isset(myOptions["types"]) && !static::mimeType(myfile, myOptions["types"])) {
            return false;
        }

        return $isUploaded;
    }

    /**
     * Validates the size of an uploaded image.
     *
     * @param mixed myfile The uploaded file data from PHP.
     * @param array<string, mixed> myOptions Options to validate width and height.
     * @return bool
     * @throws \InvalidArgumentException
     */
    static bool imageSize(myfile, array myOptions) {
        if (!isset(myOptions["height"]) && !isset(myOptions["width"])) {
            throw new InvalidArgumentException(
                "Invalid image size validation parameters! Missing `width` and / or `height`."
            );
        }

        myfile = static::getFilename(myfile);
        if (myfile == false) {
            return false;
        }

        [$width, $height] = getimagesize(myfile);
        $validHeight = null;
        $validWidth = null;

        if (isset(myOptions["height"])) {
            $validHeight = self::comparison($height, myOptions["height"][0], myOptions["height"][1]);
        }
        if (isset(myOptions["width"])) {
            $validWidth = self::comparison($width, myOptions["width"][0], myOptions["width"][1]);
        }
        if ($validHeight  !is null && $validWidth  !is null) {
            return $validHeight && $validWidth;
        }
        if ($validHeight  !is null) {
            return $validHeight;
        }
        if ($validWidth  !is null) {
            return $validWidth;
        }

        throw new InvalidArgumentException("The 2nd argument is missing the `width` and / or `height` options.");
    }

    /**
     * Validates the image width.
     *
     * @param mixed myfile The uploaded file data from PHP.
     * @param string operator Comparison operator.
     * @param int $width Min or max width.
     * @return bool
     */
    static bool imageWidth(myfile, string operator, int $width) {
        return self::imageSize(myfile, [
            "width": [
                $operator,
                $width,
            ],
        ]);
    }

    /**
     * Validates the image height.
     *
     * @param mixed myfile The uploaded file data from PHP.
     * @param string operator Comparison operator.
     * @param int $height Min or max height.
     * @return bool
     */
    static bool imageHeight(myfile, string operator, int $height) {
        return self::imageSize(myfile, [
            "height": [
                $operator,
                $height,
            ],
        ]);
    }

    /**
     * Validates a geographic coordinate.
     *
     * Supported formats:
     *
     * - `<latitude>, <longitude>` Example: `-25.274398, 133.775136`
     *
     * ### Options
     *
     * - `type` - A string of the coordinate format, right now only `latLong`.
     * - `format` - By default `both`, can be `long` and `lat` as well to validate
     *   only a part of the coordinate.
     *
     * @param mixed myValue Geographic location as string
     * @param array<string, mixed> myOptions Options for the validation logic.
     * @return bool
     */
    static bool geoCoordinate(myValue, array myOptions = []) {
        if (!is_scalar(myValue)) {
            return false;
        }

        myOptions += [
            "format": "both",
            "type": "latLong",
        ];
        if (myOptions["type"] != "latLong") {
            throw new RuntimeException(sprintf(
                "Unsupported coordinate type '%s'. Use "latLong" instead.",
                myOptions["type"]
            ));
        }
        $pattern = "/^" ~ self::_pattern["latitude"] ~ ",\s*" ~ self::_pattern["longitude"] ~ "$/";
        if (myOptions["format"] == "long") {
            $pattern = "/^" ~ self::_pattern["longitude"] ~ "$/";
        }
        if (myOptions["format"] == "lat") {
            $pattern = "/^" ~ self::_pattern["latitude"] ~ "$/";
        }

        return (bool)preg_match($pattern, (string)myValue);
    }

    /**
     * Convenience method for latitude validation.
     *
     * @param mixed myValue Latitude as string
     * @param array<string, mixed> myOptions Options for the validation logic.
     * @return bool
     * @link https://en.wikipedia.org/wiki/Latitude
     * @see uim.cake.validations.Validation::geoCoordinate()
     */
    static bool latitude(myValue, array myOptions = []) {
        myOptions["format"] = "lat";

        return self::geoCoordinate(myValue, myOptions);
    }

    /**
     * Convenience method for longitude validation.
     *
     * @param mixed myValue Latitude as string
     * @param array<string, mixed> myOptions Options for the validation logic.
     * @return bool
     * @link https://en.wikipedia.org/wiki/Longitude
     * @see uim.cake.validations.Validation::geoCoordinate()
     */
    static bool longitude(myValue, array myOptions = []) {
        myOptions["format"] = "long";

        return self::geoCoordinate(myValue, myOptions);
    }

    /**
     * Check that the input value is within the ascii byte range.
     *
     * This method will reject all non-string values.
     *
     * @param mixed myValue The value to check
     * @return bool
     */
    static bool ascii(myValue) {
        if (!is_string(myValue)) {
            return false;
        }

        return strlen(myValue) <= mb_strlen(myValue, "utf-8");
    }

    /**
     * Check that the input value is a utf8 string.
     *
     * This method will reject all non-string values.
     *
     * # Options
     *
     * - `extended` - Disallow bytes higher within the basic multilingual plane.
     *   MySQL"s older utf8 encoding type does not allow characters above
     *   the basic multilingual plane. Defaults to false.
     *
     * @param mixed myValue The value to check
     * @param array<string, mixed> myOptions An array of options. See above for the supported options.
     * @return bool
     */
    static bool utf8(myValue, array myOptions = []) {
        if (!is_string(myValue)) {
            return false;
        }
        myOptions += ["extended": false];
        if (myOptions["extended"]) {
            return true;
        }

        return preg_match("/[\x{10000}-\x{10FFFF}]/u", myValue) == 0;
    }

    /**
     * Check that the input value is an integer
     *
     * This method will accept strings that contain only integer data
     * as well.
     *
     * @param mixed myValue The value to check
     * @return bool
     */
    static bool isInteger(myValue) {
        if (is_int(myValue)) {
            return true;
        }

        if (!is_string(myValue) || !is_numeric(myValue)) {
            return false;
        }

        return (bool)preg_match("/^-?[0-9]+$/", myValue);
    }

    /**
     * Check that the input value is an array.
     *
     * @param mixed myValue The value to check
     * @return bool
     */
    static bool isArray(myValue) {
        return is_array(myValue);
    }

    /**
     * Check that the input value is a scalar.
     *
     * This method will accept integers, floats, strings and booleans, but
     * not accept arrays, objects, resources and nulls.
     *
     * @param mixed myValue The value to check
     * @return bool
     */
    static bool isScalar(myValue) {
        return is_scalar(myValue);
    }

    /**
     * Check that the input value is a 6 digits hex color.
     *
     * @param mixed $check The value to check
     * @return bool Success
     */
    static bool hexColor($check) {
        return static::_check($check, "/^#[0-9a-f]{6}$/iD");
    }

    /**
     * Check that the input value has a valid International Bank Account Number IBAN syntax
     * Requirements are uppercase, no whitespaces, max length 34, country code and checksum exist at right spots,
     * body matches against checksum via Mod97-10 algorithm
     *
     * @param mixed $check The value to check
     * @return bool Success
     */
    static bool iban($check) {
        if (
            !is_string($check) ||
            !preg_match("/^[A-Z]{2}[0-9]{2}[A-Z0-9]{1,30}$/", $check)
        ) {
            return false;
        }

        myCountry = substr($check, 0, 2);
        $checkInt = intval(substr($check, 2, 2));
        $account = substr($check, 4);
        $search = range("A", "Z");
        $replace = [];
        foreach (range(10, 35) as $tmp) {
            $replace[] = strval($tmp);
        }
        $numStr = replace($search, $replace, $account . myCountry ~ "00");
        $checksum = intval(substr($numStr, 0, 1));
        $numStrLength = strlen($numStr);
        for ($pos = 1; $pos < $numStrLength; $pos++) {
            $checksum *= 10;
            $checksum += intval(substr($numStr, $pos, 1));
            $checksum %= 97;
        }

        return $checkInt == 98 - $checksum;
    }

    /**
     * Converts an array representing a date or datetime into a ISO string.
     * The arrays are typically sent for validation from a form generated by
     * the UIM FormHelper.
     *
     * @param array<string, mixed> myValue The array representing a date or datetime.
     * @return string
     */
    protected static string _getDateString(array myValue) {
        $formatted = "";
        if (
            isset(myValue["year"], myValue["month"], myValue["day"]) &&
            (
                is_numeric(myValue["year"]) &&
                is_numeric(myValue["month"]) &&
                is_numeric(myValue["day"])
            )
        ) {
            $formatted ~= sprintf("%d-%02d-%02d ", myValue["year"], myValue["month"], myValue["day"]);
        }

        if (isset(myValue["hour"])) {
            if (isset(myValue["meridian"]) && (int)myValue["hour"] == 12) {
                myValue["hour"] = 0;
            }
            if (isset(myValue["meridian"])) {
                myValue["hour"] = strtolower(myValue["meridian"]) == "am" ? myValue["hour"] : myValue["hour"] + 12;
            }
            myValue += ["minute": 0, "second": 0, "microsecond": 0];
            if (
                is_numeric(myValue["hour"]) &&
                is_numeric(myValue["minute"]) &&
                is_numeric(myValue["second"]) &&
                is_numeric(myValue["microsecond"])
            ) {
                $formatted ~= sprintf(
                    "%02d:%02d:%02d.%06d",
                    myValue["hour"],
                    myValue["minute"],
                    myValue["second"],
                    myValue["microsecond"]
                );
            }
        }

        return trim($formatted);
    }

    // Lazily populate the IP address patterns used for validations
    protected static void _populateIp() {
        // phpcs:disable Generic.Files.LineLength
        if (!isset(static::_pattern["IPv6"])) {
            $pattern = "((([0-9A-Fa-f]{1,4}:){7}(([0-9A-Fa-f]{1,4})|:))|(([0-9A-Fa-f]{1,4}:){6}";
            $pattern ~= "(:|((25[0-5]|2[0-4]\d|[01]?\d{1,2})(\.(25[0-5]|2[0-4]\d|[01]?\d{1,2})){3})";
            $pattern ~= "|(:[0-9A-Fa-f]{1,4})))|(([0-9A-Fa-f]{1,4}:){5}((:((25[0-5]|2[0-4]\d|[01]?\d{1,2})";
            $pattern ~= "(\.(25[0-5]|2[0-4]\d|[01]?\d{1,2})){3})?)|((:[0-9A-Fa-f]{1,4}){1,2})))|(([0-9A-Fa-f]{1,4}:)";
            $pattern ~= "{4}(:[0-9A-Fa-f]{1,4}){0,1}((:((25[0-5]|2[0-4]\d|[01]?\d{1,2})(\.(25[0-5]|2[0-4]\d|[01]?\d{1,2}))";
            $pattern ~= "{3})?)|((:[0-9A-Fa-f]{1,4}){1,2})))|(([0-9A-Fa-f]{1,4}:){3}(:[0-9A-Fa-f]{1,4}){0,2}";
            $pattern ~= "((:((25[0-5]|2[0-4]\d|[01]?\d{1,2})(\.(25[0-5]|2[0-4]\d|[01]?\d{1,2})){3})?)|";
            $pattern ~= "((:[0-9A-Fa-f]{1,4}){1,2})))|(([0-9A-Fa-f]{1,4}:){2}(:[0-9A-Fa-f]{1,4}){0,3}";
            $pattern ~= "((:((25[0-5]|2[0-4]\d|[01]?\d{1,2})(\.(25[0-5]|2[0-4]\d|[01]?\d{1,2}))";
            $pattern ~= "{3})?)|((:[0-9A-Fa-f]{1,4}){1,2})))|(([0-9A-Fa-f]{1,4}:)(:[0-9A-Fa-f]{1,4})";
            $pattern ~= "{0,4}((:((25[0-5]|2[0-4]\d|[01]?\d{1,2})(\.(25[0-5]|2[0-4]\d|[01]?\d{1,2})){3})?)";
            $pattern ~= "|((:[0-9A-Fa-f]{1,4}){1,2})))|(:(:[0-9A-Fa-f]{1,4}){0,5}((:((25[0-5]|2[0-4]";
            $pattern ~= "\d|[01]?\d{1,2})(\.(25[0-5]|2[0-4]\d|[01]?\d{1,2})){3})?)|((:[0-9A-Fa-f]{1,4})";
            $pattern ~= "{1,2})))|(((25[0-5]|2[0-4]\d|[01]?\d{1,2})(\.(25[0-5]|2[0-4]\d|[01]?\d{1,2})){3})))(%.+)?";

            static::_pattern["IPv6"] = $pattern;
        }
        if (!isset(static::_pattern["IPv4"])) {
            $pattern = "(?:(?:25[0-5]|2[0-4][0-9]|(?:(?:1[0-9])?|[1-9]?)[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|(?:(?:1[0-9])?|[1-9]?)[0-9])";
            static::_pattern["IPv4"] = $pattern;
        }
        // phpcs:enable Generic.Files.LineLength
    }

    /**
     * Reset internal variables for another validation run.
     *
     * @return void
     */
    protected static void _reset() {
        static::myErrors = [];
    }
}
