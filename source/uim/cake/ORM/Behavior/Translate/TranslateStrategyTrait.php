
module uim.cake.orm.Behavior\Translate;

import uim.cake.datasources.EntityInterface;
import uim.cake.events.EventInterface;
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
     * @var uim.cake.orm.Table
     */
    protected $table;

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
     * @var uim.cake.orm.Table
     */
    protected $translationTable;

    /**
     * Return translation table instance.
     *
     * @return uim.cake.orm.Table
     */
    function getTranslationTable(): Table
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
    function setLocale(?string $locale) {
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
     * @see uim.cake.I18n\I18n::getLocale()
     * @see uim.cake.orm.Behavior\TranslateBehavior::setLocale()
     */
    function getLocale(): string
    {
        return this.locale ?: I18n::getLocale();
    }

    /**
     * Unset empty translations to avoid persistence.
     *
     * Should only be called if _config["allowEmptyTranslations"] is false.
     *
     * @param uim.cake.Datasource\EntityInterface $entity The entity to check for empty translations fields inside.
     * @return void
     */
    protected function unsetEmptyFields($entity) {
        /** @var array<uim.cake.orm.Entity> $translations */
        $translations = (array)$entity.get("_translations");
        foreach ($translations as $locale: $translation) {
            $fields = $translation.extract(_config["fields"], false);
            foreach ($fields as $field: $value) {
                if ($value == null || $value == "") {
                    $translation.unset($field);
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
     * of translations by setting `"translations": false` in the options
     * provided to `Table::newEntity()` or `Table::patchEntity()`.
     *
     * @param uim.cake.orm.Marshaller $marshaller The marhshaller of the table the behavior is attached to.
     * @param array $map The property map being built.
     * @param array<string, mixed> $options The options array used in the marshalling call.
     * @return array A map of `[property: callable]` of additional properties to marshal.
     */
    function buildMarshalMap(Marshaller $marshaller, array $map, array $options): array
    {
        if (isset($options["translations"]) && !$options["translations"]) {
            return [];
        }

        return [
            "_translations": function ($value, $entity) use ($marshaller, $options) {
                if (!is_array($value)) {
                    return null;
                }

                /** @var array<string, uim.cake.Datasource\EntityInterface>|null $translations */
                $translations = $entity.get("_translations");
                if ($translations == null) {
                    $translations = [];
                }

                $options["validate"] = _config["validator"];
                $errors = [];
                foreach ($value as $language: $fields) {
                    if (!isset($translations[$language])) {
                        $translations[$language] = this.table.newEmptyEntity();
                    }
                    $marshaller.merge($translations[$language], $fields, $options);

                    $translationErrors = $translations[$language].getErrors();
                    if ($translationErrors) {
                        $errors[$language] = $translationErrors;
                    }
                }

                // Set errors into the root entity, so validation errors match the original form data position.
                if ($errors) {
                    $entity.setErrors(["_translations": $errors]);
                }

                return $translations;
            },
        ];
    }

    /**
     * Unsets the temporary `_i18n` property after the entity has been saved
     *
     * @param uim.cake.events.IEvent $event The beforeSave event that was fired
     * @param uim.cake.Datasource\EntityInterface $entity The entity that is going to be saved
     * @return void
     */
    void afterSave(IEvent $event, EntityInterface $entity) {
        $entity.unset("_i18n");
    }
}
