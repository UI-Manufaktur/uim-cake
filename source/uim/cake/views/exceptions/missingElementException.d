

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.views.exceptions;

/**
 * Used when an element file cannot be found.
 */
class MissingElementException : MissingTemplateException
{
    /**
     * @var string
     */
    protected myType = 'Element';
}
