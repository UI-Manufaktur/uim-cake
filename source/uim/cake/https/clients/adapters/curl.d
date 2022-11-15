

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.7.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.https.clients.adapters;

import uim.cake.https.clients.adaptersInterface;
import uim.cake.https.clients\Exception\ClientException;
import uim.cake.https.clients\Exception\NetworkException;
import uim.cake.https.clients\Exception\RequestException;
import uim.cake.https.clients\Request;
import uim.cake.https.clients\Response;
import uim.cake.https\Exception\HttpException;
use Composer\CaBundle\CaBundle;
use Psr\Http\Message\RequestInterface;

/**
 * : sending Cake\Http\Client\Request via ext/curl.
 *
 * In addition to the standard options documented in {@link \Cake\Http\Client},
 * this adapter supports all available curl options. Additional curl options
 * can be set via the `curl` option key when making requests or configuring
 * a client.
 */
class Curl : AdapterInterface
{

    function send(RequestInterface myRequest, array myOptions): array
    {
        if (!extension_loaded("curl")) {
            throw new ClientException("curl extension is not loaded.");
        }

        $ch = curl_init();
        myOptions = this.buildOptions(myRequest, myOptions);
        curl_setopt_array($ch, myOptions);

        /** @var string|false $body */
        $body = this.exec($ch);
        if ($body === false) {
            myErrorCode = curl_errno($ch);
            myError = curl_error($ch);
            curl_close($ch);

            myMessage = "cURL Error ({myErrorCode}) {myError}";
            myErrorNumbers = [
                CURLE_FAILED_INIT,
                CURLE_URL_MALFORMAT,
                CURLE_URL_MALFORMAT_USER,
            ];
            if (in_array(myErrorCode, myErrorNumbers, true)) {
                throw new RequestException(myMessage, myRequest);
            }
            throw new NetworkException(myMessage, myRequest);
        }

        $responses = this.createResponse($ch, $body);
        curl_close($ch);

        return $responses;
    }

    /**
     * Convert client options into curl options.
     *
     * @param \Psr\Http\Message\RequestInterface myRequest The request.
     * @param array<string, mixed> myOptions The client options
     * @return array
     */
    function buildOptions(RequestInterface myRequest, array myOptions): array
    {
        $headers = [];
        foreach (myRequest.getHeaders() as myKey => myValues) {
            $headers[] = myKey . ": " . implode(", ", myValues);
        }

        $out = [
            CURLOPT_URL => (string)myRequest.getUri(),
            CURLOPT_HTTP_VERSION => this.getProtocolVersion(myRequest),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HEADER => true,
            CURLOPT_HTTPHEADER => $headers,
        ];
        switch (myRequest.getMethod()) {
            case Request::METHOD_GET:
                $out[CURLOPT_HTTPGET] = true;
                break;

            case Request::METHOD_POST:
                $out[CURLOPT_POST] = true;
                break;

            case Request::METHOD_HEAD:
                $out[CURLOPT_NOBODY] = true;
                break;

            default:
                $out[CURLOPT_POST] = true;
                $out[CURLOPT_CUSTOMREQUEST] = myRequest.getMethod();
                break;
        }

        $body = myRequest.getBody();
        $body.rewind();
        $out[CURLOPT_POSTFIELDS] = $body.getContents();
        // GET requests with bodies require custom request to be used.
        if ($out[CURLOPT_POSTFIELDS] !== "" && isset($out[CURLOPT_HTTPGET])) {
            $out[CURLOPT_CUSTOMREQUEST] = "get";
        }
        if ($out[CURLOPT_POSTFIELDS] == "") {
            unset($out[CURLOPT_POSTFIELDS]);
        }

        if (empty(myOptions["ssl_cafile"])) {
            myOptions["ssl_cafile"] = CaBundle::getBundledCaBundlePath();
        }
        if (!empty(myOptions["ssl_verify_host"])) {
            // Value of 1 or true is deprecated. Only 2 or 0 should be used now.
            myOptions["ssl_verify_host"] = 2;
        }
        $optionMap = [
            "timeout" => CURLOPT_TIMEOUT,
            "ssl_verify_peer" => CURLOPT_SSL_VERIFYPEER,
            "ssl_verify_host" => CURLOPT_SSL_VERIFYHOST,
            "ssl_cafile" => CURLOPT_CAINFO,
            "ssl_local_cert" => CURLOPT_SSLCERT,
            "ssl_passphrase" => CURLOPT_SSLCERTPASSWD,
        ];
        foreach ($optionMap as $option => $curlOpt) {
            if (isset(myOptions[$option])) {
                $out[$curlOpt] = myOptions[$option];
            }
        }
        if (isset(myOptions["proxy"]["proxy"])) {
            $out[CURLOPT_PROXY] = myOptions["proxy"]["proxy"];
        }
        if (isset(myOptions["proxy"]["username"])) {
            myPassword = !empty(myOptions["proxy"]["password"]) ? myOptions["proxy"]["password"] : "";
            $out[CURLOPT_PROXYUSERPWD] = myOptions["proxy"]["username"] . ":" . myPassword;
        }
        if (isset(myOptions["curl"]) && is_array(myOptions["curl"])) {
            // Can"t use array_merge() because keys will be re-ordered.
            foreach (myOptions["curl"] as myKey => myValue) {
                $out[myKey] = myValue;
            }
        }

        return $out;
    }

    /**
     * Convert HTTP version number into curl value.
     *
     * @param \Psr\Http\Message\RequestInterface myRequest The request to get a protocol version for.
     * @return int
     */
    protected int getProtocolVersion(RequestInterface myRequest) {
        switch (myRequest.getProtocolVersion()) {
            case "1.0":
                return CURL_HTTP_VERSION_1_0;
            case "1.1":
                return CURL_HTTP_VERSION_1_1;
            case "2":
            case "2.0":
                if (defined("CURL_HTTP_VERSION_2TLS")) {
                    return CURL_HTTP_VERSION_2TLS;
                }
                if (defined("CURL_HTTP_VERSION_2_0")) {
                    return CURL_HTTP_VERSION_2_0;
                }
                throw new HttpException("libcurl 7.33 or greater required for HTTP/2 support");
        }

        return CURL_HTTP_VERSION_NONE;
    }

    /**
     * Convert the raw curl response into an Http\Client\Response
     *
     * @param resource|\CurlHandle $handle Curl handle
     * @param string $responseData string The response data from curl_exec
     * @return array<\Cake\Http\Client\Response>
     * @psalm-suppress UndefinedDocblockClass
     */
    protected auto createResponse($handle, $responseData): array
    {
        /** @psalm-suppress PossiblyInvalidArgument */
        $headerSize = curl_getinfo($handle, CURLINFO_HEADER_SIZE);
        $headers = trim(substr($responseData, 0, $headerSize));
        $body = substr($responseData, $headerSize);
        $response = new Response(explode("\r\n", $headers), $body);

        return [$response];
    }

    /**
     * Execute the curl handle.
     *
     * @param resource|\CurlHandle $ch Curl Resource handle
     * @return string|bool
     * @psalm-suppress UndefinedDocblockClass
     */
    protected auto exec($ch) {
        /** @psalm-suppress PossiblyInvalidArgument */
        return curl_exec($ch);
    }
}
