module uim.baklava.datasources\Locator;

import uim.baklava.datasources\IRepository;
use RuntimeException;

/**
 * Provides an abstract registry/factory for repository objects.
 */
abstract class AbstractLocator : ILocator
{
    /**
     * Instances that belong to the registry.
     *
     * @var array<string, \Cake\Datasource\IRepository>
     */
    protected $instances = [];

    /**
     * Contains a list of options that were passed to get() method.
     *
     * @var array<string, array>
     */
    protected myOptions = [];

    /**
     * {@inheritDoc}
     *
     * @param string myAlias The alias name you want to get.
     * @param array<string, mixed> myOptions The options you want to build the table with.
     * @return \Cake\Datasource\IRepository
     * @throws \RuntimeException When trying to get alias for which instance
     *   has already been created with different options.
     */
    auto get(string myAlias, array myOptions = []) {
        $storeOptions = myOptions;
        unset($storeOptions['allowFallbackClass']);

        if (isset(this.instances[myAlias])) {
            if (!empty($storeOptions) && this.options[myAlias] !== $storeOptions) {
                throw new RuntimeException(sprintf(
                    'You cannot configure "%s", it already exists in the registry.',
                    myAlias
                ));
            }

            return this.instances[myAlias];
        }

        this.options[myAlias] = $storeOptions;

        return this.instances[myAlias] = this.createInstance(myAlias, myOptions);
    }

    /**
     * Create an instance of a given classname.
     *
     * @param string myAlias Repository alias.
     * @param array<string, mixed> myOptions The options you want to build the instance with.
     * @return \Cake\Datasource\IRepository
     */
    abstract protected auto createInstance(string myAlias, array myOptions);


    auto set(string myAlias, IRepository myRepository) {
        return this.instances[myAlias] = myRepository;
    }


    bool exists(string myAlias) {
        return isset(this.instances[myAlias]);
    }


    function remove(string myAlias): void
    {
        unset(
            this.instances[myAlias],
            this.options[myAlias]
        );
    }


    function clear(): void
    {
        this.instances = [];
        this.options = [];
    }
}
