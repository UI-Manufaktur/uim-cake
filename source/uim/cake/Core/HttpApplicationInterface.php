

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright 2005-2011, Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


 * @since         3.5.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Core;

import uim.cake.https.MiddlewareQueue;
use Psr\Http\Server\RequestHandlerInterface;

/**
 * An interface defining the methods that the
 * http server depend on.
 */
interface IHttpApplication : RequestHandlerInterface
{
    /**
     * Load all the application configuration and bootstrap logic.
     *
     * Override this method to add additional bootstrap logic for your application.
     *
     * @return void
     */
    function bootstrap(): void;

    /**
     * Define the HTTP middleware layers for an application.
     *
     * @param \Cake\Http\MiddlewareQueue $middlewareQueue The middleware queue to set in your App Class
     * @return \Cake\Http\MiddlewareQueue
     */
    function middleware(MiddlewareQueue $middlewareQueue): MiddlewareQueue;
}
