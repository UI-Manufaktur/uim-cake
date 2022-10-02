

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.4.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.ORM\Association\Loader;

import uim.cake.ORM\Query;
use RuntimeException;

/**
 * : the logic for loading an association using a SELECT query and a pivot table
 *
 * @internal
 */
class SelectWithPivotLoader : SelectLoader
{
    /**
     * The name of the junction association
     *
     * @var string
     */
    protected $junctionAssociationName;

    /**
     * The property name for the junction association, where its results should be nested at.
     *
     * @var string
     */
    protected $junctionProperty;

    /**
     * The junction association instance
     *
     * @var \Cake\ORM\Association\HasMany
     */
    protected $junctionAssoc;

    /**
     * Custom conditions for the junction association
     *
     * @var \Cake\Database\IExpression|\Closure|array|string|null
     */
    protected $junctionConditions;

    /**
     * @inheritDoc
     */
    this(array myOptions)
    {
        super.this(myOptions);
        this.junctionAssociationName = myOptions['junctionAssociationName'];
        this.junctionProperty = myOptions['junctionProperty'];
        this.junctionAssoc = myOptions['junctionAssoc'];
        this.junctionConditions = myOptions['junctionConditions'];
    }

    /**
     * Auxiliary function to construct a new Query object to return all the records
     * in the target table that are associated to those specified in myOptions from
     * the source table.
     *
     * This is used for eager loading records on the target table based on conditions.
     *
     * @param array<string, mixed> myOptions options accepted by eagerLoader()
     * @return \Cake\ORM\Query
     * @throws \InvalidArgumentException When a key is required for associations but not selected.
     */
    protected auto _buildQuery(array myOptions): Query
    {
        myName = this.junctionAssociationName;
        $assoc = this.junctionAssoc;
        myQueryBuilder = false;

        if (!empty(myOptions['queryBuilder'])) {
            myQueryBuilder = myOptions['queryBuilder'];
            unset(myOptions['queryBuilder']);
        }

        myQuery = super._buildQuery(myOptions);

        if (myQueryBuilder) {
            myQuery = myQueryBuilder(myQuery);
        }

        if (myQuery.isAutoFieldsEnabled() === null) {
            myQuery.enableAutoFields(myQuery.clause('select') === []);
        }

        // Ensure that association conditions are applied
        // and that the required keys are in the selected columns.

        $tempName = this.alias . '_CJoin';
        $schema = $assoc.getSchema();
        $joinFields = myTypes = [];

        foreach ($schema.typeMap() as $f => myType) {
            myKey = $tempName . '__' . $f;
            $joinFields[myKey] = "myName.$f";
            myTypes[myKey] = myType;
        }

        myQuery
            .where(this.junctionConditions)
            .select($joinFields);

        myQuery
            .getEagerLoader()
            .addToJoinsMap($tempName, $assoc, false, this.junctionProperty);

        $assoc.attachTo(myQuery, [
            'aliasPath' => $assoc.getAlias(),
            'includeFields' => false,
            'propertyPath' => this.junctionProperty,
        ]);
        myQuery.getTypeMap().addDefaults(myTypes);

        return myQuery;
    }

    /**
     * @inheritDoc
     */
    protected auto _assertFieldsPresent(Query $fetchQuery, array myKey): void
    {
        // _buildQuery() manually adds in required fields from junction table
    }

    /**
     * Generates a string used as a table field that contains the values upon
     * which the filter should be applied
     *
     * @param array<string, mixed> myOptions the options to use for getting the link field.
     * @return array<string>|string
     */
    protected auto _linkField(array myOptions)
    {
        $links = [];
        myName = this.junctionAssociationName;

        foreach ((array)myOptions['foreignKey'] as myKey) {
            $links[] = sprintf('%s.%s', myName, myKey);
        }

        if (count($links) === 1) {
            return $links[0];
        }

        return $links;
    }

    /**
     * Builds an array containing the results from fetchQuery indexed by
     * the foreignKey value corresponding to this association.
     *
     * @param \Cake\ORM\Query $fetchQuery The query to get results from
     * @param array<string, mixed> myOptions The options passed to the eager loader
     * @return array<string, mixed>
     * @throws \RuntimeException when the association property is not part of the results set.
     */
    protected auto _buildResultMap(Query $fetchQuery, array myOptions): array
    {
        myResultMap = [];
        myKey = (array)myOptions['foreignKey'];

        foreach ($fetchQuery.all() as myResult) {
            if (!isset(myResult[this.junctionProperty])) {
                throw new RuntimeException(sprintf(
                    '"%s" is missing from the belongsToMany results. Results cannot be created.',
                    this.junctionProperty
                ));
            }

            myValues = [];
            foreach (myKey as $k) {
                myValues[] = myResult[this.junctionProperty][$k];
            }
            myResultMap[implode(';', myValues)][] = myResult;
        }

        return myResultMap;
    }
}
