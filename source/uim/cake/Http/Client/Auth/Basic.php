

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.https.Client\Auth;

import uim.cake.https.Client\Request;

/**
 * Basic authentication adapter for Cake\Http\Client
 *
 * Generally not directly constructed, but instead used by {@link \Cake\Http\Client}
 * when $options["auth"]["type"] is "basic"
 */
class Basic
{
    /**
     * Add Authorization header to the request.
     *
     * @param \Cake\Http\Client\Request $request Request instance.
     * @param array $credentials Credentials.
     * @return \Cake\Http\Client\Request The updated request.
     * @see https://www.ietf.org/rfc/rfc2617.txt
     */
    function authentication(Request $request, array $credentials): Request
    {
        if (isset($credentials["username"], $credentials["password"])) {
            $value = _generateHeader($credentials["username"], $credentials["password"]);
            /** @var \Cake\Http\Client\Request $request */
            $request = $request.withHeader("Authorization", $value);
        }

        return $request;
    }

    /**
     * Proxy Authentication
     *
     * @param \Cake\Http\Client\Request $request Request instance.
     * @param array $credentials Credentials.
     * @return \Cake\Http\Client\Request The updated request.
     * @see https://www.ietf.org/rfc/rfc2617.txt
     */
    function proxyAuthentication(Request $request, array $credentials): Request
    {
        if (isset($credentials["username"], $credentials["password"])) {
            $value = _generateHeader($credentials["username"], $credentials["password"]);
            /** @var \Cake\Http\Client\Request $request */
            $request = $request.withHeader("Proxy-Authorization", $value);
        }

        return $request;
    }

    /**
     * Generate basic [proxy] authentication header
     *
     * @param string $user Username.
     * @param string $pass Password.
     * @return string
     */
    protected function _generateHeader(string $user, string $pass): string
    {
        return "Basic " . base64_encode($user . ":" . $pass);
    }
}
