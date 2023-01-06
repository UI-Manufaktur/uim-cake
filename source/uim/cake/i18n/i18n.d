module uim.cake.I18n;

import uim.cake.caches.Cache;
import uim.cake.I18n\exceptions.I18nException;
import uim.cake.I18n\Formatter\IcuFormatter;
import uim.cake.I18n\Formatter\SprintfFormatter;
use Locale;

/**
 * I18n handles translation of Text and time format strings.
 */
class I18n
{
    /**
     * Default locale
     */
    const string DEFAULT_LOCALE = "en_US";

    /**
     * The translators collection
     *
     * @var uim.cake.I18n\TranslatorRegistry|null
     */
    protected static _collection;

    /**
     * The environment default locale
     *
     * @var string|null
     */
    protected static _defaultLocale;

    /**
     * Returns the translators collection instance. It can be used
     * for getting specific translators based of their name and locale
     * or to configure some aspect of future translations that are not yet constructed.
     *
     * @return uim.cake.I18n\TranslatorRegistry The translator collection.
     */
    static function translators(): TranslatorRegistry
    {
        if (static::_collection != null) {
            return static::_collection;
        }

        static::_collection = new TranslatorRegistry(
            new PackageLocator(),
            new FormatterLocator([
                "default": IcuFormatter::class,
                "sprintf": SprintfFormatter::class,
            ]),
            static::getLocale()
        );

        if (class_exists(Cache::class)) {
            static::_collection.setCacher(Cache::pool("_cake_core_"));
        }

        return static::_collection;
    }

    /**
     * Sets a translator.
     *
     * Configures future translators, this is achieved by passing a callable
     * as the last argument of this function.
     *
     * ### Example:
     *
     * ```
     *  I18n::setTranslator("default", function () {
     *      $package = new uim.cake.I18n\Package();
     *      $package.setMessages([
     *          "Cake": "Gâteau"
     *      ]);
     *      return $package;
     *  }, "fr_FR");
     *
     *  $translator = I18n::getTranslator("default", "fr_FR");
     *  echo $translator.translate("Cake");
     * ```
     *
     * You can also use the `Cake\I18n\MessagesFileLoader` class to load a specific
     * file from a folder. For example for loading a `my_translations.po` file from
     * the `resources/locales/custom` folder, you would do:
     *
     * ```
     * I18n::setTranslator(
     *  "default",
     *  new MessagesFileLoader("my_translations", "custom", "po"),
     *  "fr_FR"
     * );
     * ```
     *
     * @param string aName The domain of the translation messages.
     * @param callable $loader A callback function or callable class responsible for
     *   constructing a translations package instance.
     * @param string|null $locale The locale for the translator.
     */
    static void setTranslator(string aName, callable $loader, Nullable!string $locale = null) {
        $locale = $locale ?: static::getLocale();

        $translators = static::translators();
        $loader = $translators.setLoaderFallback($name, $loader);
        $packages = $translators.getPackages();
        $packages.set($name, $locale, $loader);
    }

    /**
     * Returns an instance of a translator that was configured for the name and locale.
     *
     * If no locale is passed then it takes the value returned by the `getLocale()` method.
     *
     * @param string aName The domain of the translation messages.
     * @param string|null $locale The locale for the translator.
     * @return uim.cake.I18n\Translator The configured translator.
     * @throws uim.cake.I18n\exceptions.I18nException
     */
    static function getTranslator(string aName = "default", Nullable!string $locale = null): Translator
    {
        $translators = static::translators();

        if ($locale) {
            $currentLocale = $translators.getLocale();
            $translators.setLocale($locale);
        }

        $translator = $translators.get($name);
        if ($translator == null) {
            throw new I18nException(sprintf(
                "Translator for domain "%s" could not be found.",
                $name
            ));
        }

        if (isset($currentLocale)) {
            $translators.setLocale($currentLocale);
        }

        return $translator;
    }

    /**
     * Registers a callable object that can be used for creating new translator
     * instances for the same translations domain. Loaders will be invoked whenever
     * a translator object is requested for a domain that has not been configured or
     * loaded already.
     *
     * Registering loaders is useful when you need to lazily use translations in multiple
     * different locales for the same domain, and don"t want to use the built-in
     * translation service based of `gettext` files.
     *
     * Loader objects will receive two arguments: The domain name that needs to be
     * built, and the locale that is requested. These objects can assemble the messages
     * from any source, but must return an `Cake\I18n\Package` object.
     *
     * ### Example:
     *
     * ```
     *  import uim.cake.I18n\MessagesFileLoader;
     *  I18n::config("my_domain", function ($name, $locale) {
     *      // Load resources/locales/$locale/filename.po
     *      $fileLoader = new MessagesFileLoader("filename", $locale, "po");
     *      return $fileLoader();
     *  });
     * ```
     *
     * You can also assemble the package object yourself:
     *
     * ```
     *  import uim.cake.I18n\Package;
     *  I18n::config("my_domain", function ($name, $locale) {
     *      $package = new Package("default");
     *      $messages = (...); // Fetch messages for locale from external service.
     *      $package.setMessages($message);
     *      $package.setFallback("default");
     *      return $package;
     *  });
     * ```
     *
     * @param string aName The name of the translator to create a loader for
     * @param callable $loader A callable object that should return a Package
     * instance to be used for assembling a new translator.
     */
    static void config(string aName, callable $loader) {
        static::translators().registerLoader($name, $loader);
    }

    /**
     * Sets the default locale to use for future translator instances.
     * This also affects the `intl.default_locale` PHP setting.
     *
     * @param string $locale The name of the locale to set as default.
     */
    static void setLocale(string $locale) {
        static::getDefaultLocale();
        Locale::setDefault($locale);
        if (isset(static::_collection)) {
            static::translators().setLocale($locale);
        }
    }

    /**
     * Will return the currently configure locale as stored in the
     * `intl.default_locale` PHP setting.
     *
     * @return string The name of the default locale.
     */
    static string getLocale() {
        static::getDefaultLocale();
        $current = Locale::getDefault();
        if ($current == "") {
            $current = static::DEFAULT_LOCALE;
            Locale::setDefault($current);
        }

        return $current;
    }

    /**
     * Returns the default locale.
     *
     * This returns the default locale before any modifications, i.e.
     * the value as stored in the `intl.default_locale` PHP setting before
     * any manipulation by this class.
     *
     */
    static string getDefaultLocale() {
        if (static::_defaultLocale == null) {
            static::_defaultLocale = Locale::getDefault() ?: static::DEFAULT_LOCALE;
        }

        return static::_defaultLocale;
    }

    /**
     * Returns the currently configured default formatter.
     *
     * @return string The name of the formatter.
     */
    static string getDefaultFormatter() {
        return static::translators().defaultFormatter();
    }

    /**
     * Sets the name of the default messages formatter to use for future
     * translator instances. By default, the `default` and `sprintf` formatters
     * are available.
     *
     * @param string aName The name of the formatter to use.
     */
    static void setDefaultFormatter(string aName) {
        static::translators().defaultFormatter($name);
    }

    /**
     * Set if the domain fallback is used.
     *
     * @param bool $enable flag to enable or disable fallback
     */
    static void useFallback(bool $enable = true) {
        static::translators().useFallback($enable);
    }

    /**
     * Destroys all translator instances and creates a new empty translations
     * collection.
     */
    static void clear() {
        static::_collection = null;
    }
}
