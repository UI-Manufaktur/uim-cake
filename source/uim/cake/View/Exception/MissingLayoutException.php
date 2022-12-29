

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *

 * @since         3.0.0
  */
module uim.cake.View\Exception;

/**
 * Used when a layout file cannot be found.
 */
class MissingLayoutException : MissingTemplateException
{
    /**
     * @var string
     */
    protected $type = "Layout";
}
