


 *

 * @copyright     Copyright (c) 2017 Aura for PHP

 * @since         4.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.I18n;

import uim.cake.I18n\Exception\I18nException;

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
     * @var array<string, \Cake\I18n\FormatterInterface|class-string<\Cake\I18n\FormatterInterface>>
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
     * @param array<string, class-string<\Cake\I18n\FormatterInterface>> $registry An array of key-value pairs where the key is the
     * formatter name the value is a FQCN for the formatter.
     */
    public this(array $registry = []) {
        foreach ($registry as $name: $spec) {
            this.set($name, $spec);
        }
    }

    /**
     * Sets a formatter into the registry by name.
     *
     * @param string $name The formatter name.
     * @param class-string<\Cake\I18n\FormatterInterface> $className A FQCN for a formatter.
     * @return void
     */
    function set(string $name, string $className): void
    {
        this.registry[$name] = $className;
        this.converted[$name] = false;
    }

    /**
     * Gets a formatter from the registry by name.
     *
     * @param string $name The formatter to retrieve.
     * @return uim.cake.I18n\FormatterInterface A formatter object.
     * @throws uim.cake.I18n\Exception\I18nException
     */
    function get(string $name): FormatterInterface
    {
        if (!isset(this.registry[$name])) {
            throw new I18nException("Formatter named `{$name}` has not been registered");
        }

        if (!this.converted[$name]) {
            /** @var class-string<\Cake\I18n\FormatterInterface> $formatter */
            $formatter = this.registry[$name];
            this.registry[$name] = new $formatter();
            this.converted[$name] = true;
        }

        /** @var uim.cake.I18n\FormatterInterface */
        return this.registry[$name];
    }
}
