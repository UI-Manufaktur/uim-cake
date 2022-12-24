

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Database;

/**
 * : the TypedResultInterface
 */
trait TypedResultTrait
{
    /**
     * The type name this expression will return when executed
     *
     * @var string
     */
    protected $_returnType = 'string';

    /**
     * Gets the type of the value this object will generate.
     *
     * @return string
     */
    function getReturnType(): string
    {
        return _returnType;
    }

    /**
     * Sets the type of the value this object will generate.
     *
     * @param string $type The name of the type that is to be returned
     * @return this
     */
    function setReturnType(string $type)
    {
        _returnType = $type;

        return this;
    }
}
