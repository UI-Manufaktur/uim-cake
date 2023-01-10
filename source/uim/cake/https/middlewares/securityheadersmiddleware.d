module uim.cake.https\Middleware;

@safe:
import uim.cake;

/**
 * Handles common security headers in a convenient way
 *
 * @link https://book.UIM.org/4/en/controllers/middleware.html#security-header-middleware
 */
class SecurityHeadersMiddleware : IMiddleware {
    /** @var string X-Content-Type-Option nosniff */
    const NOSNIFF = "nosniff";

    /** @var string X-Download-Option noopen */
    const string NOOPEN = "noopen";

    /** @var string Referrer-Policy no-referrer */
    const string NO_REFERRER = "no-referrer";

    /** @var string Referrer-Policy no-referrer-when-downgrade */
    const string NO_REFERRER_WHEN_DOWNGRADE = "no-referrer-when-downgrade";

    /** @var string Referrer-Policy origin */
    const string ORIGIN = "origin";

    /** @var string Referrer-Policy origin-when-cross-origin */
    const string ORIGIN_WHEN_CROSS_ORIGIN = "origin-when-cross-origin";

    /** @var string Referrer-Policy same-origin */
    const string SAME_ORIGIN = "same-origin";

    /** @var string Referrer-Policy strict-origin */
    const string STRICT_ORIGIN = "strict-origin";

    /** @var string Referrer-Policy strict-origin-when-cross-origin */
    const string STRICT_ORIGIN_WHEN_CROSS_ORIGIN = "strict-origin-when-cross-origin";

    /** @var string Referrer-Policy unsafe-url */
    const string UNSAFE_URL = "unsafe-url";

    /** @var string X-Frame-Option deny */
    const DENY = "deny";

    /** @var string X-Frame-Option sameorigin */
    const SAMEORIGIN = "sameorigin";

    /** @var string X-Frame-Option allow-from */
    const ALLOW_FROM = "allow-from";

    /** @var string X-XSS-Protection block, sets enabled with block */
    const XSS_BLOCK = "block";

    /** @var string X-XSS-Protection enabled with block */
    const XSS_ENABLED_BLOCK = "1; mode=block";

    /** @var string X-XSS-Protection enabled */
    const XSS_ENABLED = "1";

    /** @var string X-XSS-Protection disabled */
    const XSS_DISABLED = "0";

    /** @var string X-Permitted-Cross-Domain-Policy all */
    const string ALL = "all";

    /** @var string X-Permitted-Cross-Domain-Policy none */
    const string NONE = "none";

    /** @var string X-Permitted-Cross-Domain-Policy master-only */
    const string MASTER_ONLY = "master-only";

    /** @var string X-Permitted-Cross-Domain-Policy by-content-type */
    const string BY_CONTENT_TYPE = "by-content-type";

    /** @var string X-Permitted-Cross-Domain-Policy by-ftp-filename */
    const string BY_FTP_FILENAME = "by-ftp-filename";

    /**
     * Security related headers to set
     *
     * @var array
     */
    protected headers = [];

    /**
     * X-Content-Type-Options
     *
     * Sets the header value for it to "nosniff"
     *
     * @link https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Content-Type-Options
     * @return this
     */
    function noSniff() {
        this.headers["x-content-type-options"] = self::NOSNIFF;

        return this;
    }

    /**
     * X-Download-Options
     *
     * Sets the header value for it to "noopen"
     *
     * @link https://msdn.microsoft.com/en-us/library/jj542450(v=vs.85).aspx
     * @return this
     */
    function noOpen() {
        this.headers["x-download-options"] = self::NOOPEN;

        return this;
    }

    /**
     * Referrer-Policy
     *
     * @link https://w3c.github.io/webappsec-referrer-policy
     * @param string policy Policy value. Available Value: "no-referrer", "no-referrer-when-downgrade", "origin",
     *     "origin-when-cross-origin", "same-origin", "strict-origin", "strict-origin-when-cross-origin", "unsafe-url"
     * @return this
     */
    auto setReferrerPolicy(string policy = self::SAME_ORIGIN) {
        $available = [
            self::NO_REFERRER,
            self::NO_REFERRER_WHEN_DOWNGRADE,
            self::ORIGIN,
            self::ORIGIN_WHEN_CROSS_ORIGIN,
            self::SAME_ORIGIN,
            self::STRICT_ORIGIN,
            self::STRICT_ORIGIN_WHEN_CROSS_ORIGIN,
            self::UNSAFE_URL,
        ];

        this.checkValues($policy, $available);
        this.headers["referrer-policy"] = $policy;

        return this;
    }

    /**
     * X-Frame-Options
     *
     * @link https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options
     * @param string option Option value. Available Values: "deny", "sameorigin", "allow-from <uri>"
     * @param string|null myUrl URL if mode is `allow-from`
     * @return this
     */
    auto setXFrameOptions(string option = self::SAMEORIGIN, Nullable!string myUrl = null) {
        this.checkValues($option, [self::DENY, self::SAMEORIGIN, self::ALLOW_FROM]);

        if ($option == self::ALLOW_FROM) {
            if (empty(myUrl)) {
                throw new InvalidArgumentException("The 2nd arg myUrl can not be empty when `allow-from` is used");
            }
            $option ~= " " ~ myUrl;
        }

        this.headers["x-frame-options"] = $option;

        return this;
    }

    /**
     * X-XSS-Protection
     *
     * @link https://blogs.msdn.microsoft.com/ieinternals/2011/01/31/controlling-the-xss-filter
     * @param string myMode Mode value. Available Values: "1", "0", "block"
     * @return this
     */
    auto setXssProtection(string myMode = self::XSS_BLOCK) {
        if (myMode == self::XSS_BLOCK) {
            myMode = self::XSS_ENABLED_BLOCK;
        }

        this.checkValues(myMode, [self::XSS_ENABLED, self::XSS_DISABLED, self::XSS_ENABLED_BLOCK]);
        this.headers["x-xss-protection"] = myMode;

        return this;
    }

    /**
     * X-Permitted-Cross-Domain-Policies
     *
     * @link https://www.adobe.com/devnet/adobe-media-server/articles/cross-domain-xml-for-streaming.html
     * @param string policy Policy value. Available Values: "all", "none", "master-only", "by-content-type",
     *     "by-ftp-filename"
     * @return this
     */
    auto setCrossDomainPolicy(string policy = self::ALL) {
        this.checkValues($policy, [
            self::ALL,
            self::NONE,
            self::MASTER_ONLY,
            self::BY_CONTENT_TYPE,
            self::BY_FTP_FILENAME,
        ]);
        this.headers["x-permitted-cross-domain-policies"] = $policy;

        return this;
    }

    /**
     * Convenience method to check if a value is in the list of allowed args
     *
     * @throws \InvalidArgumentException Thrown when a value is invalid.
     * @param string myValue Value to check
     * @param array<string> $allowed List of allowed values
     */
    protected void checkValues(string myValue, array $allowed) {
        if (!hasAllValues(myValue, $allowed, true)) {
            throw new InvalidArgumentException(sprintf(
                "Invalid arg `%s`, use one of these: %s",
                myValue,
                implode(", ", $allowed)
            ));
        }
    }

    /**
     * Serve assets if the path matches one.
     *
     * @param \Psr\Http\messages.IServerRequest myRequest The request.
     * @param \Psr\Http\servers.IRequestHandler $handler The request handler.
     * @return \Psr\Http\messages.IResponse A response.
     */
    function process(IServerRequest myRequest, IRequestHandler $handler): IResponse
    {
        $response = $handler.handle(myRequest);
        foreach (this.headers as $header: myValue) {
            $response = $response.withHeader($header, myValue);
        }

        return $response;
    }
}
