module uim.cake.I18n;

/**
 * Constructs and stores instances of translators that can be
 * retrieved by name and locale.
 */
class TranslatorRegistry
{
    /**
     * Fallback loader name.
     *
     * @var string
     */
    public const FALLBACK_LOADER = '_fallback';

    /**
     * A registry to retain translator objects.
     *
     * @var array<string, array<string, \Cake\I18n\Translator>>
     */
    protected $registry = [];

    /**
     * The current locale code.
     *
     * @var string
     */
    protected $locale;

    /**
     * A package locator.
     *
     * @var \Cake\I18n\PackageLocator
     */
    protected $packages;

    /**
     * A formatter locator.
     *
     * @var \Cake\I18n\FormatterLocator
     */
    protected $formatters;

    /**
     * A list of loader functions indexed by domain name. Loaders are
     * callables that are invoked as a default for building translation
     * packages where none can be found for the combination of translator
     * name and locale.
     *
     * @var array<callable>
     */
    protected $_loaders = [];

    /**
     * The name of the default formatter to use for newly created
     * translators from the fallback loader
     *
     * @var string
     */
    protected $_defaultFormatter = 'default';

    /**
     * Use fallback-domain for translation loaders.
     *
     * @var bool
     */
    protected $_useFallback = true;

    /**
     * A CacheEngine object that is used to remember translator across
     * requests.
     *
     * @var (\Psr\SimpleCache\ICache&\Cake\Cache\ICacheEngine)|null
     */
    protected $_cacher;

    /**
     * Constructor.
     *
     * @param \Cake\I18n\PackageLocator $packages The package locator.
     * @param \Cake\I18n\FormatterLocator $formatters The formatter locator.
     * @param string $locale The default locale code to use.
     */
    this(
        PackageLocator $packages,
        FormatterLocator $formatters,
        string $locale
    ) {
        this.packages = $packages;
        this.formatters = $formatters;
        this.setLocale($locale);

        this.registerLoader(static::FALLBACK_LOADER, function (myName, $locale) {
            $loader = new ChainMessagesLoader([
                new MessagesFileLoader(myName, $locale, 'mo'),
                new MessagesFileLoader(myName, $locale, 'po'),
            ]);

            $formatter = myName === 'cake' ? 'default' : this._defaultFormatter;
            $package = $loader();
            $package.setFormatter($formatter);

            return $package;
        });
    }

    /**
     * Sets the default locale code.
     *
     * @param string $locale The new locale code.
     * @return void
     */
    auto setLocale(string $locale): void
    {
        this.locale = $locale;
    }

    /**
     * Returns the default locale code.
     *
     * @return string
     */
    string getLocale() {
        return this.locale;
    }

    /**
     * Returns the translator packages
     *
     * @return \Cake\I18n\PackageLocator
     */
    auto getPackages(): PackageLocator
    {
        return this.packages;
    }

    /**
     * An object of type FormatterLocator
     *
     * @return \Cake\I18n\FormatterLocator
     */
    auto getFormatters(): FormatterLocator
    {
        return this.formatters;
    }

    /**
     * Sets the CacheEngine instance used to remember translators across
     * requests.
     *
     * @param \Psr\SimpleCache\ICache&\Cake\Cache\ICacheEngine $cacher The cacher instance.
     * @return void
     */
    auto setCacher($cacher): void
    {
        this._cacher = $cacher;
    }

    /**
     * Gets a translator from the registry by package for a locale.
     *
     * @param string myName The translator package to retrieve.
     * @param string|null $locale The locale to use; if empty, uses the default
     * locale.
     * @return \Cake\I18n\Translator|null A translator object.
     * @throws \Cake\I18n\Exception\I18nException If no translator with that name could be found
     * for the given locale.
     */
    auto get(string myName, ?string $locale = null): ?Translator
    {
        if ($locale === null) {
            $locale = this.getLocale();
        }

        if (isset(this.registry[myName][$locale])) {
            return this.registry[myName][$locale];
        }

        if (this._cacher === null) {
            return this.registry[myName][$locale] = this._getTranslator(myName, $locale);
        }

        // Cache keys cannot contain / if they go to file engine.
        myKeyName = str_replace('/', '.', myName);
        myKey = "translations.{myKeyName}.{$locale}";
        $translator = this._cacher.get(myKey);
        if (!$translator || !$translator.getPackage()) {
            $translator = this._getTranslator(myName, $locale);
            this._cacher.set(myKey, $translator);
        }

        return this.registry[myName][$locale] = $translator;
    }

    /**
     * Gets a translator from the registry by package for a locale.
     *
     * @param string myName The translator package to retrieve.
     * @param string $locale The locale to use; if empty, uses the default
     * locale.
     * @return \Cake\I18n\Translator A translator object.
     */
    protected auto _getTranslator(string myName, string $locale): Translator
    {
        if (this.packages.has(myName, $locale)) {
            return this.createInstance(myName, $locale);
        }

        if (isset(this._loaders[myName])) {
            $package = this._loaders[myName](myName, $locale);
        } else {
            $package = this._loaders[static::FALLBACK_LOADER](myName, $locale);
        }

        $package = this.setFallbackPackage(myName, $package);
        this.packages.set(myName, $locale, $package);

        return this.createInstance(myName, $locale);
    }

    /**
     * Create translator instance.
     *
     * @param string myName The translator package to retrieve.
     * @param string $locale The locale to use; if empty, uses the default locale.
     * @return \Cake\I18n\Translator A translator object.
     */
    protected auto createInstance(string myName, string $locale): Translator
    {
        $package = this.packages.get(myName, $locale);
        $fallback = $package.getFallback();
        if ($fallback !== null) {
            $fallback = this.get($fallback, $locale);
        }
        $formatter = this.formatters.get($package.getFormatter());

        return new Translator($locale, $package, $formatter, $fallback);
    }

    /**
     * Registers a loader function for a package name that will be used as a fallback
     * in case no package with that name can be found.
     *
     * Loader callbacks will get as first argument the package name and the locale as
     * the second argument.
     *
     * @param string myName The name of the translator package to register a loader for
     * @param callable $loader A callable object that should return a Package
     * @return void
     */
    function registerLoader(string myName, callable $loader): void
    {
        this._loaders[myName] = $loader;
    }

    /**
     * Sets the name of the default messages formatter to use for future
     * translator instances.
     *
     * If called with no arguments, it will return the currently configured value.
     *
     * @param string|null myName The name of the formatter to use.
     * @return string The name of the formatter.
     */
    string defaultFormatter(?string myName = null) {
        if (myName === null) {
            return this._defaultFormatter;
        }

        return this._defaultFormatter = myName;
    }

    /**
     * Set if the default domain fallback is used.
     *
     * @param bool myEnable flag to enable or disable fallback
     * @return void
     */
    function useFallback(bool myEnable = true): void
    {
        this._useFallback = myEnable;
    }

    /**
     * Set fallback domain for package.
     *
     * @param string myName The name of the package.
     * @param \Cake\I18n\Package $package Package instance
     * @return \Cake\I18n\Package
     */
    auto setFallbackPackage(string myName, Package $package): Package
    {
        if ($package.getFallback()) {
            return $package;
        }

        $fallbackDomain = null;
        if (this._useFallback && myName !== 'default') {
            $fallbackDomain = 'default';
        }

        $package.setFallback($fallbackDomain);

        return $package;
    }

    /**
     * Set domain fallback for loader.
     *
     * @param string myName The name of the loader domain
     * @param callable $loader invokable loader
     * @return callable loader
     */
    auto setLoaderFallback(string myName, callable $loader): callable
    {
        $fallbackDomain = 'default';
        if (!this._useFallback || myName === $fallbackDomain) {
            return $loader;
        }
        $loader = function () use ($loader, $fallbackDomain) {
            /** @var \Cake\I18n\Package $package */
            $package = $loader();
            if (!$package.getFallback()) {
                $package.setFallback($fallbackDomain);
            }

            return $package;
        };

        return $loader;
    }
}
