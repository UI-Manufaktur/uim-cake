module uim.cake.uilities;

/**
 * Pluralize and singularize English words.
 *
 * Inflector pluralizes and singularizes English nouns.
 * Used by UIM"s naming conventions throughout the framework.
 *
 * @link https://book.UIM.org/4/en/core-libraries/inflector.html
 */
class Inflector
{
    /**
     * Plural inflector rules
     *
     * @var array<string, string>
     */
    protected static _plural = [
        "/(s)tatus$/i": "\1tatuses",
        "/(quiz)$/i": "\1zes",
        "/^(ox)$/i": "\1\2en",
        "/([m|l])ouse$/i": "\1ice",
        "/(matr|vert)(ix|ex)$/i": "\1ices",
        "/(x|ch|ss|sh)$/i": "\1es",
        "/([^aeiouy]|qu)y$/i": "\1ies",
        "/(hive)$/i": "\1s",
        "/(chef)$/i": "\1s",
        "/(?:([^f])fe|([lre])f)$/i": "\1\2ves",
        "/sis$/i": "ses",
        "/([ti])um$/i": "\1a",
        "/(p)erson$/i": "\1eople",
        "/(?<!u)(m)an$/i": "\1en",
        "/(c)hild$/i": "\1hildren",
        "/(buffal|tomat)o$/i": "\1\2oes",
        "/(alumn|bacill|cact|foc|fung|nucle|radi|stimul|syllab|termin)us$/i": "\1i",
        "/us$/i": "uses",
        "/(alias)$/i": "\1es",
        "/(ax|cris|test)is$/i": "\1es",
        "/s$/": "s",
        "/^$/": "",
        "/$/": "s",
    ];

    /**
     * Singular inflector rules
     *
     * @var array<string, string>
     */
    protected static _singular = [
        "/(s)tatuses$/i": "\1\2tatus",
        "/^(.*)(menu)s$/i": "\1\2",
        "/(quiz)zes$/i": "\\1",
        "/(matr)ices$/i": "\1ix",
        "/(vert|ind)ices$/i": "\1ex",
        "/^(ox)en/i": "\1",
        "/(alias|lens)(es)*$/i": "\1",
        "/(alumn|bacill|cact|foc|fung|nucle|radi|stimul|syllab|termin|viri?)i$/i": "\1us",
        "/([ftw]ax)es/i": "\1",
        "/(cris|ax|test)es$/i": "\1is",
        "/(shoe)s$/i": "\1",
        "/(o)es$/i": "\1",
        "/ouses$/": "ouse",
        "/([^a])uses$/": "\1us",
        "/([m|l])ice$/i": "\1ouse",
        "/(x|ch|ss|sh)es$/i": "\1",
        "/(m)ovies$/i": "\1\2ovie",
        "/(s)eries$/i": "\1\2eries",
        "/(s)pecies$/i": "\1\2pecies",
        "/([^aeiouy]|qu)ies$/i": "\1y",
        "/(tive)s$/i": "\1",
        "/(hive)s$/i": "\1",
        "/(drive)s$/i": "\1",
        "/([le])ves$/i": "\1f",
        "/([^rfoa])ves$/i": "\1fe",
        "/(^analy)ses$/i": "\1sis",
        "/(analy|diagno|^ba|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$/i": "\1\2sis",
        "/([ti])a$/i": "\1um",
        "/(p)eople$/i": "\1\2erson",
        "/(m)en$/i": "\1an",
        "/(c)hildren$/i": "\1\2hild",
        "/(n)ews$/i": "\1\2ews",
        "/eaus$/": "eau",
        "/^(.*us)$/": "\\1",
        "/s$/i": "",
    ];

    /**
     * Irregular rules
     *
     * @var array<string, string>
     */
    protected static _irregular = [
        "atlas": "atlases",
        "beef": "beefs",
        "brief": "briefs",
        "brother": "brothers",
        "cafe": "cafes",
        "child": "children",
        "cookie": "cookies",
        "corpus": "corpuses",
        "cow": "cows",
        "criterion": "criteria",
        "ganglion": "ganglions",
        "genie": "genies",
        "genus": "genera",
        "graffito": "graffiti",
        "hoof": "hoofs",
        "loaf": "loaves",
        "man": "men",
        "money": "monies",
        "mongoose": "mongooses",
        "move": "moves",
        "mythos": "mythoi",
        "niche": "niches",
        "numen": "numina",
        "occiput": "occiputs",
        "octopus": "octopuses",
        "opus": "opuses",
        "ox": "oxen",
        "penis": "penises",
        "person": "people",
        "sex": "sexes",
        "soliloquy": "soliloquies",
        "testis": "testes",
        "trilby": "trilbys",
        "turf": "turfs",
        "potato": "potatoes",
        "hero": "heroes",
        "tooth": "teeth",
        "goose": "geese",
        "foot": "feet",
        "foe": "foes",
        "sieve": "sieves",
        "cache": "caches",
    ];

    /**
     * Words that should not be inflected
     *
     * @var array<string>
     */
    protected static _uninflected = [
        ".*[nrlm]ese", ".*data", ".*deer", ".*fish", ".*measles", ".*ois",
        ".*pox", ".*sheep", "people", "feedback", "stadia", ".*?media",
        "chassis", "clippers", "debris", "diabetes", "equipment", "gallows",
        "graffiti", "headquarters", "information", "innings", "news", "nexus",
        "pokemon", "proceedings", "research", "sea[- ]bass", "series", "species", "weather",
    ];

    /**
     * Method cache array.
     *
     * @var array
     */
    protected static _cache = null;

    /**
     * The initial state of Inflector so reset() works.
     *
     * @var array
     */
    protected static _initialState = null;

    /**
     * Cache inflected values, and return if already available
     *
     * @param string myType Inflection type
     * @param string myKey Original value
     * @param string|false myValue Inflected value
     * @return string|false Inflected value on cache hit or false on cache miss.
     */
    protected static auto _cache(string myType, string myKey, myValue = false) {
        myKey = "_" ~ myKey;
        myType = "_" ~ myType;
        if (myValue != false) {
            static::_cache[myType][myKey] = myValue;

            return myValue;
        }
        if (!isset(static::_cache[myType][myKey])) {
            return false;
        }

        return static::_cache[myType][myKey];
    }

    /**
     * Clears Inflectors inflected value caches. And resets the inflection
     * rules to the initial values.
     */
    static void reset() {
        if (empty(static::_initialState)) {
            static::_initialState = get_class_vars(self::class);

            return;
        }
        foreach (static::_initialState as myKey: $val) {
            if (myKey != "_initialState") {
                static::${myKey} = $val;
            }
        }
    }

    /**
     * Adds custom inflection $rules, of either "plural", "singular",
     * "uninflected" or "irregular" myType.
     *
     * ### Usage:
     *
     * ```
     * Inflector::rules("plural", ["/^(inflect)or$/i": "\1ables"]);
     * Inflector::rules("irregular", ["red": "redlings"]);
     * Inflector::rules("uninflected", ["dontinflectme"]);
     * ```
     *
     * @param string myType The type of inflection, either "plural", "singular",
     *    or "uninflected".
     * @param array $rules Array of rules to be added.
     * @param bool $reset If true, will unset default inflections for all
     *        new rules that are being defined in $rules.
     */
    static void rules(string myType, array $rules, bool $reset = false) {
        $var = "_" ~ myType;

        if ($reset) {
            static::${$var} = $rules;
        } elseif (myType == "uninflected") {
            static::_uninflected = array_merge(
                $rules,
                static::_uninflected
            );
        } else {
            static::${$var} = $rules + static::${$var};
        }

        static::_cache = null;
    }

    /**
     * Return $word in plural form.
     *
     * @param string word Word in singular
     * @return string Word in plural
     * @link https://book.UIM.org/4/en/core-libraries/inflector.html#creating-plural-singular-forms
     */
    static string pluralize(string word) {
        if (isset(static::_cache["pluralize"][$word])) {
            return static::_cache["pluralize"][$word];
        }

        if (!isset(static::_cache["irregular"]["pluralize"])) {
            $words = array_keys(static::_irregular);
            static::_cache["irregular"]["pluralize"] = "/(.*?(?:\\b|_))(" ~ implode("|", $words) ~ ")$/i";

            $upperWords = array_map("ucfirst", $words);
            static::_cache["irregular"]["upperPluralize"] = "/(.*?(?:\\b|[a-z]))(" ~ implode("|", $upperWords) ~ ")$/";
        }

        if (
            preg_match(static::_cache["irregular"]["pluralize"], $word, $regs) ||
            preg_match(static::_cache["irregular"]["upperPluralize"], $word, $regs)
        ) {
            static::_cache["pluralize"][$word] = $regs[1] . substr($regs[2], 0, 1) .
                substr(static::_irregular[strtolower($regs[2])], 1);

            return static::_cache["pluralize"][$word];
        }

        if (!isset(static::_cache["uninflected"])) {
            static::_cache["uninflected"] = "/^(" ~ implode("|", static::_uninflected) ~ ")$/i";
        }

        if (preg_match(static::_cache["uninflected"], $word, $regs)) {
            static::_cache["pluralize"][$word] = $word;

            return $word;
        }

        foreach (static::_plural as $rule: $replacement) {
            if (preg_match($rule, $word)) {
                static::_cache["pluralize"][$word] = preg_replace($rule, $replacement, $word);

                return static::_cache["pluralize"][$word];
            }
        }

        return $word;
    }

    /**
     * Return $word in singular form.
     *
     * @param string word Word in plural
     * @return string Word in singular
     * @link https://book.UIM.org/4/en/core-libraries/inflector.html#creating-plural-singular-forms
     */
    static string singularize(string word) {
        if (isset(static::_cache["singularize"][$word])) {
            return static::_cache["singularize"][$word];
        }

        if (!isset(static::_cache["irregular"]["singular"])) {
            $wordList = array_values(static::_irregular);
            static::_cache["irregular"]["singular"] = "/(.*?(?:\\b|_))(" ~ implode("|", $wordList) ~ ")$/i";

            $upperWordList = array_map("ucfirst", $wordList);
            static::_cache["irregular"]["singularUpper"] = "/(.*?(?:\\b|[a-z]))(" ~
                implode("|", $upperWordList) .
                ")$/";
        }

        if (
            preg_match(static::_cache["irregular"]["singular"], $word, $regs) ||
            preg_match(static::_cache["irregular"]["singularUpper"], $word, $regs)
        ) {
            $suffix = array_search(strtolower($regs[2]), static::_irregular, true);
            $suffix = $suffix ? substr($suffix, 1) : "";
            static::_cache["singularize"][$word] = $regs[1] . substr($regs[2], 0, 1) . $suffix;

            return static::_cache["singularize"][$word];
        }

        if (!isset(static::_cache["uninflected"])) {
            static::_cache["uninflected"] = "/^(" ~ implode("|", static::_uninflected) ~ ")$/i";
        }

        if (preg_match(static::_cache["uninflected"], $word, $regs)) {
            static::_cache["pluralize"][$word] = $word;

            return $word;
        }

        foreach (static::_singular as $rule: $replacement) {
            if (preg_match($rule, $word)) {
                static::_cache["singularize"][$word] = preg_replace($rule, $replacement, $word);

                return static::_cache["singularize"][$word];
            }
        }
        static::_cache["singularize"][$word] = $word;

        return $word;
    }

    /**
     * Returns the input lower_case_delimited_string as a CamelCasedString.
     *
     * @param string string String to camelize
     * @param string delimiter the delimiter in the input string
     * @return string CamelizedStringLikeThis.
     * @link https://book.UIM.org/4/en/core-libraries/inflector.html#creating-camelcase-and-under-scored-forms
     */
    static string camelize(string string, string delimiter = "_") {
        $cacheKey = __FUNCTION__ . $delimiter;

        myResult = static::_cache($cacheKey, $string);

        if (myResult == false) {
            myResult = replace(" ", "", static::humanize($string, $delimiter));
            static::_cache($cacheKey, $string, myResult);
        }

        return myResult;
    }

    /**
     * Returns the input CamelCasedString as an underscored_string.
     *
     * Also replaces dashes with underscores
     *
     * @param string string CamelCasedString to be "underscorized"
     * @return string underscore_version of the input string
     * @link https://book.UIM.org/4/en/core-libraries/inflector.html#creating-camelcase-and-under-scored-forms
     */
    static string underscore(string string) {
        return static::delimit(replace("-", "_", $string), "_");
    }

    /**
     * Returns the input CamelCasedString as an dashed-string.
     *
     * Also replaces underscores with dashes
     *
     * @param string string The string to dasherize.
     * @return string Dashed version of the input string
     */
    static string dasherize(string string) {
        return static::delimit(replace("_", "-", $string), "-");
    }

    /**
     * Returns the input lower_case_delimited_string as "A Human Readable String".
     * (Underscores are replaced by spaces and capitalized following words.)
     *
     * @param string string String to be humanized
     * @param string delimiter the character to replace with a space
     * @return string Human-readable string
     * @link https://book.UIM.org/4/en/core-libraries/inflector.html#creating-human-readable-forms
     */
    static string humanize(string string, string delimiter = "_") {
        $cacheKey = __FUNCTION__ . $delimiter;

        myResult = static::_cache($cacheKey, $string);

        if (myResult == false) {
            myResult = explode(" ", replace($delimiter, " ", $string));
            foreach (myResult as &$word) {
                $word = mb_strtoupper(mb_substr($word, 0, 1)) . mb_substr($word, 1);
            }
            myResult = implode(" ", myResult);
            static::_cache($cacheKey, $string, myResult);
        }

        return myResult;
    }

    /**
     * Expects a CamelCasedInputString, and produces a lower_case_delimited_string
     *
     * @param string string String to delimit
     * @param string delimiter the character to use as a delimiter
     * @return string delimited string
     */
    static string delimit(string string, string delimiter = "_") {
        $cacheKey = __FUNCTION__ . $delimiter;

        myResult = static::_cache($cacheKey, $string);

        if (myResult == false) {
            myResult = mb_strtolower(preg_replace("/(?<=\\w)([A-Z])/", $delimiter ~ "\\1", $string));
            static::_cache($cacheKey, $string, myResult);
        }

        return myResult;
    }

    /**
     * Returns corresponding table name for given model myClassName. ("people" for the model class "Person").
     *
     * @param string myClassName Name of class to get database table name for
     * @return string Name of the database table for given class
     * @link https://book.UIM.org/4/en/core-libraries/inflector.html#creating-table-and-class-name-forms
     */
    static string tableize(string myClassName) {
        myResult = static::_cache(__FUNCTION__, myClassName);

        if (myResult == false) {
            myResult = static::pluralize(static::underscore(myClassName));
            static::_cache(__FUNCTION__, myClassName, myResult);
        }

        return myResult;
    }

    /**
     * Returns Cake model class name ("Person" for the database table "people".) for given database table.
     *
     * @param string myTableName Name of database table to get class name for
     * @return string Class name
     * @link https://book.UIM.org/4/en/core-libraries/inflector.html#creating-table-and-class-name-forms
     */
    static string classify(string myTableName) {
        myResult = static::_cache(__FUNCTION__, myTableName);

        if (myResult == false) {
            myResult = static::camelize(static::singularize(myTableName));
            static::_cache(__FUNCTION__, myTableName, myResult);
        }

        return myResult;
    }

    /**
     * Returns camelBacked version of an underscored string.
     *
     * @param string string String to convert.
     * @return string in variable form
     * @link https://book.UIM.org/4/en/core-libraries/inflector.html#creating-variable-names
     */
    static string variable(string string) {
        myResult = static::_cache(__FUNCTION__, $string);

        if (myResult == false) {
            $camelized = static::camelize(static::underscore($string));
            $replace = strtolower(substr($camelized, 0, 1));
            myResult = $replace . substr($camelized, 1);
            static::_cache(__FUNCTION__, $string, myResult);
        }

        return myResult;
    }
}
