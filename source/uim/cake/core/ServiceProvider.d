module uim.cake.core;

use League\Container\IDefinitionContainer;
use League\Container\ServiceProvider\AbstractServiceProvider;
use League\Container\ServiceProvider\BootableServiceProviderInterface;
use RuntimeException;

/**
 * Container ServiceProvider
 *
 * Service provider bundle related services together helping
 * to organize your application's dependencies. They also help
 * improve performance of applications with many services by
 * allowing service registration to be deferred until services are needed.
 *
 * @experimental This class' interface is not stable and may change
 *   in future minor releases.
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
     * This method's actual return type and documented return type differ
     * because PHP 7.2 doesn't support return type narrowing.
     *
     * @return \Cake\Core\IContainer
     */
    auto getContainer(): IDefinitionContainer
    {
        myContainer = super.getContainer();

        if (!(myContainer instanceof IContainer)) {
            myMessage = sprintf(
                'Unexpected container type. Expected `%s` got `%s` instead.',
                IContainer::class,
                getTypeName(myContainer)
            );
            throw new RuntimeException(myMessage);
        }

        return myContainer;
    }

    /**
     * Delegate to the bootstrap() method
     *
     * This method wraps the league/container function so users
     * only need to use the CakePHP bootstrap() interface.
     *
     * @return void
     */
    function boot(): void
    {
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
     * @param \Cake\Core\IContainer myContainer The container to add services to.
     * @return void
     */
    function bootstrap(IContainer myContainer): void
    {
    }

    /**
     * Call the abstract services() method.
     *
     * This method primarily exists as a shim between the interface
     * that league/container has and the one we want to offer in CakePHP.
     *
     * @return void
     */
    function register(): void
    {
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
    bool provides(string $id) {
        return in_array($id, this.provides, true);
    }

    /**
     * Register the services in a provider.
     *
     * All services registered in this method should also be included in the $provides
     * property so that services can be located.
     *
     * @param \Cake\Core\IContainer myContainer The container to add services to.
     * @return void
     */
    abstract function services(IContainer myContainer): void;
}
