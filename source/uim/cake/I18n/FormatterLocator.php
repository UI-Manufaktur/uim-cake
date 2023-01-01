


 *

 * @copyright     Copyright (c) 2017 Aura for PHP

 * @since         4.2.0
  */module uim.cake.I18n;

import uim.cake.I18n\exceptions.I18nException;

/**
 * A ServiceLocator implementation for loading and retaining formatter objects.
 *
 * @internal
 */
class FormatterLocator
{
    /**
     * A registry to retain formatter objects.
     *
     * @var array<string, uim.cake.I18n\IFormatter|class-string<uim.cake.I18n\IFormatter>>
     */
    protected $registry = [];

    /**
     * Tracks whether a registry entry has been converted from a
     * FQCN to a formatter object.
     *
     * @var array<bool>
     */
    protected $converted = [];

    /**
     * Constructor.
     *
     * @param array<string, class-string<uim.cake.I18n\IFormatter>> $registry An array of key-value pairs where the key is the
     * formatter name the value is a FQCN for the formatter.
     */
    this(array $registry = []) {
        foreach ($registry as $name: $spec) {
            this.set($name, $spec);
        }
    }

    /**
     * Sets a formatter into the registry by name.
     *
     * @param string aName The formatter name.
     * @param class-string<uim.cake.I18n\IFormatter> $className A FQCN for a formatter.
     */
    void set(string aName, string $className): void
    {
        this.registry[$name] = $className;
        this.converted[$name] = false;
    }

    /**
     * Gets a formatter from the registry by name.
     *
     * @param string aName The formatter to retrieve.
     * @return uim.cake.I18n\IFormatter A formatter object.
     * @throws uim.cake.I18n\exceptions.I18nException
     */
    function get(string aName): IFormatter
    {
        if (!isset(this.registry[$name])) {
            throw new I18nException("Formatter named `{$name}` has not been registered");
        }

        if (!this.converted[$name]) {
            /** @var class-string<uim.cake.I18n\IFormatter> $formatter */
            $formatter = this.registry[$name];
            this.registry[$name] = new $formatter();
            this.converted[$name] = true;
        }

        /** @var uim.cake.I18n\IFormatter */
        return this.registry[$name];
    }
}
