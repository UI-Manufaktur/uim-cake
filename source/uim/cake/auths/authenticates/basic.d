module uim.caketh;

@safe:
import uim.cake

/* import uim.caketps\Exception\UnauthorizedException;
import uim.caketps\Response;
import uim.caketps\ServerRequest;
 */
/**
 * Basic Authentication adapter for AuthComponent.
 *
 * Provides Basic HTTP authentication support for AuthComponent. Basic Auth will
 * authenticate users against the configured userModel and verify the username
 * and passwords match.
 *
 * ### Using Basic auth
 *
 * Load `AuthComponent` in your controller"s `initialize()` and add "Basic" in "authenticate" key
 * ```
 *  this.loadComponent("Auth", [
 *      "authenticate" => ["Basic"]
 *      "storage" => "Memory",
 *      "unauthorizedRedirect" => false,
 *  ]);
 * ```
 *
 * You should set `storage` to `Memory` to prevent CakePHP from sending a
 * session cookie to the client.
 *
 * You should set `unauthorizedRedirect` to `false`. This causes `AuthComponent` to
 * throw a `ForbiddenException` exception instead of redirecting to another page.
 *
 * Since HTTP Basic Authentication is stateless you don"t need call `setUser()`
 * in your controller. The user credentials will be checked on each request. If
 * valid credentials are not provided, required authentication headers will be sent
 * by this authentication provider which triggers the login dialog in the browser/client.
 *
 * @see https://book.cakephp.org/4/en/controllers/components/authentication.html
 */
class BasicAuthenticate : DAuthenticate
{
    /**
     * Authenticate a user using HTTP auth. Will use the configured User model and attempt a
     * login using HTTP auth.
     *
     * @param \Cake\Http\ServerRequest myRequest The request to authenticate with.
     * @param \Cake\Http\Response $response The response to add headers to.
     * @return array<string, mixed>|false Either false on failure, or an array of user data on success.
     */
    function authenticate(ServerRequest myRequest, Response $response) {
        return this.getUser(myRequest);
    }

    /**
     * Get a user based on information in the request. Used by cookie-less auth for stateless clients.
     *
     * @param \Cake\Http\ServerRequest myRequest Request object.
     * @return array<string, mixed>|false Either false or an array of user information
     */
    auto getUser(ServerRequest myRequest) {
        myUsername = myRequest.getEnv("PHP_AUTH_USER");
        $pass = myRequest.getEnv("PHP_AUTH_PW");

        if (!is_string(myUsername) || myUsername == "" || !is_string($pass) || $pass == "") {
            return false;
        }

        return this._findUser(myUsername, $pass);
    }

    /**
     * Handles an unauthenticated access attempt by sending appropriate login headers
     *
     * @param \Cake\Http\ServerRequest myRequest A request object.
     * @param \Cake\Http\Response $response A response object.
     * @return \Cake\Http\Response|null|void
     * @throws \Cake\Http\Exception\UnauthorizedException
     */
    function unauthenticated(ServerRequest myRequest, Response $response) {
        $unauthorizedException = new UnauthorizedException();
        $unauthorizedException.setHeaders(this.loginHeaders(myRequest));

        throw $unauthorizedException;
    }

    /**
     * Generate the login headers
     *
     * @param \Cake\Http\ServerRequest myRequest Request object.
     * @return array<string, string> Headers for logging in.
     */
    function loginHeaders(ServerRequest myRequest): array
    {
        $realm = this.getConfig("realm") ?: myRequest.getEnv("SERVER_NAME");

        return [
            "WWW-Authenticate" => sprintf("Basic realm="%s"", $realm),
        ];
    }
}
