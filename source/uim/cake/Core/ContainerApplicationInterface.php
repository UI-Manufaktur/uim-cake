


 *


 * @since         4.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Core;

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
