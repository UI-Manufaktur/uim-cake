

/**
 * UIM(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
module uim.cake.http.Cookie;

import uim.cake.utilities.Hash;
use DateTimeImmutable;
use DateTimeInterface;
use DateTimeZone;
use InvalidArgumentException;

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
 * @see uim.cake.http.Cookie\CookieCollection for working with collections of cookies.
 * @see uim.cake.http.Response::getCookieCollection() for working with response cookies.
 */
class Cookie : CookieInterface
{
    /**
     * Cookie name
     */
    protected string aName = "";

    /**
     * Raw Cookie value.
     *
     * @var array|string
     */
    protected $value = "";

    /**
     * Whether a JSON value has been expanded into an array.
     */
    protected bool $isExpanded = false;

    /**
     * Expiration time
     *
     * @var \DateTime|\DateTimeImmutable|null
     */
    protected $expiresAt;

    /**
     * Path
     */
    protected string $path = "/";

    /**
     * Domain
     */
    protected string $domain = "";

    /**
     * Secure
     */
    protected bool $secure = false;

    /**
     * HTTP only
     */
    protected bool $httpOnly = false;

    /**
     * Samesite
     *
     */
    protected Nullable!string sameSite = null;

    /**
     * Default attributes for a cookie.
     *
     * @var array<string, mixed>
     * @see uim.cake.http.Cookie\Cookie::setDefaults()
     */
    protected static $defaults = [
        "expires": null,
        "path": "/",
        "domain": "",
        "secure": false,
        "httponly": false,
        "samesite": null,
    ];

    /**
     * Constructor
     *
     * The constructors args are similar to the native PHP `setcookie()` method.
     * The only difference is the 3rd argument which excepts null or an
     * DateTime or DateTimeImmutable object instead an integer.
     *
     * @link https://php.net/manual/en/function.setcookie.php
     * @param string aName Cookie name
     * @param array|string aValue Value of the cookie
     * @param \DateTime|\DateTimeImmutable|null $expiresAt Expiration time and date
     * @param string|null $path Path
     * @param string|null $domain Domain
     * @param bool|null $secure Is secure
     * @param bool|null $httpOnly HTTP Only
     * @param string|null $sameSite Samesite
     */
    this(
        string aName,
        $value = "",
        ?DateTimeInterface $expiresAt = null,
        Nullable!string $path = null,
        Nullable!string $domain = null,
        ?bool $secure = null,
        ?bool $httpOnly = null,
        Nullable!string $sameSite = null
    ) {
        this.validateName($name);
        this.name = $name;

        _setValue($value);

        this.domain = $domain ?? static::$defaults["domain"];
        this.httpOnly = $httpOnly ?? static::$defaults["httponly"];
        this.path = $path ?? static::$defaults["path"];
        this.secure = $secure ?? static::$defaults["secure"];
        if ($sameSite == null) {
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
     * - `expires`: Can be a UNIX timestamp or `strtotime()` compatible string or `DateTimeInterface` instance or `null`.
     * - `path`: A path string. Defauts to `"/"`.
     * - `domain`: Domain name string. Defaults to `""`.
     * - `httponly`: Boolean. Defaults to `false`.
     * - `secure`: Boolean. Defaults to `false`.
     * - `samesite`: Can be one of `CookieInterface::SAMESITE_LAX`, `CookieInterface::SAMESITE_STRICT`,
     *    `CookieInterface::SAMESITE_NONE` or `null`. Defaults to `null`.
     *
     * @param array<string, mixed> $options Default options.
     */
    static void setDefaults(STRINGAA someOptions) {
        if (isset($options["expires"])) {
            $options["expires"] = static::dateTimeInstance($options["expires"]);
        }
        if (isset($options["samesite"])) {
            static::validateSameSiteValue($options["samesite"]);
        }

        static::$defaults = $options + static::$defaults;
    }

    /**
     * Factory method to create Cookie instances.
     *
     * @param string aName Cookie name
     * @param array|string aValue Value of the cookie
     * @param array<string, mixed> $options Cookies options.
     * @return static
     * @see uim.cake.Cookie\Cookie::setDefaults()
     */
    static function create(string aName, $value, STRINGAA someOptions = []) {
        $options += static::$defaults;
        $options["expires"] = static::dateTimeInstance($options["expires"]);

        return new static(
            $name,
            $value,
            $options["expires"],
            $options["path"],
            $options["domain"],
            $options["secure"],
            $options["httponly"],
            $options["samesite"]
        );
    }

    /**
     * Converts non null expiry value into DateTimeInterface instance.
     *
     * @param mixed $expires Expiry value.
     * @return \DateTime|\DateTimeImmutable|null
     */
    protected static function dateTimeInstance($expires): ?DateTimeInterface
    {
        if ($expires == null) {
            return null;
        }

        if ($expires instanceof DateTimeInterface) {
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

        if ($expires != null) {
            $expires = new DateTimeImmutable("@" ~ (string)$expires);
        }

        return $expires;
    }

    /**
     * Create Cookie instance from "set-cookie" header string.
     *
     * @param string $cookie Cookie header string.
     * @param array<string, mixed> $defaults Default attributes.
     * @return static
     * @see uim.cake.http.Cookie\Cookie::setDefaults()
     */
    static function createFromHeaderString(string $cookie, array $defaults = []) {
        if (strpos($cookie, "";"") != false) {
            $cookie = replace("";"", "{__cookie_replace__}", $cookie);
            $parts = replace("{__cookie_replace__}", "";"", explode(";", $cookie));
        } else {
            $parts = preg_split("/\;[ \t]*/", $cookie);
        }

        [$name, $value] = explode("=", array_shift($parts), 2);
        $data = [
                "name": urldecode($name),
                "value": urldecode($value),
            ] + $defaults;

        foreach ($parts as $part) {
            if (strpos($part, "=") != false) {
                [$key, $value] = explode("=", $part);
            } else {
                $key = $part;
                $value = true;
            }

            $key = $key.toLower;
            $data[$key] = $value;
        }

        if (isset($data["max-age"])) {
            $data["expires"] = time() + (int)$data["max-age"];
            unset($data["max-age"]);
        }

        if (isset($data["samesite"])) {
            // Ignore invalid value when parsing headers
            // https://tools.ietf.org/html/draft-west-first-party-cookies-07#section-4.1
            if (!hasAllValues($data["samesite"], CookieInterface::SAMESITE_VALUES, true)) {
                unset($data["samesite"]);
            }
        }

        $name = (string)$data["name"];
        $value = (string)$data["value"];
        unset($data["name"], $data["value"]);

        return Cookie::create(
            $name,
            $value,
            $data
        );
    }

    /**
     * Returns a header value as string
     */
    string toHeaderValue() {
        $value = this.value;
        if (this.isExpanded) {
            /** @psalm-suppress PossiblyInvalidArgument */
            $value = _flatten(this.value);
        }
        $headerValue = [];
        /** @psalm-suppress PossiblyInvalidArgument */
        $headerValue[] = sprintf("%s=%s", this.name, rawurlencode($value));

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


    function withName(string aName) {
        this.validateName($name);
        $new = clone this;
        $new.name = $name;

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
     * @param string aName Name of the cookie
     * @return void
     * @throws \InvalidArgumentException
     * @link https://tools.ietf.org/html/rfc2616#section-2.2 Rules for naming cookies.
     */
    protected void validateName(string aName) {
        if (preg_match("/[=,;\t\r\n\013\014]/", $name)) {
            throw new InvalidArgumentException(
                sprintf("The cookie name `%s` contains invalid characters.", $name)
            );
        }

        if (empty($name)) {
            throw new InvalidArgumentException("The cookie name cannot be empty.");
        }
    }


    function getValue() {
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
    function getStringValue() {
        deprecationWarning("Cookie::getStringValue() is deprecated. Use getScalarValue() instead.");

        return this.getScalarValue();
    }


    function getScalarValue() {
        if (this.isExpanded) {
            /** @psalm-suppress PossiblyInvalidArgument */
            return _flatten(this.value);
        }

        return this.value;
    }


    function withValue($value) {
        $new = clone this;
        $new._setValue($value);

        return $new;
    }

    /**
     * Setter for the value attribute.
     *
     * @param array|string aValue The value to store.
     */
    protected void _setValue($value) {
        this.isExpanded = is_array($value);
        this.value = $value;
    }


    function withPath(string $path) {
        $new = clone this;
        $new.path = $path;

        return $new;
    }


    string getPath() {
        return this.path;
    }


    function withDomain(string $domain) {
        $new = clone this;
        $new.domain = $domain;

        return $new;
    }


    string getDomain() {
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


    function getExpiry() {
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


    function withSameSite(Nullable!string $sameSite) {
        if ($sameSite != null) {
            this.validateSameSiteValue($sameSite);
        }

        $new = clone this;
        $new.sameSite = $sameSite;

        return $new;
    }

    /**
     * Check that value passed for SameSite is valid.
     *
     * @param string $sameSite SameSite value
     * @return void
     * @throws \InvalidArgumentException
     */
    protected static function validateSameSiteValue(string $sameSite) {
        if (!hasAllValues($sameSite, CookieInterface::SAMESITE_VALUES, true)) {
            throw new InvalidArgumentException(
                "Samesite value must be either of: " ~ implode(", ", CookieInterface::SAMESITE_VALUES)
            );
        }
    }

    /**
     * Checks if a value exists in the cookie data.
     *
     * This method will expand serialized complex data,
     * on first use.
     *
     * @param string $path Path to check
     */
    bool check(string $path) {
        if (this.isExpanded == false) {
            /** @psalm-suppress PossiblyInvalidArgument */
            this.value = _expand(this.value);
        }

        /** @psalm-suppress PossiblyInvalidArgument */
        return Hash::check(this.value, $path);
    }

    /**
     * Create a new cookie with updated data.
     *
     * @param string $path Path to write to
     * @param mixed $value Value to write
     * @return static
     */
    function withAddedValue(string $path, $value) {
        $new = clone this;
        if ($new.isExpanded == false) {
            /** @psalm-suppress PossiblyInvalidArgument */
            $new.value = $new._expand($new.value);
        }

        /** @psalm-suppress PossiblyInvalidArgument */
        $new.value = Hash::insert($new.value, $path, $value);

        return $new;
    }

    /**
     * Create a new cookie without a specific path
     *
     * @param string $path Path to remove
     * @return static
     */
    function withoutAddedValue(string $path) {
        $new = clone this;
        if ($new.isExpanded == false) {
            /** @psalm-suppress PossiblyInvalidArgument */
            $new.value = $new._expand($new.value);
        }

        /** @psalm-suppress PossiblyInvalidArgument */
        $new.value = Hash::remove($new.value, $path);

        return $new;
    }

    /**
     * Read data from the cookie
     *
     * This method will expand serialized complex data,
     * on first use.
     *
     * @param string|null $path Path to read the data from
     * @return mixed
     */
    function read(Nullable!string $path = null) {
        if (this.isExpanded == false) {
            /** @psalm-suppress PossiblyInvalidArgument */
            this.value = _expand(this.value);
        }

        if ($path == null) {
            return this.value;
        }

        /** @psalm-suppress PossiblyInvalidArgument */
        return Hash::get(this.value, $path);
    }

    /**
     * Checks if the cookie value was expanded
     */
    bool isExpanded() {
        return this.isExpanded;
    }


    array getOptions() {
        $options = [
            "expires": (int)this.getExpiresTimestamp(),
            "path": this.path,
            "domain": this.domain,
            "secure": this.secure,
            "httponly": this.httpOnly,
        ];

        if (this.sameSite != null) {
            $options["samesite"] = this.sameSite;
        }

        return $options;
    }


    array toArray() {
        return [
            "name": this.name,
            "value": this.getScalarValue(),
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
     * @param string $string A string containing JSON encoded data, or a bare string.
     * @return array|string Map of key and values
     */
    protected function _expand(string $string) {
        this.isExpanded = true;
        $first = substr($string, 0, 1);
        if ($first == "{" || $first == "[") {
            $ret = json_decode($string, true);

            return $ret ?? $string;
        }

        $array = [];
        foreach (explode(",", $string) as $pair) {
            $key = explode("|", $pair);
            if (!isset(string aKey[1])) {
                return $key[0];
            }
            $array[$key[0]] = $key[1];
        }

        return $array;
    }
}
