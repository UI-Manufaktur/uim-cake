module uim.cake.http.clients\Auth;

@safe:
import uim.cake;

/**
 * Basic authentication adapter for Cake\Http\Client
 *
 * Generally not directly constructed, but instead used by {@link uim.cake.Http\Client}
 * when $options["auth"]["type"] is "basic"
 */
class Basic
{
    /**
     * Add Authorization header to the request.
     *
     * @param uim.cake.http.Client\Request $request Request instance.
     * @param array $credentials Credentials.
     * @return uim.cake.http.Client\Request The updated request.
     * @see https://www.ietf.org/rfc/rfc2617.txt
     */
    function authentication(Request $request, array $credentials): Request
    {
        if (isset($credentials["username"], $credentials["password"])) {
            $value = _generateHeader($credentials["username"], $credentials["password"]);
            /** @var uim.cake.http.Client\Request $request */
            $request = $request.withHeader("Authorization", $value);
        }

        return $request;
    }

    /**
     * Proxy Authentication
     *
     * @param uim.cake.http.Client\Request $request Request instance.
     * @param array $credentials Credentials.
     * @return uim.cake.http.Client\Request The updated request.
     * @see https://www.ietf.org/rfc/rfc2617.txt
     */
    function proxyAuthentication(Request $request, array $credentials): Request
    {
        if (isset($credentials["username"], $credentials["password"])) {
            $value = _generateHeader($credentials["username"], $credentials["password"]);
            /** @var uim.cake.http.Client\Request $request */
            $request = $request.withHeader("Proxy-Authorization", $value);
        }

        return $request;
    }

    /**
     * Generate basic [proxy] authentication header
     *
     * @param string $user Username.
     * @param string $pass Password.
     */
    protected string _generateHeader(string $user, string $pass) {
        return "Basic " ~ base64_encode($user ~ ":" ~ $pass);
    }
}
