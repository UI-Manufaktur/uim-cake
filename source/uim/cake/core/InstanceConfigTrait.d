module uim.cake.core;

@safe:
import uim.cake

/**
 * A trait for reading and writing instance config
 *
 * Implementing objects are expected to declare a `$_defaultConfig` property.
 */
trait InstanceConfigTrait {
    // Runtime config
    protected array<string, mixed> _config = [];

    // Whether the config property has already been configured with defaults
    protected bool _configInitialized = false;

    /**
     * Sets the config.
     *
     * ### Usage
     *
     * Setting a specific value:
     *
     * ```
     * this.setConfig("key", myValue);
     * ```
     *
     * Setting a nested value:
     *
     * ```
     * this.setConfig("some.nested.key", myValue);
     * ```
     *
     * Updating multiple config settings at the same time:
     *
     * ```
     * this.setConfig(["one":"value", "another":"value"]);
     * ```
     *
     * @param array<string, mixed>|string myKey The key to set, or a complete array of configs.
     * @param mixed|null myValue The value to set.
     * @param bool myMerge Whether to recursively merge or overwrite existing config, defaults to true.
     * @return this
     * @throws uim.cake.Core\exceptions.CakeException When trying to set a key that is invalid.
     */
    auto setConfig(myKey, myValue = null, myMerge = true) {
        if (!_configInitialized) {
            _config = _defaultConfig;
            _configInitialized = true;
        }

        _configWrite(myKey, myValue, myMerge);

        return this;
    }

    /**
     * Returns the config.
     *
     * ### Usage
     *
     * Reading the whole config:
     *
     * ```
     * this.getConfig();
     * ```
     *
     * Reading a specific value:
     *
     * ```
     * this.getConfig("key");
     * ```
     *
     * Reading a nested value:
     *
     * ```
     * this.getConfig("some.nested.key");
     * ```
     *
     * Reading with default value:
     *
     * ```
     * this.getConfig("some-key", "default-value");
     * ```
     *
     * @param string|null myKey The key to get or null for the whole config.
     * @param mixed $default The return value when the key does not exist.
     * @return mixed Configuration data at the named key or null if the key does not exist.
     */
    auto getConfig(Nullable!string myKey = null, $default = null) {
        if (!_configInitialized) {
            _config = _defaultConfig;
            _configInitialized = true;
        }

        $return = _configRead(myKey);

        return $return ?? $default;
    }

    /**
     * Returns the config for this specific key.
     *
     * The config value for this key must exist, it can never be null.
     *
     * @param string myKey The key to get.
     * @return mixed Configuration data at the named key
     * @throws \InvalidArgumentException
     */
    auto getConfigOrFail(string myKey) {
        myConfig = this.getConfig(myKey);
        if (myConfig is null) {
            throw new InvalidArgumentException(sprintf("Expected configuration `%s` not found.", myKey));
        }

        return myConfig;
    }

    /**
     * Merge provided config with existing config. Unlike `config()` which does
     * a recursive merge for nested keys, this method does a simple merge.
     *
     * Setting a specific value:
     *
     * ```
     * this.configShallow("key", myValue);
     * ```
     *
     * Setting a nested value:
     *
     * ```
     * this.configShallow("some.nested.key", myValue);
     * ```
     *
     * Updating multiple config settings at the same time:
     *
     * ```
     * this.configShallow(["one":"value", "another":"value"]);
     * ```
     *
     * @param array<string, mixed>|string myKey The key to set, or a complete array of configs.
     * @param mixed|null myValue The value to set.
     * @return this
     */
    function configShallow(myKey, myValue = null) {
        if (!_configInitialized) {
            _config = _defaultConfig;
            _configInitialized = true;
        }

        _configWrite(myKey, myValue, "shallow");

        return this;
    }

    /**
     * Reads a config key.
     *
     * @param string|null myKey Key to read.
     * @return mixed
     */
    protected auto _configRead(Nullable!string myKey) {
        if (myKey is null) {
            return _config;
        }

        if (indexOf(myKey, ".") == false) {
            return _config[myKey] ?? null;
        }

        $return = _config;

        foreach (explode(".", myKey) as $k) {
            if (!is_array($return) || !isset($return[$k])) {
                $return = null;
                break;
            }

            $return = $return[$k];
        }

        return $return;
    }

    /**
     * Writes a config key.
     *
     * @param array<string, mixed>|string myKey Key to write to.
     * @param mixed myValue Value to write.
     * @param string|bool myMerge True to merge recursively, "shallow" for simple merge,
     *   false to overwrite, defaults to false.
     * @throws uim.cake.Core\exceptions.CakeException if attempting to clobber existing config
     */
    protected void _configWrite(myKey, myValue, myMerge = false) {
        if (is_string(myKey) && myValue is null) {
            _configDelete(myKey);

            return;
        }

        if (myMerge) {
            $update = is_array(myKey) ? myKey : [myKey: myValue];
            if (myMerge == "shallow") {
                _config = array_merge(_config, Hash::expand($update));
            } else {
                _config = Hash::merge(_config, Hash::expand($update));
            }

            return;
        }

        if (is_array(myKey)) {
            foreach (myKey as $k: $val) {
                _configWrite($k, $val);
            }

            return;
        }

        if (indexOf(myKey, ".") == false) {
            _config[myKey] = myValue;

            return;
        }

        $update = &_config;
        $stack = explode(".", myKey);

        foreach ($stack as $k) {
            if (!is_array($update)) {
                throw new CakeException(sprintf("Cannot set %s value", myKey));
            }

            $update[$k] = $update[$k] ?? [];

            $update = &$update[$k];
        }

        $update = myValue;
    }

    /**
     * Deletes a single config key.
     *
     * @param string myKey Key to delete.
     * @throws uim.cake.Core\exceptions.CakeException if attempting to clobber existing config
     */
    protected void _configDelete(string myKey) {
        if (indexOf(myKey, ".") == false) {
            unset(_config[myKey]);

            return;
        }

        $update = &_config;
        $stack = explode(".", myKey);
        $length = count($stack);

        foreach ($stack as $i: $k) {
            if (!is_array($update)) {
                throw new CakeException(sprintf("Cannot unset %s value", myKey));
            }

            if (!isset($update[$k])) {
                break;
            }

            if ($i == $length - 1) {
                unset($update[$k]);
                break;
            }

            $update = &$update[$k];
        }
    }
}
