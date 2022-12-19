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
    protected array _normalizeAssociations($associations)
    {
        myResult = [];
        foreach ((array)$associations as myTable: myOptions) {
            $pointer = &myResult;

            if (is_int(myTable)) {
                myTable = myOptions;
                myOptions = [];
            }

            if (!strpos(myTable, ".")) {
                myResult[myTable] = myOptions;
                continue;
            }

            myPath = explode(".", myTable);
            myTable = array_pop(myPath);
            /** @var string $first */
            $first = array_shift(myPath);
            $pointer += [$first: []];
            $pointer = &$pointer[$first];
            $pointer += ["associated":[]];

            foreach (myPath as $t) {
                $pointer += ["associated":[]];
                $pointer["associated"] += [$t: []];
                $pointer["associated"][$t] += ["associated":[]];
                $pointer = &$pointer["associated"][$t];
            }

            $pointer["associated"] += [myTable: []];
            $pointer["associated"][myTable] = myOptions + $pointer["associated"][myTable];
        }

        return myResult["associated"] ?? myResult;
    }
}
