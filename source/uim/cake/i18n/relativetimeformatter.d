module uim.cake.I18n;

import uim.cake.Chronos\ChronosInterface;
import uim.cake.Chronos\DifferenceIFormatter;

/**
 * Helper class for formatting relative dates & times.
 *
 * @internal
 */
class RelativeTimeFormatter : DifferenceIFormatter {
    /**
     * Get the difference in a human readable format.
     *
     * @param uim.cake.Chronos\ChronosInterface $date The datetime to start with.
     * @param uim.cake.Chronos\ChronosInterface|null $other The datetime to compare against.
     * @param bool $absolute Removes time difference modifiers ago, after, etc.
     * @return string The difference between the two days in a human readable format.
     * @see uim.cake.Chronos\ChronosInterface::diffForHumans
     */
    string diffForHumans(
        ChronosInterface $date,
        ?ChronosInterface $other = null,
        bool $absolute = false
    ) {
        $isNow = $other == null;
        if ($isNow) {
            $other = $date.now($date.getTimezone());
        }
        /** @psalm-suppress PossiblyNullArgument */
        $diffInterval = $date.diff($other);

        switch (true) {
            case $diffInterval.y > 0:
                $count = $diffInterval.y;
                $message = __dn("cake", "{0} year", "{0} years", $count, $count);
                break;
            case $diffInterval.m > 0:
                $count = $diffInterval.m;
                $message = __dn("cake", "{0} month", "{0} months", $count, $count);
                break;
            case $diffInterval.d > 0:
                $count = $diffInterval.d;
                if ($count >= I18nDateTimeInterface::DAYS_PER_WEEK) {
                    $count = (int)($count / I18nDateTimeInterface::DAYS_PER_WEEK);
                    $message = __dn("cake", "{0} week", "{0} weeks", $count, $count);
                } else {
                    $message = __dn("cake", "{0} day", "{0} days", $count, $count);
                }
                break;
            case $diffInterval.h > 0:
                $count = $diffInterval.h;
                $message = __dn("cake", "{0} hour", "{0} hours", $count, $count);
                break;
            case $diffInterval.i > 0:
                $count = $diffInterval.i;
                $message = __dn("cake", "{0} minute", "{0} minutes", $count, $count);
                break;
            default:
                $count = $diffInterval.s;
                $message = __dn("cake", "{0} second", "{0} seconds", $count, $count);
                break;
        }
        if ($absolute) {
            return $message;
        }
        $isFuture = $diffInterval.invert == 1;
        if ($isNow) {
            return $isFuture ? __d("cake", "{0} from now", $message) : __d("cake", "{0} ago", $message);
        }

        return $isFuture ? __d("cake", "{0} after", $message) : __d("cake", "{0} before", $message);
    }

    /**
     * Format a into a relative timestring.
     *
     * @param uim.cake.I18n\I18nDateTimeInterface $time The time instance to format.
     * @param array<string, mixed> $options Array of options.
     * @return string Relative time string.
     * @see uim.cake.I18n\Time::timeAgoInWords()
     */
    string timeAgoInWords(I18nDateTimeInterface $time, STRINGAA someOptions = null) {
        $options = _options($options, FrozenTime::class);
        if ($options["timezone"]) {
            $time = $time.timezone($options["timezone"]);
        }

        $now = $options["from"].format("U");
        $inSeconds = $time.format("U");
        $backwards = ($inSeconds > $now);

        $futureTime = $now;
        $pastTime = $inSeconds;
        if ($backwards) {
            $futureTime = $inSeconds;
            $pastTime = $now;
        }
        $diff = $futureTime - $pastTime;

        if (!$diff) {
            return __d("cake", "just now", "just now");
        }

        if ($diff > abs($now - (new FrozenTime($options["end"])).format("U"))) {
            return sprintf($options["absoluteString"], $time.i18nFormat($options["format"]));
        }

        $diffData = _diffData($futureTime, $pastTime, $backwards, $options);
        [$fNum, $fWord, $years, $months, $weeks, $days, $hours, $minutes, $seconds] = array_values($diffData);

        $relativeDate = null;
        if ($fNum >= 1 && $years > 0) {
            $relativeDate[] = __dn("cake", "{0} year", "{0} years", $years, $years);
        }
        if ($fNum >= 2 && $months > 0) {
            $relativeDate[] = __dn("cake", "{0} month", "{0} months", $months, $months);
        }
        if ($fNum >= 3 && $weeks > 0) {
            $relativeDate[] = __dn("cake", "{0} week", "{0} weeks", $weeks, $weeks);
        }
        if ($fNum >= 4 && $days > 0) {
            $relativeDate[] = __dn("cake", "{0} day", "{0} days", $days, $days);
        }
        if ($fNum >= 5 && $hours > 0) {
            $relativeDate[] = __dn("cake", "{0} hour", "{0} hours", $hours, $hours);
        }
        if ($fNum >= 6 && $minutes > 0) {
            $relativeDate[] = __dn("cake", "{0} minute", "{0} minutes", $minutes, $minutes);
        }
        if ($fNum >= 7 && $seconds > 0) {
            $relativeDate[] = __dn("cake", "{0} second", "{0} seconds", $seconds, $seconds);
        }
        $relativeDate = implode(", ", $relativeDate);

        // When time has passed
        if (!$backwards) {
            $aboutAgo = [
                "second": __d("cake", "about a second ago"),
                "minute": __d("cake", "about a minute ago"),
                "hour": __d("cake", "about an hour ago"),
                "day": __d("cake", "about a day ago"),
                "week": __d("cake", "about a week ago"),
                "month": __d("cake", "about a month ago"),
                "year": __d("cake", "about a year ago"),
            ];

            return $relativeDate ? sprintf($options["relativeString"], $relativeDate) : $aboutAgo[$fWord];
        }

        // When time is to come
        if ($relativeDate) {
            return $relativeDate;
        }
        $aboutIn = [
            "second": __d("cake", "in about a second"),
            "minute": __d("cake", "in about a minute"),
            "hour": __d("cake", "in about an hour"),
            "day": __d("cake", "in about a day"),
            "week": __d("cake", "in about a week"),
            "month": __d("cake", "in about a month"),
            "year": __d("cake", "in about a year"),
        ];

        return $aboutIn[$fWord];
    }

    /**
     * Calculate the data needed to format a relative difference string.
     *
     * @param string|int $futureTime The timestamp from the future.
     * @param string|int $pastTime The timestamp from the past.
     * @param bool $backwards Whether the difference was backwards.
     * @param array<string, mixed> $options An array of options.
     * @return array An array of values.
     */
    protected array _diffData($futureTime, $pastTime, bool $backwards, $options) {
        $futureTime = (int)$futureTime;
        $pastTime = (int)$pastTime;
        $diff = $futureTime - $pastTime;

        // If more than a week, then take into account the length of months
        if ($diff >= 604800) {
            $future = null;
            [
                $future["H"],
                $future["i"],
                $future["s"],
                $future["d"],
                $future["m"],
                $future["Y"],
            ] = explode("/", date("H/i/s/d/m/Y", $futureTime));

            $past = null;
            [
                $past["H"],
                $past["i"],
                $past["s"],
                $past["d"],
                $past["m"],
                $past["Y"],
            ] = explode("/", date("H/i/s/d/m/Y", $pastTime));
            $weeks = $days = $hours = $minutes = $seconds = 0;

            $years = (int)$future["Y"] - (int)$past["Y"];
            $months = (int)$future["m"] + (12 * $years) - (int)$past["m"];

            if ($months >= 12) {
                $years = floor($months / 12);
                $months -= $years * 12;
            }
            if ((int)$future["m"] < (int)$past["m"] && (int)$future["Y"] - (int)$past["Y"] == 1) {
                $years--;
            }

            if ((int)$future["d"] >= (int)$past["d"]) {
                $days = (int)$future["d"] - (int)$past["d"];
            } else {
                $daysInPastMonth = (int)date("t", $pastTime);
                $daysInFutureMonth = (int)date("t", mktime(0, 0, 0, (int)$future["m"] - 1, 1, (int)$future["Y"]));

                if (!$backwards) {
                    $days = $daysInPastMonth - (int)$past["d"] + (int)$future["d"];
                } else {
                    $days = $daysInFutureMonth - (int)$past["d"] + (int)$future["d"];
                }

                if ($future["m"] != $past["m"]) {
                    $months--;
                }
            }

            if (!$months && $years >= 1 && $diff < $years * 31536000) {
                $months = 11;
                $years--;
            }

            if ($months >= 12) {
                $years++;
                $months -= 12;
            }

            if ($days >= 7) {
                $weeks = floor($days / 7);
                $days -= $weeks * 7;
            }
        } else {
            $years = $months = $weeks = 0;
            $days = floor($diff / 86400);

            $diff -= $days * 86400;

            $hours = floor($diff / 3600);
            $diff -= $hours * 3600;

            $minutes = floor($diff / 60);
            $diff -= $minutes * 60;
            $seconds = $diff;
        }

        $fWord = $options["accuracy"]["second"];
        if ($years > 0) {
            $fWord = $options["accuracy"]["year"];
        } elseif (abs($months) > 0) {
            $fWord = $options["accuracy"]["month"];
        } elseif (abs($weeks) > 0) {
            $fWord = $options["accuracy"]["week"];
        } elseif (abs($days) > 0) {
            $fWord = $options["accuracy"]["day"];
        } elseif (abs($hours) > 0) {
            $fWord = $options["accuracy"]["hour"];
        } elseif (abs($minutes) > 0) {
            $fWord = $options["accuracy"]["minute"];
        }

        $fNum = replace(
            ["year", "month", "week", "day", "hour", "minute", "second"],
            ["1", "2", "3", "4", "5", "6", "7"],
            $fWord
        );

        return [
            $fNum,
            $fWord,
            (int)$years,
            (int)$months,
            (int)$weeks,
            (int)$days,
            (int)$hours,
            (int)$minutes,
            (int)$seconds,
        ];
    }

    /**
     * Format a into a relative date string.
     *
     * @param uim.cake.I18n\I18nDateTimeInterface $date The date to format.
     * @param array<string, mixed> $options Array of options.
     * @return string Relative date string.
     * @see uim.cake.I18n\Date::timeAgoInWords()
     */
    string dateAgoInWords(I18nDateTimeInterface $date, STRINGAA someOptions = null) {
        $options = _options($options, FrozenDate::class);
        if ($options["timezone"]) {
            $date = $date.timezone($options["timezone"]);
        }

        $now = $options["from"].format("U");
        $inSeconds = $date.format("U");
        $backwards = ($inSeconds > $now);

        $futureTime = $now;
        $pastTime = $inSeconds;
        if ($backwards) {
            $futureTime = $inSeconds;
            $pastTime = $now;
        }
        $diff = $futureTime - $pastTime;

        if (!$diff) {
            return __d("cake", "today");
        }

        if ($diff > abs($now - (new FrozenDate($options["end"])).format("U"))) {
            return sprintf($options["absoluteString"], $date.i18nFormat($options["format"]));
        }

        $diffData = _diffData($futureTime, $pastTime, $backwards, $options);
        [$fNum, $fWord, $years, $months, $weeks, $days] = array_values($diffData);

        $relativeDate = null;
        if ($fNum >= 1 && $years > 0) {
            $relativeDate[] = __dn("cake", "{0} year", "{0} years", $years, $years);
        }
        if ($fNum >= 2 && $months > 0) {
            $relativeDate[] = __dn("cake", "{0} month", "{0} months", $months, $months);
        }
        if ($fNum >= 3 && $weeks > 0) {
            $relativeDate[] = __dn("cake", "{0} week", "{0} weeks", $weeks, $weeks);
        }
        if ($fNum >= 4 && $days > 0) {
            $relativeDate[] = __dn("cake", "{0} day", "{0} days", $days, $days);
        }
        $relativeDate = implode(", ", $relativeDate);

        // When time has passed
        if (!$backwards) {
            $aboutAgo = [
                "day": __d("cake", "about a day ago"),
                "week": __d("cake", "about a week ago"),
                "month": __d("cake", "about a month ago"),
                "year": __d("cake", "about a year ago"),
            ];

            return $relativeDate ? sprintf($options["relativeString"], $relativeDate) : $aboutAgo[$fWord];
        }

        // When time is to come
        if ($relativeDate) {
            return $relativeDate;
        }
        $aboutIn = [
            "day": __d("cake", "in about a day"),
            "week": __d("cake", "in about a week"),
            "month": __d("cake", "in about a month"),
            "year": __d("cake", "in about a year"),
        ];

        return $aboutIn[$fWord];
    }

    /**
     * Build the options for relative date formatting.
     *
     * @param array<string, mixed> $options The options provided by the user.
     * @param string $class The class name to use for defaults.
     * @return array<string, mixed> Options with defaults applied.
     * @psalm-param class-string<uim.cake.I18n\FrozenDate>|class-string<uim.cake.I18n\FrozenTime> $class
     */
    protected array _options(STRINGAA someOptions, string $class) {
        $options += [
            "from": $class::now(),
            "timezone": null,
            "format": $class::$wordFormat,
            "accuracy": $class::$wordAccuracy,
            "end": $class::$wordEnd,
            "relativeString": __d("cake", "%s ago"),
            "absoluteString": __d("cake", "on %s"),
        ];
        if (is_string($options["accuracy"])) {
            $accuracy = $options["accuracy"];
            $options["accuracy"] = null;
            foreach ($class::$wordAccuracy as $key: $level) {
                $options["accuracy"][$key] = $accuracy;
            }
        } else {
            $options["accuracy"] += $class::$wordAccuracy;
        }

        return $options;
    }
}
