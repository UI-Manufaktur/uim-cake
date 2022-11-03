module uim.cake.orm.Behavior\Translate;

use ArrayObject;
import uim.cake.collection\ICollection;
import uim.cake.Datasource\IEntity;
import uim.cake.Event\IEvent;
import uim.cake.orm.PropertyMarshalInterface;
import uim.cake.orm.Query;
import uim.cake.orm.Table;

/**
 * This interface describes the methods for translate behavior strategies.
 */
interface TranslateStrategyInterface : PropertyMarshalInterface
{
    /**
     * Return translation table instance.
     *
     * @return \Cake\ORM\Table
     */
    auto getTranslationTable(): Table;

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
    auto setLocale(?string $locale);

    /**
     * Returns the current locale.
     *
     * If no locale has been explicitly set via `setLocale()`, this method will
     * return the currently configured global locale.
     *
     * @return string
     */
    string getLocale();

    /**
     * Returns a fully aliased field name for translated fields.
     *
     * If the requested field is configured as a translation field, field with
     * an alias of a corresponding association is returned. Table-aliased
     * field name is returned for all other fields.
     *
     * @param string myField Field name to be aliased.
     * @return string
     */
    string translationField(string myField);

    /**
     * Modifies the results from a table find in order to merge full translation records
     * into each entity under the `_translations` key
     *
     * @param \Cake\Datasource\ResultSetInterface myResults Results to modify.
     * @return \Cake\Collection\ICollection
     */
    ICollection
    /**
     * Callback method that listens to the `beforeFind` event in the bound
     * table. It modifies the passed query by eager loading the translated fields
     * and adding a formatter to copy the values into the main table records.
     *
     * @param \Cake\Event\IEvent myEvent The beforeFind event that was fired.
     * @param \Cake\ORM\Query myQuery Query
     * @param \ArrayObject myOptions The options for the query
     * @return void
     */
    void beforeFind(IEvent myEvent, Query myQuery, ArrayObject myOptions);

    /**
     * Modifies the entity before it is saved so that translated fields are persisted
     * in the database too.
     *
     * @param \Cake\Event\IEvent myEvent The beforeSave event that was fired
     * @param \Cake\Datasource\IEntity $entity The entity that is going to be saved
     * @param \ArrayObject myOptions the options passed to the save method
     * @return void
     */
    function beforeSave(IEvent myEvent, IEntity $entity, ArrayObject myOptions);

    /**
     * Unsets the temporary `_i18n` property after the entity has been saved
     *
     * @param \Cake\Event\IEvent myEvent The beforeSave event that was fired
     * @param \Cake\Datasource\IEntity $entity The entity that is going to be saved
     * @return void
     */
    function afterSave(IEvent myEvent, IEntity $entity);
}
