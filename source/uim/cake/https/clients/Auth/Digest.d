module uim.cake.http.clients\Auth;

@safe:
import uim.cake;

/**
 * Digest authentication adapter for Cake\Http\Client
 *
 * Generally not directly constructed, but instead used by {@link uim.cake.Http\Client}
 * when myOptions["auth"]["type"] is "digest"
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
     * @param array|null myOptions Options list.
     */
    this(Client $client, ?array myOptions = null) {
        _client = $client;
    }

    /**
     * Add Authorization header to the request.
     *
     * @param uim.cake.http.Client\Request myRequest The request object.
     * @param array<string, mixed> $credentials Authentication credentials.
     * @return uim.cake.http.Client\Request The updated request.
     * @see https://www.ietf.org/rfc/rfc2617.txt
     */
    function authentication(Request myRequest, array $credentials): Request
    {
        if (!isset($credentials["username"], $credentials["password"])) {
            return myRequest;
        }
        if (!isset($credentials["realm"])) {
            $credentials = _getServerInfo(myRequest, $credentials);
        }
        if (!isset($credentials["realm"])) {
            return myRequest;
        }
        myValue = _generateHeader(myRequest, $credentials);

        return myRequest.withHeader("Authorization", myValue);
    }

    /**
     * Retrieve information about the authentication
     *
     * Will get the realm and other tokens by performing
     * another request without authentication to get authentication
     * challenge.
     *
     * @param uim.cake.http.Client\Request myRequest The request object.
     * @param array $credentials Authentication credentials.
     * @return array modified credentials.
     */
    protected auto _getServerInfo(Request myRequest, array $credentials): array
    {
        $response = _client.get(
            (string)myRequest.getUri(),
            [],
            ["auth":["type":null]]
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
     * @param uim.cake.http.Client\Request myRequest The request object.
     * @param array<string, mixed> $credentials Authentication credentials.
     * @return string
     */
    protected string _generateHeader(Request myRequest, array $credentials) {
        myPath = myRequest.getUri().getPath();
        $a1 = md5($credentials["username"] . ":" . $credentials["realm"] . ":" . $credentials["password"]);
        $a2 = md5(myRequest.getMethod() . ":" . myPath);
        $nc = "";

        if (empty($credentials["qop"])) {
            $response = md5($a1 . ":" . $credentials["nonce"] . ":" . $a2);
        } else {
            $credentials["cnonce"] = uniqid();
            $nc = sprintf("%08x", $credentials["nc"]++);
            $response = md5(
                $a1 . ":" . $credentials["nonce"] . ":" . $nc . ":" . $credentials["cnonce"] . ":auth:" . $a2
            );
        }

        $authHeader = "Digest ";
        $authHeader .= "username="" . str_replace(["\\", """], ["\\\\", "\\""], $credentials["username"]) . "", ";
        $authHeader .= "realm="" . $credentials["realm"] . "", ";
        $authHeader .= "nonce="" . $credentials["nonce"] . "", ";
        $authHeader .= "uri="" . myPath . "", ";
        $authHeader .= "response="" . $response . """;
        if (!empty($credentials["opaque"])) {
            $authHeader .= ", opaque="" . $credentials["opaque"] . """;
        }
        if (!empty($credentials["qop"])) {
            $authHeader .= ", qop="auth", nc=" . $nc . ", cnonce="" . $credentials["cnonce"] . """;
        }

        return $authHeader;
    }
}
