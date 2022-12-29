

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *

 * @since         3.7.0

 */
module uim.cake.TestSuite\Constraint\Response;

/**
 * StatusCode
 *
 * @internal
 */
class StatusCode : StatusCodeBase
{
    /**
     * Assertion message
     *
     * @return string
     */
    string toString(): string
    {
        return sprintf("matches response status code `%d`", this.response.getStatusCode());
    }

    /**
     * Failure description
     *
     * @param mixed $other Expected code
     * @return string
     */
    string failureDescription($other): string
    {
        return "`" . $other . "` " . this.toString();
    }
}
