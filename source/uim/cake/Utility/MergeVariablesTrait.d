module uim.cake.Utility;

/**
 * Provides features for merging object properties recursively with
 * parent classes.
 */
trait MergeVariablesTrait
{
    /**
     * Merge the list of $properties with all parent classes of the current class.
     *
     * ### Options:
     *
     * - `associative` - A list of properties that should be treated as associative arrays.
     *   Properties in this list will be passed through Hash::normalize() before merging.
     *
     * @param array<string> $properties An array of properties and the merge strategy for them.
     * @param array<string, mixed> myOptions The options to use when merging properties.
     * @return void
     */
    protected auto _mergeVars(array $properties, array myOptions = []): void
    {
        myClass = static::class;
        $parents = [];
        while (true) {
            $parent = get_parent_class(myClass);
            if (!$parent) {
                break;
            }
            $parents[] = $parent;
            myClass = $parent;
        }
        foreach ($properties as $property) {
            if (!property_exists(this, $property)) {
                continue;
            }
            thisValue = this.{$property};
            if (thisValue === null || thisValue === false) {
                continue;
            }
            this._mergeProperty($property, $parents, myOptions);
        }
    }

    /**
     * Merge a single property with the values declared in all parent classes.
     *
     * @param string $property The name of the property being merged.
     * @param array<string> $parentClasses An array of classes you want to merge with.
     * @param array<string, mixed> myOptions Options for merging the property, see _mergeVars()
     * @return void
     */
    protected auto _mergeProperty(string $property, array $parentClasses, array myOptions): void
    {
        thisValue = this.{$property};
        $isAssoc = false;
        if (
            isset(myOptions['associative']) &&
            in_array($property, (array)myOptions['associative'], true)
        ) {
            $isAssoc = true;
        }

        if ($isAssoc) {
            thisValue = Hash::normalize(thisValue);
        }
        foreach ($parentClasses as myClass) {
            $parentProperties = get_class_vars(myClass);
            if (empty($parentProperties[$property])) {
                continue;
            }
            $parentProperty = $parentProperties[$property];
            if (!is_array($parentProperty)) {
                continue;
            }
            thisValue = this._mergePropertyData(thisValue, $parentProperty, $isAssoc);
        }
        this.{$property} = thisValue;
    }

    /**
     * Merge each of the keys in a property together.
     *
     * @param array $current The current merged value.
     * @param array $parent The parent class' value.
     * @param bool $isAssoc Whether the merging should be done in associative mode.
     * @return array The updated value.
     */
    protected auto _mergePropertyData(array $current, array $parent, bool $isAssoc) {
        if (!$isAssoc) {
            return array_merge($parent, $current);
        }
        $parent = Hash::normalize($parent);
        foreach ($parent as myKey => myValue) {
            if (!isset($current[myKey])) {
                $current[myKey] = myValue;
            }
        }

        return $current;
    }
}
