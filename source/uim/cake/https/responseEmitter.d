module uim.cake.https;

@safe:
import uim.cake;

/**
 * Emits a Response to the PHP Server API.
 *
 * This emitter offers a few changes from the emitters offered by
 * diactoros:
 *
 * - It logs headers sent using UIM"s logging tools.
 * - Cookies are emitted using setcookie() to not conflict with ext/session
 */
class ResponseEmitter : EmitterInterface
{
    /**
     * Maximum output buffering size for each iteration.
     *
     * @var int
     */
    protected $maxBufferLength;

    /**
     * Constructor
     *
     * @param int $maxBufferLength Maximum output buffering size for each iteration.
     */
    this(int $maxBufferLength = 8192) {
        this.maxBufferLength = $maxBufferLength;
    }

    /**
     * Emit a response.
     *
     * Emits a response, including status line, headers, and the message body,
     * according to the environment.
     *
     * @param \Psr\Http\Message\IResponse $response The response to emit.
     * @return bool
     */
    bool emit(IResponse $response) {
        myfile = "";
        $line = 0;
        if (headers_sent(myfile, $line)) {
            myMessage = "Unable to emit headers. Headers sent in file=myfile line=$line";
            trigger_error(myMessage, E_USER_WARNING);
        }

        this.emitStatusLine($response);
        this.emitHeaders($response);
        this.flush();

        $range = this.parseContentRange($response.getHeaderLine("Content-Range"));
        if (is_array($range)) {
            this.emitBodyRange($range, $response);
        } else {
            this.emitBody($response);
        }

        if (function_exists("fastcgi_finish_request")) {
            fastcgi_finish_request();
        }

        return true;
    }

    /**
     * Emit the message body.
     *
     * @param \Psr\Http\Message\IResponse $response The response to emit
     * @return void
     */
    protected void emitBody(IResponse $response)
    {
        if (in_array($response.getStatusCode(), [204, 304], true)) {
            return;
        }
        $body = $response.getBody();

        if (!$body.isSeekable()) {
            echo $body;

            return;
        }

        $body.rewind();
        while (!$body.eof()) {
            echo $body.read(this.maxBufferLength);
        }
    }

    /**
     * Emit a range of the message body.
     *
     * @param array $range The range data to emit
     * @param \Psr\Http\Message\IResponse $response The response to emit
     * @return void
     */
    protected void emitBodyRange(array $range, IResponse $response)
    {
        [, $first, $last] = $range;

        $body = $response.getBody();

        if (!$body.isSeekable()) {
            myContentss = $body.getContents();
            echo substr(myContentss, $first, $last - $first + 1);

            return;
        }

        $body = new RelativeStream($body, $first);
        $body.rewind();
        $pos = 0;
        $length = $last - $first + 1;
        while (!$body.eof() && $pos < $length) {
            if ($pos + this.maxBufferLength > $length) {
                echo $body.read($length - $pos);
                break;
            }

            echo $body.read(this.maxBufferLength);
            $pos = $body.tell();
        }
    }

    /**
     * Emit the status line.
     *
     * Emits the status line using the protocol version and status code from
     * the response; if a reason phrase is available, it, too, is emitted.
     *
     * @param \Psr\Http\Message\IResponse $response The response to emit
     * @return void
     */
    protected void emitStatusLine(IResponse $response)
    {
        $reasonPhrase = $response.getReasonPhrase();
        header(sprintf(
            "HTTP/%s %d%s",
            $response.getProtocolVersion(),
            $response.getStatusCode(),
            ($reasonPhrase ? " " . $reasonPhrase : "")
        ));
    }

    /**
     * Emit response headers.
     *
     * Loops through each header, emitting each; if the header value
     * is an array with multiple values, ensures that each is sent
     * in such a way as to create aggregate headers (instead of replace
     * the previous).
     *
     * @param \Psr\Http\Message\IResponse $response The response to emit
     */
    protected void emitHeaders(IResponse $response) {
        $cookies = [];
        if (method_exists($response, "getCookieCollection")) {
            $cookies = iterator_to_array($response.getCookieCollection());
        }

        foreach ($response.getHeaders() as myName: myValues) {
            if (strtolower(myName) == "set-cookie") {
                $cookies = array_merge($cookies, myValues);
                continue;
            }
            $first = true;
            foreach (myValues as myValue) {
                header(sprintf(
                    "%s: %s",
                    myName,
                    myValue
                ), $first);
                $first = false;
            }
        }

        this.emitCookies($cookies);
    }

    /**
     * Emit cookies using setcookie()
     *
     * @param array<\Cake\Http\Cookie\ICookie|string> $cookies An array of cookies.
     * @return void
     */
    protected void emitCookies(array $cookies)
    {
        foreach ($cookies as $cookie) {
            this.setCookie($cookie);
        }
    }

    /**
     * Helper methods to set cookie.
     *
     * @param \Cake\Http\Cookie\ICookie|string $cookie Cookie.
     */
    protected bool setCookie($cookie) {
        if (is_string($cookie)) {
            $cookie = Cookie::createFromHeaderString($cookie, ["path":""]);
        }

        if (PHP_VERSION_ID >= 70300) {
            /** @psalm-suppress InvalidArgument */
            return setcookie($cookie.getName(), $cookie.getScalarValue(), $cookie.getOptions());
        }

        myPath = $cookie.getPath();
        $sameSite = $cookie.getSameSite();
        if ($sameSite !== null) {
            // Temporary hack for PHP 7.2 to set "SameSite" attribute
            // https://stackoverflow.com/questions/39750906/php-setcookie-samesite-strict
            myPath .= "; samesite=" . $sameSite;
        }

        return setcookie(
            $cookie.getName(),
            $cookie.getScalarValue(),
            $cookie.getExpiresTimestamp() ?: 0,
            myPath,
            $cookie.getDomain(),
            $cookie.isSecure(),
            $cookie.isHttpOnly()
        );
    }

    /**
     * Loops through the output buffer, flushing each, before emitting
     * the response.
     *
     * @param int|null $maxBufferLevel Flush up to this buffer level.
     * @return void
     */
    protected void flush(Nullable!int $maxBufferLevel = null)
    {
        if ($maxBufferLevel == null) {
            $maxBufferLevel = ob_get_level();
        }

        while (ob_get_level() > $maxBufferLevel) {
            ob_end_flush();
        }
    }

    /**
     * Parse content-range header
     * https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.16
     *
     * @param string $header The Content-Range header to parse.
     * @return array|false [unit, first, last, length]; returns false if no
     *     content range or an invalid content range is provided
     */
    protected auto parseContentRange(string $header) {
        if (preg_match("/(?P<unit>[\w]+)\s+(?P<first>\d+)-(?P<last>\d+)\/(?P<length>\d+|\*)/", $header, $matches)) {
            return [
                $matches["unit"],
                (int)$matches["first"],
                (int)$matches["last"],
                $matches["length"] == "*" ? "*" : (int)$matches["length"],
            ];
        }

        return false;
    }
}