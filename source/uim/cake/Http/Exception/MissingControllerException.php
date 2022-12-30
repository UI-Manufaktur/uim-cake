

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


  */module uim.cake.http.Exception;

import uim.cake.core.exceptions.CakeException;

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
    "Cake\Http\exceptions.MissingControllerException",
    "Cake\routings.exceptions.MissingControllerException"
);
// phpcs:enable
