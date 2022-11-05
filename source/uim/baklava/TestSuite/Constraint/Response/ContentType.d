

/**
 * CakePHP(tm) : Rapid Development Framework (http://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 * @since         3.7.0
 * @license       http://www.opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.TestSuite\Constraint\Response;

/**
 * ContentType
 *
 * @internal
 */
class ContentType : ResponseBase
{
    /**
     * @var \Cake\Http\Response
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
        myAlias = this.response.getMimeType($other);
        if (myAlias !== false) {
            $other = myAlias;
        }

        return $other === this.response.getType();
    }

    /**
     * Assertion message
     *
     * @return string
     */
    function toString(): string
    {
        return 'is set as the Content-Type (`' . this.response.getType() . '`)';
    }
}
