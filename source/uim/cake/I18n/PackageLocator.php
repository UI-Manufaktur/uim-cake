


 *

 * @copyright     Copyright (c) 2017 Aura for PHP

 * @since         4.2.0
  */
module uim.cake.I18n;

import uim.cake.I18n\exceptions.I18nException;

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
     * @var array<string, array<string, uim.cake.I18n\Package|callable>>
     */
    protected $registry = [];

    /**
     * Tracks whether a registry entry has been converted from a
     * callable to a Package object.
     *
     * @var array<string, array<string, bool>>
     */
    protected $converted = [];

    /**
     * Constructor.
     *
     * @param array<string, array<string, uim.cake.I18n\Package|callable>> $registry A registry of packages.
     * @see PackageLocator::$registry
     */
    this(array $registry = []) {
        foreach ($registry as $name: $locales) {
            foreach ($locales as $locale: $spec) {
                this.set($name, $locale, $spec);
            }
        }
    }

    /**
     * Sets a Package loader.
     *
     * @param string $name The package name.
     * @param string $locale The locale for the package.
     * @param uim.cake.I18n\Package|callable $spec A callable that returns a package or Package instance.
     * @return void
     */
    void set(string $name, string $locale, $spec): void
    {
        this.registry[$name][$locale] = $spec;
        this.converted[$name][$locale] = $spec instanceof Package;
    }

    /**
     * Gets a Package object.
     *
     * @param string $name The package name.
     * @param string $locale The locale for the package.
     * @return uim.cake.I18n\Package
     */
    function get(string $name, string $locale): Package
    {
        if (!isset(this.registry[$name][$locale])) {
            throw new I18nException("Package "$name" with locale "$locale" is not registered.");
        }

        if (!this.converted[$name][$locale]) {
            /** @var callable $func */
            $func = this.registry[$name][$locale];
            this.registry[$name][$locale] = $func();
            this.converted[$name][$locale] = true;
        }

        /** @var uim.cake.I18n\Package */
        return this.registry[$name][$locale];
    }

    /**
     * Check if a Package object for given name and locale exists in registry.
     *
     * @param string $name The package name.
     * @param string $locale The locale for the package.
     * @return bool
     */
    function has(string $name, string $locale): bool
    {
        return isset(this.registry[$name][$locale]);
    }
}
