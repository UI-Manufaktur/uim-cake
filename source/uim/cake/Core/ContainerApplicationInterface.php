<?php
declare(strict_types=1);

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
namespace Cake\Core;

/**
 * Interface for applications that configure and use a dependency injection container.
 */
interface IContainerApplication
{
    /**
     * Register services to the container
     *
     * Registered services can have instances fetched out of the container
     * using `get()`. Dependencies and parameters will be resolved based
     * on service definitions.
     *
     * @param \Cake\Core\IContainer $container The container to add services to
     * @return void
     */
    function services(IContainer $container): void;

    /**
     * Create a new container and register services.
     *
     * This will `register()` services provided by both the application
     * and any plugins if the application has plugin support.
     *
     * @return \Cake\Core\IContainer A populated container
     */
    function getContainer(): IContainer;
}
