


 *


 * @since         2.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Auth;

import uim.cake.https.Response;
import uim.cake.https.ServerRequest;

/**
 * Form authentication adapter for AuthComponent.
 *
 * Allows you to authenticate users based on form POST data.
 * Usually, this is a login form that users enter information into.
 *
 * ### Using Form auth
 *
 * Load `AuthComponent` in your controller"s `initialize()` and add "Form" in "authenticate" key
 *
 * ```
 * this.loadComponent("Auth", [
 *     "authenticate": [
 *         "Form": [
 *             "fields": ["username": "email", "password": "passwd"],
 *             "finder": "auth",
 *         ]
 *     ]
 * ]);
 * ```
 *
 * When configuring FormAuthenticate you can pass in config to which fields, model and finder
 * are used. See `BaseAuthenticate::$_defaultConfig` for more information.
 *
 * @see https://book.cakephp.org/4/en/controllers/components/authentication.html
 */
class FormAuthenticate : BaseAuthenticate
{
    /**
     * Checks the fields to ensure they are supplied.
     *
     * @param \Cake\Http\ServerRequest $request The request that contains login information.
     * @param array<string, string> $fields The fields to be checked.
     * @return bool False if the fields have not been supplied. True if they exist.
     */
    protected bool _checkFields(ServerRequest $request, array $fields) {
        foreach ([$fields["username"], $fields["password"]] as $field) {
            $value = $request.getData($field);
            if (empty($value) || !is_string($value)) {
                return false;
            }
        }

        return true;
    }

    /**
     * Authenticates the identity contained in a request. Will use the `config.userModel`, and `config.fields`
     * to find POST data that is used to find a matching record in the `config.userModel`. Will return false if
     * there is no post data, either username or password is missing, or if the scope conditions have not been met.
     *
     * @param \Cake\Http\ServerRequest $request The request that contains login information.
     * @param \Cake\Http\Response $response Unused response object.
     * @return array<string, mixed>|false False on login failure. An array of User data on success.
     */
    function authenticate(ServerRequest $request, Response $response) {
        $fields = _config["fields"];
        if (!_checkFields($request, $fields)) {
            return false;
        }

        return _findUser(
            $request.getData($fields["username"]),
            $request.getData($fields["password"])
        );
    }
}
