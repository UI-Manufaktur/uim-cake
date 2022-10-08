module uim.cake.core;

/**
 * App is responsible for resource location, and path management.
 *
 * ### Adding paths
 *
 * Additional paths for Templates and Plugins are configured with Configure now. See config/app.php for an
 * example. The `App.paths.plugins` and `App.paths.templates` variables are used to configure paths for plugins
 * and templates respectively. All class based resources should be mapped using your application's autoloader.
 *
 * ### Inspecting loaded paths
 *
 * You can inspect the currently loaded paths using `App::classPath('Controller')` for example to see loaded
 * controller paths.
 *
 * It is also possible to inspect paths for plugin classes, for instance, to get
 * the path to a plugin's helpers you would call `App::classPath('View/Helper', 'MyPlugin')`
 *
 * ### Locating plugins
 *
 * Plugins can be located with App as well. Using Plugin::path('DebugKit') for example, will
 * give you the full path to the DebugKit plugin.
 *
 * @link https://book.cakephp.org/4/en/core-libraries/app.html
 */
class App {
    /**
     * Return the class name moduled. This method checks if the class is defined on the
     * application/plugin, otherwise try to load from the CakePHP core
     *
     * @param string aClassName Class name
     * @param string aClassType Type of class
     * @param string aClassNameSuffix Class name suffix
     * @return string|null moduled class name, null if the class is not found.
     * @psalm-return class-string|null
     */
    static string className(string aClassName, string aClassType = '', string aClassNameSuffix = '') {
        if (strpos(aClassName, '\\') !== false) {
            return class_exists(aClassName) ? aClassName : null;
        }

        [myPlugin, myName] = pluginSplit(aClassName);
        $base = myPlugin ?: Configure::read('App.module');
        $base = str_replace('/', '\\', rtrim($base, '\\'));
        $fullname = '\\' . str_replace('/', '\\', aClassType . '\\' . myName) . aClassNameSuffix;

        if (static::_classExistsInBase($fullname, $base)) {
            /** @var class-string */
            return $base . $fullname;
        }

        if (myPlugin || !static::_classExistsInBase($fullname, 'Cake')) {
            return null;
        }

        /** @var class-string */
        return 'Cake' . $fullname;
    }

    /**
     * Returns the plugin split name of a class
     *
     * Examples:
     *
     * ```
     * App::shortName(
     *     'SomeVendor\SomePlugin\Controller\Component\TestComponent',
     *     'Controller/Component',
     *     'Component'
     * )
     * ```
     *
     * Returns: SomeVendor/SomePlugin.Test
     *
     * ```
     * App::shortName(
     *     'SomeVendor\SomePlugin\Controller\Component\Subfolder\TestComponent',
     *     'Controller/Component',
     *     'Component'
     * )
     * ```
     *
     * Returns: SomeVendor/SomePlugin.Subfolder/Test
     *
     * ```
     * App::shortName(
     *     'Cake\Controller\Component\AuthComponent',
     *     'Controller/Component',
     *     'Component'
     * )
     * ```
     *
     * Returns: Auth
     *
     * @param string aClassName Class name
     * @param string aClassType Type of class
     * @param string aClassNameSuffix Class name suffix
     * @return string Plugin split name of class
     */
    static string shortName(string aClassName, string aClassType, string aClassNameSuffix = '')
    {
        aClassName = str_replace('\\', '/', aClassName);
        aClassType = '/' . aClassType . '/';

        $pos = strrpos(aClassName, aClassType);
        if ($pos === false) {
            return aClassName;
        }

        myPluginName = (string)substr(aClassName, 0, $pos);
        myName = (string)substr(aClassName, $pos + strlen(aClassType));

        if (aClassNameSuffix) {
            myName = (string)substr(myName, 0, -strlen(aClassNameSuffix));
        }

        $nonPluginmodules = [
            'Cake',
            str_replace('\\', '/', (string)Configure::read('App.module')),
        ];
        if (in_array(myPluginName, $nonPluginmodules, true)) {
            return myName;
        }

        return myPluginName . '.' . myName;
    }

    /**
     * _classExistsInBase
     *
     * Test isolation wrapper
     *
     * @param string myName Class name.
     * @param string $module module.
     * @return bool
     */
    protected static bool _classExistsInBase(string myName, string $module) {
        return class_exists($module . myName);
    }

    /**
     * Used to read information stored path.
     *
     * The 1st character of aClassType argument should be lower cased and will return the
     * value of `App.paths.aClassType` config.
     *
     * Default types:
     * - plugins
     * - templates
     * - locales
     *
     * Example:
     *
     * ```
     * App::path('plugins');
     * ```
     *
     * Will return the value of `App.paths.plugins` config.
     *
     * Deprecated: 4.0 App::path() is deprecated for class path (inside src/ directory).
     *   Use \Cake\Core\App::classPath() instead or directly the method on \Cake\Core\Plugin class.
     *
     * @param string aClassType Type of path
     * @param string|null myPlugin Plugin name
     * @return array<string>
     * @link https://book.cakephp.org/4/en/core-libraries/app.html#finding-paths-to-modules
     */
    static function path(string aClassType, ?string myPlugin = null): array
    {
        if (myPlugin === null && aClassType[0] === strtolower(aClassType[0])) {
            return (array)Configure::read('App.paths.' . aClassType);
        }

        if (aClassType === 'templates') {
            /** @psalm-suppress PossiblyNullArgument */
            return [Plugin::templatePath(myPlugin)];
        }

        if (aClassType === 'locales') {
            /** @psalm-suppress PossiblyNullArgument */
            return [Plugin::path(myPlugin) . 'resources' . DIRECTORY_SEPARATOR . 'locales' . DIRECTORY_SEPARATOR];
        }

        deprecationWarning(
            'App::path() is deprecated for class path.'
            . ' Use \Cake\Core\App::classPath() or \Cake\Core\Plugin::classPath() instead.'
        );

        return static::classPath(aClassType, myPlugin);
    }

    /**
     * Gets the path to a class type in the application or a plugin.
     *
     * Example:
     *
     * ```
     * App::classPath('Model/Table');
     * ```
     *
     * Will return the path for tables - e.g. `src/Model/Table/`.
     *
     * ```
     * App::classPath('Model/Table', 'My/Plugin');
     * ```
     *
     * Will return the plugin based path for those.
     *
     * @param string aClassType Package type.
     * @param string|null myPlugin Plugin name.
     * @return array<string>
     */
    static string[] classPath(string aClassType, ?string myPlugin = null) {
        if (myPlugin !== null) {
            return [
                Plugin::classPath(myPlugin) . aClassType . DIRECTORY_SEPARATOR,
            ];
        }

        return [APP . aClassType . DIRECTORY_SEPARATOR];
    }

    /**
     * Returns the full path to a package inside the CakePHP core
     *
     * Usage:
     *
     * ```
     * App::core('Cache/Engine');
     * ```
     *
     * Will return the full path to the cache engines package.
     *
     * @param string aClassType Package type.
     * @return array<string> Full path to package
     */
    static string[] core(string aClassType) {
        if (aClassType === 'templates') {
            return [CORE_PATH . 'templates' . DIRECTORY_SEPARATOR];
        }

        return [CAKE . str_replace('/', DIRECTORY_SEPARATOR, aClassType) . DIRECTORY_SEPARATOR];
    }
}
