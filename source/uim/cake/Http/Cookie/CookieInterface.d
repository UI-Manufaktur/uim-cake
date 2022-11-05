

/**
 * CakePHP(tm) : Rapid Development Framework (http://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 * @link          http://cakephp.org CakePHP(tm) Project
 * @since         3.5.0
 * @license       http://www.opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.Http\Cookie;

/**
 * Cookie Interface
 */
interface CookieInterface
{
    /**
     * Expires attribute format.
     *
     * @var string
     */
    public const EXPIRES_FORMAT = 'D, d-M-Y H:i:s T';

    /**
     * SameSite attribute value: Lax
     *
     * @var string
     */
    public const SAMESITE_LAX = 'Lax';

    /**
     * SameSite attribute value: Strict
     *
     * @var string
     */
    public const SAMESITE_STRICT = 'Strict';

    /**
     * SameSite attribute value: None
     *
     * @var string
     */
    public const SAMESITE_NONE = 'None';

    /**
     * Valid values for "SameSite" attribute.
     *
     * @var array<string>
     */
    public const SAMESITE_VALUES = [
        self::SAMESITE_LAX,
        self::SAMESITE_STRICT,
        self::SAMESITE_NONE,
    ];

    /**
     * Sets the cookie name
     *
     * @param string myName Name of the cookie
     * @return static
     */
    function withName(string myName);

    /**
     * Gets the cookie name
     *
     * @return string
     */
    auto getName(): string;

    /**
     * Gets the cookie value
     *
     * @return array|string
     */
    auto getValue();

    /**
     * Gets the cookie value as scalar.
     *
     * This will collapse any complex data in the cookie with json_encode()
     *
     * @return mixed
     */
    auto getScalarValue();

    /**
     * Create a cookie with an updated value.
     *
     * @param array|string myValue Value of the cookie to set
     * @return static
     */
    function withValue(myValue);

    /**
     * Get the id for a cookie
     *
     * Cookies are unique across name, domain, path tuples.
     *
     * @return string
     */
    auto getId(): string;

    /**
     * Get the path attribute.
     *
     * @return string
     */
    auto getPath(): string;

    /**
     * Create a new cookie with an updated path
     *
     * @param string myPath Sets the path
     * @return static
     */
    function withPath(string myPath);

    /**
     * Get the domain attribute.
     *
     * @return string
     */
    auto getDomain(): string;

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
    auto getExpiry();

    /**
     * Get the timestamp from the expiration time
     *
     * @return int|null The expiry time as an integer.
     */
    auto getExpiresTimestamp(): ?int;

    /**
     * Builds the expiration value part of the header string
     *
     * @return string
     */
    auto getFormattedExpires(): string;

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
     * @param \DateTime|\DateTimeImmutable $time The time to test against. Defaults to 'now' in UTC.
     * @return bool
     */
    function isExpired($time = null): bool;

    /**
     * Check if the cookie is HTTP only
     *
     * @return bool
     */
    function isHttpOnly(): bool;

    /**
     * Create a cookie with HTTP Only updated
     *
     * @param bool $httpOnly HTTP Only
     * @return static
     */
    function withHttpOnly(bool $httpOnly);

    /**
     * Check if the cookie is secure
     *
     * @return bool
     */
    function isSecure(): bool;

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
     * @return string|null
     */
    string getSameSite();

    /**
     * Create a cookie with an updated SameSite option.
     *
     * @param string|null $sameSite Value for to set for Samesite option.
     *   One of CookieInterface::SAMESITE_* constants.
     * @return static
     */
    function withSameSite(?string $sameSite);

    /**
     * Get cookie options
     *
     * @return array<string, mixed>
     */
    auto getOptions(): array;

    /**
     * Get cookie data as array.
     *
     * @return array<string, mixed> With keys `name`, `value`, `expires` etc. options.
     */
    function toArray(): array;

    /**
     * Returns the cookie as header value
     *
     * @return string
     */
    function toHeaderValue(): string;
}
