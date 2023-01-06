

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
module uim.cake.http.Cookie;

/**
 * Cookie Interface
 */
interface CookieInterface
{
    /**
     * Expires attribute format.
     */
    const string EXPIRES_FORMAT = "D, d-M-Y H:i:s T";

    /**
     * SameSite attribute value: Lax
     */
    const string SAMESITE_LAX = "Lax";

    /**
     * SameSite attribute value: Strict
     */
    const string SAMESITE_STRICT = "Strict";

    /**
     * SameSite attribute value: None
     */
    const string SAMESITE_NONE = "None";

    /**
     * Valid values for "SameSite" attribute.
     *
     * @var array<string>
     */
    const SAMESITE_VALUES = [
        self::SAMESITE_LAX,
        self::SAMESITE_STRICT,
        self::SAMESITE_NONE,
    ];

    /**
     * Sets the cookie name
     *
     * @param string aName Name of the cookie
     * @return static
     */
    function withName(string aName);

    /**
     * Gets the cookie name
     */
    string getName();

    /**
     * Gets the cookie value
     *
     * @return array|string
     */
    function getValue();

    /**
     * Gets the cookie value as scalar.
     *
     * This will collapse any complex data in the cookie with json_encode()
     *
     * @return mixed
     */
    function getScalarValue();

    /**
     * Create a cookie with an updated value.
     *
     * @param array|string aValue Value of the cookie to set
     * @return static
     */
    function withValue($value);

    /**
     * Get the id for a cookie
     *
     * Cookies are unique across name, domain, path tuples.
     */
    string getId();

    /**
     * Get the path attribute.
     */
    string getPath();

    /**
     * Create a new cookie with an updated path
     *
     * @param string $path Sets the path
     * @return static
     */
    function withPath(string $path);

    /**
     * Get the domain attribute.
     */
    string getDomain();

    /**
     * Create a cookie with an updated domain
     *
     * @param string $domain Domain to set
     * @return static
     */
    function withDomain(string $domain);

    /**
     * Get the current expiry time
     *
     * @return \DateTime|\DateTimeImmutable|null Timestamp of expiry or null
     */
    function getExpiry();

    /**
     * Get the timestamp from the expiration time
     *
     * @return int|null The expiry time as an integer.
     */
    Nullable!int getExpiresTimestamp();

    /**
     * Builds the expiration value part of the header string
     */
    string getFormattedExpires();

    /**
     * Create a cookie with an updated expiration date
     *
     * @param \DateTime|\DateTimeImmutable $dateTime Date time object
     * @return static
     */
    function withExpiry($dateTime);

    /**
     * Create a new cookie that will virtually never expire.
     *
     * @return static
     */
    function withNeverExpire();

    /**
     * Create a new cookie that will expire/delete the cookie from the browser.
     *
     * This is done by setting the expiration time to 1 year ago
     *
     * @return static
     */
    function withExpired();

    /**
     * Check if a cookie is expired when compared to $time
     *
     * Cookies without an expiration date always return false.
     *
     * @param \DateTime|\DateTimeImmutable $time The time to test against. Defaults to "now" in UTC.
     */
    bool isExpired($time = null);

    /**
     * Check if the cookie is HTTP only
     */
    bool isHttpOnly();

    /**
     * Create a cookie with HTTP Only updated
     *
     * @param bool $httpOnly HTTP Only
     * @return static
     */
    function withHttpOnly(bool $httpOnly);

    /**
     * Check if the cookie is secure
     */
    bool isSecure();

    /**
     * Create a cookie with Secure updated
     *
     * @param bool $secure Secure attribute value
     * @return static
     */
    function withSecure(bool $secure);

    /**
     * Get the SameSite attribute.
     *
     */
    Nullable!string getSameSite();

    /**
     * Create a cookie with an updated SameSite option.
     *
     * @param string|null $sameSite Value for to set for Samesite option.
     *   One of CookieInterface::SAMESITE_* constants.
     * @return static
     */
    function withSameSite(Nullable!string $sameSite);

    /**
     * Get cookie options
     *
     * @return array<string, mixed>
     */
    array getOptions();

    /**
     * Get cookie data as array.
     *
     * @return array<string, mixed> With keys `name`, `value`, `expires` etc. options.
     */
    array toArray();

    /**
     * Returns the cookie as header value
     */
    string toHeaderValue();
}
