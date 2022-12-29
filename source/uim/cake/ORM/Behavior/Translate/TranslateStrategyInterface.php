


 *



 * @license       https://www.opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.ORM\Behavior\Translate;

use ArrayObject;
import uim.cake.Collection\ICollection;
import uim.cake.Datasource\EntityInterface;
import uim.cake.Event\EventInterface;
import uim.cake.ORM\PropertyMarshalInterface;
import uim.cake.ORM\Query;
import uim.cake.ORM\Table;

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
    function getTranslationTable(): Table;

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
    function setLocale(?string $locale);

    /**
     * Returns the current locale.
     *
     * If no locale has been explicitly set via `setLocale()`, this method will
     * return the currently configured global locale.
     *
     * @return string
     */
    function getLocale(): string;

    /**
     * Returns a fully aliased field name for translated fields.
     *
     * If the requested field is configured as a translation field, field with
     * an alias of a corresponding association is returned. Table-aliased
     * field name is returned for all other fields.
     *
     * @param string $field Field name to be aliased.
     * @return string
     */
    function translationField(string $field): string;

    /**
     * Modifies the results from a table find in order to merge full translation records
     * into each entity under the `_translations` key
     *
     * @param \Cake\Datasource\IResultSet $results Results to modify.
     * @return \Cake\Collection\ICollection
     */
    function groupTranslations($results): ICollection;

    /**
     * Callback method that listens to the `beforeFind` event in the bound
     * table. It modifies the passed query by eager loading the translated fields
     * and adding a formatter to copy the values into the main table records.
     *
     * @param \Cake\Event\IEvent $event The beforeFind event that was fired.
     * @param \Cake\ORM\Query $query Query
     * @param \ArrayObject $options The options for the query
     * @return void
     */
    function beforeFind(IEvent $event, Query $query, ArrayObject $options);

    /**
     * Modifies the entity before it is saved so that translated fields are persisted
     * in the database too.
     *
     * @param \Cake\Event\IEvent $event The beforeSave event that was fired
     * @param \Cake\Datasource\EntityInterface $entity The entity that is going to be saved
     * @param \ArrayObject $options the options passed to the save method
     * @return void
     */
    function beforeSave(IEvent $event, EntityInterface $entity, ArrayObject $options);

    /**
     * Unsets the temporary `_i18n` property after the entity has been saved
     *
     * @param \Cake\Event\IEvent $event The beforeSave event that was fired
     * @param \Cake\Datasource\EntityInterface $entity The entity that is going to be saved
     * @return void
     */
    function afterSave(IEvent $event, EntityInterface $entity);
}
