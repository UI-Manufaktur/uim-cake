


 *



  */
module uim.cake.orm.Rule;

import uim.cake.datasources.EntityInterface;
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
     * @var uim.cake.ORM\Table|\Cake\ORM\Association|string
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
     * Available option for $options is "allowNullableNulls" flag.
     * Set to true to accept composite foreign keys where one or more nullable columns are null.
     *
     * @param array<string>|string $fields The field or fields to check existence as primary key.
     * @param uim.cake.ORM\Table|\Cake\ORM\Association|string $repository The repository where the
     * field will be looked for, or the association name for the repository.
     * @param array<string, mixed> $options The options that modify the rule"s behavior.
     *     Options "allowNullableNulls" will make the rule pass if given foreign keys are set to `null`.
     *     Notice: allowNullableNulls cannot pass by database columns set to `NOT NULL`.
     */
    public this($fields, $repository, array $options = []) {
        $options += ["allowNullableNulls": false];
        _options = $options;

        _fields = (array)$fields;
        _repository = $repository;
    }

    /**
     * Performs the existence check
     *
     * @param uim.cake.Datasource\EntityInterface $entity The entity from where to extract the fields
     * @param array<string, mixed> $options Options passed to the check,
     * where the `repository` key is required.
     * @throws \RuntimeException When the rule refers to an undefined association.
     * @return bool
     */
    function __invoke(EntityInterface $entity, array $options): bool
    {
        if (is_string(_repository)) {
            if (!$options["repository"].hasAssociation(_repository)) {
                throw new RuntimeException(sprintf(
                    "ExistsIn rule for "%s" is invalid. "%s" is not associated with "%s".",
                    implode(", ", _fields),
                    _repository,
                    get_class($options["repository"])
                ));
            }
            $repository = $options["repository"].getAssociation(_repository);
            _repository = $repository;
        }

        $fields = _fields;
        $source = $target = _repository;
        if ($target instanceof Association) {
            $bindingKey = (array)$target.getBindingKey();
            $realTarget = $target.getTarget();
        } else {
            $bindingKey = (array)$target.getPrimaryKey();
            $realTarget = $target;
        }

        if (!empty($options["_sourceTable"]) && $realTarget == $options["_sourceTable"]) {
            return true;
        }

        if (!empty($options["repository"])) {
            $source = $options["repository"];
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
            foreach ($fields as $i: $field) {
                if ($schema.getColumn($field) && $schema.isNullable($field) && $entity.get($field) == null) {
                    unset($bindingKey[$i], $fields[$i]);
                }
            }
        }

        $primary = array_map(
            function ($key) use ($target) {
                return $target.aliasField($key) . " IS";
            },
            $bindingKey
        );
        $conditions = array_combine(
            $primary,
            $entity.extract($fields)
        );

        return $target.exists($conditions);
    }

    /**
     * Checks whether the given entity fields are nullable and null.
     *
     * @param uim.cake.Datasource\EntityInterface $entity The entity to check.
     * @param uim.cake.ORM\Table $source The table to use schema from.
     * @return bool
     */
    protected function _fieldsAreNull(EntityInterface $entity, Table $source): bool
    {
        $nulls = 0;
        $schema = $source.getSchema();
        foreach (_fields as $field) {
            if ($schema.getColumn($field) && $schema.isNullable($field) && $entity.get($field) == null) {
                $nulls++;
            }
        }

        return $nulls == count(_fields);
    }
}
