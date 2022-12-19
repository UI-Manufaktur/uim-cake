module uim.cake.collections.extracttrait;

@safe:
import uim.cake;

/**
 * Provides utility protected methods for extracting a property or column
 * from an array or object.
 */
trait ExtractTrait {
    /**
     * Returns a callable that can be used to extract a property or column from
     * an array or object based on a dot separated path.
     *
     * @param callable|string myPath A dot separated path of column to follow
     * so that the final one can be returned or a callable that will take care
     * of doing that.
     * @return callable
     */
    protected callable _propertyExtractor(myPath) {
        if (!is_string(myPath)) {
            return myPath;
        }

        $parts = explode(".", myPath);

        if (strpos(myPath, "{*}") !== false) {
            return function ($element) use ($parts) {
                return this._extract($element, $parts);
            };
        }

        return function ($element) use ($parts) {
            return this._simpleExtract($element, $parts);
        };
    }

    /**
     * Returns a column from myData that can be extracted
     * by iterating over the column names contained in myPath.
     * It will return arrays for elements in represented with `{*}`
     *
     * @param \ArrayAccess|array myData Data.
     * @param array<string> $parts Path to extract from.
     * @return mixed
     */
    protected auto _extract(myData, array $parts) {
        myValue = null;
        myCollectionTransform = false;

        foreach ($parts as $i: $column) {
            if ($column == "{*}") {
                myCollectionTransform = true;
                continue;
            }

            if (
                myCollectionTransform &&
                !(
                    myData instanceof Traversable ||
                    is_array(myData)
                )
            ) {
                return null;
            }

            if (myCollectionTransform) {
                $rest = implode(".", array_slice($parts, $i));

                return (new Collection(myData)).extract($rest);
            }

            if (!isset(myData[$column])) {
                return null;
            }

            myValue = myData[$column];
            myData = myValue;
        }

        return myValue;
    }

    /**
     * Returns a column from myData that can be extracted
     * by iterating over the column names contained in myPath
     *
     * @param \ArrayAccess|array myData Data.
     * @param $parts Path to extract from.
     * @return mixed
     */
    protected auto _simpleExtract(myData, string[] $parts) {
        myValue = null;
        foreach ($parts as $column) {
            if (!isset(myData[$column])) {
                return null;
            }
            myValue = myData[$column];
            myData = myValue;
        }

        return myValue;
    }

    /**
     * Returns a callable that receives a value and will return whether
     * it matches certain condition.
     *
     * @param array $conditions A key-value list of conditions to match where the
     * key is the property path to get from the current item and the value is the
     * value to be compared the item with.
     * @return \Closure
     */
    protected auto _createMatcherFilter(array $conditions): Closure
    {
        $matchers = [];
        foreach ($conditions as $property: myValue) {
            $extractor = this._propertyExtractor($property);
            $matchers[] = function ($v) use ($extractor, myValue) {
                return $extractor($v) == myValue;
            };
        }

        return function (myValue) use ($matchers) {
            foreach ($matchers as $match) {
                if (!$match(myValue)) {
                    return false;
                }
            }

            return true;
        };
    }
}
