module uim.cake.http.exceptions;

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
