module uim.cake.https.clients\Auth;

@safe:
import uim.cake;

/**
 * Basic authentication adapter for Cake\Http\Client
 *
 * Generally not directly constructed, but instead used by {@link \Cake\Http\Client}
 * when myOptions["auth"]["type"] is "basic"
 */
class Basic
{
    /**
     * Add Authorization header to the request.
     *
     * @param \Cake\Http\Client\Request myRequest Request instance.
     * @param array $credentials Credentials.
     * @return \Cake\Http\Client\Request The updated request.
     * @see https://www.ietf.org/rfc/rfc2617.txt
     */
    function authentication(Request myRequest, array $credentials): Request
    {
        if (isset($credentials["username"], $credentials["password"])) {
            myValue = this._generateHeader($credentials["username"], $credentials["password"]);
            /** @var \Cake\Http\Client\Request myRequest */
            myRequest = myRequest.withHeader("Authorization", myValue);
        }

        return myRequest;
    }

    /**
     * Proxy Authentication
     *
     * @param \Cake\Http\Client\Request myRequest Request instance.
     * @param array $credentials Credentials.
     * @return \Cake\Http\Client\Request The updated request.
     * @see https://www.ietf.org/rfc/rfc2617.txt
     */
    function proxyAuthentication(Request myRequest, array $credentials): Request
    {
        if (isset($credentials["username"], $credentials["password"])) {
            myValue = this._generateHeader($credentials["username"], $credentials["password"]);
            /** @var \Cake\Http\Client\Request myRequest */
            myRequest = myRequest.withHeader("Proxy-Authorization", myValue);
        }

        return myRequest;
    }

    /**
     * Generate basic [proxy] authentication header
     *
     * @param string myUser Username.
     * @param string $pass Password.
     * @return string
     */
    protected string _generateHeader(string myUser, string $pass) {
        return "Basic " . base64_encode(myUser . ":" . $pass);
    }
}
