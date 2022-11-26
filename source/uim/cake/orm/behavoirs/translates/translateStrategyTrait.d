module uim.cake.orm.behaviors\Translate;

import uim.cake.datasources\IEntity;
import uim.cake.events\IEvent;
import uim.cake.I18n\I18n;
import uim.cake.orm.Marshaller;
import uim.cake.orm.Table;

/**
 * Contains common code needed by TranslateBehavior strategy classes.
 */
trait TranslateStrategyTrait
{
    /**
     * Table instance
     *
     * @var \Cake\ORM\Table
     */
    protected myTable;

    /**
     * The locale name that will be used to override fields in the bound table
     * from the translations table
     *
     * @var string|null
     */
    protected $locale;

    /**
     * Instance of Table responsible for translating
     *
     * @var \Cake\ORM\Table
     */
    protected $translationTable;

    /**
     * Return translation table instance.
     *
     * @return \Cake\ORM\Table
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
    auto setLocale(Nullable!string $locale) {
        this.locale = $locale;

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
    string getLocale() {
        return this.locale ?: I18n::getLocale();
    }

    /**
     * Unset empty translations to avoid persistence.
     *
     * Should only be called if this._config["allowEmptyTranslations"] is false.
     *
     * @param \Cake\Datasource\IEntity $entity The entity to check for empty translations fields inside.
     * @return void
     */
    protected auto unsetEmptyFields($entity) {
        /** @var array<\Cake\ORM\Entity> $translations */
        $translations = (array)$entity.get("_translations");
        foreach ($translations as $locale => $translation) {
            myFields = $translation.extract(this._config["fields"], false);
            foreach (myFields as myField => myValue) {
                if (myValue === null || myValue == "") {
                    $translation.unset(myField);
                }
            }

            $translation = $translation.extract(this._config["fields"]);

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
     * @param \Cake\ORM\Marshaller $marshaller The marhshaller of the table the behavior is attached to.
     * @param array $map The property map being built.
     * @param array<string, mixed> myOptions The options array used in the marshalling call.
     * @return array A map of `[property => callable]` of additional properties to marshal.
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

                /** @var array<string, \Cake\Datasource\IEntity>|null $translations */
                $translations = $entity.get("_translations");
                if ($translations === null) {
                    $translations = [];
                }

                myOptions["validate"] = this._config["validator"];
                myErrors = [];
                foreach (myValue as myLanguage => myFields) {
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
     * @param \Cake\Event\IEvent myEvent The beforeSave event that was fired
     * @param \Cake\Datasource\IEntity $entity The entity that is going to be saved
     * @return void
     */
    function afterSave(IEvent myEvent, IEntity $entity) {
        $entity.unset("_i18n");
    }
}
