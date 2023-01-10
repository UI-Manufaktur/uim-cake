/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.core.app;

@safe:
import uim.cake;

/**
 * App is responsible for resource location, and path management.
 *
 * ### Adding paths
 *
 * Additional paths for Templates and Plugins are configured with Configure now. See config/app.php for an
 * example. The `App.paths.plugins` and `App.paths.templates` variables are used to configure paths for plugins
 * and templates respectively. All class based resources should be mapped using your application"s autoloader.
 *
 * ### Inspecting loaded paths
 *
 * You can inspect the currently loaded paths using `App::classPath("Controller")` for example to see loaded
 * controller paths.
 *
 * It is also possible to inspect paths for plugin classes, for instance, to get
 * the path to a plugin"s helpers you would call `App::classPath("View/Helper", "MyPlugin")`
 *
 * ### Locating plugins
 *
 * Plugins can be located with App as well. Using Plugin::path("DebugKit") for example, will
 * give you the full path to the DebugKit plugin.
 *
 * @link https://book.cakephp.org/4/en/core-libraries/app.html
 */
class App
{
    /**
     * Return the class name namespaced. This method checks if the class is defined on the
     * application/plugin, otherwise try to load from the UIM core
     *
     * @param string $class Class name
     * @param string $type Type of class
     * @param string $suffix Class name suffix
     * @return string|null Namespaced class name, null if the class is not found.
     * @psalm-return class-string|null
     */
    static Nullable!string className(string $class, string $type = "", string $suffix = "") {
        if (strpos($class, "\\") != false) {
            return class_exists($class) ? $class : null;
        }

        [$plugin, $name] = pluginSplit($class);
        $fullname = "\\" ~ replace("/", "\\", $type ~ "\\" ~ $name) . $suffix;

        $base = $plugin ?: Configure::read("App.namespace");
        if ($base != null) {
            $base = replace("/", "\\", rtrim($base, "\\"));

            if (static::_classExistsInBase($fullname, $base)) {
                /** @var class-string */
                return $base . $fullname;
            }
        }

        if ($plugin || !static::_classExistsInBase($fullname, "Cake")) {
            return null;
        }

        /** @var class-string */
        return "Cake" ~ $fullname;
    }

    /**
     * Returns the plugin split name of a class
     *
     * Examples:
     *
     * ```
     * App::shortName(
     *     "SomeVendor\SomePlugin\Controller\Component\TestComponent",
     *     "Controller/Component",
     *     "Component"
     * )
     * ```
     *
     * Returns: SomeVendor/SomePlugin.Test
     *
     * ```
     * App::shortName(
     *     "SomeVendor\SomePlugin\Controller\Component\Subfolder\TestComponent",
     *     "Controller/Component",
     *     "Component"
     * )
     * ```
     *
     * Returns: SomeVendor/SomePlugin.Subfolder/Test
     *
     * ```
     * App::shortName(
     *     "Cake\Controller\Component\AuthComponent",
     *     "Controller/Component",
     *     "Component"
     * )
     * ```
     *
     * Returns: Auth
     *
     * @param string $class Class name
     * @param string $type Type of class
     * @param string $suffix Class name suffix
     * @return string Plugin split name of class
     */
    static string shortName(string $class, string $type, string $suffix = "") {
        $class = replace("\\", "/", $class);
        $type = "/" ~ $type ~ "/";

        $pos = strrpos($class, $type);
        if ($pos == false) {
            return $class;
        }

        $pluginName = (string)substr($class, 0, $pos);
        $name = (string)substr($class, $pos + strlen($type));

        if ($suffix) {
            $name = (string)substr($name, 0, -strlen($suffix));
        }

        $nonPluginNamespaces = [
            "Cake",
            replace("\\", "/", (string)Configure::read("App.namespace")),
        ];
        if (in_array($pluginName, $nonPluginNamespaces, true)) {
            return $name;
        }

        return $pluginName ~ "." ~ $name;
    }

    /**
     * _classExistsInBase
     *
     * Test isolation wrapper
     *
     * @param string aName Class name.
     * @param string aNamespace Namespace.
     * @return bool
     */
    protected static bool _classExistsInBase(string aName, string aNamespace) {
        return class_exists($namespace . $name);
    }

    /**
     * Used to read information stored path.
     *
     * The 1st character of $type argument should be lower cased and will return the
     * value of `App.paths.$type` config.
     *
     * Default types:
     * - plugins
     * - templates
     * - locales
     *
     * Example:
     *
     * ```
     * App::path("plugins");
     * ```
     *
     * Will return the value of `App.paths.plugins` config.
     *
     * Deprecated: 4.0 App::path() is deprecated for class path (inside src/ directory).
     *   Use uim.cake.Core\App::classPath() instead or directly the method on uim.cake.Core\Plugin class.
     *
     * @param string $type Type of path
     * @param string|null $plugin Plugin name
     */
    static string[] path(string $type, Nullable!string $plugin = null) {
        if ($plugin == null && $type[0] == strtolower($type[0])) {
            return (array)Configure::read("App.paths." ~ $type);
        }

        if ($type == "templates") {
            /** @psalm-suppress PossiblyNullArgument */
            return [Plugin::templatePath($plugin)];
        }

        if ($type == "locales") {
            /** @psalm-suppress PossiblyNullArgument */
            return [Plugin::path($plugin) ~ "resources" ~ DIRECTORY_SEPARATOR ~ "locales" ~ DIRECTORY_SEPARATOR];
        }

        deprecationWarning(
            "App::path() is deprecated for class path."
            ~ " Use uim.cake.Core\App::classPath() or uim.cake.Core\Plugin::classPath() instead."
        );

        return static::classPath($type, $plugin);
    }

    /**
     * Gets the path to a class type in the application or a plugin.
     *
     * Example:
     *
     * ```
     * App::classPath("Model/Table");
     * ```
     *
     * Will return the path for tables - e.g. `src/Model/Table/`.
     *
     * ```
     * App::classPath("Model/Table", "My/Plugin");
     * ```
     *
     * Will return the plugin based path for those.
     *
     * @param string $type Package type.
     * @param string|null $plugin Plugin name.
     * @return array<string>
     */
    static string[] classPath(string $type, Nullable!string $plugin = null) {
        if ($plugin != null) {
            return [
                Plugin::classPath($plugin) . $type . DIRECTORY_SEPARATOR,
            ];
        }

        return [APP . $type . DIRECTORY_SEPARATOR];
    }

    /**
     * Returns the full path to a package inside the UIM core
     *
     * Usage:
     *
     * ```
     * App::core("Cache/Engine");
     * ```
     *
     * Will return the full path to the cache engines package.
     *
     * @param string $type Package type.
     * @return array<string> Full path to package
     */
    static array core(string $type) {
        if ($type == "templates") {
            return [CORE_PATH ~ "templates" ~ DIRECTORY_SEPARATOR];
        }

        return [CAKE . replace("/", DIRECTORY_SEPARATOR, $type) . DIRECTORY_SEPARATOR];
    }
}
