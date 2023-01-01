/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.orm.associations.loaders;

import uim.cake.orm.Query;
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
     */
    protected string junctionAssociationName;

    /**
     * The property name for the junction association, where its results should be nested at.
     */
    protected string junctionProperty;

    /**
     * The junction association instance
     *
     * @var uim.cake.orm.associations.HasMany
     */
    protected junctionAssoc;

    /**
     * Custom conditions for the junction association
     *
     * @var uim.cake.databases.IExpression|\Closure|array|string|null
     */
    protected junctionConditions;


    this(array myOptions) {
        super.this(myOptions);
        this.junctionAssociationName = myOptions["junctionAssociationName"];
        this.junctionProperty = myOptions["junctionProperty"];
        this.junctionAssoc = myOptions["junctionAssoc"];
        this.junctionConditions = myOptions["junctionConditions"];
    }

    /**
     * Auxiliary function to construct a new Query object to return all the records
     * in the target table that are associated to those specified in myOptions from
     * the source table.
     *
     * This is used for eager loading records on the target table based on conditions.
     *
     * @param array<string, mixed> myOptions options accepted by eagerLoader()
     * @return uim.cake.orm.Query
     * @throws \InvalidArgumentException When a key is required for associations but not selected.
     */
    protected auto _buildQuery(array myOptions): Query
    {
        myName = this.junctionAssociationName;
        $assoc = this.junctionAssoc;
        myQueryBuilder = false;

        if (!empty(myOptions["queryBuilder"])) {
            myQueryBuilder = myOptions["queryBuilder"];
            unset(myOptions["queryBuilder"]);
        }

        myQuery = super._buildQuery(myOptions);

        if (myQueryBuilder) {
            myQuery = myQueryBuilder(myQuery);
        }

        if (myQuery.isAutoFieldsEnabled() is null) {
            myQuery.enableAutoFields(myQuery.clause("select") == []);
        }

        // Ensure that association conditions are applied
        // and that the required keys are in the selected columns.

        $tempName = this.alias ~ "_CJoin";
        $schema = $assoc.getSchema();
        $joinFields = myTypes = [];

        foreach ($schema.typeMap() as $f: myType) {
            myKey = $tempName ~ "__" ~ $f;
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
            "aliasPath":$assoc.getAlias(),
            "includeFields":false,
            "propertyPath":this.junctionProperty,
        ]);
        myQuery.getTypeMap().addDefaults(myTypes);

        return myQuery;
    }


    protected void _assertFieldsPresent(Query $fetchQuery, array myKey) {
        // _buildQuery() manually adds in required fields from junction table
    }

    /**
     * Generates a string used as a table field that contains the values upon
     * which the filter should be applied
     *
     * @param array<string, mixed> myOptions the options to use for getting the link field.
     */
    protected string[] _linkField(array myOptions) {
        $links = [];
        myName = this.junctionAssociationName;

        foreach ((array)myOptions["foreignKey"] as myKey) {
            $links[] = sprintf("%s.%s", myName, myKey);
        }

        if (count($links) == 1) {
            return $links[0];
        }

        return $links;
    }

    /**
     * Builds an array containing the results from fetchQuery indexed by
     * the foreignKey value corresponding to this association.
     *
     * @param uim.cake.orm.Query $fetchQuery The query to get results from
     * @param array<string, mixed> myOptions The options passed to the eager loader
     * @return array<string, mixed>
     * @throws \RuntimeException when the association property is not part of the results set.
     */
    protected auto _buildResultMap(Query $fetchQuery, array myOptions): array
    {
        myResultMap = [];
        myKey = (array)myOptions["foreignKey"];

        foreach ($fetchQuery.all() as myResult) {
            if (!isset(myResult[this.junctionProperty])) {
                throw new RuntimeException(sprintf(
                    ""%s" is missing from the belongsToMany results. Results cannot be created.",
                    this.junctionProperty
                ));
            }

            myValues = [];
            foreach (myKey as $k) {
                myValues[] = myResult[this.junctionProperty][$k];
            }
            myResultMap[implode(";", myValues)][] = myResult;
        }

        return myResultMap;
    }
}
