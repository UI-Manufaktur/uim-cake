module uim.cake.orm.Rule;

@safe:
import uim.cake;

/**
 * Checks that the value provided in a field exists as the primary key of another
 * table.
 */
class ExistsIn {
    // --------

    /**
     * Options for the constructor
     *
     * @var array<string, mixed>
     */
    protected _options = [];

    /**
     * Constructor.
     *
     * Available option for myOptions is "allowNullableNulls" flag.
     * Set to true to accept composite foreign keys where one or more nullable columns are null.
     *
     * @param array<string>|string myFields The field or fields to check existence as primary key.
     * @param uim.cake.orm.Table|uim.cake.orm.Association|string myRepository The repository where the
     * field will be looked for, or the association name for the repository.
     * @param array<string, mixed> myOptions The options that modify the rule"s behavior.
     *     Options "allowNullableNulls" will make the rule pass if given foreign keys are set to `null`.
     *     Notice: allowNullableNulls cannot pass by database columns set to `NOT NULL`.
     */
    this(myFields, myRepository, array myOptions = []) {
        myOptions += ["allowNullableNulls": false];
        _options = myOptions;

        _fields = (array)myFields;
        _repository = myRepository;
    }

    /**
     * Performs the existence check
     *
     * @param uim.cake.Datasource\IEntity $entity The entity from where to extract the fields
     * @param array<string, mixed> myOptions Options passed to the check,
     * where the `repository` key is required.
     * @throws \RuntimeException When the rule refers to an undefined association.
     */
    bool __invoke(IEntity $entity, array myOptions) {
        if (is_string(_repository)) {
            if (!myOptions["repository"].hasAssociation(_repository)) {
                throw new RuntimeException(sprintf(
                    "ExistsIn rule for '%s' is invalid~ '%s' is not associated with '%s'.",
                    implode(", ", _fields),
                    _repository,
                    get_class(myOptions["repository"])
                ));
            }
            myRepository = myOptions["repository"].getAssociation(_repository);
            _repository = myRepository;
        }

        myFields = _fields;
        $source = myTarget = _repository;
        if (myTarget instanceof Association) {
            $bindingKey = (array)myTarget.getBindingKey();
            $realTarget = myTarget.getTarget();
        } else {
            $bindingKey = (array)myTarget.getPrimaryKey();
            $realTarget = myTarget;
        }

        if (!empty(myOptions["_sourceTable"]) && $realTarget == myOptions["_sourceTable"]) {
            return true;
        }

        if (!empty(myOptions["repository"])) {
            $source = myOptions["repository"];
        }
        if ($source instanceof Association) {
            $source = $source.getSource();
        }

        if (!$entity.extract(_fields, true)) {
            return true;
        }

        if (_fieldsAreNull($entity, $source)) {
            return true;
        }

        if (_options["allowNullableNulls"]) {
            $schema = $source.getSchema();
            foreach (myFields as $i: myField) {
                if ($schema.getColumn(myField) && $schema.isNullable(myField) && $entity.get(myField) is null) {
                    unset($bindingKey[$i], myFields[$i]);
                }
            }
        }

        $primary = array_map(
            function (myKey) use (myTarget) {
                return myTarget.aliasField(myKey) ~ " IS";
            },
            $bindingKey
        );
        $conditions = array_combine(
            $primary,
            $entity.extract(myFields)
        );

        return myTarget.exists($conditions);
    }

    /**
     * Checks whether the given entity fields are nullable and null.
     *
     * @param uim.cake.Datasource\IEntity $entity The entity to check.
     * @param uim.cake.orm.Table $source The table to use schema from.
     */
    protected bool _fieldsAreNull(IEntity $entity, Table $source) {
        $nulls = 0;
        $schema = $source.getSchema();
        foreach (_fields as myField) {
            if ($schema.getColumn(myField) && $schema.isNullable(myField) && $entity.get(myField) is null) {
                $nulls++;
            }
        }

        return $nulls == count(_fields);
    }
}
