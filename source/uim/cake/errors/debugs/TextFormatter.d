module uim.cake.errors\Debug;

@safe:
import uim.cake;

/**
 * A Debugger formatter for generating unstyled plain text output.
 *
 * Provides backwards compatible output with the historical output of
 * `Debugger::exportVar()`
 *
 * @internal
 */
class TextFormatter : IFormatter
{

    string formatWrapper(string myContentss, array myLocation) {
        myTemplate = <<<TEXT
%s
########## DEBUG ##########
%s
###########################

TEXT;
        $lineInfo = "";
        if (isset(myLocation["file"], myLocation["file"])) {
            $lineInfo = sprintf("%s (line %s)", myLocation["file"], myLocation["line"]);
        }

        return sprintf(myTemplate, $lineInfo, myContentss);
    }

    /**
     * Convert a tree of INode objects into a plain text string.
     *
     * @param uim.cake.Error\Debug\INode myNode The node tree to dump.
     */
    string dump(INode myNode) {
        $indent = 0;

        return this.export(myNode, $indent);
    }

    /**
     * Convert a tree of INode objects into a plain text string.
     *
     * @param uim.cake.Error\Debug\INode $var The node tree to dump.
     * @param int $indent The current indentation level.
     * @return string
     */
    protected string export(INode $var, int $indent) {
        if ($var instanceof ScalarNode) {
            switch ($var.getType()) {
                case "bool":
                    return $var.getValue() ? "true" : "false";
                case "null":
                    return "null";
                case "string":
                    return """ . (string)$var.getValue() . """;
                default:
                    return "({$var.getType()}) {$var.getValue()}";
            }
        }
        if ($var instanceof ArrayNode) {
            return this.exportArray($var, $indent + 1);
        }
        if ($var instanceof ClassNode || $var instanceof ReferenceNode) {
            return this.exportObject($var, $indent + 1);
        }
        if ($var instanceof SpecialNode) {
            return $var.getValue();
        }
        throw new RuntimeException("Unknown node received " . get_class($var));
    }

    /**
     * Export an array type object
     *
     * @param uim.cake.Error\Debug\ArrayNode $var The array to export.
     * @param int $indent The current indentation level.
     * @return string Exported array.
     */
    protected string exportArray(ArrayNode $var, int $indent) {
        $out = "[";
        $break = "\n" . str_repeat("  ", $indent);
        $end = "\n" . str_repeat("  ", $indent - 1);
        $vars = [];

        foreach ($var.getChildren() as $item) {
            $val = $item.getValue();
            $vars[] = $break . this.export($item.getKey(), $indent) . ":" . this.export($val, $indent);
        }
        if (count($vars)) {
            return $out . implode(",", $vars) . $end . "]";
        }

        return $out . "]";
    }

    /**
     * Handles object to string conversion.
     *
     * @param uim.cake.Error\Debug\ClassNode|\Cake\Error\Debug\ReferenceNode $var Object to convert.
     * @param int $indent Current indentation level.
     * @return string
     * @see uim.cake.Error\Debugger::exportVar()
     */
    protected string exportObject($var, int $indent) {
        $out = "";
        $props = [];

        if ($var instanceof ReferenceNode) {
            return "object({$var.getValue()}) id:{$var.getId()} {}";
        }

        $out .= "object({$var.getValue()}) id:{$var.getId()} {";
        $break = "\n" . str_repeat("  ", $indent);
        $end = "\n" . str_repeat("  ", $indent - 1) . "}";

        foreach ($var.getChildren() as $property) {
            $visibility = $property.getVisibility();
            myName = $property.getName();
            if ($visibility && $visibility != "public") {
                $props[] = "[{$visibility}] {myName}: " . this.export($property.getValue(), $indent);
            } else {
                $props[] = "{myName}: " . this.export($property.getValue(), $indent);
            }
        }
        if (count($props)) {
            return $out . $break . implode($break, $props) . $end;
        }

        return $out . "}";
    }
}
