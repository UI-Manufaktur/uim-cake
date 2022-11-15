

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         1.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.core.Configure;

/**
 * An interface for creating objects compatible with Configure::load()
 */
interface ConfigEngineInterface
{
    /**
     * Read a configuration file/storage key
     *
     * This method is used for reading configuration information from sources.
     * These sources can either be static resources like files, or dynamic ones like
     * a database, or other datasource.
     *
     * @param string myKey Key to read.
     * @return array An array of data to merge into the runtime configuration
     */
    function read(string myKey): array;

    /**
     * Dumps the configure data into the storage key/file of the given `myKey`.
     *
     * @param string myKey The identifier to write to.
     * @param array myData The data to dump.
     * @return bool True on success or false on failure.
     */
    bool dump(string myKey, array myData);
}
