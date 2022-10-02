

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @copyright     Copyright (c) 2017 Aura for PHP
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.I18n;

import uim.cake.I18n\Exception\I18nException;

/**
 * A ServiceLocator implementation for loading and retaining package objects.
 *
 * @internal
 */
class PackageLocator
{
    /**
     * A registry of packages.
     *
     * Unlike many other registries, this one is two layers deep. The first
     * key is a package name, the second key is a locale code, and the value
     * is a callable that returns a Package object for that name and locale.
     *
     * @var array
     */
    protected $registry = [];

    /**
     * Tracks whether a registry entry has been converted from a
     * callable to a Package object.
     *
     * @var array
     */
    protected $converted = [];

    /**
     * Constructor.
     *
     * @param array $registry A registry of packages.
     * @see PackageLocator::$registry
     */
    this(array $registry = [])
    {
        foreach ($registry as myName => $locales) {
            foreach ($locales as $locale => $spec) {
                this.set(myName, $locale, $spec);
            }
        }
    }

    /**
     * Sets a Package loader.
     *
     * @param string myName The package name.
     * @param string $locale The locale for the package.
     * @param \Cake\I18n\Package|callable $spec A callable that returns a package or Package instance.
     * @return void
     */
    auto set(string myName, string $locale, $spec): void
    {
        this.registry[myName][$locale] = $spec;
        this.converted[myName][$locale] = $spec instanceof Package;
    }

    /**
     * Gets a Package object.
     *
     * @param string myName The package name.
     * @param string $locale The locale for the package.
     * @return \Cake\I18n\Package
     */
    auto get(string myName, string $locale): Package
    {
        if (!isset(this.registry[myName][$locale])) {
            throw new I18nException("Package 'myName' with locale '$locale' is not registered.");
        }

        if (!this.converted[myName][$locale]) {
            $func = this.registry[myName][$locale];
            this.registry[myName][$locale] = $func();
            this.converted[myName][$locale] = true;
        }

        return this.registry[myName][$locale];
    }

    /**
     * Check if a Package object for given name and locale exists in registry.
     *
     * @param string myName The package name.
     * @param string $locale The locale for the package.
     * @return bool
     */
    function has(string myName, string $locale): bool
    {
        return isset(this.registry[myName][$locale]);
    }
}
