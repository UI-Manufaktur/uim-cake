


 *


 * @since         4.1.0
  */
module uim.cake.datasources.Locator;

import uim.cake.datasources.RepositoryInterface;
use RuntimeException;

/**
 * Provides an abstract registry/factory for repository objects.
 */
abstract class AbstractLocator : ILocator
{
    /**
     * Instances that belong to the registry.
     *
     * @var array<string, uim.cake.Datasource\RepositoryInterface>
     */
    protected $instances = [];

    /**
     * Contains a list of options that were passed to get() method.
     *
     * @var array<string, array>
     */
    protected $options = [];

    /**
     * {@inheritDoc}
     *
     * @param string $alias The alias name you want to get.
     * @param array<string, mixed> $options The options you want to build the table with.
     * @return uim.cake.Datasource\RepositoryInterface
     * @throws \RuntimeException When trying to get alias for which instance
     *   has already been created with different options.
     */
    function get(string $alias, array $options = []) {
        $storeOptions = $options;
        unset($storeOptions["allowFallbackClass"]);

        if (isset(this.instances[$alias])) {
            if (!empty($storeOptions) && isset(this.options[$alias]) && this.options[$alias] != $storeOptions) {
                throw new RuntimeException(sprintf(
                    "You cannot configure "%s", it already exists in the registry.",
                    $alias
                ));
            }

            return this.instances[$alias];
        }

        this.options[$alias] = $storeOptions;

        return this.instances[$alias] = this.createInstance($alias, $options);
    }

    /**
     * Create an instance of a given classname.
     *
     * @param string $alias Repository alias.
     * @param array<string, mixed> $options The options you want to build the instance with.
     * @return uim.cake.Datasource\RepositoryInterface
     */
    abstract protected function createInstance(string $alias, array $options);


    function set(string $alias, RepositoryInterface $repository) {
        return this.instances[$alias] = $repository;
    }


    function exists(string $alias): bool
    {
        return isset(this.instances[$alias]);
    }


    function remove(string $alias): void
    {
        unset(
            this.instances[$alias],
            this.options[$alias]
        );
    }


    function clear(): void
    {
        this.instances = [];
        this.options = [];
    }
}
