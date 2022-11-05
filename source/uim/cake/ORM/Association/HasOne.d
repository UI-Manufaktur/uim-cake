module uim.baklava.orm.Association;

import uim.baklava.Datasource\IEntity;
import uim.baklava.orm.Association;
import uim.baklava.orm.Association\Loader\SelectLoader;
import uim.baklava.orm.Table;
import uim.baklava.utikities.Inflector;
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
    protected $_validStrategies = [
        self::STRATEGY_JOIN,
        self::STRATEGY_SELECT,
    ];

    /**
     * Gets the name of the field representing the foreign key to the target table.
     *
     * @return array<string>|string
     */
    auto getForeignKey() {
        if (this._foreignKey === null) {
            this._foreignKey = this._modelKey(this.getSource().getAlias());
        }

        return this._foreignKey;
    }

    /**
     * Returns default property name based on association name.
     *
     * @return string
     */
    protected auto _propertyName(): string
    {
        [, myName] = pluginSplit(this._name);

        return Inflector::underscore(Inflector::singularize(myName));
    }

    /**
     * Returns whether the passed table is the owning side for this
     * association. This means that rows in the 'target' table would miss important
     * or required information if the row in 'source' did not exist.
     *
     * @param \Cake\ORM\Table $side The potential Table with ownership
     * @return bool
     */
    function isOwningSide(Table $side): bool
    {
        return $side === this.getSource();
    }

    /**
     * Get the relationship type.
     *
     * @return string
     */
    function type(): string
    {
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
     * @see \Cake\ORM\Table::save()
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
        myTargetEntity.set($properties, ['guard' => false]);

        if (!this.getTarget().save(myTargetEntity, myOptions)) {
            myTargetEntity.unset(array_keys($properties));

            return false;
        }

        return $entity;
    }


    function eagerLoader(array myOptions): Closure
    {
        $loader = new SelectLoader([
            'alias' => this.getAlias(),
            'sourceAlias' => this.getSource().getAlias(),
            'targetAlias' => this.getTarget().getAlias(),
            'foreignKey' => this.getForeignKey(),
            'bindingKey' => this.getBindingKey(),
            'strategy' => this.getStrategy(),
            'associationType' => this.type(),
            'finder' => [this, 'find'],
        ]);

        return $loader.buildEagerLoader(myOptions);
    }


    function cascadeDelete(IEntity $entity, array myOptions = []): bool
    {
        $helper = new DependentDeleteHelper();

        return $helper.cascadeDelete(this, $entity, myOptions);
    }
}
