


 *


 * @since         4.2.0
  */module uim.cake.core;

use League\Container\DefinitionIContainer;
use League\Container\ServiceProvider\AbstractServiceProvider;
use League\Container\ServiceProvider\BootableServiceProviderInterface;
use RuntimeException;

/**
 * Container ServiceProvider
 *
 * Service provider bundle related services together helping
 * to organize your application"s dependencies. They also help
 * improve performance of applications with many services by
 * allowing service registration to be deferred until services are needed.
 */
abstract class ServiceProvider : AbstractServiceProvider : BootableServiceProviderInterface
{
    /**
     * List of ids of services this provider provides.
     *
     * @var array<string>
     * @see ServiceProvider::provides()
     */
    protected $provides = [];

    /**
     * Get the container.
     *
     * This method"s actual return type and documented return type differ
     * because PHP 7.2 doesn"t support return type narrowing.
     *
     * @return uim.cake.Core\IContainer
     */
    function getContainer(): DefinitionIContainer
    {
        $container = super.getContainer();

        if (!($container instanceof IContainer)) {
            $message = sprintf(
                "Unexpected container type. Expected `%s` got `%s` instead.",
                IContainer::class,
                getTypeName($container)
            );
            throw new RuntimeException($message);
        }

        return $container;
    }

    /**
     * Delegate to the bootstrap() method
     *
     * This method wraps the league/container function so users
     * only need to use the CakePHP bootstrap() interface.
     */
    void boot() {
        this.bootstrap(this.getContainer());
    }

    /**
     * Bootstrap hook for ServiceProviders
     *
     * This hook should be implemented if your service provider
     * needs to register additional service providers, load configuration
     * files or do any other work when the service provider is added to the
     * container.
     *
     * @param uim.cake.Core\IContainer $container The container to add services to.
     */
    void bootstrap(IContainer $container) {
    }

    /**
     * Call the abstract services() method.
     *
     * This method primarily exists as a shim between the interface
     * that league/container has and the one we want to offer in CakePHP.
     */
    void register() {
        this.services(this.getContainer());
    }

    /**
     * The provides method is a way to let the container know that a service
     * is provided by this service provider.
     *
     * Every service that is registered via this service provider must have an
     * alias added to this array or it will be ignored.
     *
     * @param string $id Identifier.
     * @return bool
     */
    function provides(string $id): bool
    {
        return in_array($id, this.provides, true);
    }

    /**
     * Register the services in a provider.
     *
     * All services registered in this method should also be included in the $provides
     * property so that services can be located.
     *
     * @param uim.cake.Core\IContainer $container The container to add services to.
     * @return void
     */
    abstract function services(IContainer $container): void;
}
