module uim.cake.View;

import uim.cake.core.App;
import uim.cake.utilities.Inflector;
import uim.cake.View\exceptions.MissingCellException;

/**
 * Provides cell() method for usage in Controller and View classes.
 */
trait CellTrait
{
    /**
     * Renders the given cell.
     *
     * Example:
     *
     * ```
     * // Taxonomy\View\Cell\TagCloudCell::smallList()
     * $cell = this.cell("Taxonomy.TagCloud::smallList", ["limit": 10]);
     *
     * // App\View\Cell\TagCloudCell::smallList()
     * $cell = this.cell("TagCloud::smallList", ["limit": 10]);
     * ```
     *
     * The `display` action will be used by default when no action is provided:
     *
     * ```
     * // Taxonomy\View\Cell\TagCloudCell::display()
     * $cell = this.cell("Taxonomy.TagCloud");
     * ```
     *
     * Cells are not rendered until they are echoed.
     *
     * @param string $cell You must indicate cell name, and optionally a cell action. e.g.: `TagCloud::smallList` will
     *  invoke `View\Cell\TagCloudCell::smallList()`, `display` action will be invoked by default when none is provided.
     * @param array $data Additional arguments for cell method. e.g.:
     *    `cell("TagCloud::smallList", ["a1": "v1", "a2": "v2"])` maps to `View\Cell\TagCloud::smallList(v1, v2)`
     * @param array<string, mixed> $options Options for Cell"s constructor
     * @return uim.cake.View\Cell The cell instance
     * @throws uim.cake.View\exceptions.MissingCellException If Cell class was not found.
     */
    protected function cell(string $cell, array $data = null, STRINGAA someOptions = null): Cell
    {
        $parts = explode("::", $cell);

        if (count($parts) == 2) {
            [$pluginAndCell, $action] = [$parts[0], $parts[1]];
        } else {
            [$pluginAndCell, $action] = [$parts[0], "display"];
        }

        [$plugin] = pluginSplit($pluginAndCell);
        $className = App::className($pluginAndCell, "View/Cell", "Cell");

        if (!$className) {
            throw new MissingCellException(["className": $pluginAndCell ~ "Cell"]);
        }

        if (!empty($data)) {
            $data = array_values($data);
        }
        $options = ["action": $action, "args": $data] + $options;

        return _createCell($className, $action, $plugin, $options);
    }

    /**
     * Create and configure the cell instance.
     *
     * @param string $className The cell classname.
     * @param string $action The action name.
     * @param string|null $plugin The plugin name.
     * @param array<string, mixed> $options The constructor options for the cell.
     * @return uim.cake.View\Cell
     */
    protected function _createCell(string $className, string $action, Nullable!string $plugin, STRINGAA someOptions): Cell
    {
        /** @var uim.cake.View\Cell $instance */
        $instance = new $className(this.request, this.response, this.getEventManager(), $options);

        $builder = $instance.viewBuilder();
        $builder.setTemplate(Inflector::underscore($action));

        if (!empty($plugin)) {
            $builder.setPlugin($plugin);
        }
        if (!empty(this.helpers)) {
            $builder.addHelpers(this.helpers);
        }

        if (this instanceof View) {
            if (!empty(this.theme)) {
                $builder.setTheme(this.theme);
            }

            $class = static::class;
            $builder.setClassName($class);
            $instance.viewBuilder().setClassName($class);

            return $instance;
        }

        if (method_exists(this, "viewBuilder")) {
            $builder.setTheme(this.viewBuilder().getTheme());

            if (this.viewBuilder().getClassName() != null) {
                $builder.setClassName(this.viewBuilder().getClassName());
            }
        }

        return $instance;
    }
}
