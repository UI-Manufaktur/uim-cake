module uim.cakeility;

import uim.cake.core.exceptions\CakeException;
use InvalidArgumentException;
use Transliterator;

/**
 * Text handling methods.
 */
class Text
{
    /**
     * Default transliterator.
     *
     * @var \Transliterator|null Transliterator instance.
     */
    protected static $_defaultTransliterator;

    /**
     * Default transliterator id string.
     *
     * @var string $_defaultTransliteratorId Transliterator identifier string.
     */
    protected static $_defaultTransliteratorId = "Any-Latin; Latin-ASCII; [\u0080-\u7fff] remove";

    /**
     * Default HTML tags which must not be counted for truncating text.
     *
     * @var array<string>
     */
    protected static $_defaultHtmlNoCount = [
        "style",
        "script",
    ];

    /**
     * Generate a random UUID version 4
     *
     * Warning: This method should not be used as a random seed for any cryptographic operations.
     * Instead, you should use the openssl or mcrypt extensions.
     *
     * It should also not be used to create identifiers that have security implications, such as
     * "unguessable" URL identifiers. Instead, you should use {@link \Cake\Utility\Security::randomBytes()}` for that.
     *
     * @see https://www.ietf.org/rfc/rfc4122.txt
     * @return string RFC 4122 UUID
     * @copyright Matt Farina MIT License https://github.com/lootils/uuid/blob/master/LICENSE
     */
    static string uuid() {
        return sprintf(
            "%04x%04x-%04x-%04x-%04x-%04x%04x%04x",
            // 32 bits for "time_low"
            random_int(0, 65535),
            random_int(0, 65535),
            // 16 bits for "time_mid"
            random_int(0, 65535),
            // 12 bits before the 0100 of (version) 4 for "time_hi_and_version"
            random_int(0, 4095) | 0x4000,
            // 16 bits, 8 bits for "clk_seq_hi_res",
            // 8 bits for "clk_seq_low",
            // two most significant bits holds zero and one for variant DCE1.1
            random_int(0, 0x3fff) | 0x8000,
            // 48 bits for "node"
            random_int(0, 65535),
            random_int(0, 65535),
            random_int(0, 65535)
        );
    }

    /**
     * Tokenizes a string using $separator, ignoring any instance of $separator that appears between
     * $leftBound and $rightBound.
     *
     * @param string myData The data to tokenize.
     * @param string $separator The token to split the data on.
     * @param string $leftBound The left boundary to ignore separators in.
     * @param string $rightBound The right boundary to ignore separators in.
     * @return array<string> Array of tokens in myData.
     */
    static function tokenize(
        string myData,
        string $separator = ",",
        string $leftBound = "(",
        string $rightBound = ")"
    ): array {
        if (empty(myData)) {
            return [];
        }

        $depth = 0;
        $offset = 0;
        $buffer = "";
        myResults = [];
        $length = mb_strlen(myData);
        $open = false;

        while ($offset <= $length) {
            $tmpOffset = -1;
            $offsets = [
                mb_strpos(myData, $separator, $offset),
                mb_strpos(myData, $leftBound, $offset),
                mb_strpos(myData, $rightBound, $offset),
            ];
            for ($i = 0; $i < 3; $i++) {
                if ($offsets[$i] !== false && ($offsets[$i] < $tmpOffset || $tmpOffset === -1)) {
                    $tmpOffset = $offsets[$i];
                }
            }
            if ($tmpOffset !== -1) {
                $buffer .= mb_substr(myData, $offset, $tmpOffset - $offset);
                $char = mb_substr(myData, $tmpOffset, 1);
                if (!$depth && $char === $separator) {
                    myResults[] = $buffer;
                    $buffer = "";
                } else {
                    $buffer .= $char;
                }
                if ($leftBound !== $rightBound) {
                    if ($char === $leftBound) {
                        $depth++;
                    }
                    if ($char === $rightBound) {
                        $depth--;
                    }
                } else {
                    if ($char === $leftBound) {
                        if (!$open) {
                            $depth++;
                            $open = true;
                        } else {
                            $depth--;
                            $open = false;
                        }
                    }
                }
                $tmpOffset += 1;
                $offset = $tmpOffset;
            } else {
                myResults[] = $buffer . mb_substr(myData, $offset);
                $offset = $length + 1;
            }
        }
        if (empty(myResults) && !empty($buffer)) {
            myResults[] = $buffer;
        }

        if (!empty(myResults)) {
            return array_map("trim", myResults);
        }

        return [];
    }

    /**
     * Replaces variable placeholders inside a $str with any given myData. Each key in the myData array
     * corresponds to a variable placeholder name in $str.
     * Example:
     * ```
     * Text::insert(":name is :age years old.", ["name" => "Bob", "age" => "65"]);
     * ```
     * Returns: Bob is 65 years old.
     *
     * Available myOptions are:
     *
     * - before: The character or string in front of the name of the variable placeholder (Defaults to `:`)
     * - after: The character or string after the name of the variable placeholder (Defaults to null)
     * - escape: The character or string used to escape the before character / string (Defaults to `\`)
     * - format: A regex to use for matching variable placeholders. Default is: `/(?<!\\)\:%s/`
     *   (Overwrites before, after, breaks escape / clean)
     * - clean: A boolean or array with instructions for Text::cleanInsert
     *
     * @param string $str A string containing variable placeholders
     * @param array myData A key => val array where each key stands for a placeholder variable name
     *     to be replaced with val
     * @param array<string, mixed> myOptions An array of options, see description above
     * @return string
     */
    static string insert(string $str, array myData, array myOptions = []) {
        $defaults = [
            "before" => ":", "after" => "", "escape" => "\\", "format" => null, "clean" => false,
        ];
        myOptions += $defaults;
        if (empty(myData)) {
            return myOptions["clean"] ? static::cleanInsert($str, myOptions) : $str;
        }

        if (strpos($str, "?") !== false && is_numeric(key(myData))) {
            deprecationWarning(
                "Using Text::insert() with `?` placeholders is deprecated. " .
                "Use sprintf() with `%s` placeholders instead."
            );

            $offset = 0;
            while (($pos = strpos($str, "?", $offset)) !== false) {
                $val = array_shift(myData);
                $offset = $pos + strlen($val);
                $str = substr_replace($str, $val, $pos, 1);
            }

            return myOptions["clean"] ? static::cleanInsert($str, myOptions) : $str;
        }

        $format = myOptions["format"];
        if ($format === null) {
            $format = sprintf(
                "/(?<!%s)%s%%s%s/",
                preg_quote(myOptions["escape"], "/"),
                str_replace("%", "%%", preg_quote(myOptions["before"], "/")),
                str_replace("%", "%%", preg_quote(myOptions["after"], "/"))
            );
        }

        myDataKeys = array_keys(myData);
        $hashKeys = array_map("md5", myDataKeys);
        /** @var array<string, string> $tempData */
        $tempData = array_combine(myDataKeys, $hashKeys);
        krsort($tempData);

        foreach ($tempData as myKey => $hashVal) {
            myKey = sprintf($format, preg_quote(myKey, "/"));
            $str = preg_replace(myKey, $hashVal, $str);
        }
        /** @var array<string, mixed> myDataReplacements */
        myDataReplacements = array_combine($hashKeys, array_values(myData));
        foreach (myDataReplacements as $tmpHash => $tmpValue) {
            $tmpValue = is_array($tmpValue) ? "" : (string)$tmpValue;
            $str = str_replace($tmpHash, $tmpValue, $str);
        }

        if (!isset(myOptions["format"]) && isset(myOptions["before"])) {
            $str = str_replace(myOptions["escape"] . myOptions["before"], myOptions["before"], $str);
        }

        return myOptions["clean"] ? static::cleanInsert($str, myOptions) : $str;
    }

    /**
     * Cleans up a Text::insert() formatted string with given myOptions depending on the "clean" key in
     * myOptions. The default method used is text but html is also available. The goal of this function
     * is to replace all whitespace and unneeded markup around placeholders that did not get replaced
     * by Text::insert().
     *
     * @param string $str String to clean.
     * @param array<string, mixed> myOptions Options list.
     * @return string
     * @see \Cake\Utility\Text::insert()
     */
    static string cleanInsert(string $str, array myOptions) {
        $clean = myOptions["clean"];
        if (!$clean) {
            return $str;
        }
        if ($clean === true) {
            $clean = ["method" => "text"];
        }
        if (!is_array($clean)) {
            $clean = ["method" => myOptions["clean"]];
        }
        switch ($clean["method"]) {
            case "html":
                $clean += [
                    "word" => "[\w,.]+",
                    "andText" => true,
                    "replacement" => "",
                ];
                $kleenex = sprintf(
                    "/[\s]*[a-z]+=(")(%s%s%s[\s]*)+\\1/i",
                    preg_quote(myOptions["before"], "/"),
                    $clean["word"],
                    preg_quote(myOptions["after"], "/")
                );
                $str = preg_replace($kleenex, $clean["replacement"], $str);
                if ($clean["andText"]) {
                    myOptions["clean"] = ["method" => "text"];
                    $str = static::cleanInsert($str, myOptions);
                }
                break;
            case "text":
                $clean += [
                    "word" => "[\w,.]+",
                    "gap" => "[\s]*(?:(?:and|or)[\s]*)?",
                    "replacement" => "",
                ];

                $kleenex = sprintf(
                    "/(%s%s%s%s|%s%s%s%s)/",
                    preg_quote(myOptions["before"], "/"),
                    $clean["word"],
                    preg_quote(myOptions["after"], "/"),
                    $clean["gap"],
                    $clean["gap"],
                    preg_quote(myOptions["before"], "/"),
                    $clean["word"],
                    preg_quote(myOptions["after"], "/")
                );
                $str = preg_replace($kleenex, $clean["replacement"], $str);
                break;
        }

        return $str;
    }

    /**
     * Wraps text to a specific width, can optionally wrap at word breaks.
     *
     * ### Options
     *
     * - `width` The width to wrap to. Defaults to 72.
     * - `wordWrap` Only wrap on words breaks (spaces) Defaults to true.
     * - `indent` String to indent with. Defaults to null.
     * - `indentAt` 0 based index to start indenting at. Defaults to 0.
     *
     * @param string $text The text to format.
     * @param array<string, mixed>|int myOptions Array of options to use, or an integer to wrap the text to.
     * @return string Formatted text.
     */
    static string wrap(string $text, myOptions = []) {
        if (is_numeric(myOptions)) {
            myOptions = ["width" => myOptions];
        }
        myOptions += ["width" => 72, "wordWrap" => true, "indent" => null, "indentAt" => 0];
        if (myOptions["wordWrap"]) {
            $wrapped = self::wordWrap($text, myOptions["width"], "\n");
        } else {
            $wrapped = trim(chunk_split($text, myOptions["width"] - 1, "\n"));
        }
        if (!empty(myOptions["indent"])) {
            $chunks = explode("\n", $wrapped);
            for ($i = myOptions["indentAt"], $len = count($chunks); $i < $len; $i++) {
                $chunks[$i] = myOptions["indent"] . $chunks[$i];
            }
            $wrapped = implode("\n", $chunks);
        }

        return $wrapped;
    }

    /**
     * Wraps a complete block of text to a specific width, can optionally wrap
     * at word breaks.
     *
     * ### Options
     *
     * - `width` The width to wrap to. Defaults to 72.
     * - `wordWrap` Only wrap on words breaks (spaces) Defaults to true.
     * - `indent` String to indent with. Defaults to null.
     * - `indentAt` 0 based index to start indenting at. Defaults to 0.
     *
     * @param string $text The text to format.
     * @param array<string, mixed>|int myOptions Array of options to use, or an integer to wrap the text to.
     * @return string Formatted text.
     */
    static string wrapBlock(string $text, myOptions = []) {
        if (is_numeric(myOptions)) {
            myOptions = ["width" => myOptions];
        }
        myOptions += ["width" => 72, "wordWrap" => true, "indent" => null, "indentAt" => 0];

        if (!empty(myOptions["indentAt"]) && myOptions["indentAt"] === 0) {
            $indentLength = !empty(myOptions["indent"]) ? strlen(myOptions["indent"]) : 0;
            myOptions["width"] -= $indentLength;

            return self::wrap($text, myOptions);
        }

        $wrapped = self::wrap($text, myOptions);

        if (!empty(myOptions["indent"])) {
            $indentationLength = mb_strlen(myOptions["indent"]);
            $chunks = explode("\n", $wrapped);
            myCount = count($chunks);
            if (myCount < 2) {
                return $wrapped;
            }
            $toRewrap = "";
            for ($i = myOptions["indentAt"]; $i < myCount; $i++) {
                $toRewrap .= mb_substr($chunks[$i], $indentationLength) . " ";
                unset($chunks[$i]);
            }
            myOptions["width"] -= $indentationLength;
            myOptions["indentAt"] = 0;
            $rewrapped = self::wrap($toRewrap, myOptions);
            $newChunks = explode("\n", $rewrapped);

            $chunks = array_merge($chunks, $newChunks);
            $wrapped = implode("\n", $chunks);
        }

        return $wrapped;
    }

    /**
     * Unicode and newline aware version of wordwrap.
     *
     * @phpstan-param non-empty-string $break
     * @param string $text The text to format.
     * @param int $width The width to wrap to. Defaults to 72.
     * @param string $break The line is broken using the optional break parameter. Defaults to "\n".
     * @param bool $cut If the cut is set to true, the string is always wrapped at the specified width.
     * @return string Formatted text.
     */
    static string wordWrap(string $text, int $width = 72, string $break = "\n", bool $cut = false) {
        $paragraphs = explode($break, $text);
        foreach ($paragraphs as &$paragraph) {
            $paragraph = static::_wordWrap($paragraph, $width, $break, $cut);
        }

        return implode($break, $paragraphs);
    }

    /**
     * Unicode aware version of wordwrap as helper method.
     *
     * @param string $text The text to format.
     * @param int $width The width to wrap to. Defaults to 72.
     * @param string $break The line is broken using the optional break parameter. Defaults to "\n".
     * @param bool $cut If the cut is set to true, the string is always wrapped at the specified width.
     * @return string Formatted text.
     */
    protected static string _wordWrap(string $text, int $width = 72, string $break = "\n", bool $cut = false) {
        $parts = [];
        if ($cut) {
            while (mb_strlen($text) > 0) {
                $part = mb_substr($text, 0, $width);
                $parts[] = trim($part);
                $text = trim(mb_substr($text, mb_strlen($part)));
            }

            return implode($break, $parts);
        }

        while (mb_strlen($text) > 0) {
            if ($width >= mb_strlen($text)) {
                $parts[] = trim($text);
                break;
            }

            $part = mb_substr($text, 0, $width);
            $nextChar = mb_substr($text, $width, 1);
            if ($nextChar !== " ") {
                $breakAt = mb_strrpos($part, " ");
                if ($breakAt === false) {
                    $breakAt = mb_strpos($text, " ", $width);
                }
                if ($breakAt === false) {
                    $parts[] = trim($text);
                    break;
                }
                $part = mb_substr($text, 0, $breakAt);
            }

            $part = trim($part);
            $parts[] = $part;
            $text = trim(mb_substr($text, mb_strlen($part)));
        }

        return implode($break, $parts);
    }

    /**
     * Highlights a given phrase in a text. You can specify any expression in highlighter that
     * may include the \1 expression to include the $phrase found.
     *
     * ### Options:
     *
     * - `format` The piece of HTML with that the phrase will be highlighted
     * - `html` If true, will ignore any HTML tags, ensuring that only the correct text is highlighted
     * - `regex` A custom regex rule that is used to match words, default is "|$tag|iu"
     * - `limit` A limit, optional, defaults to -1 (none)
     *
     * @param string $text Text to search the phrase in.
     * @param array<string>|string $phrase The phrase or phrases that will be searched.
     * @param array<string, mixed> myOptions An array of HTML attributes and options.
     * @return string The highlighted text
     * @link https://book.cakephp.org/4/en/core-libraries/text.html#highlighting-substrings
     */
    static string highlight(string $text, $phrase, array myOptions = []) {
        if (empty($phrase)) {
            return $text;
        }

        $defaults = [
            "format" => "<span class="highlight">\1</span>",
            "html" => false,
            "regex" => "|%s|iu",
            "limit" => -1,
        ];
        myOptions += $defaults;

        if (is_array($phrase)) {
            $replace = [];
            $with = [];

            foreach ($phrase as myKey => $segment) {
                $segment = "(" . preg_quote($segment, "|") . ")";
                if (myOptions["html"]) {
                    $segment = "(?![^<]+>)$segment(?![^<]+>)";
                }

                $with[] = is_array(myOptions["format"]) ? myOptions["format"][myKey] : myOptions["format"];
                $replace[] = sprintf(myOptions["regex"], $segment);
            }

            return preg_replace($replace, $with, $text, myOptions["limit"]);
        }

        $phrase = "(" . preg_quote($phrase, "|") . ")";
        if (myOptions["html"]) {
            $phrase = "(?![^<]+>)$phrase(?![^<]+>)";
        }

        return preg_replace(
            sprintf(myOptions["regex"], $phrase),
            myOptions["format"],
            $text,
            myOptions["limit"]
        );
    }

    /**
     * Truncates text starting from the end.
     *
     * Cuts a string to the length of $length and replaces the first characters
     * with the ellipsis if the text is longer than length.
     *
     * ### Options:
     *
     * - `ellipsis` Will be used as beginning and prepended to the trimmed string
     * - `exact` If false, $text will not be cut mid-word
     *
     * @param string $text String to truncate.
     * @param int $length Length of returned string, including ellipsis.
     * @param array<string, mixed> myOptions An array of options.
     * @return string Trimmed string.
     */
    static string tail(string $text, int $length = 100, array myOptions = []) {
        $default = [
            "ellipsis" => "...", "exact" => true,
        ];
        myOptions += $default;
        $ellipsis = myOptions["ellipsis"];

        if (mb_strlen($text) <= $length) {
            return $text;
        }

        $truncate = mb_substr($text, mb_strlen($text) - $length + mb_strlen($ellipsis));
        if (!myOptions["exact"]) {
            $spacepos = mb_strpos($truncate, " ");
            $truncate = $spacepos === false ? "" : trim(mb_substr($truncate, $spacepos));
        }

        return $ellipsis . $truncate;
    }

    /**
     * Truncates text.
     *
     * Cuts a string to the length of $length and replaces the last characters
     * with the ellipsis if the text is longer than length.
     *
     * ### Options:
     *
     * - `ellipsis` Will be used as ending and appended to the trimmed string
     * - `exact` If false, $text will not be cut mid-word
     * - `html` If true, HTML tags would be handled correctly
     * - `trimWidth` If true, $text will be truncated with the width
     *
     * @param string $text String to truncate.
     * @param int $length Length of returned string, including ellipsis.
     * @param array<string, mixed> myOptions An array of HTML attributes and options.
     * @return string Trimmed string.
     * @link https://book.cakephp.org/4/en/core-libraries/text.html#truncating-text
     */
    static function truncate(string $text, int $length = 100, array myOptions = []): string
    {
        $default = [
            "ellipsis": "...", 
            "exact": "true", "html" => false, "trimWidth" => false,
        ];
        if (!empty(myOptions["html"]) && strtolower((string)mb_internal_encoding()) === "utf-8") {
            $default["ellipsis"] = "\xe2\x80\xa6";
        }
        myOptions += $default;

        $prefix = "";
        $suffix = myOptions["ellipsis"];

        if (myOptions["html"]) {
            $ellipsisLength = self::_strlen(strip_tags(myOptions["ellipsis"]), myOptions);

            $truncateLength = 0;
            $totalLength = 0;
            $openTags = [];
            $truncate = "";

            preg_match_all("/(<\/?([\w+]+)[^>]*>)?([^<>]*)/", $text, $tags, PREG_SET_ORDER);
            foreach ($tags as $tag) {
                myContentsLength = 0;
                if (!in_array($tag[2], static::$_defaultHtmlNoCount, true)) {
                    myContentsLength = self::_strlen($tag[3], myOptions);
                }

                if ($truncate == "") {
                    if (
                        !preg_match(
                            "/img|br|input|hr|area|base|basefont|col|frame|isindex|link|meta|param/i",
                            $tag[2]
                        )
                    ) {
                        if (preg_match("/<[\w]+[^>]*>/", $tag[0])) {
                            array_unshift($openTags, $tag[2]);
                        } elseif (preg_match("/<\/([\w]+)[^>]*>/", $tag[0], $closeTag)) {
                            $pos = array_search($closeTag[1], $openTags, true);
                            if ($pos !== false) {
                                array_splice($openTags, $pos, 1);
                            }
                        }
                    }

                    $prefix .= $tag[1];

                    if ($totalLength + myContentsLength + $ellipsisLength > $length) {
                        $truncate = $tag[3];
                        $truncateLength = $length - $totalLength;
                    } else {
                        $prefix .= $tag[3];
                    }
                }

                $totalLength += myContentsLength;
                if ($totalLength > $length) {
                    break;
                }
            }

            if ($totalLength <= $length) {
                return $text;
            }

            $text = $truncate;
            $length = $truncateLength;

            foreach ($openTags as $tag) {
                $suffix .= "</" . $tag . ">";
            }
        } else {
            if (self::_strlen($text, myOptions) <= $length) {
                return $text;
            }
            $ellipsisLength = self::_strlen(myOptions["ellipsis"], myOptions);
        }

        myResult = self::_substr($text, 0, $length - $ellipsisLength, myOptions);

        if (!myOptions["exact"]) {
            if (self::_substr($text, $length - $ellipsisLength, 1, myOptions) !== " ") {
                myResult = self::_removeLastWord(myResult);
            }

            // If result is empty, then we don"t need to count ellipsis in the cut.
            if (myResult == "") {
                myResult = self::_substr($text, 0, $length, myOptions);
            }
        }

        return $prefix . myResult . $suffix;
    }

    /**
     * Truncate text with specified width.
     *
     * @param string $text String to truncate.
     * @param int $length Length of returned string, including ellipsis.
     * @param array<string, mixed> myOptions An array of HTML attributes and options.
     * @return string Trimmed string.
     * @see \Cake\Utility\Text::truncate()
     */
    static function truncateByWidth(string $text, int $length = 100, array myOptions = []): string
    {
        return static::truncate($text, $length, ["trimWidth" => true] + myOptions);
    }

    /**
     * Get string length.
     *
     * ### Options:
     *
     * - `html` If true, HTML entities will be handled as decoded characters.
     * - `trimWidth` If true, the width will return.
     *
     * @param string $text The string being checked for length
     * @param array<string, mixed> myOptions An array of options.
     * @return int
     */
    protected static auto _strlen(string $text, array myOptions): int
    {
        if (empty(myOptions["trimWidth"])) {
            $strlen = "mb_strlen";
        } else {
            $strlen = "mb_strwidth";
        }

        if (empty(myOptions["html"])) {
            return $strlen($text);
        }

        $pattern = "/&[0-9a-z]{2,8};|&#[0-9]{1,7};|&#x[0-9a-f]{1,6};/i";
        $replace = preg_replace_callback(
            $pattern,
            function ($match) use ($strlen) {
                $utf8 = html_entity_decode($match[0], ENT_HTML5 | ENT_QUOTES, "UTF-8");

                return str_repeat(" ", $strlen($utf8, "UTF-8"));
            },
            $text
        );

        return $strlen($replace);
    }

    /**
     * Return part of a string.
     *
     * ### Options:
     *
     * - `html` If true, HTML entities will be handled as decoded characters.
     * - `trimWidth` If true, will be truncated with specified width.
     *
     * @param string $text The input string.
     * @param int $start The position to begin extracting.
     * @param int|null $length The desired length.
     * @param array<string, mixed> myOptions An array of options.
     * @return string
     */
    protected static auto _substr(string $text, int $start, Nullable!int $length, array myOptions): string
    {
        if (empty(myOptions["trimWidth"])) {
            $substr = "mb_substr";
        } else {
            $substr = "mb_strimwidth";
        }

        $maxPosition = self::_strlen($text, ["trimWidth" => false] + myOptions);
        if ($start < 0) {
            $start += $maxPosition;
            if ($start < 0) {
                $start = 0;
            }
        }
        if ($start >= $maxPosition) {
            return "";
        }

        if ($length === null) {
            $length = self::_strlen($text, myOptions);
        }

        if ($length < 0) {
            $text = self::_substr($text, $start, null, myOptions);
            $start = 0;
            $length += self::_strlen($text, myOptions);
        }

        if ($length <= 0) {
            return "";
        }

        if (empty(myOptions["html"])) {
            return (string)$substr($text, $start, $length);
        }

        $totalOffset = 0;
        $totalLength = 0;
        myResult = "";

        $pattern = "/(&[0-9a-z]{2,8};|&#[0-9]{1,7};|&#x[0-9a-f]{1,6};)/i";
        $parts = preg_split($pattern, $text, -1, PREG_SPLIT_DELIM_CAPTURE | PREG_SPLIT_NO_EMPTY);
        foreach ($parts as $part) {
            $offset = 0;

            if ($totalOffset < $start) {
                $len = self::_strlen($part, ["trimWidth" => false] + myOptions);
                if ($totalOffset + $len <= $start) {
                    $totalOffset += $len;
                    continue;
                }

                $offset = $start - $totalOffset;
                $totalOffset = $start;
            }

            $len = self::_strlen($part, myOptions);
            if ($offset !== 0 || $totalLength + $len > $length) {
                if (
                    strpos($part, "&") === 0
                    && preg_match($pattern, $part)
                    && $part !== html_entity_decode($part, ENT_HTML5 | ENT_QUOTES, "UTF-8")
                ) {
                    // Entities cannot be passed substr.
                    continue;
                }

                $part = $substr($part, $offset, $length - $totalLength);
                $len = self::_strlen($part, myOptions);
            }

            myResult .= $part;
            $totalLength += $len;
            if ($totalLength >= $length) {
                break;
            }
        }

        return myResult;
    }

    /**
     * Removes the last word from the input text.
     *
     * @param string $text The input text
     * @return string
     */
    protected static auto _removeLastWord(string $text): string
    {
        $spacepos = mb_strrpos($text, " ");

        if ($spacepos !== false) {
            $lastWord = mb_substr($text, $spacepos);

            // Some languages are written without word separation.
            // We recognize a string as a word if it doesn"t contain any full-width characters.
            if (mb_strwidth($lastWord) === mb_strlen($lastWord)) {
                $text = mb_substr($text, 0, $spacepos);
            }

            return $text;
        }

        return "";
    }

    /**
     * Extracts an excerpt from the text surrounding the phrase with a number of characters on each side
     * determined by radius.
     *
     * @param string $text String to search the phrase in
     * @param string $phrase Phrase that will be searched for
     * @param int $radius The amount of characters that will be returned on each side of the founded phrase
     * @param string $ellipsis Ending that will be appended
     * @return string Modified string
     * @link https://book.cakephp.org/4/en/core-libraries/text.html#extracting-an-excerpt
     */
    static function excerpt(string $text, string $phrase, int $radius = 100, string $ellipsis = "..."): string
    {
        if (empty($text) || empty($phrase)) {
            return static::truncate($text, $radius * 2, ["ellipsis" => $ellipsis]);
        }

        $append = $prepend = $ellipsis;

        $phraseLen = mb_strlen($phrase);
        $textLen = mb_strlen($text);

        $pos = mb_stripos($text, $phrase);
        if ($pos === false) {
            return mb_substr($text, 0, $radius) . $ellipsis;
        }

        $startPos = $pos - $radius;
        if ($startPos <= 0) {
            $startPos = 0;
            $prepend = "";
        }

        $endPos = $pos + $phraseLen + $radius;
        if ($endPos >= $textLen) {
            $endPos = $textLen;
            $append = "";
        }

        $excerpt = mb_substr($text, $startPos, $endPos - $startPos);
        $excerpt = $prepend . $excerpt . $append;

        return $excerpt;
    }

    /**
     * Creates a comma separated list where the last two items are joined with "and", forming natural language.
     *
     * @param array<string> $list The list to be joined.
     * @param string|null $and The word used to join the last and second last items together with. Defaults to "and".
     * @param string $separator The separator used to join all the other items together. Defaults to ", ".
     * @return string The glued together string.
     * @link https://book.cakephp.org/4/en/core-libraries/text.html#converting-an-array-to-sentence-form
     */
    static function toList(array $list, Nullable!string $and = null, string $separator = ", "): string
    {
        if ($and === null) {
            $and = __d("cake", "and");
        }
        if (count($list) > 1) {
            return implode($separator, array_slice($list, 0, -1)) . " " . $and . " " . array_pop($list);
        }

        return (string)array_pop($list);
    }

    /**
     * Check if the string contain multibyte characters
     *
     * @param string $string value to test
     * @return bool
     */
    static bool isMultibyte(string $string) {
        $length = strlen($string);

        for ($i = 0; $i < $length; $i++) {
            myValue = ord($string[$i]);
            if (myValue > 128) {
                return true;
            }
        }

        return false;
    }

    /**
     * Converts a multibyte character string
     * to the decimal value of the character
     *
     * @param string $string String to convert.
     * @return array
     */
    static function utf8(string $string): array
    {
        $map = [];

        myValues = [];
        $find = 1;
        $length = strlen($string);

        for ($i = 0; $i < $length; $i++) {
            myValue = ord($string[$i]);

            if (myValue < 128) {
                $map[] = myValue;
            } else {
                if (empty(myValues)) {
                    $find = myValue < 224 ? 2 : 3;
                }
                myValues[] = myValue;

                if (count(myValues) === $find) {
                    if ($find === 3) {
                        $map[] = ((myValues[0] % 16) * 4096) + ((myValues[1] % 64) * 64) + (myValues[2] % 64);
                    } else {
                        $map[] = ((myValues[0] % 32) * 64) + (myValues[1] % 64);
                    }
                    myValues = [];
                    $find = 1;
                }
            }
        }

        return $map;
    }

    /**
     * Converts the decimal value of a multibyte character string
     * to a string
     *
     * @param array $array Array
     * @return string
     */
    static function ascii(array $array): string
    {
        $ascii = "";

        foreach ($array as $utf8) {
            if ($utf8 < 128) {
                $ascii .= chr($utf8);
            } elseif ($utf8 < 2048) {
                $ascii .= chr(192 + (($utf8 - ($utf8 % 64)) / 64));
                $ascii .= chr(128 + ($utf8 % 64));
            } else {
                $ascii .= chr(224 + (($utf8 - ($utf8 % 4096)) / 4096));
                $ascii .= chr(128 + ((($utf8 % 4096) - ($utf8 % 64)) / 64));
                $ascii .= chr(128 + ($utf8 % 64));
            }
        }

        return $ascii;
    }

    /**
     * Converts filesize from human readable string to bytes
     *
     * @param string $size Size in human readable string like "5MB", "5M", "500B", "50kb" etc.
     * @param mixed $default Value to be returned when invalid size was used, for example "Unknown type"
     * @return mixed Number of bytes as integer on success, `$default` on failure if not false
     * @throws \InvalidArgumentException On invalid Unit type.
     * @link https://book.cakephp.org/4/en/core-libraries/text.html#Cake\Utility\Text::parseFileSize
     */
    static function parseFileSize(string $size, $default = false) {
        if (ctype_digit($size)) {
            return (int)$size;
        }
        $size = strtoupper($size);

        $l = -2;
        $i = array_search(substr($size, -2), ["KB", "MB", "GB", "TB", "PB"], true);
        if ($i === false) {
            $l = -1;
            $i = array_search(substr($size, -1), ["K", "M", "G", "T", "P"], true);
        }
        if ($i !== false) {
            $size = (float)substr($size, 0, $l);

            return (int)($size * pow(1024, $i + 1));
        }

        if (substr($size, -1) === "B" && ctype_digit(substr($size, 0, -1))) {
            $size = substr($size, 0, -1);

            return (int)$size;
        }

        if ($default !== false) {
            return $default;
        }
        throw new InvalidArgumentException("No unit type.");
    }

    /**
     * Get the default transliterator.
     *
     * @return \Transliterator|null Either a Transliterator instance, or `null`
     *   in case no transliterator has been set yet.
     */
    static auto getTransliterator(): ?Transliterator
    {
        return static::$_defaultTransliterator;
    }

    /**
     * Set the default transliterator.
     *
     * @param \Transliterator $transliterator A `Transliterator` instance.
     * @return void
     */
    static auto setTransliterator(Transliterator $transliterator): void
    {
        static::$_defaultTransliterator = $transliterator;
    }

    /**
     * Get default transliterator identifier string.
     *
     * @return string Transliterator identifier.
     */
    static auto getTransliteratorId(): string
    {
        return static::$_defaultTransliteratorId;
    }

    /**
     * Set default transliterator identifier string.
     *
     * @param string $transliteratorId Transliterator identifier.
     * @return void
     */
    static auto setTransliteratorId(string $transliteratorId): void
    {
        $transliterator = transliterator_create($transliteratorId);
        if ($transliterator === null) {
            throw new CakeException("Unable to create transliterator for id: " . $transliteratorId);
        }

        static::setTransliterator($transliterator);
        static::$_defaultTransliteratorId = $transliteratorId;
    }

    /**
     * Transliterate string.
     *
     * @param string $string String to transliterate.
     * @param \Transliterator|string|null $transliterator Either a Transliterator
     *   instance, or a transliterator identifier string. If `null`, the default
     *   transliterator (identifier) set via `setTransliteratorId()` or
     *   `setTransliterator()` will be used.
     * @return string
     * @see https://secure.php.net/manual/en/transliterator.transliterate.php
     */
    static function transliterate(string $string, $transliterator = null): string
    {
        if (empty($transliterator)) {
            $transliterator = static::$_defaultTransliterator ?: static::$_defaultTransliteratorId;
        }

        $return = transliterator_transliterate($transliterator, $string);
        if ($return === false) {
            throw new CakeException(sprintf("Unable to transliterate string: %s", $string));
        }

        return $return;
    }

    /**
     * Returns a string with all spaces converted to dashes (by default),
     * characters transliterated to ASCII characters, and non word characters removed.
     *
     * ### Options:
     *
     * - `replacement`: Replacement string. Default "-".
     * - `transliteratorId`: A valid transliterator id string.
     *   If `null` (default) the transliterator (identifier) set via
     *   `setTransliteratorId()` or `setTransliterator()` will be used.
     *   If `false` no transliteration will be done, only non words will be removed.
     * - `preserve`: Specific non-word character to preserve. Default `null`.
     *   For e.g. this option can be set to "." to generate clean file names.
     *
     * @param string $string the string you want to slug
     * @param array<string, mixed>|string myOptions If string it will be use as replacement character
     *   or an array of options.
     * @return string
     * @see setTransliterator()
     * @see setTransliteratorId()
     */
    static function slug(string $string, myOptions = []): string
    {
        if (is_string(myOptions)) {
            myOptions = ["replacement" => myOptions];
        }
        myOptions += [
            "replacement" => "-",
            "transliteratorId" => null,
            "preserve" => null,
        ];

        if (myOptions["transliteratorId"] !== false) {
            $string = static::transliterate($string, myOptions["transliteratorId"]);
        }

        $regex = "^\p{Ll}\p{Lm}\p{Lo}\p{Lt}\p{Lu}\p{Nd}";
        if (myOptions["preserve"]) {
            $regex .= preg_quote(myOptions["preserve"], "/");
        }
        $quotedReplacement = preg_quote((string)myOptions["replacement"], "/");
        $map = [
            "/[" . $regex . "]/mu" => myOptions["replacement"],
            sprintf("/^[%s]+|[%s]+$/", $quotedReplacement, $quotedReplacement) => "",
        ];
        if (is_string(myOptions["replacement"]) && myOptions["replacement"] !== "") {
            $map[sprintf("/[%s]+/mu", $quotedReplacement)] = myOptions["replacement"];
        }
        $string = preg_replace(array_keys($map), $map, $string);

        return $string;
    }
}
