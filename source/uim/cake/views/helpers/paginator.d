module uim.cakeews\Helper;

import uim.cakeilities.Hash;
import uim.cakeilities.Inflector;
import uim.cakeews\Helper;
import uim.cakeews\StringTemplate;
import uim.cakeews\StringTemplateTrait;
import uim.cakeews\View;

/**
 * Pagination Helper class for easy generation of pagination links.
 *
 * PaginationHelper encloses all methods needed when working with pagination.
 *
 * @property \Cake\View\Helper\UrlHelper myUrl
 * @property \Cake\View\Helper\NumberHelper $Number
 * @property \Cake\View\Helper\HtmlHelper $Html
 * @property \Cake\View\Helper\FormHelper $Form
 * @link https://book.UIM.org/4/en/views/helpers/paginator.html
 */
class PaginatorHelper : Helper
{
    use StringTemplateTrait;

    /**
     * List of helpers used by this helper
     *
     * @var array
     */
    protected $helpers = ['Url', 'Number', 'Html', 'Form'];

    /**
     * Default config for this class
     *
     * Options: Holds the default options for pagination links
     *
     * The values that may be specified are:
     *
     * - `url` Url of the action. See Router::url()
     * - `url['?']['sort']` the key that the recordset is sorted.
     * - `url['?']['direction']` Direction of the sorting (default: 'asc').
     * - `url['?']['page']` Page number to use in links.
     * - `model` The name of the model.
     * - `escape` Defines if the title field for the link should be escaped (default: true).
     * - `routePlaceholders` An array specifying which paging params should be
     *   passed as route placeholders instead of query string parameters. The array
     *   can have values `'sort'`, `'direction'`, `'page'`.
     *
     * Templates: the templates used by this class
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        'options' => [],
        'templates' => [
            'nextActive' => '<li class="next"><a rel="next" href="{{url}}">{{text}}</a></li>',
            'nextDisabled' => '<li class="next disabled"><a href="" onclick="return false;">{{text}}</a></li>',
            'prevActive' => '<li class="prev"><a rel="prev" href="{{url}}">{{text}}</a></li>',
            'prevDisabled' => '<li class="prev disabled"><a href="" onclick="return false;">{{text}}</a></li>',
            'counterRange' => '{{start}} - {{end}} of {{count}}',
            'counterPages' => '{{page}} of {{pages}}',
            'first' => '<li class="first"><a href="{{url}}">{{text}}</a></li>',
            'last' => '<li class="last"><a href="{{url}}">{{text}}</a></li>',
            'number' => '<li><a href="{{url}}">{{text}}</a></li>',
            'current' => '<li class="active"><a href="">{{text}}</a></li>',
            'ellipsis' => '<li class="ellipsis">&hellip;</li>',
            'sort' => '<a href="{{url}}">{{text}}</a>',
            'sortAsc' => '<a class="asc" href="{{url}}">{{text}}</a>',
            'sortDesc' => '<a class="desc" href="{{url}}">{{text}}</a>',
            'sortAscLocked' => '<a class="asc locked" href="{{url}}">{{text}}</a>',
            'sortDescLocked' => '<a class="desc locked" href="{{url}}">{{text}}</a>',
        ],
    ];

    /**
     * Default model of the paged sets
     *
     * @var string|null
     */
    protected $_defaultModel;

    /**
     * Constructor. Overridden to merge passed args with URL options.
     *
     * @param \Cake\View\View $view The View this helper is being attached to.
     * @param array<string, mixed> myConfig Configuration settings for the helper.
     */
    this(View $view, array myConfig = []) {
        super.this($view, myConfig);

        myQuery = this._View.getRequest().getQueryParams();
        unset(myQuery['page'], myQuery['limit'], myQuery['sort'], myQuery['direction']);
        this.setConfig(
            'options.url',
            array_merge(this._View.getRequest().getParam('pass', []), ['?' => myQuery])
        );
    }

    /**
     * Gets the current paging parameters from the resultset for the given model
     *
     * @param string|null myModel Optional model name. Uses the default if none is specified.
     * @return array The array of paging parameters for the paginated resultset.
     */
    function params(Nullable!string myModel = null): array
    {
        myRequest = this._View.getRequest();

        if (empty(myModel)) {
            myModel = (string)this.defaultModel();
        }

        myParams = myRequest.getAttribute('paging');

        return empty(myParams[myModel]) ? [] : myParams[myModel];
    }

    /**
     * Convenience access to any of the paginator params.
     *
     * @param string myKey Key of the paginator params array to retrieve.
     * @param string|null myModel Optional model name. Uses the default if none is specified.
     * @return mixed Content of the requested param.
     */
    function param(string myKey, Nullable!string myModel = null) {
        myParams = this.params(myModel);

        return myParams[myKey] ?? null;
    }

    /**
     * Sets default options for all pagination links
     *
     * @param array<string, mixed> myOptions Default options for pagination links.
     *   See PaginatorHelper::myOptions for list of keys.
     * @return void
     */
    function options(array myOptions = []): void
    {
        myRequest = this._View.getRequest();

        if (!empty(myOptions['paging'])) {
            myRequest = myRequest.withAttribute(
                'paging',
                myOptions['paging'] + myRequest.getAttribute('paging', [])
            );
            unset(myOptions['paging']);
        }

        myModel = (string)this.defaultModel();
        if (!empty(myOptions[myModel])) {
            myParams = myRequest.getAttribute('paging', []);
            myParams[myModel] = myOptions[myModel] + Hash::get(myParams, myModel, []);
            myRequest = myRequest.withAttribute('paging', myParams);
            unset(myOptions[myModel]);
        }

        this._View.setRequest(myRequest);

        this._config['options'] = array_filter(myOptions + this._config['options']);
        if (empty(this._config['options']['url'])) {
            this._config['options']['url'] = [];
        }
        if (!empty(this._config['options']['model'])) {
            this.defaultModel(this._config['options']['model']);
        }
    }

    /**
     * Gets the current page of the recordset for the given model
     *
     * @param string|null myModel Optional model name. Uses the default if none is specified.
     * @return int The current page number of the recordset.
     * @link https://book.UIM.org/4/en/views/helpers/paginator.html#checking-the-pagination-state
     */
    int current(Nullable!string myModel = null) {
        myParams = this.params(myModel);

        return myParams['page'] ?? 1;
    }

    /**
     * Gets the total number of pages in the recordset for the given model.
     *
     * @param string|null myModel Optional model name. Uses the default if none is specified.
     * @return int The total pages for the recordset.
     */
    int total(Nullable!string myModel = null) {
        myParams = this.params(myModel);

        return myParams['pageCount'] ?? 0;
    }

    /**
     * Gets the current key by which the recordset is sorted
     *
     * @param string|null myModel Optional model name. Uses the default if none is specified.
     * @param array<string, mixed> myOptions Options for pagination links.
     * @return string|null The name of the key by which the recordset is being sorted, or
     *  null if the results are not currently sorted.
     * @link https://book.UIM.org/4/en/views/helpers/paginator.html#creating-sort-links
     */
    function sortKey(Nullable!string myModel = null, array myOptions = []): Nullable!string
    {
        if (empty(myOptions)) {
            myOptions = this.params(myModel);
        }
        if (!empty(myOptions['sort'])) {
            return myOptions['sort'];
        }

        return null;
    }

    /**
     * Gets the current direction the recordset is sorted
     *
     * @param string|null myModel Optional model name. Uses the default if none is specified.
     * @param array<string, mixed> myOptions Options for pagination links.
     * @return string The direction by which the recordset is being sorted, or
     *  null if the results are not currently sorted.
     * @link https://book.UIM.org/4/en/views/helpers/paginator.html#creating-sort-links
     */
    function sortDir(Nullable!string myModel = null, array myOptions = []): string
    {
        $dir = null;

        if (empty(myOptions)) {
            myOptions = this.params(myModel);
        }

        if (!empty(myOptions['direction'])) {
            $dir = strtolower(myOptions['direction']);
        }

        if ($dir === 'desc') {
            return 'desc';
        }

        return 'asc';
    }

    /**
     * Generate an active/inactive link for next/prev methods.
     *
     * @param string|false $text The enabled text for the link.
     * @param bool myEnabled Whether the enabled/disabled version should be created.
     * @param array<string, mixed> myOptions An array of options from the calling method.
     * @param array<string, mixed> myTemplates An array of templates with the 'active' and 'disabled' keys.
     * @return string Generated HTML
     */
    protected auto _toggledLink($text, myEnabled, myOptions, myTemplates): string
    {
        myTemplate = myTemplates['active'];
        if (!myEnabled) {
            $text = myOptions['disabledTitle'];
            myTemplate = myTemplates['disabled'];
        }

        if (!myEnabled && $text === false) {
            return '';
        }
        $text = myOptions['escape'] ? h($text) : $text;

        myTemplater = this.templater();
        $newTemplates = myOptions['templates'] ?? false;
        if ($newTemplates) {
            myTemplater.push();
            myTemplateMethod = is_string(myOptions['templates']) ? 'load' : 'add';
            myTemplater.{myTemplateMethod}(myOptions['templates']);
        }

        if (!myEnabled) {
            $out = myTemplater.format(myTemplate, [
                'text' => $text,
            ]);

            if ($newTemplates) {
                myTemplater.pop();
            }

            return $out;
        }
        $paging = this.params(myOptions['model']);

        myUrl = this.generateUrl(
            ['page' => $paging['page'] + myOptions['step']],
            myOptions['model'],
            myOptions['url']
        );

        $out = myTemplater.format(myTemplate, [
            'url' => myUrl,
            'text' => $text,
        ]);

        if ($newTemplates) {
            myTemplater.pop();
        }

        return $out;
    }

    /**
     * Generates a "previous" link for a set of paged records
     *
     * ### Options:
     *
     * - `disabledTitle` The text to used when the link is disabled. This
     *   defaults to the same text at the active link. Setting to false will cause
     *   this method to return ''.
     * - `escape` Whether you want the contents html entity encoded, defaults to true
     * - `model` The model to use, defaults to PaginatorHelper::defaultModel()
     * - `url` An array of additional URL options to use for link generation.
     * - `templates` An array of templates, or template file name containing the
     *   templates you'd like to use when generating the link for previous page.
     *   The helper's original templates will be restored once prev() is done.
     *
     * @param string $title Title for the link. Defaults to '<< Previous'.
     * @param array<string, mixed> myOptions Options for pagination link. See above for list of keys.
     * @return string A "previous" link or a disabled link.
     * @link https://book.UIM.org/4/en/views/helpers/paginator.html#creating-jump-links
     */
    function prev(string $title = '<< Previous', array myOptions = []): string
    {
        $defaults = [
            'url' => [],
            'model' => this.defaultModel(),
            'disabledTitle' => $title,
            'escape' => true,
        ];
        myOptions += $defaults;
        myOptions['step'] = -1;

        myEnabled = this.hasPrev(myOptions['model']);
        myTemplates = [
            'active' => 'prevActive',
            'disabled' => 'prevDisabled',
        ];

        return this._toggledLink($title, myEnabled, myOptions, myTemplates);
    }

    /**
     * Generates a "next" link for a set of paged records
     *
     * ### Options:
     *
     * - `disabledTitle` The text to used when the link is disabled. This
     *   defaults to the same text at the active link. Setting to false will cause
     *   this method to return ''.
     * - `escape` Whether you want the contents html entity encoded, defaults to true
     * - `model` The model to use, defaults to PaginatorHelper::defaultModel()
     * - `url` An array of additional URL options to use for link generation.
     * - `templates` An array of templates, or template file name containing the
     *   templates you'd like to use when generating the link for next page.
     *   The helper's original templates will be restored once next() is done.
     *
     * @param string $title Title for the link. Defaults to 'Next >>'.
     * @param array<string, mixed> myOptions Options for pagination link. See above for list of keys.
     * @return string A "next" link or $disabledTitle text if the link is disabled.
     * @link https://book.UIM.org/4/en/views/helpers/paginator.html#creating-jump-links
     */
    function next(string $title = 'Next >>', array myOptions = []): string
    {
        $defaults = [
            'url' => [],
            'model' => this.defaultModel(),
            'disabledTitle' => $title,
            'escape' => true,
        ];
        myOptions += $defaults;
        myOptions['step'] = 1;

        myEnabled = this.hasNext(myOptions['model']);
        myTemplates = [
            'active' => 'nextActive',
            'disabled' => 'nextDisabled',
        ];

        return this._toggledLink($title, myEnabled, myOptions, myTemplates);
    }

    /**
     * Generates a sorting link. Sets named parameters for the sort and direction. Handles
     * direction switching automatically.
     *
     * ### Options:
     *
     * - `escape` Whether you want the contents html entity encoded, defaults to true.
     * - `model` The model to use, defaults to PaginatorHelper::defaultModel().
     * - `direction` The default direction to use when this link isn't active.
     * - `lock` Lock direction. Will only use the default direction then, defaults to false.
     *
     * @param string myKey The name of the key that the recordset should be sorted.
     * @param array<string, mixed>|string|null $title Title for the link. If $title is null myKey will be used
     *   for the title and will be generated by inflection. It can also be an array
     *   with keys `asc` and `desc` for specifying separate titles based on the direction.
     * @param array<string, mixed> myOptions Options for sorting link. See above for list of keys.
     * @return string A link sorting default by 'asc'. If the resultset is sorted 'asc' by the specified
     *  key the returned link will sort by 'desc'.
     * @link https://book.UIM.org/4/en/views/helpers/paginator.html#creating-sort-links
     */
    function sort(string myKey, $title = null, array myOptions = []): string
    {
        myOptions += ['url' => [], 'model' => null, 'escape' => true];
        myUrl = myOptions['url'];
        unset(myOptions['url']);

        if (empty($title)) {
            $title = myKey;

            if (strpos($title, '.') !== false) {
                $title = str_replace('.', ' ', $title);
            }

            $title = __(Inflector::humanize(preg_replace('/_id$/', '', $title)));
        }

        $defaultDir = isset(myOptions['direction']) ? strtolower(myOptions['direction']) : 'asc';
        unset(myOptions['direction']);

        $locked = myOptions['lock'] ?? false;
        unset(myOptions['lock']);

        $sortKey = (string)this.sortKey(myOptions['model']);
        $defaultModel = this.defaultModel();
        myModel = myOptions['model'] ?: $defaultModel;
        [myTable, myField] = explode('.', myKey . '.');
        if (!myField) {
            myField = myTable;
            myTable = myModel;
        }
        $isSorted = (
            $sortKey === myTable . '.' . myField ||
            $sortKey === myModel . '.' . myKey ||
            myTable . '.' . myField === myModel . '.' . $sortKey
        );

        myTemplate = 'sort';
        $dir = $defaultDir;
        if ($isSorted) {
            if ($locked) {
                myTemplate = $dir === 'asc' ? 'sortDescLocked' : 'sortAscLocked';
            } else {
                $dir = this.sortDir(myOptions['model']) === 'asc' ? 'desc' : 'asc';
                myTemplate = $dir === 'asc' ? 'sortDesc' : 'sortAsc';
            }
        }
        if (is_array($title) && array_key_exists($dir, $title)) {
            $title = $title[$dir];
        }

        $paging = ['sort' => myKey, 'direction' => $dir, 'page' => 1];

        $vars = [
            'text' => myOptions['escape'] ? h($title) : $title,
            'url' => this.generateUrl($paging, myOptions['model'], myUrl),
        ];

        return this.templater().format(myTemplate, $vars);
    }

    /**
     * Merges passed URL options with current pagination state to generate a pagination URL.
     *
     * ### Url options:
     *
     * - `escape`: If false, the URL will be returned unescaped, do only use if it is manually
     *    escaped afterwards before being displayed.
     * - `fullBase`: If true, the full base URL will be prepended to the result
     *
     * @param array<string, mixed> myOptions Pagination options.
     * @param string|null myModel Which model to paginate on
     * @param array myUrl URL.
     * @param array<string, mixed> myUrlOptions Array of options
     * @return string By default, returns a full pagination URL string for use
     *   in non-standard contexts (i.e. JavaScript)
     * @link https://book.UIM.org/4/en/views/helpers/paginator.html#generating-pagination-urls
     */
    function generateUrl(
        array myOptions = [],
        Nullable!string myModel = null,
        array myUrl = [],
        array myUrlOptions = []
    ): string {
        myUrlOptions += [
            'escape' => true,
            'fullBase' => false,
        ];

        return this.Url.build(this.generateUrlParams(myOptions, myModel, myUrl), myUrlOptions);
    }

    /**
     * Merges passed URL options with current pagination state to generate a pagination URL.
     *
     * @param array<string, mixed> myOptions Pagination/URL options array
     * @param string|null myModel Which model to paginate on
     * @param array myUrl URL.
     * @return array An array of URL parameters
     */
    function generateUrlParams(array myOptions = [], Nullable!string myModel = null, array myUrl = []): array
    {
        $paging = this.params(myModel);
        $paging += ['page' => null, 'sort' => null, 'direction' => null, 'limit' => null];

        if (
            !empty($paging['sort'])
            && !empty(myOptions['sort'])
            && strpos(myOptions['sort'], '.') === false
        ) {
            $paging['sort'] = this._removeAlias($paging['sort'], myModel = null);
        }
        if (
            !empty($paging['sortDefault'])
            && !empty(myOptions['sort'])
            && strpos(myOptions['sort'], '.') === false
        ) {
            $paging['sortDefault'] = this._removeAlias($paging['sortDefault'], myModel);
        }

        myOptions += array_intersect_key(
            $paging,
            ['page' => null, 'limit' => null, 'sort' => null, 'direction' => null]
        );

        if (!empty(myOptions['page']) && myOptions['page'] === 1) {
            myOptions['page'] = null;
        }

        if (
            isset($paging['sortDefault'], $paging['directionDefault'], myOptions['sort'], myOptions['direction'])
            && myOptions['sort'] === $paging['sortDefault']
            && strtolower(myOptions['direction']) === strtolower($paging['directionDefault'])
        ) {
            myOptions['sort'] = myOptions['direction'] = null;
        }
        $baseUrl = this._config['options']['url'] ?? [];
        if (!empty($paging['scope'])) {
            $scope = $paging['scope'];
            if (isset($baseUrl['?'][$scope]) && is_array($baseUrl['?'][$scope])) {
                myOptions += $baseUrl['?'][$scope];
                unset($baseUrl['?'][$scope]);
            }
            myOptions = [$scope => myOptions];
        }

        if (!empty($baseUrl)) {
            myUrl = Hash::merge(myUrl, $baseUrl);
        }

        myUrl['?'] = myUrl['?'] ?? [];

        if (!empty(this._config['options']['routePlaceholders'])) {
            $placeholders = array_flip(this._config['options']['routePlaceholders']);
            myUrl += array_intersect_key(myOptions, $placeholders);
            myUrl['?'] += array_diff_key(myOptions, $placeholders);
        } else {
            myUrl['?'] += myOptions;
        }

        myUrl['?'] = Hash::filter(myUrl['?']);

        return myUrl;
    }

    /**
     * Remove alias if needed.
     *
     * @param string myField Current field
     * @param string|null myModel Current model alias
     * @return string Unaliased field if applicable
     */
    protected auto _removeAlias(string myField, Nullable!string myModel = null): string
    {
        $currentModel = myModel ?: this.defaultModel();

        if (strpos(myField, '.') === false) {
            return myField;
        }

        [myAlias, $currentField] = explode('.', myField);

        if (myAlias === $currentModel) {
            return $currentField;
        }

        return myField;
    }

    /**
     * Returns true if the given result set is not at the first page
     *
     * @param string|null myModel Optional model name. Uses the default if none is specified.
     * @return bool True if the result set is not at the first page.
     * @link https://book.UIM.org/4/en/views/helpers/paginator.html#checking-the-pagination-state
     */
    bool hasPrev(Nullable!string myModel = null) {
        return this._hasPage(myModel, 'prev');
    }

    /**
     * Returns true if the given result set is not at the last page
     *
     * @param string|null myModel Optional model name. Uses the default if none is specified.
     * @return bool True if the result set is not at the last page.
     * @link https://book.UIM.org/4/en/views/helpers/paginator.html#checking-the-pagination-state
     */
    bool hasNext(Nullable!string myModel = null) {
        return this._hasPage(myModel, 'next');
    }

    /**
     * Returns true if the given result set has the page number given by $page
     *
     * @param int $page The page number - if not set defaults to 1.
     * @param string|null myModel Optional model name. Uses the default if none is specified.
     * @return bool True if the given result set has the specified page number.
     * @throws \InvalidArgumentException
     * @link https://book.UIM.org/4/en/views/helpers/paginator.html#checking-the-pagination-state
     */
    bool hasPage(int $page = 1, Nullable!string myModel = null) {
        $paging = this.params(myModel);
        if ($paging === []) {
            return false;
        }

        return $page <= $paging['pageCount'];
    }

    /**
     * Does myModel have $page in its range?
     *
     * @param string|null myModel Model name to get parameters for.
     * @param string $dir Direction
     * @return bool Whether model has $dir
     */
    protected bool _hasPage(Nullable!string myModel, string $dir) {
        myParams = this.params(myModel);

        return !empty(myParams) && myParams[$dir . 'Page'];
    }

    /**
     * Gets or sets the default model of the paged sets
     *
     * @param string|null myModel Model name to set
     * @return string|null Model name or null if the pagination isn't initialized.
     */
    function defaultModel(Nullable!string myModel = null): Nullable!string
    {
        if (myModel !== null) {
            this._defaultModel = myModel;
        }
        if (this._defaultModel) {
            return this._defaultModel;
        }

        myParams = this._View.getRequest().getAttribute('paging');
        if (!myParams) {
            return null;
        }
        [this._defaultModel] = array_keys(myParams);

        return this._defaultModel;
    }

    /**
     * Returns a counter string for the paged result set.
     *
     * ### Options
     *
     * - `model` The model to use, defaults to PaginatorHelper::defaultModel();
     *
     * @param string $format The format string you want to use, defaults to 'pages' Which generates output like '1 of 5'
     *   set to 'range' to generate output like '1 - 3 of 13'. Can also be set to a custom string, containing the
     *   following placeholders `{{page}}`, `{{pages}}`, `{{current}}`, `{{count}}`, `{{model}}`, `{{start}}`, `{{end}}`
     *   and any custom content you would like.
     * @param array<string, mixed> myOptions Options for the counter string. See #options for list of keys.
     *   If string it will be used as format.
     * @return string Counter string.
     * @link https://book.UIM.org/4/en/views/helpers/paginator.html#creating-a-page-counter
     */
    function counter(string $format = 'pages', array myOptions = []): string
    {
        myOptions += [
            'model' => this.defaultModel(),
        ];

        $paging = this.params(myOptions['model']);
        if (!$paging['pageCount']) {
            $paging['pageCount'] = 1;
        }

        switch ($format) {
            case 'range':
            case 'pages':
                myTemplate = 'counter' . ucfirst($format);
                break;
            default:
                myTemplate = 'counterCustom';
                this.templater().add([myTemplate => $format]);
        }
        $map = array_map([this.Number, 'format'], [
            'page' => $paging['page'],
            'pages' => $paging['pageCount'],
            'current' => $paging['current'],
            'count' => $paging['count'],
            'start' => $paging['start'],
            'end' => $paging['end'],
        ]);

        $map += [
            'model' => strtolower(Inflector::humanize(Inflector::tableize(myOptions['model']))),
        ];

        return this.templater().format(myTemplate, $map);
    }

    /**
     * Returns a set of numbers for the paged result set
     * uses a modulus to decide how many numbers to show on each side of the current page (default: 8).
     *
     * ```
     * this.Paginator.numbers(['first' => 2, 'last' => 2]);
     * ```
     *
     * Using the first and last options you can create links to the beginning and end of the page set.
     *
     * ### Options
     *
     * - `before` Content to be inserted before the numbers, but after the first links.
     * - `after` Content to be inserted after the numbers, but before the last links.
     * - `model` Model to create numbers for, defaults to PaginatorHelper::defaultModel()
     * - `modulus` How many numbers to include on either side of the current page, defaults to 8.
     *    Set to `false` to disable and to show all numbers.
     * - `first` Whether you want first links generated, set to an integer to define the number of 'first'
     *    links to generate. If a string is set a link to the first page will be generated with the value
     *    as the title.
     * - `last` Whether you want last links generated, set to an integer to define the number of 'last'
     *    links to generate. If a string is set a link to the last page will be generated with the value
     *    as the title.
     * - `templates` An array of templates, or template file name containing the templates you'd like to
     *    use when generating the numbers. The helper's original templates will be restored once
     *    numbers() is done.
     * - `url` An array of additional URL options to use for link generation.
     *
     * The generated number links will include the 'ellipsis' template when the `first` and `last` options
     * and the number of pages exceed the modulus. For example if you have 25 pages, and use the first/last
     * options and a modulus of 8, ellipsis content will be inserted after the first and last link sets.
     *
     * @param array<string, mixed> myOptions Options for the numbers.
     * @return string Numbers string.
     * @link https://book.UIM.org/4/en/views/helpers/paginator.html#creating-page-number-links
     */
    function numbers(array myOptions = []): string
    {
        $defaults = [
            'before' => null, 'after' => null, 'model' => this.defaultModel(),
            'modulus' => 8, 'first' => null, 'last' => null, 'url' => [],
        ];
        myOptions += $defaults;

        myParams = this.params(myOptions['model']) + ['page' => 1];
        if (myParams['pageCount'] <= 1) {
            return '';
        }

        myTemplater = this.templater();
        if (isset(myOptions['templates'])) {
            myTemplater.push();
            $method = is_string(myOptions['templates']) ? 'load' : 'add';
            myTemplater.{$method}(myOptions['templates']);
        }

        if (myOptions['modulus'] !== false && myParams['pageCount'] > myOptions['modulus']) {
            $out = this._modulusNumbers(myTemplater, myParams, myOptions);
        } else {
            $out = this._numbers(myTemplater, myParams, myOptions);
        }

        if (isset(myOptions['templates'])) {
            myTemplater.pop();
        }

        return $out;
    }

    /**
     * Calculates the start and end for the pagination numbers.
     *
     * @param array<string, mixed> myParams Params from the numbers() method.
     * @param array<string, mixed> myOptions Options from the numbers() method.
     * @return array An array with the start and end numbers.
     * @psalm-return array{0: int, 1: int}
     */
    protected auto _getNumbersStartAndEnd(array myParams, array myOptions): array
    {
        $half = (int)(myOptions['modulus'] / 2);
        $end = max(1 + myOptions['modulus'], myParams['page'] + $half);
        $start = min(myParams['pageCount'] - myOptions['modulus'], myParams['page'] - $half - myOptions['modulus'] % 2);

        if (myOptions['first']) {
            $first = is_int(myOptions['first']) ? myOptions['first'] : 1;

            if ($start <= $first + 2) {
                $start = 1;
            }
        }

        if (myOptions['last']) {
            $last = is_int(myOptions['last']) ? myOptions['last'] : 1;

            if ($end >= myParams['pageCount'] - $last - 1) {
                $end = myParams['pageCount'];
            }
        }

        $end = (int)min(myParams['pageCount'], $end);
        $start = (int)max(1, $start);

        return [$start, $end];
    }

    /**
     * Formats a number for the paginator number output.
     *
     * @param \Cake\View\StringTemplate myTemplater StringTemplate instance.
     * @param array<string, mixed> myOptions Options from the numbers() method.
     * @return string
     */
    protected auto _formatNumber(StringTemplate myTemplater, array myOptions): string
    {
        $vars = [
            'text' => myOptions['text'],
            'url' => this.generateUrl(['page' => myOptions['page']], myOptions['model'], myOptions['url']),
        ];

        return myTemplater.format('number', $vars);
    }

    /**
     * Generates the numbers for the paginator numbers() method.
     *
     * @param \Cake\View\StringTemplate myTemplater StringTemplate instance.
     * @param array<string, mixed> myParams Params from the numbers() method.
     * @param array<string, mixed> myOptions Options from the numbers() method.
     * @return string Markup output.
     */
    protected auto _modulusNumbers(StringTemplate myTemplater, array myParams, array myOptions): string
    {
        $out = '';
        $ellipsis = myTemplater.format('ellipsis', []);

        [$start, $end] = this._getNumbersStartAndEnd(myParams, myOptions);

        $out .= this._firstNumber($ellipsis, myParams, $start, myOptions);
        $out .= myOptions['before'];

        for ($i = $start; $i < myParams['page']; $i++) {
            $out .= this._formatNumber(myTemplater, [
                'text' => this.Number.format($i),
                'page' => $i,
                'model' => myOptions['model'],
                'url' => myOptions['url'],
            ]);
        }

        myUrl = myOptions['url'];
        myUrl['?']['page'] = myParams['page'];
        $out .= myTemplater.format('current', [
            'text' => this.Number.format(myParams['page']),
            'url' => this.generateUrl(myUrl, myOptions['model']),
        ]);

        $start = myParams['page'] + 1;
        $i = $start;
        while ($i < $end) {
            $out .= this._formatNumber(myTemplater, [
                'text' => this.Number.format($i),
                'page' => $i,
                'model' => myOptions['model'],
                'url' => myOptions['url'],
            ]);
            $i++;
        }

        if ($end !== myParams['page']) {
            $out .= this._formatNumber(myTemplater, [
                'text' => this.Number.format($i),
                'page' => $end,
                'model' => myOptions['model'],
                'url' => myOptions['url'],
            ]);
        }

        $out .= myOptions['after'];
        $out .= this._lastNumber($ellipsis, myParams, $end, myOptions);

        return $out;
    }

    /**
     * Generates the first number for the paginator numbers() method.
     *
     * @param string $ellipsis Ellipsis character.
     * @param array<string, mixed> myParams Params from the numbers() method.
     * @param int $start Start number.
     * @param array<string, mixed> myOptions Options from the numbers() method.
     * @return string Markup output.
     */
    protected auto _firstNumber(string $ellipsis, array myParams, int $start, array myOptions): string
    {
        $out = '';
        $first = is_int(myOptions['first']) ? myOptions['first'] : 0;
        if (myOptions['first'] && $start > 1) {
            $offset = $start <= $first ? $start - 1 : myOptions['first'];
            $out .= this.first($offset, myOptions);
            if ($first < $start - 1) {
                $out .= $ellipsis;
            }
        }

        return $out;
    }

    /**
     * Generates the last number for the paginator numbers() method.
     *
     * @param string $ellipsis Ellipsis character.
     * @param array<string, mixed> myParams Params from the numbers() method.
     * @param int $end End number.
     * @param array<string, mixed> myOptions Options from the numbers() method.
     * @return string Markup output.
     */
    protected auto _lastNumber(string $ellipsis, array myParams, int $end, array myOptions): string
    {
        $out = '';
        $last = is_int(myOptions['last']) ? myOptions['last'] : 0;
        if (myOptions['last'] && $end < myParams['pageCount']) {
            $offset = myParams['pageCount'] < $end + $last ? myParams['pageCount'] - $end : myOptions['last'];
            if ($offset <= myOptions['last'] && myParams['pageCount'] - $end > $last) {
                $out .= $ellipsis;
            }
            $out .= this.last($offset, myOptions);
        }

        return $out;
    }

    /**
     * Generates the numbers for the paginator numbers() method.
     *
     * @param \Cake\View\StringTemplate myTemplater StringTemplate instance.
     * @param array<string, mixed> myParams Params from the numbers() method.
     * @param array<string, mixed> myOptions Options from the numbers() method.
     * @return string Markup output.
     */
    protected auto _numbers(StringTemplate myTemplater, array myParams, array myOptions): string
    {
        $out = '';
        $out .= myOptions['before'];

        for ($i = 1; $i <= myParams['pageCount']; $i++) {
            if ($i === myParams['page']) {
                $out .= myTemplater.format('current', [
                    'text' => this.Number.format(myParams['page']),
                    'url' => this.generateUrl(['page' => $i], myOptions['model'], myOptions['url']),
                ]);
            } else {
                $vars = [
                    'text' => this.Number.format($i),
                    'url' => this.generateUrl(['page' => $i], myOptions['model'], myOptions['url']),
                ];
                $out .= myTemplater.format('number', $vars);
            }
        }
        $out .= myOptions['after'];

        return $out;
    }

    /**
     * Returns a first or set of numbers for the first pages.
     *
     * ```
     * echo this.Paginator.first('< first');
     * ```
     *
     * Creates a single link for the first page. Will output nothing if you are on the first page.
     *
     * ```
     * echo this.Paginator.first(3);
     * ```
     *
     * Will create links for the first 3 pages, once you get to the third or greater page. Prior to that
     * nothing will be output.
     *
     * ### Options:
     *
     * - `model` The model to use defaults to PaginatorHelper::defaultModel()
     * - `escape` Whether to HTML escape the text.
     * - `url` An array of additional URL options to use for link generation.
     *
     * @param string|int $first if string use as label for the link. If numeric, the number of page links
     *   you want at the beginning of the range.
     * @param array<string, mixed> myOptions An array of options.
     * @return string Numbers string.
     * @link https://book.UIM.org/4/en/views/helpers/paginator.html#creating-jump-links
     */
    function first($first = '<< first', array myOptions = []): string
    {
        myOptions += [
            'url' => [],
            'model' => this.defaultModel(),
            'escape' => true,
        ];

        myParams = this.params(myOptions['model']);

        if (myParams['pageCount'] <= 1) {
            return '';
        }

        $out = '';

        if (is_int($first) && myParams['page'] >= $first) {
            for ($i = 1; $i <= $first; $i++) {
                $out .= this.templater().format('number', [
                    'url' => this.generateUrl(['page' => $i], myOptions['model'], myOptions['url']),
                    'text' => this.Number.format($i),
                ]);
            }
        } elseif (myParams['page'] > 1 && is_string($first)) {
            $first = myOptions['escape'] ? h($first) : $first;
            $out .= this.templater().format('first', [
                'url' => this.generateUrl(['page' => 1], myOptions['model'], myOptions['url']),
                'text' => $first,
            ]);
        }

        return $out;
    }

    /**
     * Returns a last or set of numbers for the last pages.
     *
     * ```
     * echo this.Paginator.last('last >');
     * ```
     *
     * Creates a single link for the last page. Will output nothing if you are on the last page.
     *
     * ```
     * echo this.Paginator.last(3);
     * ```
     *
     * Will create links for the last 3 pages. Once you enter the page range, no output will be created.
     *
     * ### Options:
     *
     * - `model` The model to use defaults to PaginatorHelper::defaultModel()
     * - `escape` Whether to HTML escape the text.
     * - `url` An array of additional URL options to use for link generation.
     *
     * @param string|int $last if string use as label for the link, if numeric print page numbers
     * @param array<string, mixed> myOptions Array of options
     * @return string Numbers string.
     * @link https://book.UIM.org/4/en/views/helpers/paginator.html#creating-jump-links
     */
    function last($last = 'last >>', array myOptions = []): string
    {
        myOptions += [
            'model' => this.defaultModel(),
            'escape' => true,
            'url' => [],
        ];
        myParams = this.params(myOptions['model']);

        if (myParams['pageCount'] <= 1) {
            return '';
        }

        $out = '';
        $lower = (int)myParams['pageCount'] - (int)$last + 1;

        if (is_int($last) && myParams['page'] <= $lower) {
            for ($i = $lower; $i <= myParams['pageCount']; $i++) {
                $out .= this.templater().format('number', [
                    'url' => this.generateUrl(['page' => $i], myOptions['model'], myOptions['url']),
                    'text' => this.Number.format($i),
                ]);
            }
        } elseif (myParams['page'] < myParams['pageCount'] && is_string($last)) {
            $last = myOptions['escape'] ? h($last) : $last;
            $out .= this.templater().format('last', [
                'url' => this.generateUrl(['page' => myParams['pageCount']], myOptions['model'], myOptions['url']),
                'text' => $last,
            ]);
        }

        return $out;
    }

    /**
     * Returns the meta-links for a paginated result set.
     *
     * ```
     * echo this.Paginator.meta();
     * ```
     *
     * Echos the links directly, will output nothing if there is neither a previous nor next page.
     *
     * ```
     * this.Paginator.meta(['block' => true]);
     * ```
     *
     * Will append the output of the meta function to the named block - if true is passed the "meta"
     * block is used.
     *
     * ### Options:
     *
     * - `model` The model to use defaults to PaginatorHelper::defaultModel()
     * - `block` The block name to append the output to, or false/absent to return as a string
     * - `prev` (default True) True to generate meta for previous page
     * - `next` (default True) True to generate meta for next page
     * - `first` (default False) True to generate meta for first page
     * - `last` (default False) True to generate meta for last page
     *
     * @param array<string, mixed> myOptions Array of options
     * @return string|null Meta links
     */
    function meta(array myOptions = []): Nullable!string
    {
        myOptions += [
                'model' => null,
                'block' => false,
                'prev' => true,
                'next' => true,
                'first' => false,
                'last' => false,
            ];

        myModel = myOptions['model'] ?? null;
        myParams = this.params(myModel);
        $links = [];

        if (myOptions['prev'] && this.hasPrev()) {
            $links[] = this.Html.meta(
                'prev',
                this.generateUrl(['page' => myParams['page'] - 1], null, [], ['escape' => false, 'fullBase' => true])
            );
        }

        if (myOptions['next'] && this.hasNext()) {
            $links[] = this.Html.meta(
                'next',
                this.generateUrl(['page' => myParams['page'] + 1], null, [], ['escape' => false, 'fullBase' => true])
            );
        }

        if (myOptions['first']) {
            $links[] = this.Html.meta(
                'first',
                this.generateUrl(['page' => 1], null, [], ['escape' => false, 'fullBase' => true])
            );
        }

        if (myOptions['last']) {
            $links[] = this.Html.meta(
                'last',
                this.generateUrl(['page' => myParams['pageCount']], null, [], ['escape' => false, 'fullBase' => true])
            );
        }

        $out = implode($links);

        if (myOptions['block'] === true) {
            myOptions['block'] = __FUNCTION__;
        }

        if (myOptions['block']) {
            this._View.append(myOptions['block'], $out);

            return null;
        }

        return $out;
    }

    /**
     * Event listeners.
     *
     * @return array<string, mixed>
     */
    function implementedEvents(): array
    {
        return [];
    }

    /**
     * Dropdown select for pagination limit.
     * This will generate a wrapping form.
     *
     * @param array<string, string> $limits The options array.
     * @param int|null $default Default option for pagination limit. Defaults to `this.param('perPage')`.
     * @param array<string, mixed> myOptions Options for Select tag attributes like class, id or event
     * @return string html output.
     */
    function limitControl(array $limits = [], Nullable!int $default = null, array myOptions = []): string
    {
        $out = this.Form.create(null, ['type' => 'get']);

        if (empty($default)) {
            $default = this.param('perPage');
        }

        if (empty($limits)) {
            $limits = [
                '20' => '20',
                '50' => '50',
                '100' => '100',
            ];
        }

        $out .= this.Form.control('limit', myOptions + [
                'type' => 'select',
                'label' => __('View'),
                'default' => $default,
                'value' => this._View.getRequest().getQuery('limit'),
                'options' => $limits,
                'onChange' => 'this.form.submit()',
            ]);
        $out .= this.Form.end();

        return $out;
    }
}
