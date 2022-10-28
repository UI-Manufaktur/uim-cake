module uim.cake.ORM\Behavior;

import uim.cake.I18n\I18n;
import uim.cake.ORM\Behavior;
import uim.cake.ORM\Behavior\Translate\EavStrategy;
import uim.cake.ORM\Behavior\Translate\TranslateStrategyInterface;
import uim.cake.ORM\Marshaller;
import uim.cake.ORM\PropertyMarshalInterface;
import uim.cake.ORM\Query;
import uim.cake.ORM\Table;
import uim.cake.Utility\Inflector;

/**
 * This behavior provides a way to translate dynamic data by keeping translations
 * in a separate table linked to the original record from another one. Translated
 * fields can be configured to override those in the main table when fetched or
 * put aside into another property for the same entity.
 *
 * If you wish to override fields, you need to call the `locale` method in this
 * behavior for setting the language you want to fetch from the translations table.
 *
 * If you want to bring all or certain languages for each of the fetched records,
 * you can use the custom `translations` finders that is exposed to the table.
 */
class TranslateBehavior : Behavior : PropertyMarshalInterface
{
    /**
     * Default config
     *
     * These are merged with user-provided configuration when the behavior is used.
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        'implementedFinders' => ['translations' => 'findTranslations'],
        'implementedMethods' => [
            'setLocale' => 'setLocale',
            'getLocale' => 'getLocale',
            'translationField' => 'translationField',
        ],
        'fields' => [],
        'defaultLocale' => null,
        'referenceName' => '',
        'allowEmptyTranslations' => true,
        'onlyTranslated' => false,
        'strategy' => 'subquery',
        'tableLocator' => null,
        'validator' => false,
    ];

    /**
     * Default strategy class name.
     *
     * @var string
     * @psalm-var class-string<\Cake\ORM\Behavior\Translate\TranslateStrategyInterface>
     */
    protected static $defaultStrategyClass = EavStrategy::class;

    /**
     * Translation strategy instance.
     *
     * @var \Cake\ORM\Behavior\Translate\TranslateStrategyInterface|null
     */
    protected $strategy;

    /**
     * Constructor
     *
     * ### Options
     *
     * - `fields`: List of fields which need to be translated. Providing this fields
     *   list is mandatory when using `EavStrategy`. If the fields list is empty when
     *   using `ShadowTableStrategy` then the list will be auto generated based on
     *   shadow table schema.
     * - `defaultLocale`: The locale which is treated as default by the behavior.
     *   Fields values for defaut locale will be stored in the primary table itself
     *   and the rest in translation table. If not explicitly set the value of
     *   `I18n::getDefaultLocale()` will be used to get default locale.
     *   If you do not want any default locale and want translated fields
     *   for all locales to be stored in translation table then set this config
     *   to empty string `''`.
     * - `allowEmptyTranslations`: By default if a record has been translated and
     *   stored as an empty string the translate behavior will take and use this
     *   value to overwrite the original field value. If you don't want this behavior
     *   then set this option to `false`.
     * - `validator`: The validator that should be used when translation records
     *   are created/modified. Default `null`.
     *
     * @param \Cake\ORM\Table myTable The table this behavior is attached to.
     * @param array<string, mixed> myConfig The config for this behavior.
     */
    this(Table myTable, array myConfig = []) {
        myConfig += [
            'defaultLocale' => I18n::getDefaultLocale(),
            'referenceName' => this.referenceName(myTable),
            'tableLocator' => myTable.associations().getTableLocator(),
        ];

        super.this(myTable, myConfig);
    }

    /**
     * Initialize hook
     *
     * @param array<string, mixed> myConfig The config for this behavior.
     * @return void
     */
    function initialize(array myConfig): void
    {
        this.getStrategy();
    }

    /**
     * Set default strategy class name.
     *
     * @param string myClass Class name.
     * @return void
     * @since 4.0.0
     * @psalm-param class-string<\Cake\ORM\Behavior\Translate\TranslateStrategyInterface> myClass
     */
    static auto setDefaultStrategyClass(string myClass) {
        static::$defaultStrategyClass = myClass;
    }

    /**
     * Get default strategy class name.
     *
     * @return string
     * @since 4.0.0
     * @psalm-return class-string<\Cake\ORM\Behavior\Translate\TranslateStrategyInterface>
     */
    static auto getDefaultStrategyClass(): string
    {
        return static::$defaultStrategyClass;
    }

    /**
     * Get strategy class instance.
     *
     * @return \Cake\ORM\Behavior\Translate\TranslateStrategyInterface
     * @since 4.0.0
     */
    auto getStrategy(): TranslateStrategyInterface
    {
        if (this.strategy !== null) {
            return this.strategy;
        }

        return this.strategy = this.createStrategy();
    }

    /**
     * Create strategy instance.
     *
     * @return \Cake\ORM\Behavior\Translate\TranslateStrategyInterface
     * @since 4.0.0
     */
    protected auto createStrategy() {
        myConfig = array_diff_key(
            this._config,
            ['implementedFinders', 'implementedMethods', 'strategyClass']
        );
        /** @var class-string<\Cake\ORM\Behavior\Translate\TranslateStrategyInterface> myClassName */
        myClassName = this.getConfig('strategyClass', static::$defaultStrategyClass);

        return new myClassName(this._table, myConfig);
    }

    /**
     * Set strategy class instance.
     *
     * @param \Cake\ORM\Behavior\Translate\TranslateStrategyInterface $strategy Strategy class instance.
     * @return this
     * @since 4.0.0
     */
    auto setStrategy(TranslateStrategyInterface $strategy) {
        this.strategy = $strategy;

        return this;
    }

    /**
     * Gets the Model callbacks this behavior is interested in.
     *
     * @return array<string, mixed>
     */
    function implementedEvents(): array
    {
        return [
            'Model.beforeFind' => 'beforeFind',
            'Model.beforeSave' => 'beforeSave',
            'Model.afterSave' => 'afterSave',
        ];
    }

    /**
     * {@inheritDoc}
     *
     * Add in `_translations` marshalling handlers. You can disable marshalling
     * of translations by setting `'translations' => false` in the options
     * provided to `Table::newEntity()` or `Table::patchEntity()`.
     *
     * @param \Cake\ORM\Marshaller $marshaller The marhshaller of the table the behavior is attached to.
     * @param array $map The property map being built.
     * @param array<string, mixed> myOptions The options array used in the marshalling call.
     * @return array A map of `[property => callable]` of additional properties to marshal.
     */
    function buildMarshalMap(Marshaller $marshaller, array $map, array myOptions): array
    {
        return this.getStrategy().buildMarshalMap($marshaller, $map, myOptions);
    }

    /**
     * Sets the locale that should be used for all future find and save operations on
     * the table where this behavior is attached to.
     *
     * When fetching records, the behavior will include the content for the locale set
     * via this method, and likewise when saving data, it will save the data in that
     * locale.
     *
     * Note that in case an entity has a `_locale` property set, that locale will win
     * over the locale set via this method (and over the globally configured one for
     * that matter)!
     *
     * @param string|null $locale The locale to use for fetching and saving records. Pass `null`
     * in order to unset the current locale, and to make the behavior fall back to using the
     * globally configured locale.
     * @return this
     * @see \Cake\ORM\Behavior\TranslateBehavior::getLocale()
     * @link https://book.cakephp.org/4/en/orm/behaviors/translate.html#retrieving-one-language-without-using-i18n-locale
     * @link https://book.cakephp.org/4/en/orm/behaviors/translate.html#saving-in-another-language
     */
    auto setLocale(?string $locale) {
        this.getStrategy().setLocale($locale);

        return this;
    }

    /**
     * Returns the current locale.
     *
     * If no locale has been explicitly set via `setLocale()`, this method will return
     * the currently configured global locale.
     *
     * @return string
     * @see \Cake\I18n\I18n::getLocale()
     * @see \Cake\ORM\Behavior\TranslateBehavior::setLocale()
     */
    auto getLocale(): string
    {
        return this.getStrategy().getLocale();
    }

    /**
     * Returns a fully aliased field name for translated fields.
     *
     * If the requested field is configured as a translation field, the `content`
     * field with an alias of a corresponding association is returned. Table-aliased
     * field name is returned for all other fields.
     *
     * @param string myField Field name to be aliased.
     * @return string
     */
    function translationField(string myField): string
    {
        return this.getStrategy().translationField(myField);
    }

    /**
     * Custom finder method used to retrieve all translations for the found records.
     * Fetched translations can be filtered by locale by passing the `locales` key
     * in the options array.
     *
     * Translated values will be found for each entity under the property `_translations`,
     * containing an array indexed by locale name.
     *
     * ### Example:
     *
     * ```
     * $article = $articles.find('translations', ['locales' => ['eng', 'deu']).first();
     * $englishTranslatedFields = $article.get('_translations')['eng'];
     * ```
     *
     * If the `locales` array is not passed, it will bring all translations found
     * for each record.
     *
     * @param \Cake\ORM\Query myQuery The original query to modify
     * @param array<string, mixed> myOptions Options
     * @return \Cake\ORM\Query
     */
    function findTranslations(Query myQuery, array myOptions): Query
    {
        $locales = myOptions['locales'] ?? [];
        myTargetAlias = this.getStrategy().getTranslationTable().getAlias();

        return myQuery
            .contain([myTargetAlias => function (myQuery) use ($locales, myTargetAlias) {
                /** @var \Cake\Datasource\QueryInterface myQuery */
                if ($locales) {
                    myQuery.where(["myTargetAlias.locale IN" => $locales]);
                }

                return myQuery;
            }])
            .formatResults([this.getStrategy(), 'groupTranslations'], myQuery::PREPEND);
    }

    /**
     * Proxy method calls to strategy class instance.
     *
     * @param string $method Method name.
     * @param array $args Method arguments.
     * @return mixed
     */
    auto __call($method, $args) {
        return this.strategy.{$method}(...$args);
    }

    /**
     * Determine the reference name to use for a given table
     *
     * The reference name is usually derived from the class name of the table object
     * (PostsTable . Posts), however for autotable instances it is derived from
     * the database table the object points at - or as a last resort, the alias
     * of the autotable instance.
     *
     * @param \Cake\ORM\Table myTable The table class to get a reference name for.
     * @return string
     */
    protected auto referenceName(Table myTable): string
    {
        myName = moduleSplit(get_class(myTable));
        myName = substr(end(myName), 0, -5);
        if (empty(myName)) {
            myName = myTable.getTable() ?: myTable.getAlias();
            myName = Inflector::camelize(myName);
        }

        return myName;
    }
}
