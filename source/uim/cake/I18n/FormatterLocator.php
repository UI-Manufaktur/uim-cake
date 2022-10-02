

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
 * A ServiceLocator implementation for loading and retaining formatter objects.
 *
 * @internal
 */
class FormatterLocator
{
    /**
     * A registry to retain formatter objects.
     *
     * @var array
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
     * @param array $registry An array of key-value pairs where the key is the
     * formatter name the value is a FQCN for the formatter.
     */
    this(array $registry = [])
    {
        foreach ($registry as myName => $spec) {
            this.set(myName, $spec);
        }
    }

    /**
     * Sets a formatter into the registry by name.
     *
     * @param string myName The formatter name.
     * @param string myClassName A FQCN for a formatter.
     * @return void
     */
    auto set(string myName, string myClassName): void
    {
        this.registry[myName] = myClassName;
        this.converted[myName] = false;
    }

    /**
     * Gets a formatter from the registry by name.
     *
     * @param string myName The formatter to retrieve.
     * @return \Cake\I18n\IFormatter A formatter object.
     * @throws \Cake\I18n\Exception\I18nException
     */
    auto get(string myName): IFormatter
    {
        if (!isset(this.registry[myName])) {
            throw new I18nException("Formatter named `{myName}` has not been registered");
        }

        if (!this.converted[myName]) {
            this.registry[myName] = new this.registry[myName]();
            this.converted[myName] = true;
        }

        return this.registry[myName];
    }
}
