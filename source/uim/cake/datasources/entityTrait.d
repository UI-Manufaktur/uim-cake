module uim.cake.datasources;

@safe:
import uim.cake;

/**
 * An entity represents a single result row from a repository. It exposes the
 * methods for retrieving and storing fields associated in this row.
 */
trait EntityTrait
{
    /**
     * Holds all fields and their values for this entity.
     *
     * @var array<string, mixed>
     */
    protected $_fields = [];

    /**
     * Holds all fields that have been changed and their original values for this entity.
     *
     * @var array<string, mixed>
     */
    protected $_original = ;

    /**
     * List of field names that should **not** be included in JSON or Array
     * representations of this Entity.
     */
    protected string[] _hidden;

    /**
     * List of computed or virtual fields that **should** be included in JSON or array
     * representations of this Entity. If a field is present in both _hidden and _virtual
     * the field will **not** be in the array/JSON versions of the entity.
     */
    protected string[] _virtual = [];

    /**
     * Holds a list of the fields that were modified or added after this object
     * was originally created.
     */
    protected bool[] _dirty;

    /**
     * Holds a cached list of getters/setters per class
     *
     * @var array<string, array<string, array<string, string>>>
     */
    protected static $_accessors = [];

    /**
     * Indicates whether this entity is yet to be persisted.
     * Entities default to assuming they are new. You can use Table::persisted()
     * to set the new flag on an entity based on records in the database.
     *
     * @var bool
     */
    protected $_new = true;

    /**
     * List of errors per field as stored in this object.
     *
     * @var array<string, mixed>
     */
    protected $_errors = [];

    /**
     * List of invalid fields and their data for errors upon validation/patching.
     *
     * @var array<string, mixed>
     */
    protected $_invalid = [];

    /**
     * Map of fields in this entity that can be safely assigned, each
     * field name points to a boolean indicating its status. An empty array
     * means no fields are accessible
     *
     * The special field "\*" can also be mapped, meaning that any other field
     * not defined in the map will take its value. For example, `"*": true`
     * means that any field not defined in the map will be accessible by default
     */
    protected bool[] _accessible = ["*": true];

    /**
     * The alias of the repository this entity came from
     */
    protected string $_registryAlias = "";

    /**
     * Magic getter to access fields that have been set in this entity
     *
     * @param string myField Name of the field to access
     * @return mixed
     */
    function &__get(string myField) {
        return this.get(myField);
    }

    /**
     * Magic setter to add or edit a field in this entity
     *
     * @param string myField The name of the field to set
     * @param mixed myValue The value to set to the field
     */
    void __set(string myField, myValue) {
        this.set(myField, myValue);
    }

    /**
     * Returns whether this entity contains a field named myField
     * regardless of if it is empty.
     *
     * @param string myField The field to check.
     * @return bool
     * @see \Cake\ORM\Entity::has()
     */
    bool __isset(string myField) {
        return this.has(myField);
    }

    /**
     * Removes a field from this entity
     *
     * @param string myField The field to unset
     */
    void __unset(string myField) {
        this.unset(myField);
    }

    /**
     * Sets a single field inside this entity.
     *
     * ### Example:
     *
     * ```
     * $entity.set("name", "Andrew");
     * ```
     *
     * It is also possible to mass-assign multiple fields to this entity
     * with one call by passing a hashed array as fields in the form of
     * field: value pairs
     *
     * ### Example:
     *
     * ```
     * $entity.set(["name": "andrew", "id": 1]);
     * echo $entity.name // prints andrew
     * echo $entity.id // prints 1
     * ```
     *
     * Some times it is handy to bypass setter functions in this entity when assigning
     * fields. You can achieve this by disabling the `setter` option using the
     * `myOptions` parameter:
     *
     * ```
     * $entity.set("name", "Andrew", ["setter": false]);
     * $entity.set(["name": "Andrew", "id": 1], ["setter": false]);
     * ```
     *
     * Mass assignment should be treated carefully when accepting user input, by default
     * entities will guard all fields when fields are assigned in bulk. You can disable
     * the guarding for a single set call with the `guard` option:
     *
     * ```
     * $entity.set(["name": "Andrew", "id": 1], ["guard": false]);
     * ```
     *
     * You do not need to use the guard option when assigning fields individually:
     *
     * ```
     * // No need to use the guard option.
     * $entity.set("name", "Andrew");
     * ```
     *
     * @param array<string, mixed>|string myField the name of field to set or a list of
     * fields with their respective values
     * @param mixed myValue The value to set to the field or an array if the
     * first argument is also an array, in which case will be treated as myOptions
     * @param array<string, mixed> myOptions Options to be used for setting the field. Allowed option
     * keys are `setter` and `guard`
     * @return this
     * @throws \InvalidArgumentException
     */
    auto set(myField, myValue = null, array myOptions = []) {
        if (is_string(myField) && myField !== "") {
            $guard = false;
            myField = [myField: myValue];
        } else {
            $guard = true;
            myOptions = (array)myValue;
        }

        if (!is_array(myField)) {
            throw new InvalidArgumentException("Cannot set an empty field");
        }
        myOptions += ["setter": true, "guard": $guard];

        foreach (myField as myName: myValue) {
            myName = (string)myName;
            if (myOptions["guard"] == true && !this.isAccessible(myName)) {
                continue;
            }

            this.setDirty(myName, true);

            if (
                !array_key_exists(myName, this._original) &&
                array_key_exists(myName, this._fields) &&
                this._fields[myName] !== myValue
            ) {
                this._original[myName] = this._fields[myName];
            }

            if (!myOptions["setter"]) {
                this._fields[myName] = myValue;
                continue;
            }

            $setter = static::_accessor(myName, "set");
            if ($setter) {
                myValue = this.{$setter}(myValue);
            }
            this._fields[myName] = myValue;
        }

        return this;
    }

    /**
     * Returns the value of a field by name
     *
     * @param string myField the name of the field to retrieve
     * @return mixed
     * @throws \InvalidArgumentException if an empty field name is passed
     */
    function &get(string myField) {
        if (myField == "") {
            throw new InvalidArgumentException("Cannot get an empty field");
        }

        myValue = null;
        $method = static::_accessor(myField, "get");

        if (isset(this._fields[myField])) {
            myValue = &this._fields[myField];
        }

        if ($method) {
            myResult = this.{$method}(myValue);

            return myResult;
        }

        return myValue;
    }

    /**
     * Returns the value of an original field by name
     *
     * @param string myField the name of the field for which original value is retrieved.
     * @return mixed
     * @throws \InvalidArgumentException if an empty field name is passed.
     */
    auto getOriginal(string myField) {
        if (myField == "") {
            throw new InvalidArgumentException("Cannot get an empty field");
        }
        if (array_key_exists(myField, this._original)) {
            return this._original[myField];
        }

        return this.get(myField);
    }

    /**
     * Gets all original values of the entity.
     *
     * @return array
     */
    auto getOriginalValues(): array
    {
        $originals = this._original;
        $originalKeys = array_keys($originals);
        foreach (this._fields as myKey: myValue) {
            if (!in_array(myKey, $originalKeys, true)) {
                $originals[myKey] = myValue;
            }
        }

        return $originals;
    }

    /**
     * Returns whether this entity contains a field named myField
     * that contains a non-null value.
     *
     * ### Example:
     *
     * ```
     * $entity = new Entity(["id": 1, "name": null]);
     * $entity.has("id"); // true
     * $entity.has("name"); // false
     * $entity.has("last_name"); // false
     * ```
     *
     * You can check multiple fields by passing an array:
     *
     * ```
     * $entity.has(["name", "last_name"]);
     * ```
     *
     * All fields must not be null to get a truthy result.
     *
     * When checking multiple fields. All fields must not be null
     * in order for true to be returned.
     *
     * @param array<string>|string myField The field or fields to check.
     */
    bool has(myField) {
        foreach ((array)myField as $prop) {
            if (this.get($prop) == null) {
                return false;
            }
        }

        return true;
    }

    /**
     * Checks that a field is empty
     *
     * This is not working like the PHP `empty()` function. The method will
     * return true for:
     *
     * - `""` (empty string)
     * - `null`
     * - `[]`
     *
     * and false in all other cases.
     *
     * @param string myField The field to check.
     */
    bool isEmpty(string myField) {
        myValue = this.get(myField);
        if (
            myValue == null ||
            (
                is_array(myValue) &&
                empty(myValue) ||
                (
                    is_string(myValue) &&
                    myValue == ""
                )
            )
        ) {
            return true;
        }

        return false;
    }

    /**
     * Checks tha a field has a value.
     *
     * This method will return true for
     *
     * - Non-empty strings
     * - Non-empty arrays
     * - Any object
     * - Integer, even `0`
     * - Float, even 0.0
     *
     * and false in all other cases.
     *
     * @param string myField The field to check.
     */
    bool hasValue(string myField) {
        return !this.isEmpty(myField);
    }

    /**
     * Removes a field or list of fields from this entity
     *
     * ### Examples:
     *
     * ```
     * $entity.unset("name");
     * $entity.unset(["name", "last_name"]);
     * ```
     *
     * @param array<string>|string myField The field to unset.
     * @return this
     */
    function unset(myField) {
        myField = (array)myField;
        foreach (myField as $p) {
            unset(this._fields[$p], this._original[$p], this._dirty[$p]);
        }

        return this;
    }

    /**
     * Removes a field or list of fields from this entity
     *
     * @deprecated 4.0.0 Use {@link unset()} instead. Will be removed in 5.0.
     * @param array<string>|string myField The field to unset.
     * @return this
     */
    function unsetProperty(myField) {
        deprecationWarning("EntityTrait::unsetProperty() is deprecated. Use unset() instead.");

        return this.unset(myField);
    }

    /**
     * Sets hidden fields.
     *
     * @param myFields An array of fields to hide from array exports.
     * @param bool myMerge Merge the new fields with the existing. By default false.
     * @return this
     */
    auto setHidden(string[] myFields, bool myMerge = false) {
        if (myMerge == false) {
            this._hidden = myFields;

            return this;
        }

        myFields = array_merge(this._hidden, myFields);
        this._hidden = array_unique(myFields);

        return this;
    }

    // Gets the hidden fields.
    string[] getHidden() {
        return this._hidden;
    }

    /**
     * Sets the virtual fields on this entity.
     *
     * @param myFields An array of fields to treat as virtual.
     * @param bool myMerge Merge the new fields with the existing. By default false.
     * @return this
     */
    auto setVirtual(string[] myFields, bool myMerge = false) {
        if (myMerge == false) {
            this._virtual = myFields;

            return this;
        }

        myFields = array_merge(this._virtual, myFields);
        this._virtual = array_unique(myFields);

        return this;
    }

    // Gets the virtual fields on this entity.
    string[] getVirtual() {
        return this._virtual;
    }

    /**
     * Gets the list of visible fields.
     *
     * The list of visible fields is all standard fields
     * plus virtual fields minus hidden fields.
     *
     * @return A list of fields that are "visible" in all
     *     representations.
     */
    string[] getVisible() {
        myFields = array_keys(this._fields);
        myFields = array_merge(myFields, this._virtual);

        return array_diff(myFields, this._hidden);
    }

    /**
     * Returns an array with all the fields that have been set
     * to this entity
     *
     * This method will recursively transform entities assigned to fields
     * into arrays as well.
     *
     * @return array
     */
    function toArray(): array
    {
        myResult = [];
        foreach (this.getVisible() as myField) {
            myValue = this.get(myField);
            if (is_array(myValue)) {
                myResult[myField] = [];
                foreach (myValue as $k: $entity) {
                    if ($entity instanceof IEntity) {
                        myResult[myField][$k] = $entity.toArray();
                    } else {
                        myResult[myField][$k] = $entity;
                    }
                }
            } elseif (myValue instanceof IEntity) {
                myResult[myField] = myValue.toArray();
            } else {
                myResult[myField] = myValue;
            }
        }

        return myResult;
    }

    /**
     * Returns the fields that will be serialized as JSON
     *
     * @return array
     */
    function jsonSerialize(): array
    {
        return this.extract(this.getVisible());
    }

    /**
     * : isset($entity);
     *
     * @param string $offset The offset to check.
     * @return bool Success
     */
    bool offsetExists($offset) {
        return this.has($offset);
    }

    /**
     * : $entity[$offset];
     *
     * @param string $offset The offset to get.
     * @return mixed
     */
    #[\ReturnTypeWillChange]
    function &offsetGet($offset) {
        return this.get($offset);
    }

    /**
     * : $entity[$offset] = myValue;
     *
     * @param string $offset The offset to set.
     * @param mixed myValue The value to set.
     */
    void offsetSet($offset, myValue) {
        this.set($offset, myValue);
    }

    /**
     * : unset(myResult[$offset]);
     *
     * @param string $offset The offset to remove.
     */
    void offsetUnset($offset) {
        this.unset($offset);
    }

    /**
     * Fetch accessor method name
     * Accessor methods (available or not) are cached in $_accessors
     *
     * @param string $property the field name to derive getter name from
     * @param string myType the accessor type ("get" or "set")
     * return method name or empty string (no method available)
     */
    protected static string _accessor(string $property, string myType) {
        myClass = static::class;

        if (isset(static::$_accessors[myClass][myType][$property])) {
            return static::$_accessors[myClass][myType][$property];
        }

        if (!empty(static::$_accessors[myClass])) {
            return static::$_accessors[myClass][myType][$property] = "";
        }

        if (static::class == Entity::class) {
            return "";
        }

        foreach (get_class_methods(myClass) as $method) {
            $prefix = substr($method, 1, 3);
            if ($method[0] !== "_" || ($prefix !== "get" && $prefix !== "set")) {
                continue;
            }
            myField = lcfirst(substr($method, 4));
            $snakeField = Inflector::underscore(myField);
            $titleField = ucfirst(myField);
            static::$_accessors[myClass][$prefix][$snakeField] = $method;
            static::$_accessors[myClass][$prefix][myField] = $method;
            static::$_accessors[myClass][$prefix][$titleField] = $method;
        }

        if (!isset(static::$_accessors[myClass][myType][$property])) {
            static::$_accessors[myClass][myType][$property] = "";
        }

        return static::$_accessors[myClass][myType][$property];
    }

    /**
     * Returns an array with the requested fields
     * stored in this entity, indexed by field name
     *
     * @param myFields list of fields to be returned
     * @param bool $onlyDirty Return the requested field only if it is dirty
     * @return array
     */
    function extract(string[] myFields, bool $onlyDirty = false): array
    {
        myResult = [];
        foreach (myFields as myField) {
            if (!$onlyDirty || this.isDirty(myField)) {
                myResult[myField] = this.get(myField);
            }
        }

        return myResult;
    }

    /**
     * Returns an array with the requested original fields
     * stored in this entity, indexed by field name.
     *
     * Fields that are unchanged from their original value will be included in the
     * return of this method.
     *
     * @param myFields List of fields to be returned
     * @return array
     */
    function extractOriginal(string[] myFields): array
    {
        myResult = [];
        foreach (myFields as myField) {
            myResult[myField] = this.getOriginal(myField);
        }

        return myResult;
    }

    /**
     * Returns an array with only the original fields
     * stored in this entity, indexed by field name.
     *
     * This method will only return fields that have been modified since
     * the entity was built. Unchanged fields will be omitted.
     *
     * @param myFields List of fields to be returned
     * @return array
     */
    function extractOriginalChanged(string[] myFields): array
    {
        myResult = [];
        foreach (myField; myFields) {
            $original = this.getOriginal(myField);
            if ($original !== this.get(myField)) {
                myResult[myField] = $original;
            }
        }

        return myResult;
    }

    /**
     * Sets the dirty status of a single field.
     *
     * @param string myField the field to set or check status for
     * @param bool $isDirty true means the field was changed, false means
     * it was not changed. Defaults to true.
     * @return this
     */
    auto setDirty(string myField, bool $isDirty = true) {
        if ($isDirty == false) {
            unset(this._dirty[myField]);

            return this;
        }

        this._dirty[myField] = true;
        unset(this._errors[myField], this._invalid[myField]);

        return this;
    }

    /**
     * Checks if the entity is dirty or if a single field of it is dirty.
     *
     * @param string|null myField The field to check the status for. Null for the whole entity.
     * @return bool Whether the field was changed or not
     */
    bool isDirty(Nullable!string myField = null) {
        if (myField == null) {
            return !empty(this._dirty);
        }

        return isset(this._dirty[myField]);
    }

    // Gets the dirty fields.
    string[] getDirty() {
        return array_keys(this._dirty);
    }

    /**
     * Sets the entire entity as clean, which means that it will appear as
     * no fields being modified or added at all. This is an useful call
     * for an initial object hydration
     */
    void clean() {
        this._dirty = [];
        this._errors = [];
        this._invalid = [];
        this._original = [];
    }

    /**
     * Set the status of this entity.
     *
     * Using `true` means that the entity has not been persisted in the database,
     * `false` that it already is.
     *
     * @param bool $new Indicate whether this entity has been persisted.
     * @return this
     */
    auto setNew(bool $new) {
        if ($new) {
            foreach (this._fields as $k: $p) {
                this._dirty[$k] = true;
            }
        }

        this._new = $new;

        return this;
    }

    /**
     * Returns whether this entity has already been persisted.
     *
     * @return bool Whether the entity has been persisted.
     */
    bool isNew() {
        if (func_num_args()) {
            deprecationWarning("Using isNew() as setter is deprecated. Use setNew() instead.");

            this.setNew(func_get_arg(0));
        }

        return this._new;
    }

    /**
     * Returns whether this entity has errors.
     *
     * @param bool $includeNested true will check nested entities for hasErrors()
     */
    bool hasErrors(bool $includeNested = true) {
        if (Hash::filter(this._errors)) {
            return true;
        }

        if ($includeNested == false) {
            return false;
        }

        foreach (this._fields as myField) {
            if (this._readHasErrors(myField)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Returns all validation errors.
     *
     * @return array
     */
    auto getErrors(): array
    {
        $diff = array_diff_key(this._fields, this._errors);

        return this._errors + (new Collection($diff))
            .filter(function (myValue) {
                return is_array(myValue) || myValue instanceof IEntity;
            })
            .map(function (myValue) {
                return this._readError(myValue);
            })
            .filter()
            .toArray();
    }

    /**
     * Returns validation errors of a field
     *
     * @param string myField Field name to get the errors from
     * @return array
     */
    auto getError(string myField): array
    {
        myErrors = this._errors[myField] ?? [];
        if (myErrors) {
            return myErrors;
        }

        return this._nestedErrors(myField);
    }

    /**
     * Sets error messages to the entity
     *
     * ## Example
     *
     * ```
     * // Sets the error messages for multiple fields at once
     * $entity.setErrors(["salary": ["message"], "name": ["another message"]]);
     * ```
     *
     * @param array myErrors The array of errors to set.
     * @param bool $overwrite Whether to overwrite pre-existing errors for myFields
     * @return this
     */
    auto setErrors(array myErrors, bool $overwrite = false) {
        if ($overwrite) {
            foreach (myErrors as $f: myError) {
                this._errors[$f] = (array)myError;
            }

            return this;
        }

        foreach (myErrors as $f: myError) {
            this._errors += [$f: []];

            // String messages are appended to the list,
            // while more complex error structures need their
            // keys preserved for nested validator.
            if (is_string(myError)) {
                this._errors[$f][] = myError;
            } else {
                foreach (myError as $k: $v) {
                    this._errors[$f][$k] = $v;
                }
            }
        }

        return this;
    }

    /**
     * Sets errors for a single field
     *
     * ### Example
     *
     * ```
     * // Sets the error messages for a single field
     * $entity.setError("salary", ["must be numeric", "must be a positive number"]);
     * ```
     *
     * @param string myField The field to get errors for, or the array of errors to set.
     * @param array|string myErrors The errors to be set for myField
     * @param bool $overwrite Whether to overwrite pre-existing errors for myField
     * @return this
     */
    auto setError(string myField, myErrors, bool $overwrite = false) {
        if (is_string(myErrors)) {
            myErrors = [myErrors];
        }

        return this.setErrors([myField: myErrors], $overwrite);
    }

    /**
     * Auxiliary method for getting errors in nested entities
     *
     * @param string myField the field in this entity to check for errors
     * @return array errors in nested entity if any
     */
    protected auto _nestedErrors(string myField): array
    {
        // Only one path element, check for nested entity with error.
        if (indexOf(myField, ".") == false) {
            return this._readError(this.get(myField));
        }
        // Try reading the errors data with field as a simple path
        myError = Hash::get(this._errors, myField);
        if (myError !== null) {
            return myError;
        }
        myPath = explode(".", myField);

        // Traverse down the related entities/arrays for
        // the relevant entity.
        $entity = this;
        $len = count(myPath);
        while ($len) {
            $part = array_shift(myPath);
            $len = count(myPath);
            $val = null;
            if ($entity instanceof IEntity) {
                $val = $entity.get($part);
            } elseif (is_array($entity)) {
                $val = $entity[$part] ?? false;
            }

            if (
                is_array($val) ||
                $val instanceof Traversable ||
                $val instanceof IEntity
            ) {
                $entity = $val;
            } else {
                myPath[] = $part;
                break;
            }
        }
        if (count(myPath) <= 1) {
            return this._readError($entity, array_pop(myPath));
        }

        return [];
    }

    /**
     * Reads if there are errors for one or many objects.
     *
     * @param \Cake\Datasource\IEntity|array $object The object to read errors from.
     * @return bool
     */
    protected      */
    bool _readHasErrors($object) {
        if ($object instanceof IEntity && $object.hasErrors()) {
            return true;
        }

        if (is_array($object)) {
            foreach ($object as myValue) {
                if (this._readHasErrors(myValue)) {
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * Read the error(s) from one or many objects.
     *
     * @param \Cake\Datasource\IEntity|iterable $object The object to read errors from.
     * @param string|null myPath The field name for errors.
     * @return array
     */
    protected auto _readError($object, myPath = null): array
    {
        if (myPath !== null && $object instanceof IEntity) {
            return $object.getError(myPath);
        }
        if ($object instanceof IEntity) {
            return $object.getErrors();
        }
        if (is_iterable($object)) {
            $array = array_map(function ($val) {
                if ($val instanceof IEntity) {
                    return $val.getErrors();
                }

                return null;
            }, (array)$object);

            return array_filter($array);
        }

        return [];
    }

    /**
     * Get a list of invalid fields and their data for errors upon validation/patching
     *
     * @return array
     */
    auto getInvalid(): array
    {
        return this._invalid;
    }

    /**
     * Get a single value of an invalid field. Returns null if not set.
     *
     * @param string myField The name of the field.
     * @return mixed|null
     */
    auto getInvalidField(string myField) {
        return this._invalid[myField] ?? null;
    }

    /**
     * Set fields as invalid and not patchable into the entity.
     *
     * This is useful for batch operations when one needs to get the original value for an error message after patching.
     * This value could not be patched into the entity and is simply copied into the _invalid property for debugging
     * purposes or to be able to log it away.
     *
     * @param array myFields The values to set.
     * @param bool $overwrite Whether to overwrite pre-existing values for myField.
     * @return this
     */
    auto setInvalid(array myFields, bool $overwrite = false) {
        foreach (myFields as myField: myValue) {
            if ($overwrite == true) {
                this._invalid[myField] = myValue;
                continue;
            }
            this._invalid += [myField: myValue];
        }

        return this;
    }

    /**
     * Sets a field as invalid and not patchable into the entity.
     *
     * @param string myField The value to set.
     * @param mixed myValue The invalid value to be set for myField.
     * @return this
     */
    auto setInvalidField(string myField, myValue) {
        this._invalid[myField] = myValue;

        return this;
    }

    /**
     * Stores whether a field value can be changed or set in this entity.
     * The special field `*` can also be marked as accessible or protected, meaning
     * that any other field specified before will take its value. For example
     * `$entity.setAccess("*", true)` means that any field not specified already
     * will be accessible by default.
     *
     * You can also call this method with an array of fields, in which case they
     * will each take the accessibility value specified in the second argument.
     *
     * ### Example:
     *
     * ```
     * $entity.setAccess("id", true); // Mark id as not protected
     * $entity.setAccess("author_id", false); // Mark author_id as protected
     * $entity.setAccess(["id", "user_id"], true); // Mark both fields as accessible
     * $entity.setAccess("*", false); // Mark all fields as protected
     * ```
     *
     * @param array<string>|string myField Single or list of fields to change its accessibility
     * @param bool $set True marks the field as accessible, false will
     * mark it as protected.
     * @return this
     */
    auto setAccess(myField, bool $set) {
        if (myField == "*") {
            this._accessible = array_map(function ($p) use ($set) {
                return $set;
            }, this._accessible);
            this._accessible["*"] = $set;

            return this;
        }

        foreach ((array)myField as $prop) {
            this._accessible[$prop] = $set;
        }

        return this;
    }

    /**
     * Returns the raw accessible configuration for this entity.
     * The `*` wildcard refers to all fields.
     *
     * @return array<bool>
     */
    auto getAccessible(): array
    {
        return this._accessible;
    }

    /**
     * Checks if a field is accessible
     *
     * ### Example:
     *
     * ```
     * $entity.isAccessible("id"); // Returns whether it can be set or not
     * ```
     *
     * @param string myField Field name to check
     * @return bool
     */
         */
    bool isAccessible(string myField) {
        myValue = this._accessible[myField] ?? null;

        return (myValue == null && !empty(this._accessible["*"])) || myValue;
    }

    /**
     * Returns the alias of the repository from which this entity came from.
     */
    string getSource() {
        return this._registryAlias;
    }

    /**
     * Sets the source alias
     *
     * @param string myAlias the alias of the repository
     * @return this
     */
    auto setSource(string myAlias) {
        this._registryAlias = myAlias;

        return this;
    }

    /**
     * Returns a string representation of this object in a human readable format.
     */
    string __toString() {
        return (string)json_encode(this, JSON_PRETTY_PRINT);
    }

    /**
     * Returns an array that can be used to describe the internal state of this
     * object.
     *
     * @return array<string, mixed>
     */
    auto __debugInfo(): array
    {
        myFields = this._fields;
        foreach (this._virtual as myField) {
            myFields[myField] = this.myField;
        }

        return myFields + [
            "[new]": this.isNew(),
            "[accessible]": this._accessible,
            "[dirty]": this._dirty,
            "[original]": this._original,
            "[virtual]": this._virtual,
            "[hasErrors]": this.hasErrors(),
            "[errors]": this._errors,
            "[invalid]": this._invalid,
            "[repository]": this._registryAlias,
        ];
    }
}
