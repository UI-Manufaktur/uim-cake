module uim.cake.orm.behaviors;

use ArrayObject;
import uim.cake.datasources\IEntity;
import uim.cake.events\IEvent;
import uim.cake.orm.Association;
import uim.cake.orm.behaviors;
use Closure;

/**
 * CounterCache behavior
 *
 * Enables models to cache the amount of connections in a given relation.
 *
 * Examples with Post model belonging to User model
 *
 * Regular counter cache
 * ```
 * [
 *     "Users" => [
 *         "post_count"
 *     ]
 * ]
 * ```
 *
 * Counter cache with scope
 * ```
 * [
 *     "Users" => [
 *         "posts_published" => [
 *             "conditions" => [
 *                 "published" => true
 *             ]
 *         ]
 *     ]
 * ]
 * ```
 *
 * Counter cache using custom find
 * ```
 * [
 *     "Users" => [
 *         "posts_published" => [
 *             "finder" => "published" // Will be using findPublished()
 *         ]
 *     ]
 * ]
 * ```
 *
 * Counter cache using lambda function returning the count
 * This is equivalent to example #2
 *
 * ```
 * [
 *     "Users" => [
 *         "posts_published" => function (IEvent myEvent, IEntity $entity, Table myTable) {
 *             myQuery = myTable.find("all").where([
 *                 "published" => true,
 *                 "user_id" => $entity.get("user_id")
 *             ]);
 *             return myQuery.count();
 *          }
 *     ]
 * ]
 * ```
 *
 * When using a lambda function you can return `false` to disable updating the counter value
 * for the current operation.
 *
 * Ignore updating the field if it is dirty
 * ```
 * [
 *     "Users" => [
 *         "posts_published" => [
 *             "ignoreDirty" => true
 *         ]
 *     ]
 * ]
 * ```
 *
 * You can disable counter updates entirely by sending the `ignoreCounterCache` option
 * to your save operation:
 *
 * ```
 * this.Articles.save($article, ["ignoreCounterCache" => true]);
 * ```
 */
class CounterCacheBehavior : Behavior
{
    /**
     * Store the fields which should be ignored
     *
     * @var array<string, array<string, bool>>
     */
    protected $_ignoreDirty = [];

    /**
     * beforeSave callback.
     *
     * Check if a field, which should be ignored, is dirty
     *
     * @param \Cake\Event\IEvent myEvent The beforeSave event that was fired
     * @param \Cake\Datasource\IEntity $entity The entity that is going to be saved
     * @param \ArrayObject myOptions The options for the query
     * @return void
     */
    function beforeSave(IEvent myEvent, IEntity $entity, ArrayObject myOptions) {
        if (isset(myOptions["ignoreCounterCache"]) && myOptions["ignoreCounterCache"] === true) {
            return;
        }

        foreach (this._config as $assoc => $settings) {
            $assoc = this._table.getAssociation($assoc);
            foreach ($settings as myField => myConfig) {
                if (is_int(myField)) {
                    continue;
                }

                $registryAlias = $assoc.getTarget().getRegistryAlias();
                $entityAlias = $assoc.getProperty();

                if (
                    !is_callable(myConfig) &&
                    isset(myConfig["ignoreDirty"]) &&
                    myConfig["ignoreDirty"] === true &&
                    $entity.$entityAlias.isDirty(myField)
                ) {
                    this._ignoreDirty[$registryAlias][myField] = true;
                }
            }
        }
    }

    /**
     * afterSave callback.
     *
     * Makes sure to update counter cache when a new record is created or updated.
     *
     * @param \Cake\Event\IEvent myEvent The afterSave event that was fired.
     * @param \Cake\Datasource\IEntity $entity The entity that was saved.
     * @param \ArrayObject myOptions The options for the query
     * @return void
     */
    function afterSave(IEvent myEvent, IEntity $entity, ArrayObject myOptions): void
    {
        if (isset(myOptions["ignoreCounterCache"]) && myOptions["ignoreCounterCache"] === true) {
            return;
        }

        this._processAssociations(myEvent, $entity);
        this._ignoreDirty = [];
    }

    /**
     * afterDelete callback.
     *
     * Makes sure to update counter cache when a record is deleted.
     *
     * @param \Cake\Event\IEvent myEvent The afterDelete event that was fired.
     * @param \Cake\Datasource\IEntity $entity The entity that was deleted.
     * @param \ArrayObject myOptions The options for the query
     * @return void
     */
    function afterDelete(IEvent myEvent, IEntity $entity, ArrayObject myOptions) {
        if (isset(myOptions["ignoreCounterCache"]) && myOptions["ignoreCounterCache"] === true) {
            return;
        }

        this._processAssociations(myEvent, $entity);
    }

    /**
     * Iterate all associations and update counter caches.
     *
     * @param \Cake\Event\IEvent myEvent Event instance.
     * @param \Cake\Datasource\IEntity $entity Entity.
     * @return void
     */
    protected auto _processAssociations(IEvent myEvent, IEntity $entity): void
    {
        foreach (this._config as $assoc => $settings) {
            $assoc = this._table.getAssociation($assoc);
            this._processAssociation(myEvent, $entity, $assoc, $settings);
        }
    }

    /**
     * Updates counter cache for a single association
     *
     * @param \Cake\Event\IEvent myEvent Event instance.
     * @param \Cake\Datasource\IEntity $entity Entity
     * @param \Cake\ORM\Association $assoc The association object
     * @param array $settings The settings for counter cache for this association
     * @return void
     * @throws \RuntimeException If invalid callable is passed.
     */
    protected auto _processAssociation(
        IEvent myEvent,
        IEntity $entity,
        Association $assoc,
        array $settings
    ): void {
        $foreignKeys = (array)$assoc.getForeignKey();
        myCountConditions = $entity.extract($foreignKeys);

        foreach (myCountConditions as myField => myValue) {
            if (myValue === null) {
                myCountConditions[myField . " IS"] = myValue;
                unset(myCountConditions[myField]);
            }
        }

        $primaryKeys = (array)$assoc.getBindingKey();
        $updateConditions = array_combine($primaryKeys, myCountConditions);

        myCountOriginalConditions = $entity.extractOriginalChanged($foreignKeys);
        if (myCountOriginalConditions !== []) {
            $updateOriginalConditions = array_combine($primaryKeys, myCountOriginalConditions);
        }

        foreach ($settings as myField => myConfig) {
            if (is_int(myField)) {
                myField = myConfig;
                myConfig = [];
            }

            if (
                isset(this._ignoreDirty[$assoc.getTarget().getRegistryAlias()][myField]) &&
                this._ignoreDirty[$assoc.getTarget().getRegistryAlias()][myField] === true
            ) {
                continue;
            }

            if (this._shouldUpdateCount($updateConditions)) {
                if (myConfig instanceof Closure) {
                    myCount = myConfig(myEvent, $entity, this._table, false);
                } else {
                    myCount = this._getCount(myConfig, myCountConditions);
                }
                if (myCount !== false) {
                    $assoc.getTarget().updateAll([myField => myCount], $updateConditions);
                }
            }

            if (isset($updateOriginalConditions) && this._shouldUpdateCount($updateOriginalConditions)) {
                if (myConfig instanceof Closure) {
                    myCount = myConfig(myEvent, $entity, this._table, true);
                } else {
                    myCount = this._getCount(myConfig, myCountOriginalConditions);
                }
                if (myCount !== false) {
                    $assoc.getTarget().updateAll([myField => myCount], $updateOriginalConditions);
                }
            }
        }
    }

    /**
     * Checks if the count should be updated given a set of conditions.
     *
     * @param array $conditions Conditions to update count.
     * @return bool True if the count update should happen, false otherwise.
     */
    protected auto _shouldUpdateCount(array $conditions) {
        return !empty(array_filter($conditions, function (myValue) {
            return myValue !== null;
        }));
    }

    /**
     * Fetches and returns the count for a single field in an association
     *
     * @param array<string, mixed> myConfig The counter cache configuration for a single field
     * @param array $conditions Additional conditions given to the query
     * @return int The number of relations matching the given config and conditions
     */
    protected auto _getCount(array myConfig, array $conditions): int
    {
        myFinder = "all";
        if (!empty(myConfig["finder"])) {
            myFinder = myConfig["finder"];
            unset(myConfig["finder"]);
        }

        myConfig["conditions"] = array_merge($conditions, myConfig["conditions"] ?? []);
        myQuery = this._table.find(myFinder, myConfig);

        return myQuery.count();
    }
}
