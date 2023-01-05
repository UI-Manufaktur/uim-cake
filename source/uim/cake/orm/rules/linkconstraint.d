module uim.cake.orm.Rule;

@safe:
import uim.cake;

/**
 * Checks whether links to a given association exist / do not exist.
 */
class LinkConstraint
{
  // -------------

    /**
     * Constructor.
     *
     * @param uim.cake.orm.Association|string association The alias of the association that should be checked.
     * @param string requiredLinkStatus The link status that is required to be present in order for the check to
     *  succeed.
     */
    this($association, string requiredLinkStatus) {
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
     * @param array<string, mixed> myOptions Options passed from the rules checker.
     * @return bool Whether the check was successful.
     */
    bool __invoke(IEntity $entity, array myOptions) {
        myTable = myOptions["repository"] ?? null;
        if (!(myTable instanceof Table)) {
            throw new \InvalidArgumentException(
                "Argument 2 is expected to have a `repository` key that holds an instance of `uim.cake.orm.Table`."
            );
        }

        $association = _association;
        if (!$association instanceof Association) {
            $association = myTable.getAssociation($association);
        }

        myCount = _countLinks($association, $entity);

        if (
            (
                _requiredLinkState == static::STATUS_LINKED &&
                myCount < 1
            ) ||
            (
                _requiredLinkState == static::STATUS_NOT_LINKED &&
                myCount != 0
            )
        ) {
            return false;
        }

        return true;
    }

    /**
     * Alias fields.
     *
     * @param array<string> myFields The fields that should be aliased.
     * @param uim.cake.orm.Table $source The object to use for aliasing.
     * @return The aliased fields
     */
    protected string[] _aliasFields(array myFields, Table $source) {
        foreach (myFields as myKey: myValue) {
            myFields[myKey] = $source.aliasField(myValue);
        }

        return myFields;
    }

    /**
     * Build conditions.
     *
     * @param array myFields The condition fields.
     * @param array myValues The condition values.
     * @return array A conditions array combined from the passed fields and values.
     */
    protected array _buildConditions(array myFields, array myValues) {
        if (count(myFields) != count(myValues)) {
            throw new \InvalidArgumentException(sprintf(
                "The number of fields is expected to match the number of values, got %d field(s) and %d value(s).",
                count(myFields),
                count(myValues)
            ));
        }

        return array_combine(myFields, myValues);
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

        $primaryKey = (array)$source.getPrimaryKey();
        if (!$entity.has($primaryKey)) {
            throw new \RuntimeException(sprintf(
                "LinkConstraint rule on `%s` requires all primary key values for building the counting " ~
                "conditions, expected values for `(%s)`, got `(%s)`.",
                $source.getAlias(),
                implode(", ", $primaryKey),
                implode(", ", $entity.extract($primaryKey))
            ));
        }

        myAliasedPrimaryKey = _aliasFields($primaryKey, $source);
        $conditions = _buildConditions(
            myAliasedPrimaryKey,
            $entity.extract($primaryKey)
        );

        return $source
            .find()
            .matching($association.getName())
            .where($conditions)
            .count();
    }
}
