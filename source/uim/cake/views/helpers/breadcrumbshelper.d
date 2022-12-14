/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.views\Helper;

import uim.cake.views\Helper;
import uim.cake.views\StringTemplateTrait;
use LogicException;

/**
 * BreadcrumbsHelper to register and display a breadcrumb trail for your views
 *
 * @property uim.cake.views\Helper\UrlHelper $Url
 */
class BreadcrumbsHelper : Helper
{
    use StringTemplateTrait;

    /**
     * Other helpers used by BreadcrumbsHelper.
     *
     * @var array
     */
    protected $helpers = ["Url"];

    /**
     * Default config for the helper.
     *
     * @var array<string, mixed>
     */
    protected _defaultConfig = [
        "templates": [
            "wrapper": "<ul{{attrs}}>{{content}}</ul>",
            "item": "<li{{attrs}}><a href="{{url}}"{{innerAttrs}}>{{title}}</a></li>{{separator}}",
            "itemWithoutLink": "<li{{attrs}}><span{{innerAttrs}}>{{title}}</span></li>{{separator}}",
            "separator": "<li{{attrs}}><span{{innerAttrs}}>{{separator}}</span></li>",
        ],
    ];

    /**
     * The crumb list.
     *
     * @var array
     */
    protected $crumbs = null;

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
     * @param array|string|null $url URL of the crumb. Either a string, an array of route params to pass to
     * Url::build() or null / empty if the crumb does not have a link.
     * @param array<string, mixed> $options Array of options. These options will be used as attributes HTML attribute the crumb will
     * be rendered in (a <li> tag by default). It accepts two special keys:
     *
     * - *innerAttrs*: An array that allows you to define attributes for the inner element of the crumb (by default, to
     *   the link)
     * - *templateVars*: Specific template vars in case you override the templates provided.
     * @return this
     */
    function add($title, $url = null, STRINGAA someOptions = null) {
        if (is_array($title)) {
            foreach ($title as $crumb) {
                this.crumbs[] = $crumb + ["title": "", "url": null, "options": []];
            }

            return this;
        }

        this.crumbs[] = compact("title", "url", "options");

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
     * @param array|string|null $url URL of the crumb. Either a string, an array of route params to pass to
     * Url::build() or null / empty if the crumb does not have a link.
     * @param array<string, mixed> $options Array of options. These options will be used as attributes HTML attribute the crumb will
     * be rendered in (a <li> tag by default). It accepts two special keys:
     *
     * - *innerAttrs*: An array that allows you to define attributes for the inner element of the crumb (by default, to
     *   the link)
     * - *templateVars*: Specific template vars in case you override the templates provided.
     * @return this
     */
    function prepend($title, $url = null, STRINGAA someOptions = null) {
        if (is_array($title)) {
            $crumbs = null;
            foreach ($title as $crumb) {
                $crumbs[] = $crumb + ["title": "", "url": null, "options": []];
            }

            array_splice(this.crumbs, 0, 0, $crumbs);

            return this;
        }

        array_unshift(this.crumbs, compact("title", "url", "options"));

        return this;
    }

    /**
     * Insert a crumb at a specific index.
     *
     * If the index already exists, the new crumb will be inserted,
     * before the existing element, shifting the existing element one index
     * greater than before.
     *
     * If the index is out of bounds, an exception will be thrown.
     *
     * @param int $index The index to insert at.
     * @param string $title Title of the crumb.
     * @param array|string|null $url URL of the crumb. Either a string, an array of route params to pass to
     * Url::build() or null / empty if the crumb does not have a link.
     * @param array<string, mixed> $options Array of options. These options will be used as attributes HTML attribute the crumb will
     * be rendered in (a <li> tag by default). It accepts two special keys:
     *
     * - *innerAttrs*: An array that allows you to define attributes for the inner element of the crumb (by default, to
     *   the link)
     * - *templateVars*: Specific template vars in case you override the templates provided.
     * @return this
     * @throws \LogicException In case the index is out of bound
     */
    function insertAt(int $index, string $title, $url = null, STRINGAA someOptions = null) {
        if (!isset(this.crumbs[$index]) && $index != count(this.crumbs)) {
            throw new LogicException(sprintf("No crumb could be found at index '%s'", $index));
        }

        array_splice(this.crumbs, $index, 0, [compact("title", "url", "options")]);

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
     * @param array|string|null $url URL of the crumb. Either a string, an array of route params to pass to
     * Url::build() or null / empty if the crumb does not have a link.
     * @param array<string, mixed> $options Array of options. These options will be used as attributes HTML attribute the crumb will
     * be rendered in (a <li> tag by default). It accepts two special keys:
     *
     * - *innerAttrs*: An array that allows you to define attributes for the inner element of the crumb (by default, to
     *   the link)
     * - *templateVars*: Specific template vars in case you override the templates provided.
     * @return this
     * @throws \LogicException In case the matching crumb can not be found
     */
    function insertBefore(string $matchingTitle, string $title, $url = null, STRINGAA someOptions = null) {
        $key = this.findCrumb($matchingTitle);

        if ($key == null) {
            throw new LogicException(sprintf("No crumb matching '%s' could be found.", $matchingTitle));
        }

        return this.insertAt($key, $title, $url, $options);
    }

    /**
     * Insert a crumb after the first matching crumb with the specified title.
     *
     * Finds the index of the first crumb that matches the provided class,
     * and inserts the supplied callable before it.
     *
     * @param string $matchingTitle The title of the crumb you want to insert this one after.
     * @param string $title Title of the crumb.
     * @param array|string|null $url URL of the crumb. Either a string, an array of route params to pass to
     * Url::build() or null / empty if the crumb does not have a link.
     * @param array<string, mixed> $options Array of options. These options will be used as attributes HTML attribute the crumb will
     * be rendered in (a <li> tag by default). It accepts two special keys:
     *
     * - *innerAttrs*: An array that allows you to define attributes for the inner element of the crumb (by default, to
     *   the link)
     * - *templateVars*: Specific template vars in case you override the templates provided.
     * @return this
     * @throws \LogicException In case the matching crumb can not be found.
     */
    function insertAfter(string $matchingTitle, string $title, $url = null, STRINGAA someOptions = null) {
        $key = this.findCrumb($matchingTitle);

        if ($key == null) {
            throw new LogicException(sprintf("No crumb matching '%s' could be found.", $matchingTitle));
        }

        return this.insertAt($key + 1, $title, $url, $options);
    }

    /**
     * Returns the crumb list.
     */
    array getCrumbs() {
        return this.crumbs;
    }

    /**
     * Removes all existing crumbs.
     *
     * @return this
     */
    function reset() {
        this.crumbs = null;

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
    string render(array $attributes = null, array $separator = null) {
        if (!this.crumbs) {
            return "";
        }

        $crumbs = this.crumbs;
        $crumbsCount = count($crumbs);
        $templater = this.templater();
        $separatorString = "";

        if ($separator) {
            if (isset($separator["innerAttrs"])) {
                $separator["innerAttrs"] = $templater.formatAttributes($separator["innerAttrs"]);
            }

            $separator["attrs"] = $templater.formatAttributes(
                $separator,
                ["innerAttrs", "separator"]
            );

            $separatorString = this.formatTemplate("separator", $separator);
        }

        $crumbTrail = "";
        foreach ($crumbs as $key: $crumb) {
            $url = $crumb["url"] ? this.Url.build($crumb["url"]) : null;
            $title = $crumb["title"];
            $options = $crumb["options"];

            $optionsLink = null;
            if (isset($options["innerAttrs"])) {
                $optionsLink = $options["innerAttrs"];
                unset($options["innerAttrs"]);
            }

            $template = "item";
            $templateParams = [
                "attrs": $templater.formatAttributes($options, ["templateVars"]),
                "innerAttrs": $templater.formatAttributes($optionsLink),
                "title": $title,
                "url": $url,
                "separator": "",
                "templateVars": $options["templateVars"] ?? [],
            ];

            if (!$url) {
                $template = "itemWithoutLink";
            }

            if ($separatorString && $key != $crumbsCount - 1) {
                $templateParams["separator"] = $separatorString;
            }

            $crumbTrail ~= this.formatTemplate($template, $templateParams);
        }

        return this.formatTemplate("wrapper", [
            "content": $crumbTrail,
            "attrs": $templater.formatAttributes($attributes, ["templateVars"]),
            "templateVars": $attributes["templateVars"] ?? [],
        ]);
    }

    /**
     * Search a crumb in the current stack which title matches the one provided as argument.
     * If found, the index of the matching crumb will be returned.
     *
     * @param string $title Title to find.
     * @return int|null Index of the crumb found, or null if it can not be found.
     */
    protected Nullable!int findCrumb(string $title) {
        foreach (this.crumbs as $key: $crumb) {
            if ($crumb["title"] == $title) {
                return $key;
            }
        }

        return null;
    }
}
