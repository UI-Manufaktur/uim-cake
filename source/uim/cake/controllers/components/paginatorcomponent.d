module uim.cake.controllerss.components;

@safe:
import uim.cake;

/**
 * This component is used to handle automatic model data pagination. The primary way to use this
 * component is to call the paginate() method. There is a convenience wrapper on Controller as well.
 *
 * ### Configuring pagination
 *
 * You configure pagination when calling paginate(). See that method for more details.
 *
 * @link https://book.UIM.org/4/en/controllers/components/pagination.html
 * @mixin uim.cake.Datasource\Paginator
 */
class PaginatorComponent : Component
{
    /**
     * Default pagination settings.
     *
     * When calling paginate() these settings will be merged with the configuration
     * you provide.
     *
     * - `maxLimit` - The maximum limit users can choose to view. Defaults to 100
     * - `limit` - The initial number of items per page. Defaults to 20.
     * - `page` - The starting page, defaults to 1.
     * - `allowedParameters` - A list of parameters users are allowed to set using request
     *   parameters. Modifying this list will allow users to have more influence
     *   over pagination, be careful with what you permit.
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        "page":1,
        "limit":20,
        "maxLimit":100,
        "allowedParameters":["limit", "sort", "page", "direction"],
    ];

    /**
     * Datasource paginator instance.
     *
     * @var uim.cake.datasources.Paginator
     */
    protected _paginator;


    this(ComponentRegistry $registry, array myConfig = []) {
        if (isset(myConfig["paginator"])) {
            if (!myConfig["paginator"] instanceof Paginator) {
                throw new InvalidArgumentException("Paginator must be an instance of " . Paginator::class);
            }
            _paginator = myConfig["paginator"];
            unset(myConfig["paginator"]);
        } else {
            _paginator = new Paginator();
        }

        super.this($registry, myConfig);
    }

    /**
     * Events supported by this component.
     *
     * @return array<string, mixed>
     */
    array implementedEvents() {
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
     * Otherwise the top level configuration will be used.
     *
     * ```
     *  $settings = [
     *    "limit":20,
     *    "maxLimit":100
     *  ];
     *  myResults = $paginator.paginate(myTable, $settings);
     * ```
     *
     * The above settings will be used to paginate any Table. You can configure Table specific settings by
     * keying the settings with the Table alias.
     *
     * ```
     *  $settings = [
     *    "Articles":[
     *      "limit":20,
     *      "maxLimit":100
     *    ],
     *    "Comments":[ ... ]
     *  ];
     *  myResults = $paginator.paginate(myTable, $settings);
     * ```
     *
     * This would allow you to have different pagination settings for `Articles` and `Comments` tables.
     *
     * ### Controlling sort fields
     *
     * By default UIM will automatically allow sorting on any column on the table object being
     * paginated. Often times you will want to allow sorting on either associated columns or calculated
     * fields. In these cases you will need to define an allowed list of fields you wish to allow
     * sorting on. You can define the allowed fields in the `$settings` parameter:
     *
     * ```
     * $settings = [
     *   "Articles":[
     *     "finder":"custom",
     *     "sortableFields":["title", "author_id", "comment_count"],
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
     *    "Articles":[
     *      "finder":"popular"
     *    ]
     *  ];
     *  myResults = $paginator.paginate(myTable, $settings);
     * ```
     *
     * Would paginate using the `find("popular")` method.
     *
     * You can also pass an already created instance of a query to this method:
     *
     * ```
     * myQuery = this.Articles.find("popular").matching("Tags", function ($q) {
     *   return $q.where(["name": "UIM"])
     * });
     * myResults = $paginator.paginate(myQuery);
     * ```
     *
     * ### Scoping Request parameters
     *
     * By using request parameter scopes you can paginate multiple queries in the same controller action:
     *
     * ```
     * $articles = $paginator.paginate($articlesQuery, ["scope":"articles"]);
     * $tags = $paginator.paginate($tagsQuery, ["scope":"tags"]);
     * ```
     *
     * Each of the above queries will use different query string parameter sets
     * for pagination data. An example URL paginating both results would be:
     *
     * ```
     * /dashboard?articles[page]=1&tags[page]=2
     * ```
     *
     * @param uim.cake.Datasource\IRepository|uim.cake.Datasource\IQuery $object Table or query to paginate.
     * @param array<string, mixed> $settings The settings/configuration used for pagination.
     * @return uim.cake.Datasource\IResultSet Query results
     * @throws uim.cake.http.exceptions.NotFoundException
     */
    IResultSet paginate(object $object, array $settings = []) {
        myRequest = _registry.getController().getRequest();

        try {
            myResults = _paginator.paginate(
                $object,
                myRequest.getQueryParams(),
                $settings
            );

            _setPagingParams();
        } catch (PageOutOfBoundsException $e) {
            _setPagingParams();

            throw new NotFoundException(null, null, $e);
        }

        return myResults;
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
     * @param string myAlias Model alias being paginated, if the general settings has a key with this value
     *   that key"s settings will be used for pagination instead of the general ones.
     * @param array<string, mixed> $settings The settings to merge with the request data.
     * @return array<string, mixed> Array of merged options.
     */
    array mergeOptions(string myAlias, array $settings) {
        auto myRequest = _registry.getController().getRequest();

        return _paginator.mergeOptions(
            myRequest.getQueryParams(),
            _paginator.getDefaults(myAlias, $settings)
        );
    }

    /**
     * Set paginator instance.
     *
     * @param uim.cake.Datasource\Paginator $paginator Paginator instance.
     * @return this
     */
    auto setPaginator(Paginator $paginator) {
        _paginator = $paginator;

        return this;
    }

    /**
     * Get paginator instance.
     *
     * @return uim.cake.Datasource\Paginator
     */
    auto getPaginator() {
        return _paginator;
    }

    /**
     * Set paging params to request instance.
     */
    protected void _setPagingParams() {
        $controller = this.getController();
        myRequest = $controller.getRequest();
        $paging = _paginator.getPagingParams() + (array)myRequest.getAttribute("paging", []);

        $controller.setRequest(myRequest.withAttribute("paging", $paging));
    }

    /**
     * Proxy setting config options to Paginator.
     *
     * @param array<string, mixed>|string myKey The key to set, or a complete array of configs.
     * @param mixed|null myValue The value to set.
     * @param bool myMerge Whether to recursively merge or overwrite existing config, defaults to true.
     * @return this
     */
    auto setConfig(myKey, myValue = null, myMerge = true) {
        _paginator.setConfig(myKey, myValue, myMerge);

        return this;
    }

    /**
     * Proxy getting config options to Paginator.
     *
     * @param string|null myKey The key to get or null for the whole config.
     * @param mixed $default The return value when the key does not exist.
     * @return mixed Config value being read.
     */
    auto getConfig(Nullable!string myKey = null, $default = null) {
        return _paginator.getConfig(myKey, $default);
    }

    /**
     * Proxy setting config options to Paginator.
     *
     * @param array<string, mixed>|string myKey The key to set, or a complete array of configs.
     * @param mixed|null myValue The value to set.
     * @return this
     */
    function configShallow(myKey, myValue = null) {
        _paginator.configShallow(myKey, null);

        return this;
    }

    /**
     * Proxy method calls to Paginator.
     *
     * @param string method Method name.
     * @param array $args Method arguments.
     * @return mixed
     */
    auto __call(string method, array $args) {
        return _paginator.{$method}(...$args);
    }
}
