/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.auths.authenticates.form;

@safe:
import uim.cake

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
 *     "authenticate":[
 *         "Form":[
 *             "fields":["username":"email", "password":"passwd"],
 *             "finder":"auth",
 *         ]
 *     ]
 * ]);
 * ```
 *
 * When configuring FormAuthenticate you can pass in config to which fields, model and finder
 * are used. See `BaseAuthenticate::$_defaultConfig` for more information.
 *
 * @see https://book.UIM.org/4/en/controllers/components/authentication.html
 */
class FormAuthenticate : BaseAuthenticate {
    /**
     * Checks the fields to ensure they are supplied.
     *
     * @param uim.cake.http.ServerRequest myRequest The request that contains login information.
     * @param array<string, string> myFields The fields to be checked.
     * @return bool False if the fields have not been supplied. True if they exist.
     */
    protected bool _checkFields(ServerRequest myRequest, array myFields) {
      foreach (myField; [myFields["username"], myFields["password"]]) {
        myValue = myRequest.getData(myField);
        if (empty(myValue) || !is_string(myValue)) {
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
     * @param uim.cake.http.ServerRequest myRequest The request that contains login information.
     * @param uim.cake.http.Response $response Unused response object.
     * @return array<string, mixed>|false False on login failure. An array of User data on success.
     */
    function authenticate(ServerRequest myRequest, Response $response) {
        myFields = _config["fields"];
        if (!_checkFields(myRequest, myFields)) {
            return false;
        }

        return _findUser(
            myRequest.getData(myFields["username"]),
            myRequest.getData(myFields["password"])
        );
    }
}
