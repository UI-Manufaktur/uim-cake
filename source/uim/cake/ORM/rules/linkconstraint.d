module uim.cake.orm.Rule;

import uim.cake.datasources.IEntity;
import uim.cake.orm.Association;
import uim.cake.orm.Table;

/**
 * Checks whether links to a given association exist / do not exist.
 */
class LinkConstraint
{
    /**
     * Status that requires a link to be present.
     */
    const string STATUS_LINKED = "linked";

    /**
     * Status that requires a link to not be present.
     */
    const string STATUS_NOT_LINKED = "notLinked";

    /**
     * The association that should be checked.
     *
     * @var uim.cake.orm.Association|string
     */
    protected _association;

    /**
     * The link status that is required to be present in order for the check to succeed.
     */
    protected string _requiredLinkState;

    /**
     * Constructor.
     *
     * @param uim.cake.orm.Association|string $association The alias of the association that should be checked.
     * @param string $requiredLinkStatus The link status that is required to be present in order for the check to
     *  succeed.
     */
    this($association, string $requiredLinkStatus) {
        if (
            !is_string($association) &&
            !($association instanceof Association)
        ) {
            throw new \InvalidArgumentException(sprintf(
                "Argument 1 is expected to be of type `uim.cake.orm.Association|string`, `%s` given.",
                getTypeName($association)
            ));
        }

        if (!in_array($requiredLinkStatus, [static::STATUS_LINKED, static::STATUS_NOT_LINKED], true)) {
            throw new \InvalidArgumentException(
                "Argument 2 is expected to match one of the `uim.cake.orm.rules.LinkConstraint::STATUS_*` constants."
            );
        }

        _association = $association;
        _requiredLinkState = $requiredLinkStatus;
    }

    /**
     * Callable handler.
     *
     * Performs the actual link check.
     *
     * @param uim.cake.Datasource\IEntity $entity The entity involved in the operation.
     * @param array<string, mixed> $options Options passed from the rules checker.
     * @return bool Whether the check was successful.
     */
    bool __invoke(IEntity $entity, array $options) {
        $table = $options["repository"] ?? null;
        if (!($table instanceof Table)) {
            throw new \InvalidArgumentException(
                "Argument 2 is expected to have a `repository` key that holds an instance of `uim.cake.orm.Table`."
            );
        }

        $association = _association;
        if (!$association instanceof Association) {
            $association = $table.getAssociation($association);
        }

        $count = _countLinks($association, $entity);

        if (
            (
                _requiredLinkState == static::STATUS_LINKED &&
                $count < 1
            ) ||
            (
                _requiredLinkState == static::STATUS_NOT_LINKED &&
                $count != 0
            )
        ) {
            return false;
        }

        return true;
    }

    /**
     * Alias fields.
     *
     * @param array<string> $fields The fields that should be aliased.
     * @param uim.cake.orm.Table $source The object to use for aliasing.
     * @return array<string> The aliased fields
     */
    protected string[] _aliasFields(array $fields, Table $source) {
        foreach ($fields as $key: $value) {
            $fields[$key] = $source.aliasField($value);
        }

        return $fields;
    }

    /**
     * Build conditions.
     *
     * @param array $fields The condition fields.
     * @param array $values The condition values.
     * @return array A conditions array combined from the passed fields and values.
     */
    protected array _buildConditions(array $fields, array $values) {
        if (count($fields) != count($values)) {
            throw new \InvalidArgumentException(sprintf(
                "The number of fields is expected to match the number of values, got %d field(s) and %d value(s).",
                count($fields),
                count($values)
            ));
        }

        return array_combine($fields, $values);
    }

    /**
     * Count links.
     *
     * @param uim.cake.orm.Association $association The association for which to count links.
     * @param uim.cake.Datasource\IEntity $entity The entity involved in the operation.
     * @return int The number of links.
     */
    protected int _countLinks(Association $association, IEntity $entity) {
        $source = $association.getSource();

        $primaryKey = (array)$source.getPrimaryKeys();
        if (!$entity.has($primaryKey)) {
            throw new \RuntimeException(sprintf(
                "LinkConstraint rule on `%s` requires all primary key values for building the counting " ~
                "conditions, expected values for `(%s)`, got `(%s)`.",
                $source.getAlias(),
                implode(", ", $primaryKey),
                implode(", ", $entity.extract($primaryKey))
            ));
        }

        $aliasedPrimaryKey = _aliasFields($primaryKey, $source);
        $conditions = _buildConditions(
            $aliasedPrimaryKey,
            $entity.extract($primaryKey)
        );

        return $source
            .find()
            .matching($association.getName())
            .where($conditions)
            .count();
    }
}
