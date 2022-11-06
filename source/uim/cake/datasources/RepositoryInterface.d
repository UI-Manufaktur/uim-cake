module uim.caketasources;

/**
 * Describes the methods that any class representing a data storage should
 * comply with.
 */
interface IRepository
{
    /**
     * Sets the repository alias.
     *
     * @param string myAlias Table alias
     * @return this
     */
    auto setAlias(string myAlias);

    /**
     * Returns the repository alias.
     *
     * @return string
     */
    auto getAlias(): string;

    /**
     * Sets the table registry key used to create this table instance.
     *
     * @param string $registryAlias The key used to access this object.
     * @return this
     */
    auto setRegistryAlias(string $registryAlias);

    /**
     * Returns the table registry key used to create this table instance.
     *
     * @return string
     */
    auto getRegistryAlias(): string;

    /**
     * Test to see if a Repository has a specific field/column.
     *
     * @param string myField The field to check for.
     * @return bool True if the field exists, false if it does not.
     */
    bool hasField(string myField);

    /**
     * Creates a new Query for this repository and applies some defaults based on the
     * type of search that was selected.
     *
     * @param string myType the type of query to perform
     * @param array<string, mixed> myOptions An array that will be passed to Query::applyOptions()
     * @return \Cake\Datasource\QueryInterface
     */
    function find(string myType = 'all', array myOptions = []);

    /**
     * Returns a single record after finding it by its primary key, if no record is
     * found this method throws an exception.
     *
     * ### Example:
     *
     * ```
     * $id = 10;
     * $article = $articles.get($id);
     *
     * $article = $articles.get($id, ['contain' => ['Comments]]);
     * ```
     *
     * @param mixed $primaryKey primary key value to find
     * @param array<string, mixed> myOptions options accepted by `Table::find()`
     * @throws \Cake\Datasource\Exception\RecordNotFoundException if the record with such id
     * could not be found
     * @return \Cake\Datasource\IEntity
     * @see \Cake\Datasource\IRepository::find()
     */
    auto get($primaryKey, array myOptions = []): IEntity;

    /**
     * Creates a new Query instance for this repository
     *
     * @return \Cake\Datasource\QueryInterface
     */
    function query();

    /**
     * Update all matching records.
     *
     * Sets the myFields to the provided values based on $conditions.
     * This method will *not* trigger beforeSave/afterSave events. If you need those
     * first load a collection of records and update them.
     *
     * @param \Cake\Database\Expression\QueryExpression|\Closure|array|string myFields A hash of field => new value.
     * @param mixed $conditions Conditions to be used, accepts anything Query::where()
     * can take.
     * @return int Count Returns the affected rows.
     */
    function updateAll(myFields, $conditions): int;

    /**
     * Deletes all records matching the provided conditions.
     *
     * This method will *not* trigger beforeDelete/afterDelete events. If you
     * need those first load a collection of records and delete them.
     *
     * This method will *not* execute on associations' `cascade` attribute. You should
     * use database foreign keys + ON CASCADE rules if you need cascading deletes combined
     * with this method.
     *
     * @param mixed $conditions Conditions to be used, accepts anything Query::where()
     * can take.
     * @return int Returns the number of affected rows.
     * @see \Cake\Datasource\IRepository::delete()
     */
    function deleteAll($conditions): int;

    /**
     * Returns true if there is any record in this repository matching the specified
     * conditions.
     *
     * @param array $conditions list of conditions to pass to the query
     */
    bool exists($conditions);

    /**
     * Persists an entity based on the fields that are marked as dirty and
     * returns the same entity after a successful save or false in case
     * of any error.
     *
     * @param \Cake\Datasource\IEntity $entity the entity to be saved
     * @param \ArrayAccess|array myOptions The options to use when saving.
     * @return \Cake\Datasource\IEntity|false
     */
    function save(IEntity $entity, myOptions = []);

    /**
     * Delete a single entity.
     *
     * Deletes an entity and possibly related associations from the database
     * based on the 'dependent' option used when defining the association.
     *
     * @param \Cake\Datasource\IEntity $entity The entity to remove.
     * @param \ArrayAccess|array myOptions The options for the delete.
     * @return bool success
     */
    bool delete(IEntity $entity, myOptions = []);

    /**
     * This creates a new entity object.
     *
     * Careful: This does not trigger any field validation.
     * This entity can be persisted without validation error as empty record.
     * Always patch in required fields before saving.
     *
     * @return \Cake\Datasource\IEntity
     */
    function newEmptyEntity(): IEntity;

    /**
     * Create a new entity + associated entities from an array.
     *
     * This is most useful when hydrating request data back into entities.
     * For example, in your controller code:
     *
     * ```
     * $article = this.Articles.newEntity(this.request.getData());
     * ```
     *
     * The hydrated entity will correctly do an insert/update based
     * on the primary key data existing in the database when the entity
     * is saved. Until the entity is saved, it will be a detached record.
     *
     * @param array myData The data to build an entity with.
     * @param array<string, mixed> myOptions A list of options for the object hydration.
     * @return \Cake\Datasource\IEntity
     */
    function newEntity(array myData, array myOptions = []): IEntity;

    /**
     * Create a list of entities + associated entities from an array.
     *
     * This is most useful when hydrating request data back into entities.
     * For example, in your controller code:
     *
     * ```
     * $articles = this.Articles.newEntities(this.request.getData());
     * ```
     *
     * The hydrated entities can then be iterated and saved.
     *
     * @param array myData The data to build an entity with.
     * @param array<string, mixed> myOptions A list of options for the objects hydration.
     * @return array<\Cake\Datasource\IEntity> An array of hydrated records.
     */
    function newEntities(array myData, array myOptions = []): array;

    /**
     * Merges the passed `myData` into `$entity` respecting the accessible
     * fields configured on the entity. Returns the same entity after being
     * altered.
     *
     * This is most useful when editing an existing entity using request data:
     *
     * ```
     * $article = this.Articles.patchEntity($article, this.request.getData());
     * ```
     *
     * @param \Cake\Datasource\IEntity $entity the entity that will get the
     * data merged in
     * @param array myData key value list of fields to be merged into the entity
     * @param array<string, mixed> myOptions A list of options for the object hydration.
     * @return \Cake\Datasource\IEntity
     */
    function patchEntity(IEntity $entity, array myData, array myOptions = []): IEntity;

    /**
     * Merges each of the elements passed in `myData` into the entities
     * found in `$entities` respecting the accessible fields configured on the entities.
     * Merging is done by matching the primary key in each of the elements in `myData`
     * and `$entities`.
     *
     * This is most useful when editing a list of existing entities using request data:
     *
     * ```
     * $article = this.Articles.patchEntities($articles, this.request.getData());
     * ```
     *
     * @param \Traversable|array<\Cake\Datasource\IEntity> $entities the entities that will get the
     * data merged in
     * @param array myData list of arrays to be merged into the entities
     * @param array<string, mixed> myOptions A list of options for the objects hydration.
     * @return array<\Cake\Datasource\IEntity>
     */
    function patchEntities(iterable $entities, array myData, array myOptions = []): array;
}
