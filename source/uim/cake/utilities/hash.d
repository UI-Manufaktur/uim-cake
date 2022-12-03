

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         2.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.uilities;

use ArrayAccess;
use InvalidArgumentException;
use RuntimeException;

/**
 * Library of array functions for manipulating and extracting data
 * from arrays or 'sets' of data.
 *
 * `Hash` provides an improved interface, more consistent and
 * predictable set of features over `Set`. While it lacks the spotty
 * support for pseudo Xpath, its more fully featured dot notation provides
 * similar features in a more consistent implementation.
 *
 * @link https://book.UIM.org/4/en/core-libraries/hash.html
 */
class Hash
{
    /**
     * Get a single value specified by myPath out of myData.
     * Does not support the full dot notation feature set,
     * but is faster for simple read operations.
     *
     * @param \ArrayAccess|array myData Array of data or object implementing
     *   \ArrayAccess interface to operate on.
     * @param array<string>|string|int|null myPath The path being searched for. Either a dot
     *   separated string, or an array of path segments.
     * @param mixed $default The return value when the path does not exist
     * @throws \InvalidArgumentException
     * @return mixed The value fetched from the array, or null.
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::get
     */
    static auto get(myData, myPath, $default = null) {
        if (!(is_array(myData) || myData instanceof ArrayAccess)) {
            throw new InvalidArgumentException(
                'Invalid data type, must be an array or \ArrayAccess instance.'
            );
        }

        if (empty(myData) || myPath === null) {
            return $default;
        }

        if (is_string(myPath) || is_numeric(myPath)) {
            $parts = explode('.', (string)myPath);
        } else {
            if (!is_array(myPath)) {
                throw new InvalidArgumentException(sprintf(
                    'Invalid Parameter %s, should be dot separated path or array.',
                    myPath
                ));
            }

            $parts = myPath;
        }

        switch (count($parts)) {
            case 1:
                return myData[$parts[0]] ?? $default;
            case 2:
                return myData[$parts[0]][$parts[1]] ?? $default;
            case 3:
                return myData[$parts[0]][$parts[1]][$parts[2]] ?? $default;
            default:
                foreach ($parts as myKey) {
                    if ((is_array(myData) || myData instanceof ArrayAccess) && isset(myData[myKey])) {
                        myData = myData[myKey];
                    } else {
                        return $default;
                    }
                }
        }

        return myData;
    }

    /**
     * Gets the values from an array matching the myPath expression.
     * The path expression is a dot separated expression, that can contain a set
     * of patterns and expressions:
     *
     * - `{n}` Matches any numeric key, or integer.
     * - `{s}` Matches any string key.
     * - `{*}` Matches any value.
     * - `Foo` Matches any key with the exact same value.
     *
     * There are a number of attribute operators:
     *
     *  - `=`, `!=` Equality.
     *  - `>`, `<`, `>=`, `<=` Value comparison.
     *  - `=/.../` Regular expression pattern match.
     *
     * Given a set of User array data, from a `myUsersTable.find('all')` call:
     *
     * - `1.User.name` Get the name of the user at index 1.
     * - `{n}.User.name` Get the name of every user in the set of users.
     * - `{n}.User[id].name` Get the name of every user with an id key.
     * - `{n}.User[id>=2].name` Get the name of every user with an id key greater than or equal to 2.
     * - `{n}.User[username=/^paul/]` Get User elements with username matching `^paul`.
     * - `{n}.User[id=1].name` Get the Users name with id matching `1`.
     *
     * @param \ArrayAccess|array myData The data to extract from.
     * @param string myPath The path to extract.
     * @return \ArrayAccess|array An array of the extracted values. Returns an empty array
     *   if there are no matches.
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::extract
     */
    static function extract(myData, string myPath) {
        if (!(is_array(myData) || myData instanceof ArrayAccess)) {
            throw new InvalidArgumentException(
                'Invalid data type, must be an array or \ArrayAccess instance.'
            );
        }

        if (empty(myPath)) {
            return myData;
        }

        // Simple paths.
        if (!preg_match('/[{\[]/', myPath)) {
            myData = static::get(myData, myPath);
            if (myData !== null && !(is_array(myData) || myData instanceof ArrayAccess)) {
                return [myData];
            }

            return myData !== null ? (array)myData : [];
        }

        if (strpos(myPath, '[') === false) {
            $tokens = explode('.', myPath);
        } else {
            $tokens = Text::tokenize(myPath, '.', '[', ']');
        }

        $_key = '__set_item__';

        $context = [$_key => [myData]];

        foreach ($tokens as $token) {
            $next = [];

            [$token, $conditions] = self::_splitConditions($token);

            foreach ($context[$_key] as $item) {
                if (is_object($item) && method_exists($item, 'toArray')) {
                    /** @var \Cake\Datasource\IEntity $item */
                    $item = $item.toArray();
                }
                foreach ((array)$item as $k => $v) {
                    if (static::_matchToken($k, $token)) {
                        $next[] = $v;
                    }
                }
            }

            // Filter for attributes.
            if ($conditions) {
                $filter = [];
                foreach ($next as $item) {
                    if (
                        (
                            is_array($item) ||
                            $item instanceof ArrayAccess
                        ) &&
                        static::_matches($item, $conditions)
                    ) {
                        $filter[] = $item;
                    }
                }
                $next = $filter;
            }
            $context = [$_key => $next];
        }

        return $context[$_key];
    }

    /**
     * Split token conditions
     *
     * @param string $token the token being splitted.
     * @return array [token, conditions] with token splitted
     */
    protected static auto _splitConditions(string $token): array
    {
        $conditions = false;
        $position = strpos($token, '[');
        if ($position !== false) {
            $conditions = substr($token, $position);
            $token = substr($token, 0, $position);
        }

        return [$token, $conditions];
    }

    /**
     * Check a key against a token.
     *
     * @param mixed myKey The key in the array being searched.
     * @param string $token The token being matched.
     * @return bool
     */
    protected static bool _matchToken(myKey, string $token) {
        switch ($token) {
            case '{n}':
                return is_numeric(myKey);
            case '{s}':
                return is_string(myKey);
            case '{*}':
                return true;
            default:
                return is_numeric($token) ? (myKey == $token) : myKey === $token;
        }
    }

    /**
     * Checks whether myData matches the attribute patterns
     *
     * @param \ArrayAccess|array myData Array of data to match.
     * @param string $selector The patterns to match.
     * @return bool Fitness of expression.
     */
    protected static bool _matches(myData, string $selector) {
        preg_match_all(
            '/(\[ (?P<attr>[^=><!]+?) (\s* (?P<op>[><!]?[=]|[><]) \s* (?P<val>(?:\/.*?\/ | [^\]]+)) )? \])/x',
            $selector,
            $conditions,
            PREG_SET_ORDER
        );

        foreach ($conditions as $cond) {
            $attr = $cond['attr'];
            $op = $cond['op'] ?? null;
            $val = $cond['val'] ?? null;

            // Presence test.
            if (empty($op) && empty($val) && !isset(myData[$attr])) {
                return false;
            }

            if (is_array(myData)) {
                $attrPresent = array_key_exists($attr, myData);
            } else {
                $attrPresent = myData.offsetExists($attr);
            }
            // Empty attribute = fail.
            if (!$attrPresent) {
                return false;
            }

            $prop = myData[$attr] ?? '';
            $isBool = is_bool($prop);
            if ($isBool && is_numeric($val)) {
                $prop = $prop ? '1' : '0';
            } elseif ($isBool) {
                $prop = $prop ? 'true' : 'false';
            } elseif (is_numeric($prop)) {
                $prop = (string)$prop;
            }

            // Pattern matches and other operators.
            if ($op === '=' && $val && $val[0] === '/') {
                if (!preg_match($val, $prop)) {
                    return false;
                }
                // phpcs:disable
            } elseif (
                ($op === '=' && $prop != $val) ||
                ($op === '!=' && $prop == $val) ||
                ($op === '>' && $prop <= $val) ||
                ($op === '<' && $prop >= $val) ||
                ($op === '>=' && $prop < $val) ||
                ($op === '<=' && $prop > $val)
                // phpcs:enable
            ) {
                return false;
            }
        }

        return true;
    }

    /**
     * Insert myValues into an array with the given myPath. You can use
     * `{n}` and `{s}` elements to insert myData multiple times.
     *
     * @param array myData The data to insert into.
     * @param string myPath The path to insert at.
     * @param mixed myValues The values to insert.
     * @return array The data with myValues inserted.
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::insert
     */
    static function insert(array myData, string myPath, myValues = null): array
    {
        $noTokens = strpos(myPath, '[') === false;
        if ($noTokens && strpos(myPath, '.') === false) {
            myData[myPath] = myValues;

            return myData;
        }

        if ($noTokens) {
            $tokens = explode('.', myPath);
        } else {
            $tokens = Text::tokenize(myPath, '.', '[', ']');
        }

        if ($noTokens && strpos(myPath, '{') === false) {
            return static::_simpleOp('insert', myData, $tokens, myValues);
        }

        $token = array_shift($tokens);
        $nextPath = implode('.', $tokens);

        [$token, $conditions] = static::_splitConditions($token);

        foreach (myData as $k => $v) {
            if (static::_matchToken($k, $token)) {
                if (!$conditions || static::_matches($v, $conditions)) {
                    myData[$k] = $nextPath
                        ? static::insert($v, $nextPath, myValues)
                        : array_merge($v, (array)myValues);
                }
            }
        }

        return myData;
    }

    /**
     * Perform a simple insert/remove operation.
     *
     * @param string $op The operation to do.
     * @param array myData The data to operate on.
     * @param array<string> myPath The path to work on.
     * @param mixed myValues The values to insert when doing inserts.
     * @return array data.
     */
    protected static auto _simpleOp(string $op, array myData, array myPath, myValues = null): array
    {
        $_list = &myData;

        myCount = count(myPath);
        $last = myCount - 1;
        foreach (myPath as $i => myKey) {
            if ($op === 'insert') {
                if ($i === $last) {
                    $_list[myKey] = myValues;

                    return myData;
                }
                $_list[myKey] = $_list[myKey] ?? [];
                $_list = &$_list[myKey];
                if (!is_array($_list)) {
                    $_list = [];
                }
            } elseif ($op === 'remove') {
                if ($i === $last) {
                    if (is_array($_list)) {
                        unset($_list[myKey]);
                    }

                    return myData;
                }
                if (!isset($_list[myKey])) {
                    return myData;
                }
                $_list = &$_list[myKey];
            }
        }

        return myData;
    }

    /**
     * Remove data matching myPath from the myData array.
     * You can use `{n}` and `{s}` to remove multiple elements
     * from myData.
     *
     * @param array myData The data to operate on
     * @param string myPath A path expression to use to remove.
     * @return array The modified array.
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::remove
     */
    static function remove(array myData, string myPath): array
    {
        $noTokens = strpos(myPath, '[') === false;
        $noExpansion = strpos(myPath, '{') === false;

        if ($noExpansion && $noTokens && strpos(myPath, '.') === false) {
            unset(myData[myPath]);

            return myData;
        }

        $tokens = $noTokens ? explode('.', myPath) : Text::tokenize(myPath, '.', '[', ']');

        if ($noExpansion && $noTokens) {
            return static::_simpleOp('remove', myData, $tokens);
        }

        $token = array_shift($tokens);
        $nextPath = implode('.', $tokens);

        [$token, $conditions] = self::_splitConditions($token);

        foreach (myData as $k => $v) {
            $match = static::_matchToken($k, $token);
            if ($match && is_array($v)) {
                if ($conditions) {
                    if (static::_matches($v, $conditions)) {
                        if ($nextPath !== '') {
                            myData[$k] = static::remove($v, $nextPath);
                        } else {
                            unset(myData[$k]);
                        }
                    }
                } else {
                    myData[$k] = static::remove($v, $nextPath);
                }
                if (empty(myData[$k])) {
                    unset(myData[$k]);
                }
            } elseif ($match && $nextPath == "") {
                unset(myData[$k]);
            }
        }

        return myData;
    }

    /**
     * Creates an associative array using `myKeyPath` as the path to build its keys, and optionally
     * `myValuePath` as path to get the values. If `myValuePath` is not specified, all values will be initialized
     * to null (useful for Hash::merge). You can optionally group the values by what is obtained when
     * following the path specified in `myGroupPath`.
     *
     * @param array myData Array from where to extract keys and values
     * @param array<string>|string|null myKeyPath A dot-separated string.
     * @param array<string>|string|null myValuePath A dot-separated string.
     * @param string|null myGroupPath A dot-separated string.
     * @return array Combined array
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::combine
     * @throws \RuntimeException When keys and values count is unequal.
     */
    static function combine(array myData, myKeyPath, myValuePath = null, Nullable!string myGroupPath = null): array
    {
        if (empty(myData)) {
            return [];
        }

        if (is_array(myKeyPath)) {
            $format = array_shift(myKeyPath);
            /** @var array myKeys */
            myKeys = static::format(myData, myKeyPath, $format);
        } elseif (myKeyPath === null) {
            myKeys = myKeyPath;
        } else {
            /** @var array myKeys */
            myKeys = static::extract(myData, myKeyPath);
        }
        if (myKeyPath !== null && empty(myKeys)) {
            return [];
        }

        $vals = null;
        if (!empty(myValuePath) && is_array(myValuePath)) {
            $format = array_shift(myValuePath);
            /** @var array $vals */
            $vals = static::format(myData, myValuePath, $format);
        } elseif (!empty(myValuePath)) {
            /** @var array $vals */
            $vals = static::extract(myData, myValuePath);
        }
        if (empty($vals)) {
            $vals = array_fill(0, myKeys === null ? count(myData) : count(myKeys), null);
        }

        if (is_array(myKeys) && count(myKeys) !== count($vals)) {
            throw new RuntimeException(
                'Hash::combine() needs an equal number of keys + values.'
            );
        }

        if (myGroupPath !== null) {
            myGroup = static::extract(myData, myGroupPath);
            if (!empty(myGroup)) {
                $c = is_array(myKeys) ? count(myKeys) : count($vals);
                $out = [];
                for ($i = 0; $i < $c; $i++) {
                    myGroup[$i] = myGroup[$i] ?? 0;
                    $out[myGroup[$i]] = $out[myGroup[$i]] ?? [];
                    if (myKeys === null) {
                        $out[myGroup[$i]][] = $vals[$i];
                    } else {
                        $out[myGroup[$i]][myKeys[$i]] = $vals[$i];
                    }
                }

                return $out;
            }
        }
        if (empty($vals)) {
            return [];
        }

        return array_combine(myKeys ?? range(0, count($vals) - 1), $vals);
    }

    /**
     * Returns a formatted series of values extracted from `myData`, using
     * `$format` as the format and `myPaths` as the values to extract.
     *
     * Usage:
     *
     * ```
     * myResult = Hash::format(myUsers, ['{n}.User.id', '{n}.User.name'], '%s : %s');
     * ```
     *
     * The `$format` string can use any format options that `vsprintf()` and `sprintf()` do.
     *
     * @param array myData Source array from which to extract the data
     * @param array<string> myPaths An array containing one or more Hash::extract()-style key paths
     * @param string $format Format string into which values will be inserted, see sprintf()
     * @return array<string>|null An array of strings extracted from `myPath` and formatted with `$format`
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::format
     * @see sprintf()
     * @see \Cake\Utility\Hash::extract()
     */
    static function format(array myData, array myPaths, string $format): ?array
    {
        $extracted = [];
        myCount = count(myPaths);

        if (!myCount) {
            return null;
        }

        for ($i = 0; $i < myCount; $i++) {
            $extracted[] = static::extract(myData, myPaths[$i]);
        }
        $out = [];
        /** @var array<mixed, array> myData */
        myData = $extracted;
        myCount = count(myData[0]);

        myCountTwo = count(myData);
        for ($j = 0; $j < myCount; $j++) {
            $args = [];
            for ($i = 0; $i < myCountTwo; $i++) {
                if (array_key_exists($j, myData[$i])) {
                    $args[] = myData[$i][$j];
                }
            }
            $out[] = vsprintf($format, $args);
        }

        return $out;
    }

    /**
     * Determines if one array contains the exact keys and values of another.
     *
     * @param array myData The data to search through.
     * @param array $needle The values to file in myData
     * @return bool true If myData contains $needle, false otherwise
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::contains
     */
    static bool contains(array myData, array $needle) {
        if (empty(myData) || empty($needle)) {
            return false;
        }
        $stack = [];

        while (!empty($needle)) {
            myKey = key($needle);
            $val = $needle[myKey];
            unset($needle[myKey]);

            if (array_key_exists(myKey, myData) && is_array($val)) {
                $next = myData[myKey];
                unset(myData[myKey]);

                if (!empty($val)) {
                    $stack[] = [$val, $next];
                }
            } elseif (!array_key_exists(myKey, myData) || myData[myKey] != $val) {
                return false;
            }

            if (empty($needle) && !empty($stack)) {
                [$needle, myData] = array_pop($stack);
            }
        }

        return true;
    }

    /**
     * Test whether a given path exists in myData.
     * This method uses the same path syntax as Hash::extract()
     *
     * Checking for paths that could target more than one element will
     * make sure that at least one matching element exists.
     *
     * @param array myData The data to check.
     * @param string myPath The path to check for.
     * @return bool Existence of path.
     * @see \Cake\Utility\Hash::extract()
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::check
     */
    static bool check(array myData, string myPath) {
        myResults = static::extract(myData, myPath);
        if (!is_array(myResults)) {
            return false;
        }

        return count(myResults) > 0;
    }

    /**
     * Recursively filters a data set.
     *
     * @param array myData Either an array to filter, or value when in callback
     * @param callable|array $callback A function to filter the data with. Defaults to
     *   `static::_filter()` Which strips out all non-zero empty values.
     * @return array Filtered array
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::filter
     */
    static function filter(array myData, $callback = [Hash::class, '_filter']): array
    {
        foreach (myData as $k => $v) {
            if (is_array($v)) {
                myData[$k] = static::filter($v, $callback);
            }
        }

        return array_filter(myData, $callback);
    }

    /**
     * Callback function for filtering.
     *
     * @param mixed $var Array to filter.
     * @return bool
     */
    protected static bool _filter($var) {
        return $var === 0 || $var === 0.0 || $var === '0' || !empty($var);
    }

    /**
     * Collapses a multi-dimensional array into a single dimension, using a delimited array path for
     * each array element's key, i.e. [['Foo' => ['Bar' => 'Far']]] becomes
     * ['0.Foo.Bar' => 'Far'].)
     *
     * @param array myData Array to flatten
     * @param string $separator String used to separate array key elements in a path, defaults to '.'
     * @return array
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::flatten
     */
    static function flatten(array myData, string $separator = '.'): array
    {
        myResult = [];
        $stack = [];
        myPath = '';

        reset(myData);
        while (!empty(myData)) {
            myKey = key(myData);
            $element = myData[myKey];
            unset(myData[myKey]);

            if (is_array($element) && !empty($element)) {
                if (!empty(myData)) {
                    $stack[] = [myData, myPath];
                }
                myData = $element;
                reset(myData);
                myPath .= myKey . $separator;
            } else {
                myResult[myPath . myKey] = $element;
            }

            if (empty(myData) && !empty($stack)) {
                [myData, myPath] = array_pop($stack);
                reset(myData);
            }
        }

        return myResult;
    }

    /**
     * Expands a flat array to a nested array.
     *
     * For example, unflattens an array that was collapsed with `Hash::flatten()`
     * into a multi-dimensional array. So, `['0.Foo.Bar' => 'Far']` becomes
     * `[['Foo' => ['Bar' => 'Far']]]`.
     *
     * @phpstan-param non-empty-string $separator
     * @param array myData Flattened array
     * @param string $separator The delimiter used
     * @return array
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::expand
     */
    static function expand(array myData, string $separator = '.'): array
    {
        myResult = [];
        foreach (myData as $flat => myValue) {
            myKeys = explode($separator, (string)$flat);
            myKeys = array_reverse(myKeys);
            $child = [
                myKeys[0] => myValue,
            ];
            array_shift(myKeys);
            foreach (myKeys as $k) {
                $child = [
                    $k => $child,
                ];
            }

            $stack = [[$child, &myResult]];
            static::_merge($stack, myResult);
        }

        return myResult;
    }

    /**
     * This function can be thought of as a hybrid between PHP's `array_merge` and `array_merge_recursive`.
     *
     * The difference between this method and the built-in ones, is that if an array key contains another array, then
     * Hash::merge() will behave in a recursive fashion (unlike `array_merge`). But it will not act recursively for
     * keys that contain scalar values (unlike `array_merge_recursive`).
     *
     * This function will work with an unlimited amount of arguments and typecasts non-array parameters into arrays.
     *
     * @param array myData Array to be merged
     * @param mixed myMerge Array to merge with. The argument and all trailing arguments will be array cast when merged
     * @return array Merged array
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::merge
     */
    static function merge(array myData, myMerge): array
    {
        $args = array_slice(func_get_args(), 1);
        $return = myData;
        $stack = [];

        foreach ($args as &$curArg) {
            $stack[] = [(array)$curArg, &$return];
        }
        unset($curArg);
        static::_merge($stack, $return);

        return $return;
    }

    /**
     * Merge helper function to reduce duplicated code between merge() and expand().
     *
     * @param array $stack The stack of operations to work with.
     * @param array $return The return value to operate on.
     * @return void
     */
    protected static auto _merge(array $stack, array &$return): void
    {
        while (!empty($stack)) {
            foreach ($stack as $curKey => &$curMerge) {
                foreach ($curMerge[0] as myKey => &$val) {
                    if (!is_array($curMerge[1])) {
                        continue;
                    }

                    if (
                        !empty($curMerge[1][myKey])
                        && (array)$curMerge[1][myKey] === $curMerge[1][myKey]
                        && (array)$val === $val
                    ) {
                        // Recurse into the current merge data as it is an array.
                        $stack[] = [&$val, &$curMerge[1][myKey]];
                    } elseif ((int)myKey === myKey && isset($curMerge[1][myKey])) {
                        $curMerge[1][] = $val;
                    } else {
                        $curMerge[1][myKey] = $val;
                    }
                }
                unset($stack[$curKey]);
            }
            unset($curMerge);
        }
    }

    /**
     * Checks to see if all the values in the array are numeric
     *
     * @param array myData The array to check.
     * @return bool true if values are numeric, false otherwise
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::numeric
     */
    static bool numeric(array myData) {
        if (empty(myData)) {
            return false;
        }

        return myData === array_filter(myData, 'is_numeric');
    }

    /**
     * Counts the dimensions of an array.
     * Only considers the dimension of the first element in the array.
     *
     * If you have an un-even or heterogeneous array, consider using Hash::maxDimensions()
     * to get the dimensions of the array.
     *
     * @param array myData Array to count dimensions on
     * @return int The number of dimensions in myData
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::dimensions
     */
    static int dimensions(array myData) {
        if (empty(myData)) {
            return 0;
        }
        reset(myData);
        $depth = 1;
        while ($elem = array_shift(myData)) {
            if (is_array($elem)) {
                $depth++;
                myData = $elem;
            } else {
                break;
            }
        }

        return $depth;
    }

    /**
     * Counts the dimensions of *all* array elements. Useful for finding the maximum
     * number of dimensions in a mixed array.
     *
     * @param array myData Array to count dimensions on
     * @return int The maximum number of dimensions in myData
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::maxDimensions
     */
    static int maxDimensions(array myData) {
        $depth = [];
        if (!empty(myData)) {
            foreach (myData as myValue) {
                if (is_array(myValue)) {
                    $depth[] = static::maxDimensions(myValue) + 1;
                } else {
                    $depth[] = 1;
                }
            }
        }

        return empty($depth) ? 0 : max($depth);
    }

    /**
     * Map a callback across all elements in a set.
     * Can be provided a path to only modify slices of the set.
     *
     * @param array myData The data to map over, and extract data out of.
     * @param string myPath The path to extract for mapping over.
     * @param callable $function The function to call on each extracted value.
     * @return array An array of the modified values.
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::map
     */
    static function map(array myData, string myPath, callable $function): array
    {
        myValues = (array)static::extract(myData, myPath);

        return array_map($function, myValues);
    }

    /**
     * Reduce a set of extracted values using `$function`.
     *
     * @param array myData The data to reduce.
     * @param string myPath The path to extract from myData.
     * @param callable $function The function to call on each extracted value.
     * @return mixed The reduced value.
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::reduce
     */
    static function reduce(array myData, string myPath, callable $function) {
        myValues = (array)static::extract(myData, myPath);

        return array_reduce(myValues, $function);
    }

    /**
     * Apply a callback to a set of extracted values using `$function`.
     * The function will get the extracted values as the first argument.
     *
     * ### Example
     *
     * You can easily count the results of an extract using apply().
     * For example to count the comments on an Article:
     *
     * ```
     * myCount = Hash::apply(myData, 'Article.Comment.{n}', 'count');
     * ```
     *
     * You could also use a function like `array_sum` to sum the results.
     *
     * ```
     * $total = Hash::apply(myData, '{n}.Item.price', 'array_sum');
     * ```
     *
     * @param array myData The data to reduce.
     * @param string myPath The path to extract from myData.
     * @param callable $function The function to call on each extracted value.
     * @return mixed The results of the applied method.
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::apply
     */
    static function apply(array myData, string myPath, callable $function) {
        myValues = (array)static::extract(myData, myPath);

        return $function(myValues);
    }

    /**
     * Sorts an array by any value, determined by a Set-compatible path
     *
     * ### Sort directions
     *
     * - `asc` or \SORT_ASC Sort ascending.
     * - `desc` or \SORT_DESC Sort descending.
     *
     * ### Sort types
     *
     * - `regular` For regular sorting (don't change types)
     * - `numeric` Compare values numerically
     * - `string` Compare values as strings
     * - `locale` Compare items as strings, based on the current locale
     * - `natural` Compare items as strings using "natural ordering" in a human friendly way
     *   Will sort foo10 below foo2 as an example.
     *
     * To do case insensitive sorting, pass the type as an array as follows:
     *
     * ```
     * Hash::sort(myData, 'some.attribute', 'asc', ['type' => 'regular', 'ignoreCase' => true]);
     * ```
     *
     * When using the array form, `type` defaults to 'regular'. The `ignoreCase` option
     * defaults to `false`.
     *
     * @param array myData An array of data to sort
     * @param string myPath A Set-compatible path to the array value
     * @param string|int $dir See directions above. Defaults to 'asc'.
     * @param array<string, mixed>|string myType See direction types above. Defaults to 'regular'.
     * @return array Sorted array of data
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::sort
     */
    static function sort(array myData, string myPath, $dir = 'asc', myType = 'regular'): array
    {
        if (empty(myData)) {
            return [];
        }
        $originalKeys = array_keys(myData);
        $numeric = is_numeric(implode('', $originalKeys));
        if ($numeric) {
            myData = array_values(myData);
        }
        /** @var array $sortValues */
        $sortValues = static::extract(myData, myPath);
        myDataCount = count(myData);

        // Make sortValues match the data length, as some keys could be missing
        // the sorted value path.
        $missingData = count($sortValues) < myDataCount;
        if ($missingData && $numeric) {
            // Get the path without the leading '{n}.'
            $itemPath = substr(myPath, 4);
            foreach (myData as myKey => myValue) {
                $sortValues[myKey] = static::get(myValue, $itemPath);
            }
        } elseif ($missingData) {
            $sortValues = array_pad($sortValues, myDataCount, null);
        }
        myResult = static::_squash($sortValues);
        /** @var array myKeys */
        myKeys = static::extract(myResult, '{n}.id');
        /** @var array myValues */
        myValues = static::extract(myResult, '{n}.value');

        if (is_string($dir)) {
            $dir = strtolower($dir);
        }
        if (!in_array($dir, [\SORT_ASC, \SORT_DESC], true)) {
            $dir = $dir === 'asc' ? \SORT_ASC : \SORT_DESC;
        }

        $ignoreCase = false;

        // myType can be overloaded for case insensitive sort
        if (is_array(myType)) {
            myType += ['ignoreCase' => false, 'type' => 'regular'];
            $ignoreCase = myType['ignoreCase'];
            myType = myType['type'];
        }
        myType = strtolower(myType);

        if (myType === 'numeric') {
            myType = \SORT_NUMERIC;
        } elseif (myType === 'string') {
            myType = \SORT_STRING;
        } elseif (myType === 'natural') {
            myType = \SORT_NATURAL;
        } elseif (myType === 'locale') {
            myType = \SORT_LOCALE_STRING;
        } else {
            myType = \SORT_REGULAR;
        }
        if ($ignoreCase) {
            myValues = array_map('mb_strtolower', myValues);
        }
        array_multisort(myValues, $dir, myType, myKeys, $dir, myType);
        $sorted = [];
        myKeys = array_unique(myKeys);

        foreach (myKeys as $k) {
            if ($numeric) {
                $sorted[] = myData[$k];
                continue;
            }
            if (isset($originalKeys[$k])) {
                $sorted[$originalKeys[$k]] = myData[$originalKeys[$k]];
            } else {
                $sorted[$k] = myData[$k];
            }
        }

        return $sorted;
    }

    /**
     * Helper method for sort()
     * Squashes an array to a single hash so it can be sorted.
     *
     * @param array myData The data to squash.
     * @param mixed myKey The key for the data.
     * @return array
     */
    protected static auto _squash(array myData, myKey = null): array
    {
        $stack = [];
        foreach (myData as $k => $r) {
            $id = $k;
            if (myKey !== null) {
                $id = myKey;
            }
            if (is_array($r) && !empty($r)) {
                $stack = array_merge($stack, static::_squash($r, $id));
            } else {
                $stack[] = ['id' => $id, 'value' => $r];
            }
        }

        return $stack;
    }

    /**
     * Computes the difference between two complex arrays.
     * This method differs from the built-in array_diff() in that it will preserve keys
     * and work on multi-dimensional arrays.
     *
     * @param array myData First value
     * @param array $compare Second value
     * @return array Returns the key => value pairs that are not common in myData and $compare
     *    The expression for this function is (myData - $compare) + ($compare - (myData - $compare))
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::diff
     */
    static function diff(array myData, array $compare): array
    {
        if (empty(myData)) {
            return $compare;
        }
        if (empty($compare)) {
            return myData;
        }
        $intersection = array_intersect_key(myData, $compare);
        while ((myKey = key($intersection)) !== null) {
            if (myData[myKey] == $compare[myKey]) {
                unset(myData[myKey], $compare[myKey]);
            }
            next($intersection);
        }

        return myData + $compare;
    }

    /**
     * Merges the difference between myData and $compare onto myData.
     *
     * @param array myData The data to append onto.
     * @param array $compare The data to compare and append onto.
     * @return array The merged array.
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::mergeDiff
     */
    static function mergeDiff(array myData, array $compare): array
    {
        if (empty(myData) && !empty($compare)) {
            return $compare;
        }
        if (empty($compare)) {
            return myData;
        }
        foreach ($compare as myKey => myValue) {
            if (!array_key_exists(myKey, myData)) {
                myData[myKey] = myValue;
            } elseif (is_array(myValue) && is_array(myData[myKey])) {
                myData[myKey] = static::mergeDiff(myData[myKey], myValue);
            }
        }

        return myData;
    }

    /**
     * Normalizes an array, and converts it to a standard format.
     *
     * @param array myData List to normalize
     * @param bool $assoc If true, myData will be converted to an associative array.
     * @return array
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::normalize
     */
    static function normalize(array myData, bool $assoc = true): array
    {
        myKeys = array_keys(myData);
        myCount = count(myKeys);
        $numeric = true;

        if (!$assoc) {
            for ($i = 0; $i < myCount; $i++) {
                if (!is_int(myKeys[$i])) {
                    $numeric = false;
                    break;
                }
            }
        }
        if (!$numeric || $assoc) {
            $newList = [];
            for ($i = 0; $i < myCount; $i++) {
                if (is_int(myKeys[$i])) {
                    $newList[myData[myKeys[$i]]] = null;
                } else {
                    $newList[myKeys[$i]] = myData[myKeys[$i]];
                }
            }
            myData = $newList;
        }

        return myData;
    }

    /**
     * Takes in a flat array and returns a nested array
     *
     * ### Options:
     *
     * - `children` The key name to use in the resultset for children.
     * - `idPath` The path to a key that identifies each entry. Should be
     *   compatible with Hash::extract(). Defaults to `{n}.myAlias.id`
     * - `parentPath` The path to a key that identifies the parent of each entry.
     *   Should be compatible with Hash::extract(). Defaults to `{n}.myAlias.parent_id`
     * - `root` The id of the desired top-most result.
     *
     * @param array myData The data to nest.
     * @param array<string, mixed> myOptions Options are:
     * @return array<array> of results, nested
     * @see \Cake\Utility\Hash::extract()
     * @throws \InvalidArgumentException When providing invalid data.
     * @link https://book.UIM.org/4/en/core-libraries/hash.html#Cake\Utility\Hash::nest
     */
    static function nest(array myData, array myOptions = []): array
    {
        if (!myData) {
            return myData;
        }

        myAlias = key(current(myData));
        myOptions += [
            'idPath' => "{n}.myAlias.id",
            'parentPath' => "{n}.myAlias.parent_id",
            'children' => 'children',
            'root' => null,
        ];

        $return = $idMap = [];
        /** @var array $ids */
        $ids = static::extract(myData, myOptions['idPath']);

        $idKeys = explode('.', myOptions['idPath']);
        array_shift($idKeys);

        $parentKeys = explode('.', myOptions['parentPath']);
        array_shift($parentKeys);

        foreach (myData as myResult) {
            myResult[myOptions['children']] = [];

            $id = static::get(myResult, $idKeys);
            $parentId = static::get(myResult, $parentKeys);

            if (isset($idMap[$id][myOptions['children']])) {
                $idMap[$id] = array_merge(myResult, $idMap[$id]);
            } else {
                $idMap[$id] = array_merge(myResult, [myOptions['children'] => []]);
            }
            if (!$parentId || !in_array($parentId, $ids)) {
                $return[] = &$idMap[$id];
            } else {
                $idMap[$parentId][myOptions['children']][] = &$idMap[$id];
            }
        }

        if (!$return) {
            throw new InvalidArgumentException('Invalid data array to nest.');
        }

        if (myOptions['root']) {
            $root = myOptions['root'];
        } else {
            $root = static::get($return[0], $parentKeys);
        }

        foreach ($return as $i => myResult) {
            $id = static::get(myResult, $idKeys);
            $parentId = static::get(myResult, $parentKeys);
            if ($id !== $root && $parentId != $root) {
                unset($return[$i]);
            }
        }

        return array_values($return);
    }
}
