

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
module uim.cake.Http\Exception;

/**
 * Not Implemented Exception - used when an API method is not implemented
 */
class NotImplementedException : HttpException
{

    protected $_messageTemplate = "%s is not implemented.";


    protected $_defaultCode = 501;
}
