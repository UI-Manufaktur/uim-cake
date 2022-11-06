

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.https\Client\Adapter;

import uim.cake.https\Client\AdapterInterface;
import uim.cake.https\Client\Exception\ClientException;
import uim.cake.https\Client\Exception\NetworkException;
import uim.cake.https\Client\Exception\RequestException;
import uim.cake.https\Client\Response;
use Composer\CaBundle\CaBundle;
use Psr\Http\Message\RequestInterface;

/**
 * : sending Cake\Http\Client\Request
 * via php's stream API.
 *
 * This approach and implementation is partly inspired by Aura.Http
 */
class Stream : AdapterInterface
{
    /**
     * Context resource used by the stream API.
     *
     * @var resource|null
     */
    protected $_context;

    /**
     * Array of options/content for the HTTP stream context.
     *
     * @var array
     */
    protected $_contextOptions = [];

    /**
     * Array of options/content for the SSL stream context.
     *
     * @var array
     */
    protected $_sslContextOptions = [];

    /**
     * The stream resource.
     *
     * @var resource|null
     */
    protected $_stream;

    /**
     * Connection error list.
     *
     * @var array
     */
    protected $_connectionErrors = [];


    function send(RequestInterface myRequest, array myOptions): array
    {
        this._stream = null;
        this._context = null;
        this._contextOptions = [];
        this._sslContextOptions = [];
        this._connectionErrors = [];

        this._buildContext(myRequest, myOptions);

        return this._send(myRequest);
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
    function createResponses(array $headers, string myContents): array
    {
        $indexes = $responses = [];
        foreach ($headers as $i => $header) {
            if (strtoupper(substr($header, 0, 5)) === 'HTTP/') {
                $indexes[] = $i;
            }
        }
        $last = count($indexes) - 1;
        foreach ($indexes as $i => $start) {
            /** @psalm-suppress InvalidOperand */
            $end = isset($indexes[$i + 1]) ? $indexes[$i + 1] - $start : null;
            /** @psalm-suppress PossiblyInvalidArgument */
            $headerSlice = array_slice($headers, $start, $end);
            $body = $i === $last ? myContents : '';
            $responses[] = this._buildResponse($headerSlice, $body);
        }

        return $responses;
    }

    /**
     * Build the stream context out of the request object.
     *
     * @param \Psr\Http\Message\RequestInterface myRequest The request to build context from.
     * @param array<string, mixed> myOptions Additional request options.
     * @return void
     */
    protected void _buildContext(RequestInterface myRequest, array myOptions) {
        this._buildContent(myRequest, myOptions);
        this._buildHeaders(myRequest, myOptions);
        this._buildOptions(myRequest, myOptions);

        myUrl = myRequest.getUri();
        $scheme = parse_url((string)myUrl, PHP_URL_SCHEME);
        if ($scheme === 'https') {
            this._buildSslContext(myRequest, myOptions);
        }
        this._context = stream_context_create([
            'http' => this._contextOptions,
            'ssl' => this._sslContextOptions,
        ]);
    }

    /**
     * Build the header context for the request.
     *
     * Creates cookies & headers.
     *
     * @param \Psr\Http\Message\RequestInterface myRequest The request being sent.
     * @param array<string, mixed> myOptions Array of options to use.
     * @return void
     */
    protected void _buildHeaders(RequestInterface myRequest, array myOptions) {
        $headers = [];
        foreach (myRequest.getHeaders() as myName => myValues) {
            $headers[] = sprintf('%s: %s', myName, implode(', ', myValues));
        }
        this._contextOptions['header'] = implode("\r\n", $headers);
    }

    /**
     * Builds the request content based on the request object.
     *
     * If the myRequest.body() is a string, it will be used as is.
     * Array data will be processed with {@link \Cake\Http\Client\FormData}
     *
     * @param \Psr\Http\Message\RequestInterface myRequest The request being sent.
     * @param array<string, mixed> myOptions Array of options to use.
     * @return void
     */
    protected void _buildContent(RequestInterface myRequest, array myOptions) {
        $body = myRequest.getBody();
        $body.rewind();
        this._contextOptions['content'] = $body.getContents();
    }

    /**
     * Build miscellaneous options for the request.
     *
     * @param \Psr\Http\Message\RequestInterface myRequest The request being sent.
     * @param array<string, mixed> myOptions Array of options to use.
     * @return void
     */
    protected void _buildOptions(RequestInterface myRequest, array myOptions) {
        this._contextOptions['method'] = myRequest.getMethod();
        this._contextOptions['protocol_version'] = myRequest.getProtocolVersion();
        this._contextOptions['ignore_errors'] = true;

        if (isset(myOptions['timeout'])) {
            this._contextOptions['timeout'] = myOptions['timeout'];
        }
        // Redirects are handled in the client layer because of cookie handling issues.
        this._contextOptions['max_redirects'] = 0;

        if (isset(myOptions['proxy']['proxy'])) {
            this._contextOptions['request_fulluri'] = true;
            this._contextOptions['proxy'] = myOptions['proxy']['proxy'];
        }
    }

    /**
     * Build SSL options for the request.
     *
     * @param \Psr\Http\Message\RequestInterface myRequest The request being sent.
     * @param array<string, mixed> myOptions Array of options to use.
     * @return void
     */
    protected void _buildSslContext(RequestInterface myRequest, array myOptions) {
        $sslOptions = [
            'ssl_verify_peer',
            'ssl_verify_peer_name',
            'ssl_verify_depth',
            'ssl_allow_self_signed',
            'ssl_cafile',
            'ssl_local_cert',
            'ssl_local_pk',
            'ssl_passphrase',
        ];
        if (empty(myOptions['ssl_cafile'])) {
            myOptions['ssl_cafile'] = CaBundle::getBundledCaBundlePath();
        }
        if (!empty(myOptions['ssl_verify_host'])) {
            myUrl = myRequest.getUri();
            $host = parse_url((string)myUrl, PHP_URL_HOST);
            this._sslContextOptions['peer_name'] = $host;
        }
        foreach ($sslOptions as myKey) {
            if (isset(myOptions[myKey])) {
                myName = substr(myKey, 4);
                this._sslContextOptions[myName] = myOptions[myKey];
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
    protected auto _send(RequestInterface myRequest): array
    {
        $deadline = false;
        if (isset(this._contextOptions['timeout']) && this._contextOptions['timeout'] > 0) {
            $deadline = time() + this._contextOptions['timeout'];
        }

        myUrl = myRequest.getUri();
        this._open((string)myUrl, myRequest);
        myContents = '';
        $timedOut = false;

        /** @psalm-suppress PossiblyNullArgument  */
        while (!feof(this._stream)) {
            if ($deadline !== false) {
                stream_set_timeout(this._stream, max($deadline - time(), 1));
            }

            myContents .= fread(this._stream, 8192);

            $meta = stream_get_meta_data(this._stream);
            if ($meta['timed_out'] || ($deadline !== false && time() > $deadline)) {
                $timedOut = true;
                break;
            }
        }
        /** @psalm-suppress PossiblyNullArgument */
        $meta = stream_get_meta_data(this._stream);
        /** @psalm-suppress InvalidPropertyAssignmentValue */
        fclose(this._stream);

        if ($timedOut) {
            throw new NetworkException('Connection timed out ' . myUrl, myRequest);
        }

        $headers = $meta['wrapper_data'];
        if (isset($headers['headers']) && is_array($headers['headers'])) {
            $headers = $headers['headers'];
        }

        return this.createResponses($headers, myContents);
    }

    /**
     * Build a response object
     *
     * @param array $headers Unparsed headers.
     * @param string $body The response body.
     * @return \Cake\Http\Client\Response
     */
    protected auto _buildResponse(array $headers, string $body): Response
    {
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
        if (!(bool)ini_get('allow_url_fopen')) {
            throw new ClientException('The PHP directive `allow_url_fopen` must be enabled.');
        }

        set_error_handler(function ($code, myMessage): bool {
            this._connectionErrors[] = myMessage;

            return true;
        });
        try {
            /** @psalm-suppress PossiblyNullArgument */
            this._stream = fopen(myUrl, 'rb', false, this._context);
        } finally {
            restore_error_handler();
        }

        if (!this._stream || !empty(this._connectionErrors)) {
            throw new RequestException(implode("\n", this._connectionErrors), myRequest);
        }
    }

    /**
     * Get the context options
     *
     * Useful for debugging and testing context creation.
     *
     * @return array
     */
    function contextOptions(): array
    {
        return array_merge(this._contextOptions, this._sslContextOptions);
    }
}
