module uim.cake.orm.behaviors\Translate;

@safe:
import uim.cake;

/**
 * Contains common code needed by TranslateBehavior strategy classes.
 */
trait TranslateStrategyTrait {
    /**
     * Table instance
     *
     * @var uim.cake.orm.Table
     */
    protected myTable;

    /**
     * The locale name that will be used to override fields in the bound table
     * from the translations table
     *
     * @var string|null
     */
    protected locale;

    /**
     * Instance of Table responsible for translating
     *
     * @var uim.cake.orm.Table
     */
    protected translationTable;

    /**
     * Return translation table instance.
     *
     * @return uim.cake.orm.Table
     */
    auto getTranslationTable(): Table
    {
        return this.translationTable;
    }

    /**
     * Sets the locale to be used.
     *
     * When fetching records, the content for the locale set via this method,
     * and likewise when saving data, it will save the data in that locale.
     *
     * Note that in case an entity has a `_locale` property set, that locale
     * will win over the locale set via this method (and over the globally
     * configured one for that matter)!
     *
     * @param string|null $locale The locale to use for fetching and saving
     *   records. Pass `null` in order to unset the current locale, and to make
     *   the behavior fall back to using the globally configured locale.
     * @return this
     */
    auto locale(Nullable!string locale) {
        this.locale = $locale;

        return this;
    }

    /**
     * Returns the current locale.
     *
     * If no locale has been explicitly set via `locale()`, this method will return
     * the currently configured global locale.
     *
     * @return string
     * @see uim.cake.I18n\I18n::locale()
     * @see uim.cake.orm.Behavior\TranslateBehavior::locale()
     */
    string locale() {
        return this.locale ?: I18n::locale();
    }

    /**
     * Unset empty translations to avoid persistence.
     *
     * Should only be called if _config["allowEmptyTranslations"] is false.
     *
     * @param uim.cake.Datasource\IEntity $entity The entity to check for empty translations fields inside.
     * @return void
     */
    protected auto unsetEmptyFields($entity) {
        /** @var array<uim.cake.orm.Entity> $translations */
        $translations = (array)$entity.get("_translations");
        foreach ($translations as $locale: $translation) {
            myFields = $translation.extract(_config["fields"], false);
            foreach (myFields as myField: myValue) {
                if (myValue is null || myValue == "") {
                    $translation.unset(myField);
                }
            }

            $translation = $translation.extract(_config["fields"]);

            // If now, the current locale property is empty,
            // unset it completely.
            if (empty(array_filter($translation))) {
                unset($entity.get("_translations")[$locale]);
            }
        }

        // If now, the whole _translations property is empty,
        // unset it completely and return
        if (empty($entity.get("_translations"))) {
            $entity.unset("_translations");
        }
    }

    /**
     * Build a set of properties that should be included in the marshalling process.

     * Add in `_translations` marshalling handlers. You can disable marshalling
     * of translations by setting `"translations":false` in the options
     * provided to `Table::newEntity()` or `Table::patchEntity()`.
     *
     * @param uim.cake.orm.Marshaller $marshaller The marhshaller of the table the behavior is attached to.
     * @param array $map The property map being built.
     * @param array<string, mixed> myOptions The options array used in the marshalling call.
     * @return array A map of `[property: callable]` of additional properties to marshal.
     */
    function buildMarshalMap(Marshaller $marshaller, array $map, array myOptions): array
    {
        if (isset(myOptions["translations"]) && !myOptions["translations"]) {
            return [];
        }

        return [
            "_translations":function (myValue, $entity) use ($marshaller, myOptions) {
                if (!is_array(myValue)) {
                    return null;
                }

                /** @var array<string, uim.cake.Datasource\IEntity>|null $translations */
                $translations = $entity.get("_translations");
                if ($translations is null) {
                    $translations = [];
                }

                myOptions["validate"] = _config["validator"];
                myErrors = [];
                foreach (myValue as myLanguage: myFields) {
                    if (!isset($translations[myLanguage])) {
                        $translations[myLanguage] = this.table.newEmptyEntity();
                    }
                    $marshaller.merge($translations[myLanguage], myFields, myOptions);

                    $translationErrors = $translations[myLanguage].getErrors();
                    if ($translationErrors) {
                        myErrors[myLanguage] = $translationErrors;
                    }
                }

                // Set errors into the root entity, so validation errors match the original form data position.
                if (myErrors) {
                    $entity.setErrors(["_translations":myErrors]);
                }

                return $translations;
            },
        ];
    }

    /**
     * Unsets the temporary `_i18n` property after the entity has been saved
     *
     * @param uim.cake.events.IEvent myEvent The beforeSave event that was fired
     * @param uim.cake.Datasource\IEntity $entity The entity that is going to be saved
     * @return void
     */
    void afterSave(IEvent myEvent, IEntity $entity) {
        $entity.unset("_i18n");
    }
}
