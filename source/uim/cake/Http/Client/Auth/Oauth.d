module uim.cake.Http\Client\Auth;

import uim.cake.core.Exception\CakeException;
import uim.cake.Http\Client\Request;
import uim.cake.utikities.Security;
use Psr\Http\Message\UriInterface;
use RuntimeException;

/**
 * Oauth 1 authentication strategy for Cake\Http\Client
 *
 * This object does not handle getting Oauth access tokens from the service
 * provider. It only handles make client requests *after* you have obtained the Oauth
 * tokens.
 *
 * Generally not directly constructed, but instead used by {@link \Cake\Http\Client}
 * when myOptions['auth']['type'] is 'oauth'
 */
class Oauth
{
    /**
     * Add headers for Oauth authorization.
     *
     * @param \Cake\Http\Client\Request myRequest The request object.
     * @param array $credentials Authentication credentials.
     * @return \Cake\Http\Client\Request The updated request.
     * @throws \Cake\Core\Exception\CakeException On invalid signature types.
     */
    function authentication(Request myRequest, array $credentials): Request
    {
        if (!isset($credentials['consumerKey'])) {
            return myRequest;
        }
        if (empty($credentials['method'])) {
            $credentials['method'] = 'hmac-sha1';
        }

        $credentials['method'] = strtoupper($credentials['method']);

        switch ($credentials['method']) {
            case 'HMAC-SHA1':
                $hasKeys = isset(
                    $credentials['consumerSecret'],
                    $credentials['token'],
                    $credentials['tokenSecret']
                );
                if (!$hasKeys) {
                    return myRequest;
                }
                myValue = this._hmacSha1(myRequest, $credentials);
                break;

            case 'RSA-SHA1':
                if (!isset($credentials['privateKey'])) {
                    return myRequest;
                }
                myValue = this._rsaSha1(myRequest, $credentials);
                break;

            case 'PLAINTEXT':
                $hasKeys = isset(
                    $credentials['consumerSecret'],
                    $credentials['token'],
                    $credentials['tokenSecret']
                );
                if (!$hasKeys) {
                    return myRequest;
                }
                myValue = this._plaintext(myRequest, $credentials);
                break;

            default:
                throw new CakeException(sprintf('Unknown Oauth signature method %s', $credentials['method']));
        }

        return myRequest.withHeader('Authorization', myValue);
    }

    /**
     * Plaintext signing
     *
     * This method is **not** suitable for plain HTTP.
     * You should only ever use PLAINTEXT when dealing with SSL
     * services.
     *
     * @param \Cake\Http\Client\Request myRequest The request object.
     * @param array $credentials Authentication credentials.
     * @return string Authorization header.
     */
    protected auto _plaintext(Request myRequest, array $credentials): string
    {
        myValues = [
            'oauth_version' => '1.0',
            'oauth_nonce' => uniqid(),
            'oauth_timestamp' => time(),
            'oauth_signature_method' => 'PLAINTEXT',
            'oauth_token' => $credentials['token'],
            'oauth_consumer_key' => $credentials['consumerKey'],
        ];
        if (isset($credentials['realm'])) {
            myValues['oauth_realm'] = $credentials['realm'];
        }
        myKey = [$credentials['consumerSecret'], $credentials['tokenSecret']];
        myKey = implode('&', myKey);
        myValues['oauth_signature'] = myKey;

        return this._buildAuth(myValues);
    }

    /**
     * Use HMAC-SHA1 signing.
     *
     * This method is suitable for plain HTTP or HTTPS.
     *
     * @param \Cake\Http\Client\Request myRequest The request object.
     * @param array $credentials Authentication credentials.
     * @return string
     */
    protected auto _hmacSha1(Request myRequest, array $credentials): string
    {
        $nonce = $credentials['nonce'] ?? uniqid();
        $timestamp = $credentials['timestamp'] ?? time();
        myValues = [
            'oauth_version' => '1.0',
            'oauth_nonce' => $nonce,
            'oauth_timestamp' => $timestamp,
            'oauth_signature_method' => 'HMAC-SHA1',
            'oauth_token' => $credentials['token'],
            'oauth_consumer_key' => this._encode($credentials['consumerKey']),
        ];
        $baseString = this.baseString(myRequest, myValues);

        // Consumer key should only be encoded for base string calculation as
        // auth header generation already encodes independently
        myValues['oauth_consumer_key'] = $credentials['consumerKey'];

        if (isset($credentials['realm'])) {
            myValues['oauth_realm'] = $credentials['realm'];
        }
        myKey = [$credentials['consumerSecret'], $credentials['tokenSecret']];
        myKey = array_map([this, '_encode'], myKey);
        myKey = implode('&', myKey);

        myValues['oauth_signature'] = base64_encode(
            hash_hmac('sha1', $baseString, myKey, true)
        );

        return this._buildAuth(myValues);
    }

    /**
     * Use RSA-SHA1 signing.
     *
     * This method is suitable for plain HTTP or HTTPS.
     *
     * @param \Cake\Http\Client\Request myRequest The request object.
     * @param array $credentials Authentication credentials.
     * @return string
     * @throws \RuntimeException
     */
    protected auto _rsaSha1(Request myRequest, array $credentials): string
    {
        if (!function_exists('openssl_pkey_get_private')) {
            throw new RuntimeException('RSA-SHA1 signature method requires the OpenSSL extension.');
        }

        $nonce = $credentials['nonce'] ?? bin2hex(Security::randomBytes(16));
        $timestamp = $credentials['timestamp'] ?? time();
        myValues = [
            'oauth_version' => '1.0',
            'oauth_nonce' => $nonce,
            'oauth_timestamp' => $timestamp,
            'oauth_signature_method' => 'RSA-SHA1',
            'oauth_consumer_key' => $credentials['consumerKey'],
        ];
        if (isset($credentials['consumerSecret'])) {
            myValues['oauth_consumer_secret'] = $credentials['consumerSecret'];
        }
        if (isset($credentials['token'])) {
            myValues['oauth_token'] = $credentials['token'];
        }
        if (isset($credentials['tokenSecret'])) {
            myValues['oauth_token_secret'] = $credentials['tokenSecret'];
        }
        $baseString = this.baseString(myRequest, myValues);

        if (isset($credentials['realm'])) {
            myValues['oauth_realm'] = $credentials['realm'];
        }

        if (is_resource($credentials['privateKey'])) {
            $resource = $credentials['privateKey'];
            $privateKey = stream_get_contents($resource);
            rewind($resource);
            $credentials['privateKey'] = $privateKey;
        }

        $credentials += [
            'privateKeyPassphrase' => '',
        ];
        if (is_resource($credentials['privateKeyPassphrase'])) {
            $resource = $credentials['privateKeyPassphrase'];
            $passphrase = stream_get_line($resource, 0, PHP_EOL);
            rewind($resource);
            $credentials['privateKeyPassphrase'] = $passphrase;
        }
        $privateKey = openssl_pkey_get_private($credentials['privateKey'], $credentials['privateKeyPassphrase']);
        $signature = '';
        openssl_sign($baseString, $signature, $privateKey);
        if (PHP_MAJOR_VERSION < 8) {
            openssl_free_key($privateKey);
        }

        myValues['oauth_signature'] = base64_encode($signature);

        return this._buildAuth(myValues);
    }

    /**
     * Generate the Oauth basestring
     *
     * - Querystring, request data and oauth_* parameters are combined.
     * - Values are sorted by name and then value.
     * - Request values are concatenated and urlencoded.
     * - The request URL (without querystring) is normalized.
     * - The HTTP method, URL and request parameters are concatenated and returned.
     *
     * @param \Cake\Http\Client\Request myRequest The request object.
     * @param array $oauthValues Oauth values.
     * @return string
     */
    function baseString(Request myRequest, array $oauthValues): string
    {
        $parts = [
            myRequest.getMethod(),
            this._normalizedUrl(myRequest.getUri()),
            this._normalizedParams(myRequest, $oauthValues),
        ];
        $parts = array_map([this, '_encode'], $parts);

        return implode('&', $parts);
    }

    /**
     * Builds a normalized URL
     *
     * Section 9.1.2. of the Oauth spec
     *
     * @param \Psr\Http\Message\UriInterface $uri Uri object to build a normalized version of.
     * @return string Normalized URL
     */
    protected auto _normalizedUrl(UriInterface $uri): string
    {
        $out = $uri.getScheme() . '://';
        $out .= strtolower($uri.getHost());
        $out .= $uri.getPath();

        return $out;
    }

    /**
     * Sorts and normalizes request data and oauthValues
     *
     * Section 9.1.1 of Oauth spec.
     *
     * - URL encode keys + values.
     * - Sort keys & values by byte value.
     *
     * @param \Cake\Http\Client\Request myRequest The request object.
     * @param array $oauthValues Oauth values.
     * @return string sorted and normalized values
     */
    protected auto _normalizedParams(Request myRequest, array $oauthValues): string
    {
        myQuery = parse_url((string)myRequest.getUri(), PHP_URL_QUERY);
        parse_str((string)myQuery, myQueryArgs);

        $post = [];
        myContentsType = myRequest.getHeaderLine('Content-Type');
        if (myContentsType === '' || myContentsType === 'application/x-www-form-urlencoded') {
            parse_str((string)myRequest.getBody(), $post);
        }
        $args = array_merge(myQueryArgs, $oauthValues, $post);
        $pairs = this._normalizeData($args);
        myData = [];
        foreach ($pairs as $pair) {
            myData[] = implode('=', $pair);
        }
        sort(myData, SORT_STRING);

        return implode('&', myData);
    }

    /**
     * Recursively convert request data into the normalized form.
     *
     * @param array $args The arguments to normalize.
     * @param string myPath The current path being converted.
     * @see https://tools.ietf.org/html/rfc5849#section-3.4.1.3.2
     * @return array
     */
    protected auto _normalizeData(array $args, string myPath = ''): array
    {
        myData = [];
        foreach ($args as myKey => myValue) {
            if (myPath) {
                // Fold string keys with [].
                // Numeric keys result in a=b&a=c. While this isn't
                // standard behavior in PHP, it is common in other platforms.
                if (!is_numeric(myKey)) {
                    myKey = "{myPath}[{myKey}]";
                } else {
                    myKey = myPath;
                }
            }
            if (is_array(myValue)) {
                uksort(myValue, 'strcmp');
                myData = array_merge(myData, this._normalizeData(myValue, myKey));
            } else {
                myData[] = [myKey, myValue];
            }
        }

        return myData;
    }

    /**
     * Builds the Oauth Authorization header value.
     *
     * @param array myData The oauth_* values to build
     * @return string
     */
    protected auto _buildAuth(array myData): string
    {
        $out = 'OAuth ';
        myParams = [];
        foreach (myData as myKey => myValue) {
            myParams[] = myKey . '="' . this._encode((string)myValue) . '"';
        }
        $out .= implode(',', myParams);

        return $out;
    }

    /**
     * URL Encodes a value based on rules of rfc3986
     *
     * @param string myValue Value to encode.
     * @return string
     */
    protected auto _encode(string myValue): string
    {
        return str_replace(['%7E', '+'], ['~', ' '], rawurlencode(myValue));
    }
}
