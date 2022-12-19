module uim.cake.orm.Rule;

@safe:
import uim.cake;

/**
 * Checks that a list of fields from an entity are unique in the table
 */
class IsUnique
{
    /**
     * The list of fields to check
     *
     * @var array<string>
     */
    protected string $_fields;

    /**
     * The unique check options
     *
     * @var array<string, mixed>
     */
    protected $_options = ;

    /**
     * Constructor.
     *
     * ### Options
     *
     * - `allowMultipleNulls` Allows any field to have multiple null values. Defaults to false.
     *
     * @param myFields The list of fields to check uniqueness for
     * @param array<string, mixed> myOptions The options for unique checks.
     */
    this(string[] myFields, array myOptions = []) {
        this._fields = myFields;
        this._options = myOptions + this._options;
    }

    /**
     * Performs the uniqueness check
     *
     * @param \Cake\Datasource\IEntity $entity The entity from where to extract the fields
     *   where the `repository` key is required.
     * @param array<string, mixed> myOptions Options passed to the check,
     * @return bool
     */
    bool __invoke(IEntity $entity, array myOptions) {
        if (!$entity.extract(this._fields, true)) {
            return true;
        }

        myFields = $entity.extract(this._fields);
        if (this._options["allowMultipleNulls"] && array_filter(myFields, "is_null")) {
            return true;
        }

        myAlias = myOptions["repository"].getAlias();
        $conditions = this._alias(myAlias, myFields);
        if ($entity.isNew() == false) {
            myKeys = (array)myOptions["repository"].getPrimaryKey();
            myKeys = this._alias(myAlias, $entity.extract(myKeys));
            if (Hash::filter(myKeys)) {
                $conditions["NOT"] = myKeys;
            }
        }

        return !myOptions["repository"].exists($conditions);
    }

    /**
     * Add a model alias to all the keys in a set of conditions.
     *
     * @param string myAlias The alias to add.
     * @param array $conditions The conditions to alias.
     * @return array
     */
    protected auto _alias(string myAlias, array $conditions): array
    {
        myAliased = [];
        foreach ($conditions as myKey: myValue) {
            myAliased["myAlias.myKey IS"] = myValue;
        }

        return myAliased;
    }
}