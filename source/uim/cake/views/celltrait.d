module uim.cake.views;

@safe:
import uim.cake;

// Provides cell() method for usage in Controller and View classes.
trait CellTrait {
    /**
     * Renders the given cell.
     *
     * Example:
     *
     * ```
     * // Taxonomy\View\Cell\TagCloudCell::smallList()
     * $cell = this.cell("Taxonomy.TagCloud::smallList", ["limit" => 10]);
     *
     * // App\View\Cell\TagCloudCell::smallList()
     * $cell = this.cell("TagCloud::smallList", ["limit" => 10]);
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
     * @param array myData Additional arguments for cell method. e.g.:
     *    `cell("TagCloud::smallList", ["a1" => "v1", "a2" => "v2"])` maps to `View\Cell\TagCloud::smallList(v1, v2)`
     * @param array<string, mixed> myOptions Options for Cell"s constructor
     * @return \Cake\View\Cell The cell instance
     * @throws \Cake\View\Exception\MissingCellException If Cell class was not found.
     */
    protected auto cell(string $cell, array myData = [], array myOptions = []): Cell
    {
        $parts = explode("::", $cell);

        if (count($parts) == 2) {
            [myPluginAndCell, $action] = [$parts[0], $parts[1]];
        } else {
            [myPluginAndCell, $action] = [$parts[0], "display"];
        }

        [myPlugin] = pluginSplit(myPluginAndCell);
        myClassName = App::className(myPluginAndCell, "View/Cell", "Cell");

        if (!myClassName) {
            throw new MissingCellException(["className" => myPluginAndCell . "Cell"]);
        }

        if (!empty(myData)) {
            myData = array_values(myData);
        }
        myOptions = ["action" => $action, "args" => myData] + myOptions;
        $cell = this._createCell(myClassName, $action, myPlugin, myOptions);

        return $cell;
    }

    /**
     * Create and configure the cell instance.
     *
     * @param string myClassName The cell classname.
     * @param string $action The action name.
     * @param string|null myPlugin The plugin name.
     * @param array<string, mixed> myOptions The constructor options for the cell.
     * @return \Cake\View\Cell
     */
    protected auto _createCell(string myClassName, string $action, Nullable!string myPlugin, array myOptions): Cell
    {
        /** @var \Cake\View\Cell $instance */
        $instance = new myClassName(this.request, this.response, this.getEventManager(), myOptions);

        myBuilder = $instance.viewBuilder();
        myBuilder.setTemplate(Inflector::underscore($action));

        if (!empty(myPlugin)) {
            myBuilder.setPlugin(myPlugin);
        }
        if (!empty(this.helpers)) {
            myBuilder.addHelpers(this.helpers);
        }

        if (this instanceof View) {
            if (!empty(this.theme)) {
                myBuilder.setTheme(this.theme);
            }

            myClass = static::class;
            myBuilder.setClassName(myClass);
            $instance.viewBuilder().setClassName(myClass);

            return $instance;
        }

        if (method_exists(this, "viewBuilder")) {
            myBuilder.setTheme(this.viewBuilder().getTheme());

            if (this.viewBuilder().getClassName() !== null) {
                myBuilder.setClassName(this.viewBuilder().getClassName());
            }
        }

        return $instance;
    }
}
