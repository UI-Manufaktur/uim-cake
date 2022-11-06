

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.1
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.caketasources;

/**
 * The basis for every query object
 *
 * @method this andWhere($conditions, array myTypes = []) Connects any previously defined set of conditions to the
 *   provided list using the AND operator. {@see \Cake\Database\Query::andWhere()}
 * @method \Cake\Datasource\IEntity|array firstOrFail() Get the first result from the executing query or raise an exception.
 *   {@see \Cake\Database\Query::firstOrFail()}
 */
interface QueryInterface
{
    /**
     * Adds fields to be selected from datasource.
     *
     * Calling this function multiple times will append more fields to the list
     * of fields to be selected.
     *
     * If `true` is passed in the second argument, any previous selections will
     * be overwritten with the list passed in the first argument.
     *
     * @param \Cake\Database\IExpression|\Cake\ORM\Association|\Cake\ORM\Table|callable|array|string myFields Fields.
     * @param bool $overwrite whether to reset fields with passed list or not
     * @return this
     */
    function select(myFields, bool $overwrite = false);

    /**
     * Returns a key => value array representing a single aliased field
     * that can be passed directly to the select() method.
     * The key will contain the alias and the value the actual field name.
     *
     * If the field is already aliased, then it will not be changed.
     * If no myAlias is passed, the default table for this query will be used.
     *
     * @param string myField The field to alias
     * @param string|null myAlias the alias used to prefix the field
     * @return array
     */
    function aliasField(string myField, Nullable!string myAlias = null): array;

    /**
     * Runs `aliasField()` for each field in the provided list and returns
     * the result under a single array.
     *
     * @param array myFields The fields to alias
     * @param string|null $defaultAlias The default alias
     * @return array<string>
     */
    function aliasFields(array myFields, Nullable!string $defaultAlias = null): array;

    /**
     * Fetch the results for this query.
     *
     * Will return either the results set through setResult(), or execute this query
     * and return the ResultSetDecorator object ready for streaming of results.
     *
     * ResultSetDecorator is a traversable object that : the methods found
     * on Cake\Collection\Collection.
     *
     * @return \Cake\Datasource\ResultSetInterface
     */
    function all(): ResultSetInterface;

    /**
     * Populates or adds parts to current query clauses using an array.
     * This is handy for passing all query clauses at once. The option array accepts:
     *
     * - fields: Maps to the select method
     * - conditions: Maps to the where method
     * - limit: Maps to the limit method
     * - order: Maps to the order method
     * - offset: Maps to the offset method
     * - group: Maps to the group method
     * - having: Maps to the having method
     * - contain: Maps to the contain options for eager loading
     * - join: Maps to the join method
     * - page: Maps to the page method
     *
     * ### Example:
     *
     * ```
     * myQuery.applyOptions([
     *   'fields' => ['id', 'name'],
     *   'conditions' => [
     *     'created >=' => '2013-01-01'
     *   ],
     *   'limit' => 10
     * ]);
     * ```
     *
     * Is equivalent to:
     *
     * ```
     *  myQuery
     *  .select(['id', 'name'])
     *  .where(['created >=' => '2013-01-01'])
     *  .limit(10)
     * ```
     *
     * @param array<string, mixed> myOptions list of query clauses to apply new parts to.
     * @return this
     */
    function applyOptions(array myOptions);

    /**
     * Apply custom finds to against an existing query object.
     *
     * Allows custom find methods to be combined and applied to each other.
     *
     * ```
     * myRepository.find('all').find('recent');
     * ```
     *
     * The above is an example of stacking multiple finder methods onto
     * a single query.
     *
     * @param string myFinder The finder method to use.
     * @param array<string, mixed> myOptions The options for the finder.
     * @return static Returns a modified query.
     */
    function find(string myFinder, array myOptions = []);

    /**
     * Returns the first result out of executing this query, if the query has not been
     * executed before, it will set the limit clause to 1 for performance reasons.
     *
     * ### Example:
     *
     * ```
     * $singleUser = myQuery.select(['id', 'username']).first();
     * ```
     *
     * @return \Cake\Datasource\IEntity|array|null the first result from the ResultSet
     */
    function first();

    /**
     * Returns the total amount of results for the query.
     *
     * @return int
     */
    function count(): int;

    /**
     * Sets the number of records that should be retrieved from database,
     * accepts an integer or an expression object that evaluates to an integer.
     * In some databases, this operation might not be supported or will require
     * the query to be transformed in order to limit the result set size.
     *
     * ### Examples
     *
     * ```
     * myQuery.limit(10) // generates LIMIT 10
     * myQuery.limit(myQuery.newExpr().add(['1 + 1'])); // LIMIT (1 + 1)
     * ```
     *
     * @param \Cake\Database\IExpression|int|null $limit number of records to be returned
     * @return this
     */
    function limit($limit);

    /**
     * Sets the number of records that should be skipped from the original result set
     * This is commonly used for paginating large results. Accepts an integer or an
     * expression object that evaluates to an integer.
     *
     * In some databases, this operation might not be supported or will require
     * the query to be transformed in order to limit the result set size.
     *
     * ### Examples
     *
     * ```
     *  myQuery.offset(10) // generates OFFSET 10
     *  myQuery.offset(myQuery.newExpr().add(['1 + 1'])); // OFFSET (1 + 1)
     * ```
     *
     * @param \Cake\Database\IExpression|int|null $offset number of records to be skipped
     * @return this
     */
    function offset($offset);

    /**
     * Adds a single or multiple fields to be used in the ORDER clause for this query.
     * Fields can be passed as an array of strings, array of expression
     * objects, a single expression or a single string.
     *
     * If an array is passed, keys will be used as the field itself and the value will
     * represent the order in which such field should be ordered. When called multiple
     * times with the same fields as key, the last order definition will prevail over
     * the others.
     *
     * By default this function will append any passed argument to the list of fields
     * to be selected, unless the second argument is set to true.
     *
     * ### Examples:
     *
     * ```
     * myQuery.order(['title' => 'DESC', 'author_id' => 'ASC']);
     * ```
     *
     * Produces:
     *
     * `ORDER BY title DESC, author_id ASC`
     *
     * ```
     * myQuery
     *     .order(['title' => myQuery.newExpr('DESC NULLS FIRST')])
     *     .order('author_id');
     * ```
     *
     * Will generate:
     *
     * `ORDER BY title DESC NULLS FIRST, author_id`
     *
     * ```
     * $expression = myQuery.newExpr().add(['id % 2 = 0']);
     * myQuery.order($expression).order(['title' => 'ASC']);
     * ```
     *
     * Will become:
     *
     * `ORDER BY (id %2 = 0), title ASC`
     *
     * If you need to set complex expressions as order conditions, you
     * should use `orderAsc()` or `orderDesc()`.
     *
     * @param \Cake\Database\IExpression|\Closure|array|string myFields fields to be added to the list
     * @param bool $overwrite whether to reset order with field list or not
     * @return this
     */
    function order(myFields, $overwrite = false);

    /**
     * Set the page of results you want.
     *
     * This method provides an easier to use interface to set the limit + offset
     * in the record set you want as results. If empty the limit will default to
     * the existing limit clause, and if that too is empty, then `25` will be used.
     *
     * Pages must start at 1.
     *
     * @param int $num The page number you want.
     * @param int|null $limit The number of rows you want in the page. If null
     *  the current limit clause will be used.
     * @return this
     * @throws \InvalidArgumentException If page number < 1.
     */
    function page(int $num, Nullable!int $limit = null);

    /**
     * Returns an array representation of the results after executing the query.
     *
     * @return array
     */
    function toArray(): array;

    /**
     * Set the default Table object that will be used by this query
     * and form the `FROM` clause.
     *
     * @param \Cake\Datasource\IRepository myRepository The default repository object to use
     * @return this
     */
    function repository(IRepository myRepository);

    /**
     * Returns the default repository object that will be used by this query,
     * that is, the repository that will appear in the from clause.
     *
     * @return \Cake\Datasource\IRepository|null myRepository The default repository object to use
     */
    auto getRepository(): ?IRepository;

    /**
     * Adds a condition or set of conditions to be used in the WHERE clause for this
     * query. Conditions can be expressed as an array of fields as keys with
     * comparison operators in it, the values for the array will be used for comparing
     * the field to such literal. Finally, conditions can be expressed as a single
     * string or an array of strings.
     *
     * When using arrays, each entry will be joined to the rest of the conditions using
     * an AND operator. Consecutive calls to this function will also join the new
     * conditions specified using the AND operator. Additionally, values can be
     * expressed using expression objects which can include other query objects.
     *
     * Any conditions created with this methods can be used with any SELECT, UPDATE
     * and DELETE type of queries.
     *
     * ### Conditions using operators:
     *
     * ```
     *  myQuery.where([
     *      'posted >=' => new DateTime('3 days ago'),
     *      'title LIKE' => 'Hello W%',
     *      'author_id' => 1,
     *  ], ['posted' => 'datetime']);
     * ```
     *
     * The previous example produces:
     *
     * `WHERE posted >= 2012-01-27 AND title LIKE 'Hello W%' AND author_id = 1`
     *
     * Second parameter is used to specify what type is expected for each passed
     * key. Valid types can be used from the mapped with Database\Type class.
     *
     * ### Nesting conditions with conjunctions:
     *
     * ```
     *  myQuery.where([
     *      'author_id !=' => 1,
     *      'OR' => ['published' => true, 'posted <' => new DateTime('now')],
     *      'NOT' => ['title' => 'Hello']
     *  ], ['published' => boolean, 'posted' => 'datetime']
     * ```
     *
     * The previous example produces:
     *
     * `WHERE author_id = 1 AND (published = 1 OR posted < '2012-02-01') AND NOT (title = 'Hello')`
     *
     * You can nest conditions using conjunctions as much as you like. Sometimes, you
     * may want to define 2 different options for the same key, in that case, you can
     * wrap each condition inside a new array:
     *
     * `myQuery.where(['OR' => [['published' => false], ['published' => true]])`
     *
     * Keep in mind that every time you call where() with the third param set to false
     * (default), it will join the passed conditions to the previous stored list using
     * the AND operator. Also, using the same array key twice in consecutive calls to
     * this method will not override the previous value.
     *
     * ### Using expressions objects:
     *
     * ```
     *  $exp = myQuery.newExpr().add(['id !=' => 100, 'author_id' != 1]).tieWith('OR');
     *  myQuery.where(['published' => true], ['published' => 'boolean']).where($exp);
     * ```
     *
     * The previous example produces:
     *
     * `WHERE (id != 100 OR author_id != 1) AND published = 1`
     *
     * Other Query objects that be used as conditions for any field.
     *
     * ### Adding conditions in multiple steps:
     *
     * You can use callable functions to construct complex expressions, functions
     * receive as first argument a new QueryExpression object and this query instance
     * as second argument. Functions must return an expression object, that will be
     * added the list of conditions for the query using the AND operator.
     *
     * ```
     *  myQuery
     *  .where(['title !=' => 'Hello World'])
     *  .where(function ($exp, myQuery) {
     *      $or = $exp.or(['id' => 1]);
     *      $and = $exp.and(['id >' => 2, 'id <' => 10]);
     *  return $or.add($and);
     *  });
     * ```
     *
     * * The previous example produces:
     *
     * `WHERE title != 'Hello World' AND (id = 1 OR (id > 2 AND id < 10))`
     *
     * ### Conditions as strings:
     *
     * ```
     *  myQuery.where(['articles.author_id = authors.id', 'modified IS NULL']);
     * ```
     *
     * The previous example produces:
     *
     * `WHERE articles.author_id = authors.id AND modified IS NULL`
     *
     * Please note that when using the array notation or the expression objects, all
     * values will be correctly quoted and transformed to the correspondent database
     * data type automatically for you, thus securing your application from SQL injections.
     * If you use string conditions make sure that your values are correctly quoted.
     * The safest thing you can do is to never use string conditions.
     *
     * @param \Closure|array|string|null $conditions The conditions to filter on.
     * @param array<string, string> myTypes Associative array of type names used to bind values to query
     * @param bool $overwrite whether to reset conditions with passed list or not
     * @return this
     */
    function where($conditions = null, array myTypes = [], bool $overwrite = false);
}