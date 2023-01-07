/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.errors.debugs;

use RuntimeException;

/**
 * A Debugger formatter for generating unstyled plain text output.
 *
 * Provides backwards compatible output with the historical output of
 * `Debugger::exportVar()`
 *
 * @internal
 */
class TextFormatter : IFormatter {

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
     * @param uim.cake.errors.debugs.INode myNode The node tree to dump.
     */
    string dump(INode myNode) {
        auto myIndent = 0;

        return this.export(myNode, myIndent);
    }

    /**
     * Convert a tree of INode objects into a plain text string.
     *
     * @param uim.cake.errors.debugs.INode $var The node tree to dump.
     * @param int $indent The current indentation level.
     * @return string
     */
    protected string export(INode aNode, int anIndent) {
        if (auto scalarNode = cast(ScalarNode)aNode) {
          switch (scalarNode.getType()) {
            case "bool":
              return scalarNode.getValue() ? "true" : "false";
            case "null":
                return "null";
            case "string":
                return " ~ %s ~ ".format(scalarNode.getValue());
            default:
                return "({aVar.getType()}) {aVar.getValue()}";
          }
        }
        if (auto arrayNode = cast(ArrayNode)aNode) {
          return this.exportArray(arrayNode, anIndent + 1);
        }
        if (auto classNode = cast(ClassNode)aNode) {
          return this.exportObject(classNode, anIndent + 1);
        } 
        if (auto referenceNode = cast(ReferenceNode)aNode) {
          return this.exportObject(referenceNode, anIndent + 1);
        }
        if (auto specialNode = cast(SpecialNode)aNode) {
          return specialNode.getValue();
        }
        throw new Exception("Unknown node received " ~ get_class(aVar));
    }

    /**
     * Export an array type object
     *
     * @param uim.cake.errors.debugs.ArrayNode $var The array to export.
     * @param int $indent The current indentation level.
     * @return string Exported array.
     */
    protected string exportArray(ArrayNode $var, int $indent) {
        $out = "[";
        $break = "\n" ~ str_repeat("  ", $indent);
        $end = "\n" ~ str_repeat("  ", $indent - 1);
        $vars = [];

        foreach ($var.getChildren() as $item) {
            $val = $item.getValue();
            $vars[] = $break . this.export($item.getKey(), $indent) ~ ":" ~ this.export($val, $indent);
        }
        if (count($vars)) {
            return $out . implode(",", $vars) . $end ~ "]";
        }

        return $out ~ "]";
    }

    /**
     * Handles object to string conversion.
     *
     * @param uim.cake.errors.debugs.ClassNode|uim.cake.errors.debugs.ReferenceNode $var Object to convert.
     * @param int $indent Current indentation level.
     * @return string
     * @see uim.cake.errors.Debugger::exportVar()
     */
    protected string exportObject($var, int $indent) {
        $out = "";
        $props = [];

        if ($var instanceof ReferenceNode) {
            return "object({$var.getValue()}) id:{$var.getId()} {}";
        }

        $out .= "object({$var.getValue()}) id:{$var.getId()} {";
        $break = "\n" ~ str_repeat("  ", $indent);
        $end = "\n" ~ str_repeat("  ", $indent - 1) ~ "}";

        foreach ($var.getChildren() as $property) {
            $visibility = $property.getVisibility();
            myName = $property.getName();
            if ($visibility && $visibility != "public") {
                $props[] = "[{$visibility}] {myName}: " ~ this.export($property.getValue(), $indent);
            } else {
                $props[] = "{myName}: " ~ this.export($property.getValue(), $indent);
            }
        }
        if (count($props)) {
            return $out . $break . implode($break, $props) . $end;
        }

        return $out ~ "}";
    }
}
