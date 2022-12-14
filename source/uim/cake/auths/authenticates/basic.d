/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.auths.baseauthenticate;

@safe:
import uim.cake;

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
 *      "authenticate": ["Basic"]
 *      "storage": "Memory",
 *      "unauthorizedRedirect": false,
 *  ]);
 * ```
 *
 * You should set `storage` to `Memory` to prevent UIM from sending a
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
class BasicAuthenticate : BaseAuthenticate
{
    /**
     * Authenticate a user using HTTP auth. Will use the configured User model and attempt a
     * login using HTTP auth.
     *
     * @param uim.cake.http.ServerRequest myServerRequest The request to authenticate with.
     * @param uim.cake.http.Response $response The response to add headers to.
     * @return array<string, mixed>|false Either false on failure, or an array of user data on success.
     */
    function authenticate(ServerRequest myServerRequest, Response $response) {
        return this.getUser(myServerRequest);
    }

    /**
     * Get a user based on information in the request. Used by cookie-less auth for stateless clients.
     *
     * @param uim.cake.http.ServerRequest myServerRequest Request object.
     * @return array<string, mixed>|false Either false or an array of user information
     */
    function getUser(ServerRequest myServerRequest) {
        $username = myServerRequest.getEnv("PHP_AUTH_USER");
        $pass = myServerRequest.getEnv("PHP_AUTH_PW");

        if (!is_string($username) || $username == "" || !is_string($pass) || $pass == "") {
            return false;
        }

        return _findUser($username, $pass);
    }

    /**
     * Handles an unauthenticated access attempt by sending appropriate login headers
     *
     * @param uim.cake.http.ServerRequest myServerRequest A request object.
     * @param uim.cake.http.Response $response A response object.
     * @return uim.cake.http.Response|null|void
     * @throws uim.cake.http.exceptions.UnauthorizedException
     */
    function unauthenticated(ServerRequest myServerRequest, Response $response) {
        $unauthorizedException = new UnauthorizedException();
        $unauthorizedException.setHeaders(this.loginHeaders(myServerRequest));

        throw $unauthorizedException;
    }

    /**
     * Generate the login headers
     *
     * @param uim.cake.http.ServerRequest myServerRequest Request object.
     * @return array<string, string> Headers for logging in.
     */
    STRINGAA loginHeaders(ServerRequest myServerRequest) {
        $realm = this.getConfig("realm") ?: myServerRequest.getEnv("SERVER_NAME");

        return [
            "WWW-Authenticate": sprintf("Basic realm='%s'", $realm),
        ];
    }
}
