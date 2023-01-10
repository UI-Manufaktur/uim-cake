module uim.cake.http.Client\Auth;

import uim.cake.http.Client;
import uim.cake.http.Client\Request;

/**
 * Digest authentication adapter for Cake\Http\Client
 *
 * Generally not directly constructed, but instead used by {@link uim.cake.Http\Client}
 * when $options["auth"]["type"] is "digest"
 */
class Digest
{
    /**
     * Instance of Cake\Http\Client
     *
     * @var uim.cake.http.Client
     */
    protected _client;

    /**
     * Constructor
     *
     * @param uim.cake.http.Client $client Http client object.
     * @param array|null $options Options list.
     */
    this(Client $client, ?STRINGAA someOptions = null) {
        _client = $client;
    }

    /**
     * Add Authorization header to the request.
     *
     * @param uim.cake.http.Client\Request $request The request object.
     * @param array<string, mixed> $credentials Authentication credentials.
     * @return uim.cake.http.Client\Request The updated request.
     * @see https://www.ietf.org/rfc/rfc2617.txt
     */
    function authentication(Request $request, array $credentials): Request
    {
        if (!isset($credentials["username"], $credentials["password"])) {
            return $request;
        }
        if (!isset($credentials["realm"])) {
            $credentials = _getServerInfo($request, $credentials);
        }
        if (!isset($credentials["realm"])) {
            return $request;
        }
        $value = _generateHeader($request, $credentials);

        return $request.withHeader("Authorization", $value);
    }

    /**
     * Retrieve information about the authentication
     *
     * Will get the realm and other tokens by performing
     * another request without authentication to get authentication
     * challenge.
     *
     * @param uim.cake.http.Client\Request $request The request object.
     * @param array $credentials Authentication credentials.
     * @return array modified credentials.
     */
    protected array _getServerInfo(Request $request, array $credentials) {
        $response = _client.get(
            (string)$request.getUri(),
            [],
            ["auth": ["type": null]]
        );

        if (!$response.getHeader("WWW-Authenticate")) {
            return [];
        }
        preg_match_all(
            "@(\w+)=(?:(?:")([^"]+)"|([^\s,$]+))@",
            $response.getHeaderLine("WWW-Authenticate"),
            $matches,
            PREG_SET_ORDER
        );
        foreach ($matches as $match) {
            $credentials[$match[1]] = $match[2];
        }
        if (!empty($credentials["qop"]) && empty($credentials["nc"])) {
            $credentials["nc"] = 1;
        }

        return $credentials;
    }

    /**
     * Generate the header Authorization
     *
     * @param uim.cake.http.Client\Request $request The request object.
     * @param array<string, mixed> $credentials Authentication credentials.
     */
    protected string _generateHeader(Request $request, array $credentials) {
        $path = $request.getUri().getPath();
        $a1 = md5($credentials["username"] ~ ":" ~ $credentials["realm"] ~ ":" ~ $credentials["password"]);
        $a2 = md5($request.getMethod() ~ ":" ~ $path);
        $nc = "";

        if (empty($credentials["qop"])) {
            $response = md5($a1 ~ ":" ~ $credentials["nonce"] ~ ":" ~ $a2);
        } else {
            $credentials["cnonce"] = uniqid();
            $nc = sprintf("%08x", $credentials["nc"]++);
            $response = md5(
                $a1 ~ ":" ~ $credentials["nonce"] ~ ":" ~ $nc ~ ":" ~ $credentials["cnonce"] ~ ":auth:" ~ $a2
            );
        }

        $authHeader = "Digest ";
        $authHeader ~= "username="" ~ replace(["\\", """], ["\\\\", "\\""], $credentials["username"]) ~ "", ";
        $authHeader ~= "realm="" ~ $credentials["realm"] ~ "", ";
        $authHeader ~= "nonce="" ~ $credentials["nonce"] ~ "", ";
        $authHeader ~= "uri="" ~ $path ~ "", ";
        $authHeader ~= "response="" ~ $response ~ """;
        if (!empty($credentials["opaque"])) {
            $authHeader ~= ", opaque="" ~ $credentials["opaque"] ~ """;
        }
        if (!empty($credentials["qop"])) {
            $authHeader ~= ", qop="auth", nc=" ~ $nc ~ ", cnonce="" ~ $credentials["cnonce"] ~ """;
        }

        return $authHeader;
    }
}
