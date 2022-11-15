module uim.cake.https\Exception;

/**
 * An exception subclass used by routing and application code to
 * trigger a redirect.
 *
 * The URL and status code are provided as constructor arguments.
 *
 * ```
 * throw new RedirectException("http://example.com/some/path", 301);
 * ```
 *
 * Additional headers can also be provided in the constructor, or
 * using the addHeaders() method.
 */
class RedirectException : HttpException
{
    /**
     * Constructor
     *
     * @param string myTarget The URL to redirect to.
     * @param int $code The exception code that will be used as a HTTP status code
     * @param array $headers The headers that should be sent in the unauthorized challenge response.
     */
    this(string myTarget, int $code = 302, array $headers = []) {
        super.this(myTarget, $code);

        foreach ($headers as myKey => myValue) {
            this.setHeader(myKey, (array)myValue);
        }
    }

    /**
     * Add headers to be included in the response generated from this exception
     *
     * @param array $headers An array of `header => value` to append to the exception.
     *  If a header already exists, the new values will be appended to the existing ones.
     * @return this
     * @deprecated 4.2.0 Use `setHeaders()` instead.
     */
    function addHeaders(array $headers) {
        deprecationWarning("RedirectException::addHeaders() is deprecated, use setHeaders() instead.");

        foreach ($headers as myKey => myValue) {
            this.headers[myKey][] = myValue;
        }

        return this;
    }

    /**
     * Remove a header from the exception.
     *
     * @param string myKey The header to remove.
     * @return this
     * @deprecated 4.2.0 Use `setHeaders()` instead.
     */
    function removeHeader(string myKey) {
        deprecationWarning("RedirectException::removeHeader() is deprecated, use setHeaders() instead.");

        unset(this.headers[myKey]);

        return this;
    }
}
