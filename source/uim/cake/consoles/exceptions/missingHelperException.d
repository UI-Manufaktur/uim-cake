

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.console\Exception;

/**
 * Used when a Helper cannot be found.
 */
class MissingHelperException : ConsoleException
{
    /**
     * @var string
     */
    protected $_messageTemplate = 'Helper class %s could not be found.';
}
