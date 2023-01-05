module uim.cake.ORM;

/**
 * Contains methods for parsing the associated tables array that is typically
 * passed to a save operation
 */
trait AssociationsNormalizerTrait
{
    /**
     * Returns an array out of the original passed associations list where dot notation
     * is transformed into nested arrays so that they can be parsed by other routines
     *
     * @param array|string $associations The array of included associations.
     * @return array An array having dot notation transformed into nested arrays
     */
    protected array _normalizeAssociations($associations) {
        $result = [];
        foreach ((array)$associations as $table: $options) {
            $pointer = &$result;

            if (is_int($table)) {
                $table = $options;
                $options = [];
            }

            if (!strpos($table, ".")) {
                $result[$table] = $options;
                continue;
            }

            $path = explode(".", $table);
            $table = array_pop($path);
            /** @var string $first */
            $first = array_shift($path);
            $pointer += [$first: []];
            $pointer = &$pointer[$first];
            $pointer += ["associated": []];

            foreach ($path as $t) {
                $pointer += ["associated": []];
                $pointer["associated"] += [$t: []];
                $pointer["associated"][$t] += ["associated": []];
                $pointer = &$pointer["associated"][$t];
            }

            $pointer["associated"] += [$table: []];
            $pointer["associated"][$table] = $options + $pointer["associated"][$table];
        }

        return $result["associated"] ?? $result;
    }
}
