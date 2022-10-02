module uim.cake.controller\Component;

import uim.cake.controller\Component;
import uim.cake.controller\ComponentRegistry;
import uim.cake.Datasource\Exception\PageOutOfBoundsException;
import uim.cake.Datasource\Paginator;
import uim.cake.Datasource\ResultSetInterface;
import uim.cake.Http\Exception\NotFoundException;
use InvalidArgumentException;

/**
 * This component is used to handle automatic model data pagination. The primary way to use this
 * component is to call the paginate() method. There is a convenience wrapper on Controller as well.
 *
 * ### Configuring pagination
 *
 * You configure pagination when calling paginate(). See that method for more details.
 *
 * @link https://book.cakephp.org/4/en/controllers/components/pagination.html
 * @mixin \Cake\Datasource\Paginator
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
    protected $_defaultConfig = [
        'page' => 1,
        'limit' => 20,
        'maxLimit' => 100,
        'allowedParameters' => ['limit', 'sort', 'page', 'direction'],
    ];

    /**
     * Datasource paginator instance.
     *
     * @var \Cake\Datasource\Paginator
     */
    protected $_paginator;

    /**
     * @inheritDoc
     */
    this(ComponentRegistry $registry, array myConfig = [])
    {
        if (isset(myConfig['paginator'])) {
            if (!myConfig['paginator'] instanceof Paginator) {
                throw new InvalidArgumentException('Paginator must be an instance of ' . Paginator::class);
            }
            this._paginator = myConfig['paginator'];
            unset(myConfig['paginator']);
        } else {
            this._paginator = new Paginator();
        }

        super.this($registry, myConfig);
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
     * If your settings contain a key with the current table's alias. The data inside that key will be used.
     * Otherwise the top level configuration will be used.
     *
     * ```
     *  $settings = [
     *    'limit' => 20,
     *    'maxLimit' => 100
     *  ];
     *  myResults = $paginator.paginate(myTable, $settings);
     * ```
     *
     * The above settings will be used to paginate any Table. You can configure Table specific settings by
     * keying the settings with the Table alias.
     *
     * ```
     *  $settings = [
     *    'Articles' => [
     *      'limit' => 20,
     *      'maxLimit' => 100
     *    ],
     *    'Comments' => [ ... ]
     *  ];
     *  myResults = $paginator.paginate(myTable, $settings);
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
     *   'Articles' => [
     *     'finder' => 'custom',
     *     'sortableFields' => ['title', 'author_id', 'comment_count'],
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
     *    'Articles' => [
     *      'finder' => 'popular'
     *    ]
     *  ];
     *  myResults = $paginator.paginate(myTable, $settings);
     * ```
     *
     * Would paginate using the `find('popular')` method.
     *
     * You can also pass an already created instance of a query to this method:
     *
     * ```
     * myQuery = this.Articles.find('popular').matching('Tags', function ($q) {
     *   return $q.where(['name' => 'CakePHP'])
     * });
     * myResults = $paginator.paginate(myQuery);
     * ```
     *
     * ### Scoping Request parameters
     *
     * By using request parameter scopes you can paginate multiple queries in the same controller action:
     *
     * ```
     * $articles = $paginator.paginate($articlesQuery, ['scope' => 'articles']);
     * $tags = $paginator.paginate($tagsQuery, ['scope' => 'tags']);
     * ```
     *
     * Each of the above queries will use different query string parameter sets
     * for pagination data. An example URL paginating both results would be:
     *
     * ```
     * /dashboard?articles[page]=1&tags[page]=2
     * ```
     *
     * @param \Cake\Datasource\IRepository|\Cake\Datasource\QueryInterface $object Table or query to paginate.
     * @param array<string, mixed> $settings The settings/configuration used for pagination.
     * @return \Cake\Datasource\ResultSetInterface Query results
     * @throws \Cake\Http\Exception\NotFoundException
     */
    function paginate(object $object, array $settings = []): ResultSetInterface
    {
        myRequest = this._registry.getController().getRequest();

        try {
            myResults = this._paginator.paginate(
                $object,
                myRequest.getQueryParams(),
                $settings
            );

            this._setPagingParams();
        } catch (PageOutOfBoundsException $e) {
            this._setPagingParams();

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
     *   that key's settings will be used for pagination instead of the general ones.
     * @param array<string, mixed> $settings The settings to merge with the request data.
     * @return array<string, mixed> Array of merged options.
     */
    function mergeOptions(string myAlias, array $settings): array
    {
        myRequest = this._registry.getController().getRequest();

        return this._paginator.mergeOptions(
            myRequest.getQueryParams(),
            this._paginator.getDefaults(myAlias, $settings)
        );
    }

    /**
     * Set paginator instance.
     *
     * @param \Cake\Datasource\Paginator $paginator Paginator instance.
     * @return this
     */
    auto setPaginator(Paginator $paginator)
    {
        this._paginator = $paginator;

        return this;
    }

    /**
     * Get paginator instance.
     *
     * @return \Cake\Datasource\Paginator
     */
    auto getPaginator(): Paginator
    {
        return this._paginator;
    }

    /**
     * Set paging params to request instance.
     *
     * @return void
     */
    protected auto _setPagingParams(): void
    {
        $controller = this.getController();
        myRequest = $controller.getRequest();
        $paging = this._paginator.getPagingParams() + (array)myRequest.getAttribute('paging', []);

        $controller.setRequest(myRequest.withAttribute('paging', $paging));
    }

    /**
     * Proxy setting config options to Paginator.
     *
     * @param array<string, mixed>|string myKey The key to set, or a complete array of configs.
     * @param mixed|null myValue The value to set.
     * @param bool myMerge Whether to recursively merge or overwrite existing config, defaults to true.
     * @return this
     */
    auto setConfig(myKey, myValue = null, myMerge = true)
    {
        this._paginator.setConfig(myKey, myValue, myMerge);

        return this;
    }

    /**
     * Proxy getting config options to Paginator.
     *
     * @param string|null myKey The key to get or null for the whole config.
     * @param mixed $default The return value when the key does not exist.
     * @return mixed Config value being read.
     */
    auto getConfig(?string myKey = null, $default = null)
    {
        return this._paginator.getConfig(myKey, $default);
    }

    /**
     * Proxy setting config options to Paginator.
     *
     * @param array<string, mixed>|string myKey The key to set, or a complete array of configs.
     * @param mixed|null myValue The value to set.
     * @return this
     */
    function configShallow(myKey, myValue = null)
    {
        this._paginator.configShallow(myKey, null);

        return this;
    }

    /**
     * Proxy method calls to Paginator.
     *
     * @param string $method Method name.
     * @param array $args Method arguments.
     * @return mixed
     */
    auto __call(string $method, array $args)
    {
        return this._paginator.{$method}(...$args);
    }
}
