

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
module uim.cake.https.Exception;

import uim.cake.cores.exceptions.CakeException;

/**
 * Missing Controller exception - used when a controller
 * cannot be found.
 */
class MissingControllerException : CakeException
{

    protected $_defaultCode = 404;


    protected $_messageTemplate = "Controller class %s could not be found.";
}

// phpcs:disable
class_alias(
    "Cake\Http\Exception\MissingControllerException",
    "Cake\Routing\Exception\MissingControllerException"
);
// phpcs:enable
