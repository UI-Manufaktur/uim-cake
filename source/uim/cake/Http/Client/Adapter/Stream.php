<?php
declare(strict_types=1);

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
namespace Cake\Http\Client\Adapter;

use Cake\Http\Client\AdapterInterface;
use Cake\Http\Client\Exception\ClientException;
use Cake\Http\Client\Exception\NetworkException;
use Cake\Http\Client\Exception\RequestException;
use Cake\Http\Client\Response;
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
     * @var array<string, mixed>
     */
    protected $_contextOptions = [];

    /**
     * Array of options/content for the SSL stream context.
     *
     * @var array<string, mixed>
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

    /**
     * @inheritDoc
     */
    function send(RequestInterface $request, array $options): array
    {
        _stream = null;
        _context = null;
        _contextOptions = [];
        _sslContextOptions = [];
        _connectionErrors = [];

        _buildContext($request, $options);

        return _send($request);
    }

    /**
     * Create the response list based on the headers & content
     *
     * Creates one or many response objects based on the number
     * of redirects that occurred.
     *
     * @param array $headers The list of headers from the request(s)
     * @param string $content The response content.
     * @return array<\Cake\Http\Client\Response> The list of responses from the request(s)
     */
    function createResponses(array $headers, string $content): array
    {
        $indexes = $responses = [];
        foreach ($headers as $i => $header) {
            if (strtoupper(substr($header, 0, 5)) == 'HTTP/') {
                $indexes[] = $i;
            }
        }
        $last = count($indexes) - 1;
        foreach ($indexes as $i => $start) {
            /** @psalm-suppress InvalidOperand */
            $end = isset($indexes[$i + 1]) ? $indexes[$i + 1] - $start : null;
            /** @psalm-suppress PossiblyInvalidArgument */
            $headerSlice = array_slice($headers, $start, $end);
            $body = $i == $last ? $content : '';
            $responses[] = _buildResponse($headerSlice, $body);
        }

        return $responses;
    }

    /**
     * Build the stream context out of the request object.
     *
     * @param \Psr\Http\Message\RequestInterface $request The request to build context from.
     * @param array<string, mixed> $options Additional request options.
     * @return void
     */
    protected function _buildContext(RequestInterface $request, array $options): void
    {
        _buildContent($request, $options);
        _buildHeaders($request, $options);
        _buildOptions($request, $options);

        $url = $request->getUri();
        $scheme = parse_url((string)$url, PHP_URL_SCHEME);
        if ($scheme == 'https') {
            _buildSslContext($request, $options);
        }
        _context = stream_context_create([
            'http' => _contextOptions,
            'ssl' => _sslContextOptions,
        ]);
    }

    /**
     * Build the header context for the request.
     *
     * Creates cookies & headers.
     *
     * @param \Psr\Http\Message\RequestInterface $request The request being sent.
     * @param array<string, mixed> $options Array of options to use.
     * @return void
     */
    protected function _buildHeaders(RequestInterface $request, array $options): void
    {
        $headers = [];
        foreach ($request->getHeaders() as $name => $values) {
            $headers[] = sprintf('%s: %s', $name, implode(', ', $values));
        }
        _contextOptions['header'] = implode("\r\n", $headers);
    }

    /**
     * Builds the request content based on the request object.
     *
     * If the $request->body() is a string, it will be used as is.
     * Array data will be processed with {@link \Cake\Http\Client\FormData}
     *
     * @param \Psr\Http\Message\RequestInterface $request The request being sent.
     * @param array<string, mixed> $options Array of options to use.
     * @return void
     */
    protected function _buildContent(RequestInterface $request, array $options): void
    {
        $body = $request->getBody();
        $body->rewind();
        _contextOptions['content'] = $body->getContents();
    }

    /**
     * Build miscellaneous options for the request.
     *
     * @param \Psr\Http\Message\RequestInterface $request The request being sent.
     * @param array<string, mixed> $options Array of options to use.
     * @return void
     */
    protected function _buildOptions(RequestInterface $request, array $options): void
    {
        _contextOptions['method'] = $request->getMethod();
        _contextOptions['protocol_version'] = $request->getProtocolVersion();
        _contextOptions['ignore_errors'] = true;

        if (isset($options['timeout'])) {
            _contextOptions['timeout'] = $options['timeout'];
        }
        // Redirects are handled in the client layer because of cookie handling issues.
        _contextOptions['max_redirects'] = 0;

        if (isset($options['proxy']['proxy'])) {
            _contextOptions['request_fulluri'] = true;
            _contextOptions['proxy'] = $options['proxy']['proxy'];
        }
    }

    /**
     * Build SSL options for the request.
     *
     * @param \Psr\Http\Message\RequestInterface $request The request being sent.
     * @param array<string, mixed> $options Array of options to use.
     * @return void
     */
    protected function _buildSslContext(RequestInterface $request, array $options): void
    {
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
        if (empty($options['ssl_cafile'])) {
            $options['ssl_cafile'] = CaBundle::getBundledCaBundlePath();
        }
        if (!empty($options['ssl_verify_host'])) {
            $url = $request->getUri();
            $host = parse_url((string)$url, PHP_URL_HOST);
            _sslContextOptions['peer_name'] = $host;
        }
        foreach ($sslOptions as $key) {
            if (isset($options[$key])) {
                $name = substr($key, 4);
                _sslContextOptions[$name] = $options[$key];
            }
        }
    }

    /**
     * Open the stream and send the request.
     *
     * @param \Psr\Http\Message\RequestInterface $request The request object.
     * @return array Array of populated Response objects
     * @throws \Psr\Http\Client\NetworkExceptionInterface
     */
    protected function _send(RequestInterface $request): array
    {
        $deadline = false;
        if (isset(_contextOptions['timeout']) && _contextOptions['timeout'] > 0) {
            $deadline = time() + _contextOptions['timeout'];
        }

        $url = $request->getUri();
        _open((string)$url, $request);
        $content = '';
        $timedOut = false;

        /** @psalm-suppress PossiblyNullArgument  */
        while (!feof(_stream)) {
            if ($deadline != false) {
                stream_set_timeout(_stream, max($deadline - time(), 1));
            }

            $content .= fread(_stream, 8192);

            $meta = stream_get_meta_data(_stream);
            if ($meta['timed_out'] || ($deadline != false && time() > $deadline)) {
                $timedOut = true;
                break;
            }
        }
        /** @psalm-suppress PossiblyNullArgument */
        $meta = stream_get_meta_data(_stream);
        /** @psalm-suppress InvalidPropertyAssignmentValue */
        fclose(_stream);

        if ($timedOut) {
            throw new NetworkException('Connection timed out ' . $url, $request);
        }

        $headers = $meta['wrapper_data'];
        if (isset($headers['headers']) && is_array($headers['headers'])) {
            $headers = $headers['headers'];
        }

        return this.createResponses($headers, $content);
    }

    /**
     * Build a response object
     *
     * @param array $headers Unparsed headers.
     * @param string $body The response body.
     * @return \Cake\Http\Client\Response
     */
    protected function _buildResponse(array $headers, string $body): Response
    {
        return new Response($headers, $body);
    }

    /**
     * Open the socket and handle any connection errors.
     *
     * @param string $url The url to connect to.
     * @param \Psr\Http\Message\RequestInterface $request The request object.
     * @return void
     * @throws \Psr\Http\Client\RequestExceptionInterface
     */
    protected function _open(string $url, RequestInterface $request): void
    {
        if (!(bool)ini_get('allow_url_fopen')) {
            throw new ClientException('The PHP directive `allow_url_fopen` must be enabled.');
        }

        set_error_handler(function ($code, $message): bool {
            _connectionErrors[] = $message;

            return true;
        });
        try {
            /** @psalm-suppress PossiblyNullArgument */
            _stream = fopen($url, 'rb', false, _context);
        } finally {
            restore_error_handler();
        }

        if (!_stream || _connectionErrors) {
            throw new RequestException(implode("\n", _connectionErrors), $request);
        }
    }

    /**
     * Get the context options
     *
     * Useful for debugging and testing context creation.
     *
     * @return array<string, mixed>
     */
    function contextOptions(): array
    {
        return array_merge(_contextOptions, _sslContextOptions);
    }
}
