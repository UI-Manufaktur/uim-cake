

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


  */
module uim.cake.View\Exception;

/**
 * Used when a layout file cannot be found.
 */
class MissingLayoutException : MissingTemplateException
{
    /**
     */
    protected string $type = "Layout";
}
