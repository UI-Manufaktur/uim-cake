

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cakeiler\Exception;

import uim.cakere.exceptions\CakeException;

/**
 * Missing Action exception - used when a mailer action cannot be found.
 */
class MissingActionException : CakeException
{

    protected $_messageTemplate = 'Mail %s::%s() could not be found, or is not accessible.';
}
