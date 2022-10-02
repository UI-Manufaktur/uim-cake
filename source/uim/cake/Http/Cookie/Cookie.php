

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
 */module uim.cake.Http\Cookie;

import uim.cake.Utility\Hash;
use DateTimeImmutable;
use IDateTime;
use DateTimeZone;
use InvalidArgumentException;

/**
 * Cookie object to build a cookie and turn it into a header value
 *
 * An HTTP cookie (also called web cookie, Internet cookie, browser cookie or
 * simply cookie) is a small piece of data sent from a website and stored on
 * the user's computer by the user's web browser while the user is browsing.
 *
 * Cookies were designed to be a reliable mechanism for websites to remember
 * stateful information (such as items added in the shopping cart in an online
 * store) or to record the user's browsing activity (including clicking
 * particular buttons, logging in, or recording which pages were visited in
 * the past). They can also be used to remember arbitrary pieces of information
 * that the user previously entered into form fields such as names, and preferences.
 *
 * Cookie objects are immutable, and you must re-assign variables when modifying
 * cookie objects:
 *
 * ```
 * $cookie = $cookie.withValue('0');
 * ```
 *
 * @link https://tools.ietf.org/html/draft-ietf-httpbis-rfc6265bis-03
 * @link https://en.wikipedia.org/wiki/HTTP_cookie
 * @see \Cake\Http\Cookie\CookieCollection for working with collections of cookies.
 * @see \Cake\Http\Response::getCookieCollection() for working with response cookies.
 */
class Cookie : CookieInterface
{
    /**
     * Cookie name
     *
     * @var string
     */
    protected myName = '';

    /**
     * Raw Cookie value.
     *
     * @var array|string
     */
    protected myValue = '';

    /**
     * Whether a JSON value has been expanded into an array.
     *
     * @var bool
     */
    protected $isExpanded = false;

    /**
     * Expiration time
     *
     * @var \DateTime|\DateTimeImmutable|null
     */
    protected $expiresAt;

    /**
     * Path
     *
     * @var string
     */
    protected myPath = '/';

    /**
     * Domain
     *
     * @var string
     */
    protected $domain = '';

    /**
     * Secure
     *
     * @var bool
     */
    protected $secure = false;

    /**
     * HTTP only
     *
     * @var bool
     */
    protected $httpOnly = false;

    /**
     * Samesite
     *
     * @var string|null
     */
    protected $sameSite = null;

    /**
     * Default attributes for a cookie.
     *
     * @var array<string, mixed>
     * @see \Cake\Http\Cookie\Cookie::setDefaults()
     */
    protected static $defaults = [
        'expires' => null,
        'path' => '/',
        'domain' => '',
        'secure' => false,
        'httponly' => false,
        'samesite' => null,
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
        myValue = '',
        ?IDateTime $expiresAt = null,
        ?string myPath = null,
        ?string $domain = null,
        ?bool $secure = null,
        ?bool $httpOnly = null,
        ?string $sameSite = null
    ) {
        this.validateName(myName);
        this.name = myName;

        this._setValue(myValue);

        this.domain = $domain ?? static::$defaults['domain'];
        this.httpOnly = $httpOnly ?? static::$defaults['httponly'];
        this.path = myPath ?? static::$defaults['path'];
        this.secure = $secure ?? static::$defaults['secure'];
        if ($sameSite === null) {
            this.sameSite = static::$defaults['samesite'];
        } else {
            this.validateSameSiteValue($sameSite);
            this.sameSite = $sameSite;
        }

        if ($expiresAt) {
            $expiresAt = $expiresAt.setTimezone(new DateTimeZone('GMT'));
        } else {
            $expiresAt = static::$defaults['expires'];
        }
        this.expiresAt = $expiresAt;
    }

    /**
     * Set default options for the cookies.
     *
     * Valid option keys are:
     *
     * - `expires`: Can be a UNIX timestamp or `strtotime()` compatible string or `IDateTime` instance or `null`.
     * - `path`: A path string. Defauts to `'/'`.
     * - `domain`: Domain name string. Defaults to `''`.
     * - `httponly`: Boolean. Defaults to `false`.
     * - `secure`: Boolean. Defaults to `false`.
     * - `samesite`: Can be one of `CookieInterface::SAMESITE_LAX`, `CookieInterface::SAMESITE_STRICT`,
     *    `CookieInterface::SAMESITE_NONE` or `null`. Defaults to `null`.
     *
     * @param array<string, mixed> myOptions Default options.
     * @return void
     */
    static auto setDefaults(array myOptions): void
    {
        if (isset(myOptions['expires'])) {
            myOptions['expires'] = static::dateTimeInstance(myOptions['expires']);
        }
        if (isset(myOptions['samesite'])) {
            static::validateSameSiteValue(myOptions['samesite']);
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
     * @see \Cake\Cookie\Cookie::setDefaults()
     */
    static function create(string myName, myValue, array myOptions = [])
    {
        myOptions += static::$defaults;
        myOptions['expires'] = static::dateTimeInstance(myOptions['expires']);

        return new static(
            myName,
            myValue,
            myOptions['expires'],
            myOptions['path'],
            myOptions['domain'],
            myOptions['secure'],
            myOptions['httponly'],
            myOptions['samesite']
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
        if ($expires === null) {
            return null;
        }

        if ($expires instanceof IDateTime) {
            /** @psalm-suppress UndefinedInterfaceMethod */
            return $expires.setTimezone(new DateTimeZone('GMT'));
        }

        if (!is_string($expires) && !is_int($expires)) {
            throw new InvalidArgumentException(sprintf(
                'Invalid type `%s` for expires. Expected an string, integer or DateTime object.',
                getTypeName($expires)
            ));
        }

        if (!is_numeric($expires)) {
            $expires = strtotime($expires) ?: null;
        }

        if ($expires !== null) {
            $expires = new DateTimeImmutable('@' . (string)$expires);
        }

        return $expires;
    }

    /**
     * Create Cookie instance from "set-cookie" header string.
     *
     * @param string $cookie Cookie header string.
     * @param array<string, mixed> $defaults Default attributes.
     * @return static
     * @see \Cake\Http\Cookie\Cookie::setDefaults()
     */
    static function createFromHeaderString(string $cookie, array $defaults = [])
    {
        if (strpos($cookie, '";"') !== false) {
            $cookie = str_replace('";"', '{__cookie_replace__}', $cookie);
            $parts = str_replace('{__cookie_replace__}', '";"', explode(';', $cookie));
        } else {
            $parts = preg_split('/\;[ \t]*/', $cookie);
        }

        [myName, myValue] = explode('=', array_shift($parts), 2);
        myData = [
                'name' => urldecode(myName),
                'value' => urldecode(myValue),
            ] + $defaults;

        foreach ($parts as $part) {
            if (strpos($part, '=') !== false) {
                [myKey, myValue] = explode('=', $part);
            } else {
                myKey = $part;
                myValue = true;
            }

            myKey = strtolower(myKey);
            myData[myKey] = myValue;
        }

        if (isset(myData['max-age'])) {
            myData['expires'] = time() + (int)myData['max-age'];
            unset(myData['max-age']);
        }

        if (isset(myData['samesite'])) {
            // Ignore invalid value when parsing headers
            // https://tools.ietf.org/html/draft-west-first-party-cookies-07#section-4.1
            if (!in_array(myData['samesite'], CookieInterface::SAMESITE_VALUES, true)) {
                unset(myData['samesite']);
            }
        }

        myName = (string)myData['name'];
        myValue = (string)myData['value'];
        unset(myData['name'], myData['value']);

        return Cookie::create(
            myName,
            myValue,
            myData
        );
    }

    /**
     * Returns a header value as string
     *
     * @return string
     */
    function toHeaderValue(): string
    {
        myValue = this.value;
        if (this.isExpanded) {
            /** @psalm-suppress PossiblyInvalidArgument */
            myValue = this._flatten(this.value);
        }
        $headerValue = [];
        /** @psalm-suppress PossiblyInvalidArgument */
        $headerValue[] = sprintf('%s=%s', this.name, rawurlencode(myValue));

        if (this.expiresAt) {
            $headerValue[] = sprintf('expires=%s', this.getFormattedExpires());
        }
        if (this.path !== '') {
            $headerValue[] = sprintf('path=%s', this.path);
        }
        if (this.domain !== '') {
            $headerValue[] = sprintf('domain=%s', this.domain);
        }
        if (this.sameSite) {
            $headerValue[] = sprintf('samesite=%s', this.sameSite);
        }
        if (this.secure) {
            $headerValue[] = 'secure';
        }
        if (this.httpOnly) {
            $headerValue[] = 'httponly';
        }

        return implode('; ', $headerValue);
    }

    /**
     * @inheritDoc
     */
    function withName(string myName)
    {
        this.validateName(myName);
        $new = clone this;
        $new.name = myName;

        return $new;
    }

    /**
     * @inheritDoc
     */
    auto getId(): string
    {
        return "{this.name};{this.domain};{this.path}";
    }

    /**
     * @inheritDoc
     */
    auto getName(): string
    {
        return this.name;
    }

    /**
     * Validates the cookie name
     *
     * @param string myName Name of the cookie
     * @return void
     * @throws \InvalidArgumentException
     * @link https://tools.ietf.org/html/rfc2616#section-2.2 Rules for naming cookies.
     */
    protected auto validateName(string myName): void
    {
        if (preg_match("/[=,;\t\r\n\013\014]/", myName)) {
            throw new InvalidArgumentException(
                sprintf('The cookie name `%s` contains invalid characters.', myName)
            );
        }

        if (empty(myName)) {
            throw new InvalidArgumentException('The cookie name cannot be empty.');
        }
    }

    /**
     * @inheritDoc
     */
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
        deprecationWarning('Cookie::getStringValue() is deprecated. Use getScalarValue() instead.');

        return this.getScalarValue();
    }

    /**
     * @inheritDoc
     */
    auto getScalarValue() {
        if (this.isExpanded) {
            /** @psalm-suppress PossiblyInvalidArgument */
            return this._flatten(this.value);
        }

        return this.value;
    }

    /**
     * @inheritDoc
     */
    function withValue(myValue)
    {
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
    protected auto _setValue(myValue): void
    {
        this.isExpanded = is_array(myValue);
        this.value = myValue;
    }

    /**
     * @inheritDoc
     */
    function withPath(string myPath)
    {
        $new = clone this;
        $new.path = myPath;

        return $new;
    }

    /**
     * @inheritDoc
     */
    auto getPath(): string
    {
        return this.path;
    }

    /**
     * @inheritDoc
     */
    function withDomain(string $domain)
    {
        $new = clone this;
        $new.domain = $domain;

        return $new;
    }

    /**
     * @inheritDoc
     */
    auto getDomain(): string
    {
        return this.domain;
    }

    /**
     * @inheritDoc
     */
    function isSecure(): bool
    {
        return this.secure;
    }

    /**
     * @inheritDoc
     */
    function withSecure(bool $secure)
    {
        $new = clone this;
        $new.secure = $secure;

        return $new;
    }

    /**
     * @inheritDoc
     */
    function withHttpOnly(bool $httpOnly)
    {
        $new = clone this;
        $new.httpOnly = $httpOnly;

        return $new;
    }

    /**
     * @inheritDoc
     */
    function isHttpOnly(): bool
    {
        return this.httpOnly;
    }

    /**
     * @inheritDoc
     */
    function withExpiry($dateTime)
    {
        $new = clone this;
        $new.expiresAt = $dateTime.setTimezone(new DateTimeZone('GMT'));

        return $new;
    }

    /**
     * @inheritDoc
     */
    auto getExpiry() {
        return this.expiresAt;
    }

    /**
     * @inheritDoc
     */
    auto getExpiresTimestamp(): ?int
    {
        if (!this.expiresAt) {
            return null;
        }

        return (int)this.expiresAt.format('U');
    }

    /**
     * @inheritDoc
     */
    auto getFormattedExpires(): string
    {
        if (!this.expiresAt) {
            return '';
        }

        return this.expiresAt.format(static::EXPIRES_FORMAT);
    }

    /**
     * @inheritDoc
     */
    function isExpired($time = null): bool
    {
        $time = $time ?: new DateTimeImmutable('now', new DateTimeZone('UTC'));
        if (!this.expiresAt) {
            return false;
        }

        return this.expiresAt < $time;
    }

    /**
     * @inheritDoc
     */
    function withNeverExpire() {
        $new = clone this;
        $new.expiresAt = new DateTimeImmutable('2038-01-01');

        return $new;
    }

    /**
     * @inheritDoc
     */
    function withExpired() {
        $new = clone this;
        $new.expiresAt = new DateTimeImmutable('1970-01-01 00:00:01');

        return $new;
    }

    /**
     * @inheritDoc
     */
    auto getSameSite(): ?string
    {
        return this.sameSite;
    }

    /**
     * @inheritDoc
     */
    function withSameSite(?string $sameSite)
    {
        if ($sameSite !== null) {
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
    protected static function validateSameSiteValue(string $sameSite)
    {
        if (!in_array($sameSite, CookieInterface::SAMESITE_VALUES, true)) {
            throw new InvalidArgumentException(
                'Samesite value must be either of: ' . implode(', ', CookieInterface::SAMESITE_VALUES)
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
     * @return bool
     */
    function check(string myPath): bool
    {
        if (this.isExpanded === false) {
            /** @psalm-suppress PossiblyInvalidArgument */
            this.value = this._expand(this.value);
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
    function withAddedValue(string myPath, myValue)
    {
        $new = clone this;
        if ($new.isExpanded === false) {
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
    function withoutAddedValue(string myPath)
    {
        $new = clone this;
        if ($new.isExpanded === false) {
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
    function read(?string myPath = null)
    {
        if (this.isExpanded === false) {
            /** @psalm-suppress PossiblyInvalidArgument */
            this.value = this._expand(this.value);
        }

        if (myPath === null) {
            return this.value;
        }

        /** @psalm-suppress PossiblyInvalidArgument */
        return Hash::get(this.value, myPath);
    }

    /**
     * Checks if the cookie value was expanded
     *
     * @return bool
     */
    function isExpanded(): bool
    {
        return this.isExpanded;
    }

    /**
     * @inheritDoc
     */
    auto getOptions(): array
    {
        myOptions = [
            'expires' => (int)this.getExpiresTimestamp(),
            'path' => this.path,
            'domain' => this.domain,
            'secure' => this.secure,
            'httponly' => this.httpOnly,
        ];

        if (this.sameSite !== null) {
            myOptions['samesite'] = this.sameSite;
        }

        return myOptions;
    }

    /**
     * @inheritDoc
     */
    function toArray(): array
    {
        return [
            'name' => this.name,
            'value' => this.getScalarValue(),
        ] + this.getOptions();
    }

    /**
     * Implode method to keep keys are multidimensional arrays
     *
     * @param array $array Map of key and values
     * @return string A JSON encoded string.
     */
    protected auto _flatten(array $array): string
    {
        return json_encode($array);
    }

    /**
     * Explode method to return array from string set in CookieComponent::_flatten()
     * Maintains reading backwards compatibility with 1.x CookieComponent::_flatten().
     *
     * @param string $string A string containing JSON encoded data, or a bare string.
     * @return array|string Map of key and values
     */
    protected auto _expand(string $string)
    {
        this.isExpanded = true;
        $first = substr($string, 0, 1);
        if ($first === '{' || $first === '[') {
            $ret = json_decode($string, true);

            return $ret ?? $string;
        }

        $array = [];
        foreach (explode(',', $string) as $pair) {
            myKey = explode('|', $pair);
            if (!isset(myKey[1])) {
                return myKey[0];
            }
            $array[myKey[0]] = myKey[1];
        }

        return $array;
    }
}
