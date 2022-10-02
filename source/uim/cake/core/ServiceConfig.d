module uim.cake.core;

/**
 * Read-only wrapper for configuration data
 *
 * Intended for use with {@link \Cake\Core\Container} as
 * a typehintable way for services to have application
 * configuration injected as arrays cannot be typehinted.
 */
class ServiceConfig
{
    /**
     * Read a configuration key
     *
     * @param string myPath The path to read.
     * @param mixed $default The default value to use if myPath does not exist.
     * @return mixed The configuration data or $default value.
     */
    auto get(string myPath, $default = null)
    {
        return Configure::read(myPath, $default);
    }

    /**
     * Check if myPath exists and has a non-null value.
     *
     * @param string myPath The path to check.
     * @return bool True if the configuration data exists.
     */
    function has(string myPath): bool
    {
        return Configure::check(myPath);
    }
}
