

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
 * Used when an element file cannot be found.
 */
class MissingElementException : MissingTemplateException
{
    /**
     * @var string
     */
    protected $type = "Element";
}
