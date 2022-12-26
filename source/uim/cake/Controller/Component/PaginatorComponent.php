


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         2.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Controller\Component;

import uim.cake.Controller\Component;
import uim.cake.Controller\ComponentRegistry;
import uim.cake.Datasource\Paging\Exception\PageOutOfBoundsException;
import uim.cake.Datasource\Paging\NumericPaginator;
import uim.cake.Datasource\IResultSet;
import uim.cake.Http\Exception\NotFoundException;
use InvalidArgumentException;
use UnexpectedValueException;

/**
 * This component is used to handle automatic model data pagination. The primary way to use this
 * component is to call the paginate() method. There is a convenience wrapper on Controller as well.
 *
 * ### Configuring pagination
 *
 * You configure pagination when calling paginate(). See that method for more details.
 *
 * @link https://book.cakephp.org/4/en/controllers/components/pagination.html
 * @mixin \Cake\Datasource\Paging\NumericPaginator
 * @deprecated 4.4.0 Use Cake\Datasource\Paging\Paginator directly.
 */
class PaginatorComponent : Component
{
    /**
     * Datasource paginator instance.
     *
     * @var \Cake\Datasource\Paging\NumericPaginator
     */
    protected $_paginator;

    /**
     * @inheritDoc
     */
    public this(ComponentRegistry $registry, array $config = [])
    {
        deprecationWarning(
            "PaginatorComponent is deprecated, use a Cake\Datasource\Pagination\NumericPaginator instance directly."
        );

        if (!empty(_defaultConfig)) {
            throw new UnexpectedValueException("Default configuration must be set using a custom Paginator class.");
        }

        if (isset($config["paginator"])) {
            $config["className"] = $config["paginator"];
            deprecationWarning(
                "`paginator` option is deprecated,"
                . " use `className` instead a specify a paginator name/FQCN."
            );
        }

        if (isset($config["className"])) {
            if (!$config["className"] instanceof NumericPaginator) {
                throw new InvalidArgumentException("Paginator must be an instance of " . NumericPaginator::class);
            }
            _paginator = $config["className"];
            unset($config["className"]);
        } else {
            _paginator = new NumericPaginator();
        }

        parent::__construct($registry, $config);
    }

    /**
     * Events supported by this component.
     *
     * @return array<string, mixed>
     */
    function implementedEvents(): array
    {
        return [];
    }

    /**
     * Handles automatic pagination of model records.
     *
     * ### Configuring pagination
     *
     * When calling `paginate()` you can use the $settings parameter to pass in pagination settings.
     * These settings are used to build the queries made and control other pagination settings.
     *
     * If your settings contain a key with the current table"s alias. The data inside that key will be used.
     * Otherwise, the top level configuration will be used.
     *
     * ```
     *  $settings = [
     *    "limit": 20,
     *    "maxLimit": 100
     *  ];
     *  $results = $paginator.paginate($table, $settings);
     * ```
     *
     * The above settings will be used to paginate any Table. You can configure Table specific settings by
     * keying the settings with the Table alias.
     *
     * ```
     *  $settings = [
     *    "Articles": [
     *      "limit": 20,
     *      "maxLimit": 100
     *    ],
     *    "Comments": [ ... ]
     *  ];
     *  $results = $paginator.paginate($table, $settings);
     * ```
     *
     * This would allow you to have different pagination settings for `Articles` and `Comments` tables.
     *
     * ### Controlling sort fields
     *
     * By default CakePHP will automatically allow sorting on any column on the table object being
     * paginated. Often times you will want to allow sorting on either associated columns or calculated
     * fields. In these cases you will need to define an allowed list of fields you wish to allow
     * sorting on. You can define the allowed fields in the `$settings` parameter:
     *
     * ```
     * $settings = [
     *   "Articles": [
     *     "finder": "custom",
     *     "sortableFields": ["title", "author_id", "comment_count"],
     *   ]
     * ];
     * ```
     *
     * Passing an empty array as allowed list disallows sorting altogether.
     *
     * ### Paginating with custom finders
     *
     * You can paginate with any find type defined on your table using the `finder` option.
     *
     * ```
     *  $settings = [
     *    "Articles": [
     *      "finder": "popular"
     *    ]
     *  ];
     *  $results = $paginator.paginate($table, $settings);
     * ```
     *
     * Would paginate using the `find("popular")` method.
     *
     * You can also pass an already created instance of a query to this method:
     *
     * ```
     * $query = this.Articles.find("popular").matching("Tags", function ($q) {
     *   return $q.where(["name": "CakePHP"])
     * });
     * $results = $paginator.paginate($query);
     * ```
     *
     * ### Scoping Request parameters
     *
     * By using request parameter scopes you can paginate multiple queries in the same controller action:
     *
     * ```
     * $articles = $paginator.paginate($articlesQuery, ["scope": "articles"]);
     * $tags = $paginator.paginate($tagsQuery, ["scope": "tags"]);
     * ```
     *
     * Each of the above queries will use different query string parameter sets
     * for pagination data. An example URL paginating both results would be:
     *
     * ```
     * /dashboard?articles[page]=1&tags[page]=2
     * ```
     *
     * @param \Cake\Datasource\RepositoryInterface|\Cake\Datasource\IQuery $object Table or query to paginate.
     * @param array<string, mixed> $settings The settings/configuration used for pagination.
     * @return \Cake\Datasource\IResultSet Query results
     * @throws \Cake\Http\Exception\NotFoundException
     */
    function paginate(object $object, array $settings = []): IResultSet
    {
        $request = _registry.getController().getRequest();

        try {
            $results = _paginator.paginate(
                $object,
                $request.getQueryParams(),
                $settings
            );

            _setPagingParams();
        } catch (PageOutOfBoundsException $e) {
            _setPagingParams();

            throw new NotFoundException(null, null, $e);
        }

        return $results;
    }

    /**
     * Merges the various options that Pagination uses.
     * Pulls settings together from the following places:
     *
     * - General pagination settings
     * - Model specific settings.
     * - Request parameters
     *
     * The result of this method is the aggregate of all the option sets combined together. You can change
     * config value `allowedParameters` to modify which options/values can be set using request parameters.
     *
     * @param string $alias Model alias being paginated, if the general settings has a key with this value
     *   that key"s settings will be used for pagination instead of the general ones.
     * @param array<string, mixed> $settings The settings to merge with the request data.
     * @return array<string, mixed> Array of merged options.
     */
    function mergeOptions(string $alias, array $settings): array
    {
        $request = _registry.getController().getRequest();

        return _paginator.mergeOptions(
            $request.getQueryParams(),
            _paginator.getDefaults($alias, $settings)
        );
    }

    /**
     * Set paginator instance.
     *
     * @param \Cake\Datasource\Paging\NumericPaginator $paginator Paginator instance.
     * @return this
     */
    function setPaginator(NumericPaginator $paginator)
    {
        _paginator = $paginator;

        return this;
    }

    /**
     * Get paginator instance.
     *
     * @return \Cake\Datasource\Paging\NumericPaginator
     */
    function getPaginator(): NumericPaginator
    {
        return _paginator;
    }

    /**
     * Set paging params to request instance.
     *
     * @return void
     */
    protected function _setPagingParams(): void
    {
        $controller = this.getController();
        $request = $controller.getRequest();
        $paging = _paginator.getPagingParams() + (array)$request.getAttribute("paging", []);

        $controller.setRequest($request.withAttribute("paging", $paging));
    }

    /**
     * Proxy setting config options to Paginator.
     *
     * @param array<string, mixed>|string $key The key to set, or a complete array of configs.
     * @param mixed|null $value The value to set.
     * @param bool $merge Whether to recursively merge or overwrite existing config, defaults to true.
     * @return this
     */
    function setConfig($key, $value = null, $merge = true)
    {
        _paginator.setConfig($key, $value, $merge);

        return this;
    }

    /**
     * Proxy getting config options to Paginator.
     *
     * @param string|null $key The key to get or null for the whole config.
     * @param mixed $default The return value when the key does not exist.
     * @return mixed Config value being read.
     */
    function getConfig(?string $key = null, $default = null)
    {
        return _paginator.getConfig($key, $default);
    }

    /**
     * Proxy setting config options to Paginator.
     *
     * @param array<string, mixed>|string $key The key to set, or a complete array of configs.
     * @param mixed|null $value The value to set.
     * @return this
     */
    function configShallow($key, $value = null)
    {
        _paginator.configShallow($key, null);

        return this;
    }

    /**
     * Proxy method calls to Paginator.
     *
     * @param string $method Method name.
     * @param array $args Method arguments.
     * @return mixed
     */
    function __call(string $method, array $args)
    {
        return _paginator.{$method}(...$args);
    }
}
