module uim.cake.controllers\Exception;

import uim.cakere.exceptions\CakeException;

/**
 * Missing Action exception - used when a controller action
 * cannot be found, or when the controller"s isAction() method returns false.
 */
class MissingActionException : CakeException
{

    protected $_messageTemplate = "Action %s::%s() could not be found, or is not accessible.";
}
