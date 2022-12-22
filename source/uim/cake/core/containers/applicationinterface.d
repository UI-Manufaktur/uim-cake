module uim.cake.core;

/**
 * Interface for applications that configure and use a dependency injection container.
 *
 * @experimental This interface is not final and can have additional
 *   methods and parameters added in future minor releases.
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
     * @param \Cake\Core\IContainer myContainer The container to add services to
     */
    void services(IContainer myContainer);

    /**
     * Create a new container and register services.
     *
     * This will `register()` services provided by both the application
     * and any plugins if the application has plugin support.
     *
     * @return \Cake\Core\IContainer A populated container
     */
    auto getContainer(): IContainer;
}
