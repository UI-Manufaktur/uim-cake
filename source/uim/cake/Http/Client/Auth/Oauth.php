

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.http.Client\Auth;

import uim.cake.core.exceptions.CakeException;
import uim.cake.http.Client\Request;
import uim.cake.utilities.Security;
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
 * when $options["auth"]["type"] is "oauth"
 */
class Oauth
{
    /**
     * Add headers for Oauth authorization.
     *
     * @param uim.cake.http.Client\Request $request The request object.
     * @param array $credentials Authentication credentials.
     * @return uim.cake.http.Client\Request The updated request.
     * @throws uim.cake.Core\Exception\CakeException On invalid signature types.
     */
    function authentication(Request $request, array $credentials): Request
    {
        if (!isset($credentials["consumerKey"])) {
            return $request;
        }
        if (empty($credentials["method"])) {
            $credentials["method"] = "hmac-sha1";
        }

        $credentials["method"] = strtoupper($credentials["method"]);

        switch ($credentials["method"]) {
            case "HMAC-SHA1":
                $hasKeys = isset(
                    $credentials["consumerSecret"],
                    $credentials["token"],
                    $credentials["tokenSecret"]
                );
                if (!$hasKeys) {
                    return $request;
                }
                $value = _hmacSha1($request, $credentials);
                break;

            case "RSA-SHA1":
                if (!isset($credentials["privateKey"])) {
                    return $request;
                }
                $value = _rsaSha1($request, $credentials);
                break;

            case "PLAINTEXT":
                $hasKeys = isset(
                    $credentials["consumerSecret"],
                    $credentials["token"],
                    $credentials["tokenSecret"]
                );
                if (!$hasKeys) {
                    return $request;
                }
                $value = _plaintext($request, $credentials);
                break;

            default:
                throw new CakeException(sprintf("Unknown Oauth signature method %s", $credentials["method"]));
        }

        return $request.withHeader("Authorization", $value);
    }

    /**
     * Plaintext signing
     *
     * This method is **not** suitable for plain HTTP.
     * You should only ever use PLAINTEXT when dealing with SSL
     * services.
     *
     * @param uim.cake.http.Client\Request $request The request object.
     * @param array $credentials Authentication credentials.
     * @return string Authorization header.
     */
    protected function _plaintext(Request $request, array $credentials): string
    {
        $values = [
            "oauth_version": "1.0",
            "oauth_nonce": uniqid(),
            "oauth_timestamp": time(),
            "oauth_signature_method": "PLAINTEXT",
            "oauth_token": $credentials["token"],
            "oauth_consumer_key": $credentials["consumerKey"],
        ];
        if (isset($credentials["realm"])) {
            $values["oauth_realm"] = $credentials["realm"];
        }
        $key = [$credentials["consumerSecret"], $credentials["tokenSecret"]];
        $key = implode("&", $key);
        $values["oauth_signature"] = $key;

        return _buildAuth($values);
    }

    /**
     * Use HMAC-SHA1 signing.
     *
     * This method is suitable for plain HTTP or HTTPS.
     *
     * @param uim.cake.http.Client\Request $request The request object.
     * @param array $credentials Authentication credentials.
     * @return string
     */
    protected function _hmacSha1(Request $request, array $credentials): string
    {
        $nonce = $credentials["nonce"] ?? uniqid();
        $timestamp = $credentials["timestamp"] ?? time();
        $values = [
            "oauth_version": "1.0",
            "oauth_nonce": $nonce,
            "oauth_timestamp": $timestamp,
            "oauth_signature_method": "HMAC-SHA1",
            "oauth_token": $credentials["token"],
            "oauth_consumer_key": _encode($credentials["consumerKey"]),
        ];
        $baseString = this.baseString($request, $values);

        // Consumer key should only be encoded for base string calculation as
        // auth header generation already encodes independently
        $values["oauth_consumer_key"] = $credentials["consumerKey"];

        if (isset($credentials["realm"])) {
            $values["oauth_realm"] = $credentials["realm"];
        }
        $key = [$credentials["consumerSecret"], $credentials["tokenSecret"]];
        $key = array_map([this, "_encode"], $key);
        $key = implode("&", $key);

        $values["oauth_signature"] = base64_encode(
            hash_hmac("sha1", $baseString, $key, true)
        );

        return _buildAuth($values);
    }

    /**
     * Use RSA-SHA1 signing.
     *
     * This method is suitable for plain HTTP or HTTPS.
     *
     * @param uim.cake.http.Client\Request $request The request object.
     * @param array $credentials Authentication credentials.
     * @return string
     * @throws \RuntimeException
     */
    protected function _rsaSha1(Request $request, array $credentials): string
    {
        if (!function_exists("openssl_pkey_get_private")) {
            throw new RuntimeException("RSA-SHA1 signature method requires the OpenSSL extension.");
        }

        $nonce = $credentials["nonce"] ?? bin2hex(Security::randomBytes(16));
        $timestamp = $credentials["timestamp"] ?? time();
        $values = [
            "oauth_version": "1.0",
            "oauth_nonce": $nonce,
            "oauth_timestamp": $timestamp,
            "oauth_signature_method": "RSA-SHA1",
            "oauth_consumer_key": $credentials["consumerKey"],
        ];
        if (isset($credentials["consumerSecret"])) {
            $values["oauth_consumer_secret"] = $credentials["consumerSecret"];
        }
        if (isset($credentials["token"])) {
            $values["oauth_token"] = $credentials["token"];
        }
        if (isset($credentials["tokenSecret"])) {
            $values["oauth_token_secret"] = $credentials["tokenSecret"];
        }
        $baseString = this.baseString($request, $values);

        if (isset($credentials["realm"])) {
            $values["oauth_realm"] = $credentials["realm"];
        }

        if (is_resource($credentials["privateKey"])) {
            $resource = $credentials["privateKey"];
            $privateKey = stream_get_contents($resource);
            rewind($resource);
            $credentials["privateKey"] = $privateKey;
        }

        $credentials += [
            "privateKeyPassphrase": "",
        ];
        if (is_resource($credentials["privateKeyPassphrase"])) {
            $resource = $credentials["privateKeyPassphrase"];
            $passphrase = stream_get_line($resource, 0, PHP_EOL);
            rewind($resource);
            $credentials["privateKeyPassphrase"] = $passphrase;
        }
        $privateKey = openssl_pkey_get_private($credentials["privateKey"], $credentials["privateKeyPassphrase"]);
        this.checkSslError();

        $signature = "";
        openssl_sign($baseString, $signature, $privateKey);
        this.checkSslError();

        if (PHP_MAJOR_VERSION < 8) {
            openssl_free_key($privateKey);
        }

        $values["oauth_signature"] = base64_encode($signature);

        return _buildAuth($values);
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
     * @param uim.cake.http.Client\Request $request The request object.
     * @param array $oauthValues Oauth values.
     * @return string
     */
    function baseString(Request $request, array $oauthValues): string
    {
        $parts = [
            $request.getMethod(),
            _normalizedUrl($request.getUri()),
            _normalizedParams($request, $oauthValues),
        ];
        $parts = array_map([this, "_encode"], $parts);

        return implode("&", $parts);
    }

    /**
     * Builds a normalized URL
     *
     * Section 9.1.2. of the Oauth spec
     *
     * @param \Psr\Http\Message\UriInterface $uri Uri object to build a normalized version of.
     * @return string Normalized URL
     */
    protected function _normalizedUrl(UriInterface $uri): string
    {
        $out = $uri.getScheme() . "://";
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
     * @param uim.cake.http.Client\Request $request The request object.
     * @param array $oauthValues Oauth values.
     * @return string sorted and normalized values
     */
    protected function _normalizedParams(Request $request, array $oauthValues): string
    {
        $query = parse_url((string)$request.getUri(), PHP_URL_QUERY);
        parse_str((string)$query, $queryArgs);

        $post = [];
        $contentType = $request.getHeaderLine("Content-Type");
        if ($contentType == "" || $contentType == "application/x-www-form-urlencoded") {
            parse_str((string)$request.getBody(), $post);
        }
        $args = array_merge($queryArgs, $oauthValues, $post);
        $pairs = _normalizeData($args);
        $data = [];
        foreach ($pairs as $pair) {
            $data[] = implode("=", $pair);
        }
        sort($data, SORT_STRING);

        return implode("&", $data);
    }

    /**
     * Recursively convert request data into the normalized form.
     *
     * @param array $args The arguments to normalize.
     * @param string $path The current path being converted.
     * @see https://tools.ietf.org/html/rfc5849#section-3.4.1.3.2
     * @return array
     */
    protected function _normalizeData(array $args, string $path = ""): array
    {
        $data = [];
        foreach ($args as $key: $value) {
            if ($path) {
                // Fold string keys with [].
                // Numeric keys result in a=b&a=c. While this isn"t
                // standard behavior in PHP, it is common in other platforms.
                if (!is_numeric($key)) {
                    $key = "{$path}[{$key}]";
                } else {
                    $key = $path;
                }
            }
            if (is_array($value)) {
                uksort($value, "strcmp");
                $data = array_merge($data, _normalizeData($value, $key));
            } else {
                $data[] = [$key, $value];
            }
        }

        return $data;
    }

    /**
     * Builds the Oauth Authorization header value.
     *
     * @param array $data The oauth_* values to build
     * @return string
     */
    protected function _buildAuth(array $data): string
    {
        $out = "OAuth ";
        $params = [];
        foreach ($data as $key: $value) {
            $params[] = $key . "="" . _encode((string)$value) . """;
        }
        $out .= implode(",", $params);

        return $out;
    }

    /**
     * URL Encodes a value based on rules of rfc3986
     *
     * @param string $value Value to encode.
     * @return string
     */
    protected function _encode(string $value): string
    {
        return str_replace(["%7E", "+"], ["~", " "], rawurlencode($value));
    }

    /**
     * Check for SSL errors and raise if one is encountered.
     *
     * @return void
     */
    protected function checkSslError(): void
    {
        $error = "";
        while ($text = openssl_error_string()) {
            $error .= $text;
        }

        if (strlen($error) > 0) {
            throw new RuntimeException("openssl error: " . $error);
        }
    }
}
