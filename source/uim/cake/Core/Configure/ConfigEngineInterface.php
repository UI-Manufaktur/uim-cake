


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         1.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.cores.Configure;

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
     * @param string $key Key to read.
     * @return array An array of data to merge into the runtime configuration
     */
    function read(string $key): array;

    /**
     * Dumps the configure data into the storage key/file of the given `$key`.
     *
     * @param string $key The identifier to write to.
     * @param array $data The data to dump.
     * @return bool True on success or false on failure.
     */
    function dump(string $key, array $data): bool;
}
