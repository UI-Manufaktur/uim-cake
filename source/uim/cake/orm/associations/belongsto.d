module uim.cake.orm.associations.belongsto;

@safe:
import uim.cake;

/**
 * Represents an 1 - N relationship where the source side of the relation is
 * related to only one record in the target table.
 *
 * An example of a BelongsTo association would be Article belongs to Author.
 */
class BelongsTo : Association
{
    /**
     * Valid strategies for this type of association
     *
     * @var array<string>
     */
    protected _validStrategies = [
        self::STRATEGY_JOIN,
        self::STRATEGY_SELECT,
    ];

    // Gets the name of the field representing the foreign key to the target table.
    string[] getForeignKey() {
        if (_foreignKey is null) {
            _foreignKey = _modelKey(this.getTarget().getAlias());
        }

        return _foreignKey;
    }

    /**
     * Handle cascading deletes.
     *
     * BelongsTo associations are never cleared in a cascading delete scenario.
     *
     * @param uim.cake.Datasource\IEntity $entity The entity that started the cascaded delete.
     * @param array<string, mixed> myOptions The options for the original delete.
     * @return bool Success.
     */
    bool cascadeDelete(IEntity $entity, array myOptions = []) {
        return true;
    }

    /**
     * Returns default property name based on association name.
     */
    protected string _propertyName() {
        [, myName] = pluginSplit(_name);

        return Inflector::underscore(Inflector::singularize(myName));
    }

    /**
     * Returns whether the passed table is the owning side for this
     * association. This means that rows in the "target" table would miss important
     * or required information if the row in "source" did not exist.
     *
     * @param uim.cake.orm.Table $side The potential Table with ownership
     */
    bool isOwningSide(Table $side) {
        return $side == this.getTarget();
    }

    /**
     * Get the relationship type.
     */
    string type() {
        return self::MANY_TO_ONE;
    }

    /**
     * Takes an entity from the source table and looks if there is a field
     * matching the property name for this association. The found entity will be
     * saved on the target table for this association by passing supplied
     * `myOptions`
     *
     * @param uim.cake.Datasource\IEntity $entity an entity from the source table
     * @param array<string, mixed> myOptions options to be passed to the save method in the target table
     * @return uim.cake.Datasource\IEntity|false false if $entity could not be saved, otherwise it returns
     * the saved entity
     * @see uim.cake.orm.Table::save()
     */
    function saveAssociated(IEntity $entity, array myOptions = []) {
        myTargetEntity = $entity.get(this.getProperty());
        if (empty(myTargetEntity) || !(myTargetEntity instanceof IEntity)) {
            return $entity;
        }

        myTable = this.getTarget();
        myTargetEntity = myTable.save(myTargetEntity, myOptions);
        if (!myTargetEntity) {
            return false;
        }

        $properties = array_combine(
            (array)this.getForeignKey(),
            myTargetEntity.extract((array)this.getBindingKey())
        );
        $entity.set($properties, ["guard":false]);

        return $entity;
    }

    /**
     * Returns a single or multiple conditions to be appended to the generated join
     * clause for getting the results on the target table.
     *
     * @param array<string, mixed> myOptions list of options passed to attachTo method
     * @return array<uim.cake.databases.Expression\IdentifierExpression>
     * @throws \RuntimeException if the number of columns in the foreignKey do not
     * match the number of columns in the target table primaryKey
     */
    protected auto _joinCondition(array myOptions): array
    {
        $conditions = [];
        $tAlias = _name;
        $sAlias = _sourceTable.getAlias();
        $foreignKey = (array)myOptions["foreignKey"];
        $bindingKey = (array)this.getBindingKey();

        if (count($foreignKey) != count($bindingKey)) {
            if (empty($bindingKey)) {
                $msg = "The "%s" table does not define a primary key. Please set one.";
                throw new RuntimeException(sprintf($msg, this.getTarget().getTable()));
            }

            $msg = "Cannot match provided foreignKey for "%s", got "(%s)" but expected foreign key for "(%s)"";
            throw new RuntimeException(sprintf(
                $msg,
                _name,
                implode(", ", $foreignKey),
                implode(", ", $bindingKey)
            ));
        }

        foreach ($foreignKey as $k: $f) {
            myField = sprintf("%s.%s", $tAlias, $bindingKey[$k]);
            myValue = new IdentifierExpression(sprintf("%s.%s", $sAlias, $f));
            $conditions[myField] = myValue;
        }

        return $conditions;
    }


    Closure eagerLoader(array myOptions) {
        $loader = new SelectLoader([
            "alias":this.getAlias(),
            "sourceAlias":this.getSource().getAlias(),
            "targetAlias":this.getTarget().getAlias(),
            "foreignKey":this.getForeignKey(),
            "bindingKey":this.getBindingKey(),
            "strategy":this.getStrategy(),
            "associationType":this.type(),
            "finder":[this, "find"],
        ]);

        return $loader.buildEagerLoader(myOptions);
    }
}
