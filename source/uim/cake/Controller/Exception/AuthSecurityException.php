

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.controller\Exception;

/**
 * Auth Security exception - used when SecurityComponent detects any issue with the current request
 */
class AuthSecurityException : SecurityException
{
    /**
     * Security Exception type
     *
     * @var string
     */
    protected $_type = 'auth';
}
