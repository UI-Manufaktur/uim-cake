module uim.cake.orm.associations;

import uim.cake.datasources\IEntity;
import uim.cake.orm.associations;
import uim.cake.orm.associations.loaders\SelectLoader;
import uim.cake.orm.Table;
import uim.cake.utilities.Inflector;
use Closure;

/**
 * Represents an 1 - 1 relationship where the source side of the relation is
 * related to only one record in the target table and vice versa.
 *
 * An example of a HasOne association would be User has one Profile.
 */
class HasOne : Association
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
            _foreignKey = _modelKey(this.getSource().getAlias());
        }

        return _foreignKey;
    }

    /**
     * Returns default property name based on association name.
     *
     * @return string
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
     * @param \Cake\ORM\Table $side The potential Table with ownership
     */
    bool isOwningSide(Table $side) {
        return $side == this.getSource();
    }

    /**
     * Get the relationship type.
     */
    string type() {
        return self::ONE_TO_ONE;
    }

    /**
     * Takes an entity from the source table and looks if there is a field
     * matching the property name for this association. The found entity will be
     * saved on the target table for this association by passing supplied
     * `myOptions`
     *
     * @param \Cake\Datasource\IEntity $entity an entity from the source table
     * @param array<string, mixed> myOptions options to be passed to the save method in the target table
     * @return \Cake\Datasource\IEntity|false false if $entity could not be saved, otherwise it returns
     * the saved entity
     * @see uim.cake.ORM\Table::save()
     */
    function saveAssociated(IEntity $entity, array myOptions = []) {
        myTargetEntity = $entity.get(this.getProperty());
        if (empty(myTargetEntity) || !(myTargetEntity instanceof IEntity)) {
            return $entity;
        }

        $properties = array_combine(
            (array)this.getForeignKey(),
            $entity.extract((array)this.getBindingKey())
        );
        myTargetEntity.set($properties, ["guard":false]);

        if (!this.getTarget().save(myTargetEntity, myOptions)) {
            myTargetEntity.unset(array_keys($properties));

            return false;
        }

        return $entity;
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


    bool cascadeDelete(IEntity $entity, array myOptions = []) {
        $helper = new DependentDeleteHelper();

        return $helper.cascadeDelete(this, $entity, myOptions);
    }
}
