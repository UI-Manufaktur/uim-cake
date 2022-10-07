

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Error\Debug;

use RuntimeException;

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

    function formatWrapper(string myContentss, array myLocation): string
    {
        myTemplate = <<<TEXT
%s
########## DEBUG ##########
%s
###########################

TEXT;
        $lineInfo = '';
        if (isset(myLocation['file'], myLocation['file'])) {
            $lineInfo = sprintf('%s (line %s)', myLocation['file'], myLocation['line']);
        }

        return sprintf(myTemplate, $lineInfo, myContentss);
    }

    /**
     * Convert a tree of INode objects into a plain text string.
     *
     * @param \Cake\Error\Debug\INode myNode The node tree to dump.
     * @return string
     */
    function dump(INode myNode): string
    {
        $indent = 0;

        return this.export(myNode, $indent);
    }

    /**
     * Convert a tree of INode objects into a plain text string.
     *
     * @param \Cake\Error\Debug\INode $var The node tree to dump.
     * @param int $indent The current indentation level.
     * @return string
     */
    protected auto export(INode $var, int $indent): string
    {
        if ($var instanceof ScalarNode) {
            switch ($var.getType()) {
                case 'bool':
                    return $var.getValue() ? 'true' : 'false';
                case 'null':
                    return 'null';
                case 'string':
                    return "'" . (string)$var.getValue() . "'";
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
        throw new RuntimeException('Unknown node received ' . get_class($var));
    }

    /**
     * Export an array type object
     *
     * @param \Cake\Error\Debug\ArrayNode $var The array to export.
     * @param int $indent The current indentation level.
     * @return string Exported array.
     */
    protected auto exportArray(ArrayNode $var, int $indent): string
    {
        $out = '[';
        $break = "\n" . str_repeat('  ', $indent);
        $end = "\n" . str_repeat('  ', $indent - 1);
        $vars = [];

        foreach ($var.getChildren() as $item) {
            $val = $item.getValue();
            $vars[] = $break . this.export($item.getKey(), $indent) . ' => ' . this.export($val, $indent);
        }
        if (count($vars)) {
            return $out . implode(',', $vars) . $end . ']';
        }

        return $out . ']';
    }

    /**
     * Handles object to string conversion.
     *
     * @param \Cake\Error\Debug\ClassNode|\Cake\Error\Debug\ReferenceNode $var Object to convert.
     * @param int $indent Current indentation level.
     * @return string
     * @see \Cake\Error\Debugger::exportVar()
     */
    protected auto exportObject($var, int $indent): string
    {
        $out = '';
        $props = [];

        if ($var instanceof ReferenceNode) {
            return "object({$var.getValue()}) id:{$var.getId()} {}";
        }

        $out .= "object({$var.getValue()}) id:{$var.getId()} {";
        $break = "\n" . str_repeat('  ', $indent);
        $end = "\n" . str_repeat('  ', $indent - 1) . '}';

        foreach ($var.getChildren() as $property) {
            $visibility = $property.getVisibility();
            myName = $property.getName();
            if ($visibility && $visibility !== 'public') {
                $props[] = "[{$visibility}] {myName} => " . this.export($property.getValue(), $indent);
            } else {
                $props[] = "{myName} => " . this.export($property.getValue(), $indent);
            }
        }
        if (count($props)) {
            return $out . $break . implode($break, $props) . $end;
        }

        return $out . '}';
    }
}
