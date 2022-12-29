


 *


 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.orm.Association;

import uim.cake.datasources.EntityInterface;
import uim.cake.orm.Association;
import uim.cake.orm.Association\Loader\SelectLoader;
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
    protected $_validStrategies = [
        self::STRATEGY_JOIN,
        self::STRATEGY_SELECT,
    ];

    /**
     * Gets the name of the field representing the foreign key to the target table.
     *
     * @return array<string>|string
     */
    function getForeignKey() {
        if (_foreignKey == null) {
            _foreignKey = _modelKey(this.getSource().getAlias());
        }

        return _foreignKey;
    }

    /**
     * Returns default property name based on association name.
     *
     * @return string
     */
    protected function _propertyName(): string
    {
        [, $name] = pluginSplit(_name);

        return Inflector::underscore(Inflector::singularize($name));
    }

    /**
     * Returns whether the passed table is the owning side for this
     * association. This means that rows in the "target" table would miss important
     * or required information if the row in "source" did not exist.
     *
     * @param \Cake\ORM\Table $side The potential Table with ownership
     * @return bool
     */
    function isOwningSide(Table $side): bool
    {
        return $side == this.getSource();
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
     * `$options`
     *
     * @param \Cake\Datasource\EntityInterface $entity an entity from the source table
     * @param array<string, mixed> $options options to be passed to the save method in the target table
     * @return \Cake\Datasource\EntityInterface|false false if $entity could not be saved, otherwise it returns
     * the saved entity
     * @see uim.cake.ORM\Table::save()
     */
    function saveAssociated(EntityInterface $entity, array $options = []) {
        $targetEntity = $entity.get(this.getProperty());
        if (empty($targetEntity) || !($targetEntity instanceof EntityInterface)) {
            return $entity;
        }

        $properties = array_combine(
            (array)this.getForeignKey(),
            $entity.extract((array)this.getBindingKey())
        );
        $targetEntity.set($properties, ["guard": false]);

        if (!this.getTarget().save($targetEntity, $options)) {
            $targetEntity.unset(array_keys($properties));

            return false;
        }

        return $entity;
    }


    function eagerLoader(array $options): Closure
    {
        $loader = new SelectLoader([
            "alias": this.getAlias(),
            "sourceAlias": this.getSource().getAlias(),
            "targetAlias": this.getTarget().getAlias(),
            "foreignKey": this.getForeignKey(),
            "bindingKey": this.getBindingKey(),
            "strategy": this.getStrategy(),
            "associationType": this.type(),
            "finder": [this, "find"],
        ]);

        return $loader.buildEagerLoader($options);
    }


    function cascadeDelete(EntityInterface $entity, array $options = []): bool
    {
        $helper = new DependentDeleteHelper();

        return $helper.cascadeDelete(this, $entity, $options);
    }
}
