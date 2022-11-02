module uim.cake.views\Helper;

import uim.cake.views\Helper;
import uim.cake.views\StringTemplateTrait;
use LogicException;

/**
 * BreadcrumbsHelper to register and display a breadcrumb trail for your views
 *
 * @property \Cake\View\Helper\UrlHelper myUrl
 */
class BreadcrumbsHelper : Helper
{
    use StringTemplateTrait;

    /**
     * Other helpers used by BreadcrumbsHelper.
     *
     * @var array
     */
    protected $helpers = ['Url'];

    /**
     * Default config for the helper.
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        'templates' => [
            'wrapper' => '<ul{{attrs}}>{{content}}</ul>',
            'item' => '<li{{attrs}}><a href="{{url}}"{{innerAttrs}}>{{title}}</a></li>{{separator}}',
            'itemWithoutLink' => '<li{{attrs}}><span{{innerAttrs}}>{{title}}</span></li>{{separator}}',
            'separator' => '<li{{attrs}}><span{{innerAttrs}}>{{separator}}</span></li>',
        ],
    ];

    /**
     * The crumb list.
     *
     * @var array
     */
    protected $crumbs = [];

    /**
     * Add a crumb to the end of the trail.
     *
     * @param array|string $title If provided as a string, it represents the title of the crumb.
     * Alternatively, if you want to add multiple crumbs at once, you can provide an array, with each values being a
     * single crumb. Arrays are expected to be of this form:
     *
     * - *title* The title of the crumb
     * - *link* The link of the crumb. If not provided, no link will be made
     * - *options* Options of the crumb. See description of params option of this method.
     *
     * @param array|string|null myUrl URL of the crumb. Either a string, an array of route params to pass to
     * Url::build() or null / empty if the crumb does not have a link.
     * @param array<string, mixed> myOptions Array of options. These options will be used as attributes HTML attribute the crumb will
     * be rendered in (a <li> tag by default). It accepts two special keys:
     *
     * - *innerAttrs*: An array that allows you to define attributes for the inner element of the crumb (by default, to
     *   the link)
     * - *templateVars*: Specific template vars in case you override the templates provided.
     * @return this
     */
    function add($title, myUrl = null, array myOptions = []) {
        if (is_array($title)) {
            foreach ($title as $crumb) {
                this.crumbs[] = $crumb + ['title' => '', 'url' => null, 'options' => []];
            }

            return this;
        }

        this.crumbs[] = compact('title', 'url', 'options');

        return this;
    }

    /**
     * Prepend a crumb to the start of the queue.
     *
     * @param array|string $title If provided as a string, it represents the title of the crumb.
     * Alternatively, if you want to add multiple crumbs at once, you can provide an array, with each values being a
     * single crumb. Arrays are expected to be of this form:
     *
     * - *title* The title of the crumb
     * - *link* The link of the crumb. If not provided, no link will be made
     * - *options* Options of the crumb. See description of params option of this method.
     *
     * @param array|string|null myUrl URL of the crumb. Either a string, an array of route params to pass to
     * Url::build() or null / empty if the crumb does not have a link.
     * @param array<string, mixed> myOptions Array of options. These options will be used as attributes HTML attribute the crumb will
     * be rendered in (a <li> tag by default). It accepts two special keys:
     *
     * - *innerAttrs*: An array that allows you to define attributes for the inner element of the crumb (by default, to
     *   the link)
     * - *templateVars*: Specific template vars in case you override the templates provided.
     * @return this
     */
    function prepend($title, myUrl = null, array myOptions = []) {
        if (is_array($title)) {
            $crumbs = [];
            foreach ($title as $crumb) {
                $crumbs[] = $crumb + ['title' => '', 'url' => null, 'options' => []];
            }

            array_splice(this.crumbs, 0, 0, $crumbs);

            return this;
        }

        array_unshift(this.crumbs, compact('title', 'url', 'options'));

        return this;
    }

    /**
     * Insert a crumb at a specific index.
     *
     * If the index already exists, the new crumb will be inserted,
     * and the existing element will be shifted one index greater.
     * If the index is out of bounds, it will throw an exception.
     *
     * @param int $index The index to insert at.
     * @param string $title Title of the crumb.
     * @param array|string|null myUrl URL of the crumb. Either a string, an array of route params to pass to
     * Url::build() or null / empty if the crumb does not have a link.
     * @param array<string, mixed> myOptions Array of options. These options will be used as attributes HTML attribute the crumb will
     * be rendered in (a <li> tag by default). It accepts two special keys:
     *
     * - *innerAttrs*: An array that allows you to define attributes for the inner element of the crumb (by default, to
     *   the link)
     * - *templateVars*: Specific template vars in case you override the templates provided.
     * @return this
     * @throws \LogicException In case the index is out of bound
     */
    function insertAt(int $index, string $title, myUrl = null, array myOptions = []) {
        if (!isset(this.crumbs[$index])) {
            throw new LogicException(sprintf("No crumb could be found at index '%s'", $index));
        }

        array_splice(this.crumbs, $index, 0, [compact('title', 'url', 'options')]);

        return this;
    }

    /**
     * Insert a crumb before the first matching crumb with the specified title.
     *
     * Finds the index of the first crumb that matches the provided class,
     * and inserts the supplied callable before it.
     *
     * @param string $matchingTitle The title of the crumb you want to insert this one before.
     * @param string $title Title of the crumb.
     * @param array|string|null myUrl URL of the crumb. Either a string, an array of route params to pass to
     * Url::build() or null / empty if the crumb does not have a link.
     * @param array<string, mixed> myOptions Array of options. These options will be used as attributes HTML attribute the crumb will
     * be rendered in (a <li> tag by default). It accepts two special keys:
     *
     * - *innerAttrs*: An array that allows you to define attributes for the inner element of the crumb (by default, to
     *   the link)
     * - *templateVars*: Specific template vars in case you override the templates provided.
     * @return this
     * @throws \LogicException In case the matching crumb can not be found
     */
    function insertBefore(string $matchingTitle, string $title, myUrl = null, array myOptions = []) {
        myKey = this.findCrumb($matchingTitle);

        if (myKey === null) {
            throw new LogicException(sprintf("No crumb matching '%s' could be found.", $matchingTitle));
        }

        return this.insertAt(myKey, $title, myUrl, myOptions);
    }

    /**
     * Insert a crumb after the first matching crumb with the specified title.
     *
     * Finds the index of the first crumb that matches the provided class,
     * and inserts the supplied callable before it.
     *
     * @param string $matchingTitle The title of the crumb you want to insert this one after.
     * @param string $title Title of the crumb.
     * @param array|string|null myUrl URL of the crumb. Either a string, an array of route params to pass to
     * Url::build() or null / empty if the crumb does not have a link.
     * @param array<string, mixed> myOptions Array of options. These options will be used as attributes HTML attribute the crumb will
     * be rendered in (a <li> tag by default). It accepts two special keys:
     *
     * - *innerAttrs*: An array that allows you to define attributes for the inner element of the crumb (by default, to
     *   the link)
     * - *templateVars*: Specific template vars in case you override the templates provided.
     * @return this
     * @throws \LogicException In case the matching crumb can not be found.
     */
    function insertAfter(string $matchingTitle, string $title, myUrl = null, array myOptions = []) {
        myKey = this.findCrumb($matchingTitle);

        if (myKey === null) {
            throw new LogicException(sprintf("No crumb matching '%s' could be found.", $matchingTitle));
        }

        return this.insertAt(myKey + 1, $title, myUrl, myOptions);
    }

    /**
     * Returns the crumb list.
     *
     * @return array
     */
    auto getCrumbs(): array
    {
        return this.crumbs;
    }

    /**
     * Removes all existing crumbs.
     *
     * @return this
     */
    function reset() {
        this.crumbs = [];

        return this;
    }

    /**
     * Renders the breadcrumbs trail.
     *
     * @param array<string, mixed> $attributes Array of attributes applied to the `wrapper` template. Accepts the `templateVars` key to
     * allow the insertion of custom template variable in the template.
     * @param array<string, mixed> $separator Array of attributes for the `separator` template.
     * Possible properties are :
     *
     * - *separator* The string to be displayed as a separator
     * - *templateVars* Allows the insertion of custom template variable in the template
     * - *innerAttrs* To provide attributes in case your separator is divided in two elements.
     *
     * All other properties will be converted as HTML attributes and will replace the *attrs* key in the template.
     * If you use the default for this option (empty), it will not render a separator.
     * @return string The breadcrumbs trail
     */
    function render(array $attributes = [], array $separator = []): string
    {
        if (!this.crumbs) {
            return '';
        }

        $crumbs = this.crumbs;
        $crumbsCount = count($crumbs);
        myTemplater = this.templater();
        $separatorString = '';

        if ($separator) {
            if (isset($separator['innerAttrs'])) {
                $separator['innerAttrs'] = myTemplater.formatAttributes($separator['innerAttrs']);
            }

            $separator['attrs'] = myTemplater.formatAttributes(
                $separator,
                ['innerAttrs', 'separator']
            );

            $separatorString = this.formatTemplate('separator', $separator);
        }

        $crumbTrail = '';
        foreach ($crumbs as myKey => $crumb) {
            myUrl = $crumb['url'] ? this.Url.build($crumb['url']) : null;
            $title = $crumb['title'];
            myOptions = $crumb['options'];

            myOptionsLink = [];
            if (isset(myOptions['innerAttrs'])) {
                myOptionsLink = myOptions['innerAttrs'];
                unset(myOptions['innerAttrs']);
            }

            myTemplate = 'item';
            myTemplateParams = [
                'attrs' => myTemplater.formatAttributes(myOptions, ['templateVars']),
                'innerAttrs' => myTemplater.formatAttributes(myOptionsLink),
                'title' => $title,
                'url' => myUrl,
                'separator' => '',
                'templateVars' => myOptions['templateVars'] ?? [],
            ];

            if (!myUrl) {
                myTemplate = 'itemWithoutLink';
            }

            if ($separatorString && myKey !== $crumbsCount - 1) {
                myTemplateParams['separator'] = $separatorString;
            }

            $crumbTrail .= this.formatTemplate(myTemplate, myTemplateParams);
        }

        $crumbTrail = this.formatTemplate('wrapper', [
            'content' => $crumbTrail,
            'attrs' => myTemplater.formatAttributes($attributes, ['templateVars']),
            'templateVars' => $attributes['templateVars'] ?? [],
        ]);

        return $crumbTrail;
    }

    /**
     * Search a crumb in the current stack which title matches the one provided as argument.
     * If found, the index of the matching crumb will be returned.
     *
     * @param string $title Title to find.
     * @return int|null Index of the crumb found, or null if it can not be found.
     */
    protected auto findCrumb(string $title): ?int
    {
        foreach (this.crumbs as myKey => $crumb) {
            if ($crumb['title'] === $title) {
                return myKey;
            }
        }

        return null;
    }
}
