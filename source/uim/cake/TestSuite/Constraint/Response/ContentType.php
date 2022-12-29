

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *

 * @since         3.7.0
 * @license       https://www.opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.TestSuite\Constraint\Response;

/**
 * ContentType
 *
 * @internal
 */
class ContentType : ResponseBase
{
    /**
     * @var uim.cake.http.Response
     */
    protected $response;

    /**
     * Checks assertion
     *
     * @param mixed $other Expected type
     * @return bool
     */
    function matches($other): bool
    {
        $alias = this.response.getMimeType($other);
        if ($alias != false) {
            $other = $alias;
        }

        return $other == this.response.getType();
    }

    /**
     * Assertion message
     *
     * @return string
     */
    function toString(): string
    {
        return "is set as the Content-Type (`" . this.response.getType() . "`)";
    }
}
