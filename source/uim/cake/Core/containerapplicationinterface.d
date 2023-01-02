


 *


 * @since         4.2.0
  */module uim.cake.core;

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
     * @param uim.cake.Core\IContainer $container The container to add services to
     */
    void services(IContainer $container): void;

    /**
     * Create a new container and register services.
     *
     * This will `register()` services provided by both the application
     * and any plugins if the application has plugin support.
     *
     * @return uim.cake.Core\IContainer A populated container
     */
    function getContainer(): IContainer;
}
