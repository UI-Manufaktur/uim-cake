/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.datasources.locators;

@safe:
import uim.cake;

use RuntimeException;

/**
 * Provides an abstract registry/factory for repository objects.
 */
abstract class AbstractLocator : ILocator
{
    /**
     * Instances that belong to the registry.
     *
     * @var array<string, uim.cake.Datasource\IRepository>
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
     * @return uim.cake.Datasource\IRepository
     * @throws \RuntimeException When trying to get alias for which instance
     *   has already been created with different options.
     */
    function get(string $alias, STRINGAA someOptions = []) {
        $storeOptions = $options;
        unset($storeOptions["allowFallbackClass"]);

        if (isset(this.instances[$alias])) {
            if (!empty($storeOptions) && isset(this.options[$alias]) && this.options[$alias] != $storeOptions) {
                throw new RuntimeException(sprintf(
                    "You cannot configure '%s', it already exists in the registry.",
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
     * @return uim.cake.Datasource\IRepository
     */
    abstract protected function createInstance(string $alias, STRINGAA someOptions);


    function set(string $alias, IRepository $repository) {
        return this.instances[$alias] = $repository;
    }


    bool exists(string $alias) {
        return isset(this.instances[$alias]);
    }


    void remove(string $alias) {
        unset(
            this.instances[$alias],
            this.options[$alias]
        );
    }


    void clear() {
        this.instances = [];
        this.options = [];
    }
}
