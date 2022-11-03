module uim.cake.orm.Rule;

import uim.cake.Datasource\IEntity;
import uim.cake.orm.Association;
import uim.cake.orm.Table;
use RuntimeException;

/**
 * Checks that the value provided in a field exists as the primary key of another
 * table.
 */
class ExistsIn
{
    /**
     * The list of fields to check
     *
     * @var array<string>
     */
    protected $_fields;

    /**
     * The repository where the field will be looked for
     *
     * @var \Cake\ORM\Table|\Cake\ORM\Association|string
     */
    protected $_repository;

    /**
     * Options for the constructor
     *
     * @var array<string, mixed>
     */
    protected $_options = [];

    /**
     * Constructor.
     *
     * Available option for myOptions is 'allowNullableNulls' flag.
     * Set to true to accept composite foreign keys where one or more nullable columns are null.
     *
     * @param array<string>|string myFields The field or fields to check existence as primary key.
     * @param \Cake\ORM\Table|\Cake\ORM\Association|string myRepository The repository where the
     * field will be looked for, or the association name for the repository.
     * @param array<string, mixed> myOptions The options that modify the rule's behavior.
     *     Options 'allowNullableNulls' will make the rule pass if given foreign keys are set to `null`.
     *     Notice: allowNullableNulls cannot pass by database columns set to `NOT NULL`.
     */
    this(myFields, myRepository, array myOptions = []) {
        myOptions += ['allowNullableNulls' => false];
        this._options = myOptions;

        this._fields = (array)myFields;
        this._repository = myRepository;
    }

    /**
     * Performs the existence check
     *
     * @param \Cake\Datasource\IEntity $entity The entity from where to extract the fields
     * @param array<string, mixed> myOptions Options passed to the check,
     * where the `repository` key is required.
     * @throws \RuntimeException When the rule refers to an undefined association.
     * @return bool
     */
    auto __invoke(IEntity $entity, array myOptions): bool
    {
        if (is_string(this._repository)) {
            if (!myOptions['repository'].hasAssociation(this._repository)) {
                throw new RuntimeException(sprintf(
                    "ExistsIn rule for '%s' is invalid. '%s' is not associated with '%s'.",
                    implode(', ', this._fields),
                    this._repository,
                    get_class(myOptions['repository'])
                ));
            }
            myRepository = myOptions['repository'].getAssociation(this._repository);
            this._repository = myRepository;
        }

        myFields = this._fields;
        $source = myTarget = this._repository;
        if (myTarget instanceof Association) {
            $bindingKey = (array)myTarget.getBindingKey();
            $realTarget = myTarget.getTarget();
        } else {
            $bindingKey = (array)myTarget.getPrimaryKey();
            $realTarget = myTarget;
        }

        if (!empty(myOptions['_sourceTable']) && $realTarget === myOptions['_sourceTable']) {
            return true;
        }

        if (!empty(myOptions['repository'])) {
            $source = myOptions['repository'];
        }
        if ($source instanceof Association) {
            $source = $source.getSource();
        }

        if (!$entity.extract(this._fields, true)) {
            return true;
        }

        if (this._fieldsAreNull($entity, $source)) {
            return true;
        }

        if (this._options['allowNullableNulls']) {
            $schema = $source.getSchema();
            foreach (myFields as $i => myField) {
                if ($schema.getColumn(myField) && $schema.isNullable(myField) && $entity.get(myField) === null) {
                    unset($bindingKey[$i], myFields[$i]);
                }
            }
        }

        $primary = array_map(
            function (myKey) use (myTarget) {
                return myTarget.aliasField(myKey) . ' IS';
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
     * @param \Cake\Datasource\IEntity $entity The entity to check.
     * @param \Cake\ORM\Table $source The table to use schema from.
     * @return bool
     */
    protected auto _fieldsAreNull(IEntity $entity, Table $source): bool
    {
        $nulls = 0;
        $schema = $source.getSchema();
        foreach (this._fields as myField) {
            if ($schema.getColumn(myField) && $schema.isNullable(myField) && $entity.get(myField) === null) {
                $nulls++;
            }
        }

        return $nulls === count(this._fields);
    }
}
