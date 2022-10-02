

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Http\Exception;

import uim.cake.core.Exception\CakeException;

/**
 * Missing Controller exception - used when a controller
 * cannot be found.
 */
class MissingControllerException : CakeException
{
    /**
     * @inheritDoc
     */
    protected $_defaultCode = 404;

    /**
     * @inheritDoc
     */
    protected $_messageTemplate = 'Controller class %s could not be found.';
}
