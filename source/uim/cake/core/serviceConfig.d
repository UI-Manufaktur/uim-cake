module uim.cake.core.serviceconfig;

/**
 * Read-only wrapper for configuration data
 *
 * Intended for use with {@link uim.cake.Core\Container} as
 * a typehintable way for services to have application
 * configuration injected as arrays cannot be typehinted.
 */
class ServiceConfig {
    /**
     * Read a configuration key
     *
     * @param string $path The path to read.
     * @param mixed $default The default value to use if $path does not exist.
     * @return mixed The configuration data or $default value.
     */
    function get(string $path, $default = null) {
        return Configure::read($path, $default);
    }

    /**
     * Check if $path exists and has a non-null value.
     *
     * @param string $path The path to check.
     * @return bool True if the configuration data exists.
     */
    bool has(string $path)
    {
        return Configure::check($path);
    }
}
