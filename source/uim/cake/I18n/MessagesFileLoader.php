module uim.cake.I18n;

import uim.cake.core.App;
import uim.cake.core.Plugin;
import uim.cake.Utility\Inflector;
use Locale;
use RuntimeException;

/**
 * A generic translations package factory that will load translations files
 * based on the file extension and the package name.
 *
 * This class is a callable, so it can be used as a package loader argument.
 */
class MessagesFileLoader
{
    /**
     * The package (domain) name.
     *
     * @var string
     */
    protected $_name;

    /**
     * The locale to load for the given package.
     *
     * @var string
     */
    protected $_locale;

    /**
     * The extension name.
     *
     * @var string
     */
    protected $_extension;

    /**
     * Creates a translation file loader. The file to be loaded corresponds to
     * the following rules:
     *
     * - The locale is a folder under the `Locale` directory, a fallback will be
     *   used if the folder is not found.
     * - The myName corresponds to the file name to load
     * - If there is a loaded plugin with the underscored version of myName, the
     *   translation file will be loaded from such plugin.
     *
     * ### Examples:
     *
     * Load and parse resources/locales/fr/validation.po
     *
     * ```
     * $loader = new MessagesFileLoader('validation', 'fr_FR', 'po');
     * $package = $loader();
     * ```
     *
     * Load and parse resources/locales/fr_FR/validation.mo
     *
     * ```
     * $loader = new MessagesFileLoader('validation', 'fr_FR', 'mo');
     * $package = $loader();
     * ```
     *
     * Load the plugins/MyPlugin/resources/locales/fr/my_plugin.po file:
     *
     * ```
     * $loader = new MessagesFileLoader('my_plugin', 'fr_FR', 'mo');
     * $package = $loader();
     * ```
     *
     * @param string myName The name (domain) of the translations package.
     * @param string $locale The locale to load, this will be mapped to a folder
     * in the system.
     * @param string $extension The file extension to use. This will also be mapped
     * to a messages parser class.
     */
    this(string myName, string $locale, string $extension = 'po')
    {
        this._name = myName;
        this._locale = $locale;
        this._extension = $extension;
    }

    /**
     * Loads the translation file and parses it. Returns an instance of a translations
     * package containing the messages loaded from the file.
     *
     * @return \Cake\I18n\Package|false
     * @throws \RuntimeException if no file parser class could be found for the specified
     * file extension.
     */
    auto __invoke() {
        $folders = this.translationsFolders();
        $ext = this._extension;
        $file = false;

        $fileName = this._name;
        $pos = strpos($fileName, '/');
        if ($pos !== false) {
            $fileName = substr($fileName, $pos + 1);
        }
        foreach ($folders as $folder) {
            myPath = $folder . $fileName . ".$ext";
            if (is_file(myPath)) {
                $file = myPath;
                break;
            }
        }

        if (!$file) {
            return false;
        }

        myName = ucfirst($ext);
        myClass = App::className(myName, 'I18n\Parser', 'FileParser');

        if (!myClass) {
            throw new RuntimeException(sprintf('Could not find class %s', "{myName}FileParser"));
        }

        myMessages = (new myClass()).parse($file);
        $package = new Package('default');
        $package.setMessages(myMessages);

        return $package;
    }

    /**
     * Returns the folders where the file should be looked for according to the locale
     * and package name.
     *
     * @return array<string> The list of folders where the translation file should be looked for
     */
    function translationsFolders(): array
    {
        $locale = Locale::parseLocale(this._locale) + ['region' => null];

        $folders = [
            implode('_', [$locale['language'], $locale['region']]),
            $locale['language'],
        ];

        $searchPaths = [];

        $localePaths = App::path('locales');
        if (empty($localePaths) && defined('APP')) {
            $localePaths[] = ROOT . 'resources' . DIRECTORY_SEPARATOR . 'locales' . DIRECTORY_SEPARATOR;
        }
        foreach ($localePaths as myPath) {
            foreach ($folders as $folder) {
                $searchPaths[] = myPath . $folder . DIRECTORY_SEPARATOR;
            }
        }

        // If space is not added after slash, the character after it remains lowercased
        myPluginName = Inflector::camelize(str_replace('/', '/ ', this._name));
        if (Plugin::isLoaded(myPluginName)) {
            $basePath = App::path('locales', myPluginName)[0];
            foreach ($folders as $folder) {
                $searchPaths[] = $basePath . $folder . DIRECTORY_SEPARATOR;
            }
        }

        return $searchPaths;
    }
}
