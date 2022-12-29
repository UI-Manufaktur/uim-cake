module uim.cake.http.clients.adapters;

@safe:
import uim.cake;

/**
 * : sending Cake\Http\Client\Request
 * via php"s stream API.
 *
 * This approach and implementation is partly inspired by Aura.Http
 */
class Stream : IAdapter
{
    /**
     * Context resource used by the stream API.
     *
     * @var resource|null
     */
    protected _context;

    /**
     * Array of options/content for the HTTP stream context.
     *
     * @var array
     */
    protected _contextOptions = [];

    /**
     * Array of options/content for the SSL stream context.
     *
     * @var array
     */
    protected _sslContextOptions = [];

    /**
     * The stream resource.
     *
     * @var resource|null
     */
    protected _stream;

    /**
     * Connection error list.
     *
     * @var array
     */
    protected _connectionErrors = [];


    array send(RequestInterface myRequest, array myOptions) {
        _stream = null;
        _context = null;
        _contextOptions = [];
        _sslContextOptions = [];
        _connectionErrors = [];

        _buildContext(myRequest, myOptions);

        return _send(myRequest);
    }

    /**
     * Create the response list based on the headers & content
     *
     * Creates one or many response objects based on the number
     * of redirects that occurred.
     *
     * @param array $headers The list of headers from the request(s)
     * @param string myContents The response content.
     * @return array<\Cake\Http\Client\Response> The list of responses from the request(s)
     */
    array createResponses(array $headers, string myContents) {
        $indexes = $responses = [];
        foreach ($headers as $i: $header) {
            if (strtoupper(substr($header, 0, 5)) == "HTTP/") {
                $indexes[] = $i;
            }
        }
        $last = count($indexes) - 1;
        foreach ($indexes as $i: $start) {
            /** @psalm-suppress InvalidOperand */
            $end = isset($indexes[$i + 1]) ? $indexes[$i + 1] - $start : null;
            /** @psalm-suppress PossiblyInvalidArgument */
            $headerSlice = array_slice($headers, $start, $end);
            $body = $i == $last ? myContents : "";
            $responses[] = _buildResponse($headerSlice, $body);
        }

        return $responses;
    }

    /**
     * Build the stream context out of the request object.
     *
     * @param \Psr\Http\Message\RequestInterface myRequest The request to build context from.
     * @param array<string, mixed> myOptions Additional request options.
     */
    protected void _buildContext(RequestInterface myRequest, array myOptions) {
        _buildContent(myRequest, myOptions);
        _buildHeaders(myRequest, myOptions);
        _buildOptions(myRequest, myOptions);

        myUrl = myRequest.getUri();
        $scheme = parse_url((string)myUrl, PHP_URL_SCHEME);
        if ($scheme == "https") {
            _buildSslContext(myRequest, myOptions);
        }
        _context = stream_context_create([
            "http":_contextOptions,
            "ssl":_sslContextOptions,
        ]);
    }

    /**
     * Build the header context for the request.
     *
     * Creates cookies & headers.
     *
     * @param \Psr\Http\Message\RequestInterface myRequest The request being sent.
     * @param array<string, mixed> myOptions Array of options to use.
     */
    protected void _buildHeaders(RequestInterface myRequest, array myOptions) {
        $headers = [];
        foreach (myRequest.getHeaders() as myName: myValues) {
            $headers[] = sprintf("%s: %s", myName, implode(", ", myValues));
        }
        _contextOptions["header"] = implode("\r\n", $headers);
    }

    /**
     * Builds the request content based on the request object.
     *
     * If the myRequest.body() is a string, it will be used as is.
     * Array data will be processed with {@link \Cake\Http\Client\FormData}
     *
     * @param \Psr\Http\Message\RequestInterface myRequest The request being sent.
     * @param array<string, mixed> myOptions Array of options to use.
     */
    protected void _buildContent(RequestInterface myRequest, array myOptions) {
        $body = myRequest.getBody();
        $body.rewind();
        _contextOptions["content"] = $body.getContents();
    }

    /**
     * Build miscellaneous options for the request.
     *
     * @param \Psr\Http\Message\RequestInterface myRequest The request being sent.
     * @param array<string, mixed> myOptions Array of options to use.
     */
    protected void _buildOptions(RequestInterface myRequest, array myOptions) {
        _contextOptions["method"] = myRequest.getMethod();
        _contextOptions["protocol_version"] = myRequest.getProtocolVersion();
        _contextOptions["ignore_errors"] = true;

        if (isset(myOptions["timeout"])) {
            _contextOptions["timeout"] = myOptions["timeout"];
        }
        // Redirects are handled in the client layer because of cookie handling issues.
        _contextOptions["max_redirects"] = 0;

        if (isset(myOptions["proxy"]["proxy"])) {
            _contextOptions["request_fulluri"] = true;
            _contextOptions["proxy"] = myOptions["proxy"]["proxy"];
        }
    }

    /**
     * Build SSL options for the request.
     *
     * @param \Psr\Http\Message\RequestInterface myRequest The request being sent.
     * @param array<string, mixed> myOptions Array of options to use.
     */
    protected void _buildSslContext(RequestInterface myRequest, array myOptions) {
        $sslOptions = [
            "ssl_verify_peer",
            "ssl_verify_peer_name",
            "ssl_verify_depth",
            "ssl_allow_self_signed",
            "ssl_cafile",
            "ssl_local_cert",
            "ssl_local_pk",
            "ssl_passphrase",
        ];
        if (empty(myOptions["ssl_cafile"])) {
            myOptions["ssl_cafile"] = CaBundle::getBundledCaBundlePath();
        }
        if (!empty(myOptions["ssl_verify_host"])) {
            myUrl = myRequest.getUri();
            $host = parse_url((string)myUrl, PHP_URL_HOST);
            _sslContextOptions["peer_name"] = $host;
        }
        foreach ($sslOptions as myKey) {
            if (isset(myOptions[myKey])) {
                myName = substr(myKey, 4);
                _sslContextOptions[myName] = myOptions[myKey];
            }
        }
    }

    /**
     * Open the stream and send the request.
     *
     * @param \Psr\Http\Message\RequestInterface myRequest The request object.
     * @return array Array of populated Response objects
     * @throws \Psr\Http\Client\NetworkExceptionInterface
     */
    protected array _send(RequestInterface myRequest) {
        $deadline = false;
        if (isset(_contextOptions["timeout"]) && _contextOptions["timeout"] > 0) {
            $deadline = time() + _contextOptions["timeout"];
        }

        myUrl = myRequest.getUri();
        _open((string)myUrl, myRequest);
        myContents = "";
        $timedOut = false;

        /** @psalm-suppress PossiblyNullArgument  */
        while (!feof(_stream)) {
            if ($deadline != false) {
                stream_set_timeout(_stream, max($deadline - time(), 1));
            }

            myContents .= fread(_stream, 8192);

            $meta = stream_get_meta_data(_stream);
            if ($meta["timed_out"] || ($deadline != false && time() > $deadline)) {
                $timedOut = true;
                break;
            }
        }
        /** @psalm-suppress PossiblyNullArgument */
        $meta = stream_get_meta_data(_stream);
        /** @psalm-suppress InvalidPropertyAssignmentValue */
        fclose(_stream);

        if ($timedOut) {
            throw new NetworkException("Connection timed out " . myUrl, myRequest);
        }

        $headers = $meta["wrapper_data"];
        if (isset($headers["headers"]) && is_array($headers["headers"])) {
            $headers = $headers["headers"];
        }

        return this.createResponses($headers, myContents);
    }

    /**
     * Build a response object
     *
     * @param array $headers Unparsed headers.
     * @param string body The response body.
     * @return uim.cake.http.Client\Response
     */
    protected Response _buildResponse(array $headers, string body) {
        return new Response($headers, $body);
    }

    /**
     * Open the socket and handle any connection errors.
     *
     * @param string myUrl The url to connect to.
     * @param \Psr\Http\Message\RequestInterface myRequest The request object.
     * @return void
     * @throws \Psr\Http\Client\RequestExceptionInterface
     */
    protected void _open(string myUrl, RequestInterface myRequest) {
        if (!(bool)ini_get("allow_url_fopen")) {
            throw new ClientException("The PHP directive `allow_url_fopen` must be enabled.");
        }

        set_error_handler(bool ($code, myMessage) {
            _connectionErrors[] = myMessage;

            return true;
        });
        try {
            /** @psalm-suppress PossiblyNullArgument */
            _stream = fopen(myUrl, "rb", false, _context);
        } finally {
            restore_error_handler();
        }

        if (!_stream || !empty(_connectionErrors)) {
            throw new RequestException(implode("\n", _connectionErrors), myRequest);
        }
    }

    /**
     * Get the context options
     *
     * Useful for debugging and testing context creation.
     */
    array contextOptions() {
        return array_merge(_contextOptions, _sslContextOptions);
    }
}
