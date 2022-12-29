module uim.cake.https.cookies.cookie;

@safe:
import uim.cake;

/**
 * Cookie object to build a cookie and turn it into a header value
 *
 * An HTTP cookie (also called web cookie, Internet cookie, browser cookie or
 * simply cookie) is a small piece of data sent from a website and stored on
 * the user"s computer by the user"s web browser while the user is browsing.
 *
 * Cookies were designed to be a reliable mechanism for websites to remember
 * stateful information (such as items added in the shopping cart in an online
 * store) or to record the user"s browsing activity (including clicking
 * particular buttons, logging in, or recording which pages were visited in
 * the past). They can also be used to remember arbitrary pieces of information
 * that the user previously entered into form fields such as names, and preferences.
 *
 * Cookie objects are immutable, and you must re-assign variables when modifying
 * cookie objects:
 *
 * ```
 * $cookie = $cookie.withValue("0");
 * ```
 *
 * @link https://tools.ietf.org/html/draft-ietf-httpbis-rfc6265bis-03
 * @link https://en.wikipedia.org/wiki/HTTP_cookie
 * @see uim.cake.Http\Cookie\CookieCollection for working with collections of cookies.
 * @see uim.cake.Http\Response::getCookieCollection() for working with response cookies.
 */
class Cookie : ICookie
{
    /**
     * Cookie name
     */
    protected string myName = "";

    /**
     * Raw Cookie value.
     *
     * @var array|string
     */
    protected myValue = "";

    /**
     * Whether a JSON value has been expanded into an array.
     *
     * @var bool
     */
    protected isExpanded = false;

    /**
     * Expiration time
     *
     * @var \DateTime|\DateTimeImmutable|null
     */
    protected expiresAt;

    /**
     * Path
     */
    protected string myPath = "/";

    /**
     * Domain
     */
    protected string domain = "";

    /**
     * Secure
     *
     * @var bool
     */
    protected secure = false;

    /**
     * HTTP only
     *
     * @var bool
     */
    protected httpOnly = false;

    /**
     * Samesite
     *
     * @var string|null
     */
    protected sameSite = null;

    /**
     * Default attributes for a cookie.
     *
     * @var array<string, mixed>
     * @see uim.cake.Http\Cookie\Cookie::setDefaults()
     */
    protected static $defaults = [
        "expires":null,
        "path":"/",
        "domain":"",
        "secure":false,
        "httponly":false,
        "samesite":null,
    ];

    /**
     * Constructor
     *
     * The constructors args are similar to the native PHP `setcookie()` method.
     * The only difference is the 3rd argument which excepts null or an
     * DateTime or DateTimeImmutable object instead an integer.
     *
     * @link http://php.net/manual/en/function.setcookie.php
     * @param string myName Cookie name
     * @param array|string myValue Value of the cookie
     * @param \DateTime|\DateTimeImmutable|null $expiresAt Expiration time and date
     * @param string|null myPath Path
     * @param string|null $domain Domain
     * @param bool|null $secure Is secure
     * @param bool|null $httpOnly HTTP Only
     * @param string|null $sameSite Samesite
     */
    this(
        string myName,
        myValue = "",
        ?IDateTime $expiresAt = null,
        Nullable!string myPath = null,
        Nullable!string domain = null,
        ?bool $secure = null,
        ?bool $httpOnly = null,
        Nullable!string sameSite = null
    ) {
        this.validateName(myName);
        this.name = myName;

        _setValue(myValue);

        this.domain = $domain ?? static::$defaults["domain"];
        this.httpOnly = $httpOnly ?? static::$defaults["httponly"];
        this.path = myPath ?? static::$defaults["path"];
        this.secure = $secure ?? static::$defaults["secure"];
        if ($sameSite is null) {
            this.sameSite = static::$defaults["samesite"];
        } else {
            this.validateSameSiteValue($sameSite);
            this.sameSite = $sameSite;
        }

        if ($expiresAt) {
            $expiresAt = $expiresAt.setTimezone(new DateTimeZone("GMT"));
        } else {
            $expiresAt = static::$defaults["expires"];
        }
        this.expiresAt = $expiresAt;
    }

    /**
     * Set default options for the cookies.
     *
     * Valid option keys are:
     *
     * - `expires`: Can be a UNIX timestamp or `strtotime()` compatible string or `IDateTime` instance or `null`.
     * - `path`: A path string. Defauts to `"/"`.
     * - `domain`: Domain name string. Defaults to `""`.
     * - `httponly`: Boolean. Defaults to `false`.
     * - `secure`: Boolean. Defaults to `false`.
     * - `samesite`: Can be one of `ICookie::SAMESITE_LAX`, `ICookie::SAMESITE_STRICT`,
     *    `ICookie::SAMESITE_NONE` or `null`. Defaults to `null`.
     *
     * @param array<string, mixed> myOptions Default options.
     * @return void
     */
    static void setDefaults(array myOptions) {
        if (isset(myOptions["expires"])) {
            myOptions["expires"] = static::dateTimeInstance(myOptions["expires"]);
        }
        if (isset(myOptions["samesite"])) {
            static::validateSameSiteValue(myOptions["samesite"]);
        }

        static::$defaults = myOptions + static::$defaults;
    }

    /**
     * Factory method to create Cookie instances.
     *
     * @param string myName Cookie name
     * @param array|string myValue Value of the cookie
     * @param array<string, mixed> myOptions Cookies options.
     * @return static
     * @see uim.cake.Cookie\Cookie::setDefaults()
     */
    static function create(string myName, myValue, array myOptions = []) {
        myOptions += static::$defaults;
        myOptions["expires"] = static::dateTimeInstance(myOptions["expires"]);

        return new static(
            myName,
            myValue,
            myOptions["expires"],
            myOptions["path"],
            myOptions["domain"],
            myOptions["secure"],
            myOptions["httponly"],
            myOptions["samesite"]
        );
    }

    /**
     * Converts non null expiry value into IDateTime instance.
     *
     * @param mixed $expires Expiry value.
     * @return \DateTime|\DatetimeImmutable|null
     */
    protected static function dateTimeInstance($expires): ?IDateTime
    {
        if ($expires is null) {
            return null;
        }

        if ($expires instanceof IDateTime) {
            /** @psalm-suppress UndefinedInterfaceMethod */
            return $expires.setTimezone(new DateTimeZone("GMT"));
        }

        if (!is_string($expires) && !is_int($expires)) {
            throw new InvalidArgumentException(sprintf(
                "Invalid type `%s` for expires. Expected an string, integer or DateTime object.",
                getTypeName($expires)
            ));
        }

        if (!is_numeric($expires)) {
            $expires = strtotime($expires) ?: null;
        }

        if ($expires  !is null) {
            $expires = new DateTimeImmutable("@" . (string)$expires);
        }

        return $expires;
    }

    /**
     * Create Cookie instance from "set-cookie" header string.
     *
     * @param string cookie Cookie header string.
     * @param array<string, mixed> $defaults Default attributes.
     * @return static
     * @see uim.cake.Http\Cookie\Cookie::setDefaults()
     */
    static function createFromHeaderString(string cookie, array $defaults = []) {
        if (indexOf($cookie, "";"") != false) {
            $cookie = str_replace("";"", "{__cookie_replace__}", $cookie);
            $parts = str_replace("{__cookie_replace__}", "";"", explode(";", $cookie));
        } else {
            $parts = preg_split("/\;[ \t]*/", $cookie);
        }

        [myName, myValue] = explode("=", array_shift($parts), 2);
        myData = [
                "name":urldecode(myName),
                "value":urldecode(myValue),
            ] + $defaults;

        foreach ($parts as $part) {
            if (indexOf($part, "=") != false) {
                [myKey, myValue] = explode("=", $part);
            } else {
                myKey = $part;
                myValue = true;
            }

            myKey = strtolower(myKey);
            myData[myKey] = myValue;
        }

        if (isset(myData["max-age"])) {
            myData["expires"] = time() + (int)myData["max-age"];
            unset(myData["max-age"]);
        }

        if (isset(myData["samesite"])) {
            // Ignore invalid value when parsing headers
            // https://tools.ietf.org/html/draft-west-first-party-cookies-07#section-4.1
            if (!in_array(myData["samesite"], ICookie::SAMESITE_VALUES, true)) {
                unset(myData["samesite"]);
            }
        }

        myName = (string)myData["name"];
        myValue = (string)myData["value"];
        unset(myData["name"], myData["value"]);

        return Cookie::create(
            myName,
            myValue,
            myData
        );
    }

    /**
     * Returns a header value as string
     */
    string toHeaderValue() {
        myValue = this.value;
        if (this.isExpanded) {
            /** @psalm-suppress PossiblyInvalidArgument */
            myValue = _flatten(this.value);
        }
        $headerValue = [];
        /** @psalm-suppress PossiblyInvalidArgument */
        $headerValue[] = sprintf("%s=%s", this.name, rawurlencode(myValue));

        if (this.expiresAt) {
            $headerValue[] = sprintf("expires=%s", this.getFormattedExpires());
        }
        if (this.path != "") {
            $headerValue[] = sprintf("path=%s", this.path);
        }
        if (this.domain != "") {
            $headerValue[] = sprintf("domain=%s", this.domain);
        }
        if (this.sameSite) {
            $headerValue[] = sprintf("samesite=%s", this.sameSite);
        }
        if (this.secure) {
            $headerValue[] = "secure";
        }
        if (this.httpOnly) {
            $headerValue[] = "httponly";
        }

        return implode("; ", $headerValue);
    }


    function withName(string myName) {
        this.validateName(myName);
        $new = clone this;
        $new.name = myName;

        return $new;
    }


    string getId() {
        return "{this.name};{this.domain};{this.path}";
    }


    string getName() {
        return this.name;
    }

    /**
     * Validates the cookie name
     *
     * @param string myName Name of the cookie
     * @throws \InvalidArgumentException
     * @link https://tools.ietf.org/html/rfc2616#section-2.2 Rules for naming cookies.
     */
    protected void validateName(string myName) {
        if (preg_match("/[=,;\t\r\n\013\014]/", myName)) {
            throw new InvalidArgumentException(
                sprintf("The cookie name `%s` contains invalid characters.", myName)
            );
        }

        if (empty(myName)) {
            throw new InvalidArgumentException("The cookie name cannot be empty.");
        }
    }


    auto getValue() {
        return this.value;
    }

    /**
     * Gets the cookie value as a string.
     *
     * This will collapse any complex data in the cookie with json_encode()
     *
     * @return mixed
     * @deprecated 4.0.0 Use {@link getScalarValue()} instead.
     */
    auto getStringValue() {
        deprecationWarning("Cookie::getStringValue() is deprecated. Use getScalarValue() instead.");

        return this.getScalarValue();
    }


    auto getScalarValue() {
        if (this.isExpanded) {
            /** @psalm-suppress PossiblyInvalidArgument */
            return _flatten(this.value);
        }

        return this.value;
    }


    function withValue(myValue) {
        $new = clone this;
        $new._setValue(myValue);

        return $new;
    }

    /**
     * Setter for the value attribute.
     *
     * @param array|string myValue The value to store.
     * @return void
     */
    protected void _setValue(myValue) {
        this.isExpanded = is_array(myValue);
        this.value = myValue;
    }


    function withPath(string myPath) {
        $new = clone this;
        $new.path = myPath;

        return $new;
    }


    string getPath() {
        return this.path;
    }


    function withDomain(string domain) {
        $new = clone this;
        $new.domain = $domain;

        return $new;
    }


    auto getDomain() {
        return this.domain;
    }


    bool isSecure() {
        return this.secure;
    }


    function withSecure(bool $secure) {
        $new = clone this;
        $new.secure = $secure;

        return $new;
    }


    function withHttpOnly(bool $httpOnly) {
        $new = clone this;
        $new.httpOnly = $httpOnly;

        return $new;
    }


    bool isHttpOnly() {
        return this.httpOnly;
    }


    function withExpiry($dateTime) {
        $new = clone this;
        $new.expiresAt = $dateTime.setTimezone(new DateTimeZone("GMT"));

        return $new;
    }


    auto getExpiry() {
      return this.expiresAt;
    }


    Nullable!int getExpiresTimestamp() {
      if (!this.expiresAt) {
          return null;
      }

      return (int)this.expiresAt.format("U");
    }


    string getFormattedExpires() {
      if (!this.expiresAt) {
          return "";
      }

      return this.expiresAt.format(static::EXPIRES_FORMAT);
    }


    bool isExpired($time = null) {
        $time = $time ?: new DateTimeImmutable("now", new DateTimeZone("UTC"));
        if (!this.expiresAt) {
            return false;
        }

        return this.expiresAt < $time;
    }


    function withNeverExpire() {
        $new = clone this;
        $new.expiresAt = new DateTimeImmutable("2038-01-01");

        return $new;
    }


    function withExpired() {
        $new = clone this;
        $new.expiresAt = new DateTimeImmutable("1970-01-01 00:00:01");

        return $new;
    }


    Nullable!string getSameSite() {
        return this.sameSite;
    }


    function withSameSite(Nullable!string sameSite) {
        if ($sameSite  !is null) {
            this.validateSameSiteValue($sameSite);
        }

        $new = clone this;
        $new.sameSite = $sameSite;

        return $new;
    }

    /**
     * Check that value passed for SameSite is valid.
     *
     * @param string sameSite SameSite value
     * @return void
     * @throws \InvalidArgumentException
     */
    protected static function validateSameSiteValue(string sameSite) {
      if (!in_array($sameSite, ICookie::SAMESITE_VALUES, true)) {
        throw new InvalidArgumentException(
            "Samesite value must be either of: " . implode(", ", ICookie::SAMESITE_VALUES)
        );
      }
    }

    /**
     * Checks if a value exists in the cookie data.
     *
     * This method will expand serialized complex data,
     * on first use.
     *
     * @param string myPath Path to check
     */
    bool check(string myPath) {
        if (this.isExpanded == false) {
            /** @psalm-suppress PossiblyInvalidArgument */
            this.value = _expand(this.value);
        }

        /** @psalm-suppress PossiblyInvalidArgument */
        return Hash::check(this.value, myPath);
    }

    /**
     * Create a new cookie with updated data.
     *
     * @param string myPath Path to write to
     * @param mixed myValue Value to write
     * @return static
     */
    function withAddedValue(string myPath, myValue) {
      $new = clone this;
      if ($new.isExpanded == false) {
          /** @psalm-suppress PossiblyInvalidArgument */
          $new.value = $new._expand($new.value);
      }

      /** @psalm-suppress PossiblyInvalidArgument */
      $new.value = Hash::insert($new.value, myPath, myValue);

      return $new;
    }

    /**
     * Create a new cookie without a specific path
     *
     * @param string myPath Path to remove
     * @return static
     */
    function withoutAddedValue(string myPath) {
        $new = clone this;
        if ($new.isExpanded == false) {
            /** @psalm-suppress PossiblyInvalidArgument */
            $new.value = $new._expand($new.value);
        }

        /** @psalm-suppress PossiblyInvalidArgument */
        $new.value = Hash::remove($new.value, myPath);

        return $new;
    }

    /**
     * Read data from the cookie
     *
     * This method will expand serialized complex data,
     * on first use.
     *
     * @param string|null myPath Path to read the data from
     * @return mixed
     */
    function read(Nullable!string myPath = null) {
        if (this.isExpanded == false) {
            /** @psalm-suppress PossiblyInvalidArgument */
            this.value = _expand(this.value);
        }

        if (myPath is null) {
            return this.value;
        }

        /** @psalm-suppress PossiblyInvalidArgument */
        return Hash::get(this.value, myPath);
    }

    /**
     * Checks if the cookie value was expanded
     */
    bool isExpanded() {
        return this.isExpanded;
    }


    auto getOptions(): array
    {
        myOptions = [
            "expires":(int)this.getExpiresTimestamp(),
            "path":this.path,
            "domain":this.domain,
            "secure":this.secure,
            "httponly":this.httpOnly,
        ];

        if (this.sameSite  !is null) {
            myOptions["samesite"] = this.sameSite;
        }

        return myOptions;
    }


    function toArray(): array
    {
        return [
            "name":this.name,
            "value":this.getScalarValue(),
        ] + this.getOptions();
    }

    /**
     * Implode method to keep keys are multidimensional arrays
     *
     * @param array $array Map of key and values
     * @return string A JSON encoded string.
     */
    protected string _flatten(array $array) {
        return json_encode($array);
    }

    /**
     * Explode method to return array from string set in CookieComponent::_flatten()
     * Maintains reading backwards compatibility with 1.x CookieComponent::_flatten().
     *
     * @param string string A string containing JSON encoded data, or a bare string.
     * @return array|string Map of key and values
     */
    protected auto _expand(string string) {
        this.isExpanded = true;
        $first = substr($string, 0, 1);
        if ($first == "{" || $first == "[") {
            $ret = json_decode($string, true);

            return $ret ?? $string;
        }

        $array = [];
        foreach (explode(",", $string) as $pair) {
            myKey = explode("|", $pair);
            if (!isset(myKey[1])) {
                return myKey[0];
            }
            $array[myKey[0]] = myKey[1];
        }

        return $array;
    }
}
