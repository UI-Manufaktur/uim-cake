module uim.cake.http.clients\Auth;

@safe:
import uim.cake;

/**
 * Basic authentication adapter for Cake\Http\Client
 *
 * Generally not directly constructed, but instead used by {@link uim.cake.Http\Client}
 * when myOptions["auth"]["type"] is "basic"
 */
class Basic
{
    /**
     * Add Authorization header to the request.
     *
     * @param uim.cake.http.Client\Request myRequest Request instance.
     * @param array $credentials Credentials.
     * @return uim.cake.http.Client\Request The updated request.
     * @see https://www.ietf.org/rfc/rfc2617.txt
     */
    function authentication(Request myRequest, array $credentials): Request
    {
        if (isset($credentials["username"], $credentials["password"])) {
            myValue = _generateHeader($credentials["username"], $credentials["password"]);
            /** @var uim.cake.http.Client\Request myRequest */
            myRequest = myRequest.withHeader("Authorization", myValue);
        }

        return myRequest;
    }

    /**
     * Proxy Authentication
     *
     * @param uim.cake.http.Client\Request myRequest Request instance.
     * @param array $credentials Credentials.
     * @return uim.cake.http.Client\Request The updated request.
     * @see https://www.ietf.org/rfc/rfc2617.txt
     */
    function proxyAuthentication(Request myRequest, array $credentials): Request
    {
        if (isset($credentials["username"], $credentials["password"])) {
            myValue = _generateHeader($credentials["username"], $credentials["password"]);
            /** @var uim.cake.http.Client\Request myRequest */
            myRequest = myRequest.withHeader("Proxy-Authorization", myValue);
        }

        return myRequest;
    }

    /**
     * Generate basic [proxy] authentication header
     *
     * @param string myUser Username.
     * @param string pass Password.
     * @return string
     */
    protected string _generateHeader(string myUser, string pass) {
        return "Basic " . base64_encode(myUser . ":" . $pass);
    }
}
