

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://UIM.org UIM(tm) Project
 * @since         3.0.7
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.datasources;

use ArrayObject;
import uim.cakeents\IEventDispatcher;

/**
 * A trait that allows a class to build and apply application.
 * rules.
 *
 * If the implementing class also : EventAwareTrait, then
 * events will be emitted when rules are checked.
 *
 * The implementing class is expected to define the `RULES_CLASS` constant
 * if they need to customize which class is used for rules objects.
 */
trait RulesAwareTrait
{
    /**
     * The domain rules to be applied to entities saved by this table
     *
     * @var \Cake\Datasource\RulesChecker
     */
    protected $_rulesChecker;

    /**
     * Returns whether the passed entity complies with all the rules stored in
     * the rules checker.
     *
     * @param \Cake\Datasource\IEntity $entity The entity to check for validity.
     * @param string $operation The operation being run. Either "create", "update" or "delete".
     * @param \ArrayObject|array|null myOptions The options To be passed to the rules.
     * @return bool
     */
    bool checkRules(IEntity $entity, string $operation = RulesChecker::CREATE, myOptions = null) {
        $rules = this.rulesChecker();
        myOptions = myOptions ?: new ArrayObject();
        myOptions = is_array(myOptions) ? new ArrayObject(myOptions) : myOptions;
        $hasEvents = (this instanceof IEventDispatcher);

        if ($hasEvents) {
            myEvent = this.dispatchEvent(
                "Model.beforeRules",
                compact("entity", "options", "operation")
            );
            if (myEvent.isStopped()) {
                return myEvent.getResult();
            }
        }

        myResult = $rules.check($entity, $operation, myOptions.getArrayCopy());

        if ($hasEvents) {
            myEvent = this.dispatchEvent(
                "Model.afterRules",
                compact("entity", "options", "result", "operation")
            );

            if (myEvent.isStopped()) {
                return myEvent.getResult();
            }
        }

        return myResult;
    }

    /**
     * Returns the RulesChecker for this instance.
     *
     * A RulesChecker object is used to test an entity for validity
     * on rules that may involve complex logic or data that
     * needs to be fetched from relevant datasources.
     *
     * @see \Cake\Datasource\RulesChecker
     * @return \Cake\Datasource\RulesChecker
     */
    function rulesChecker(): RulesChecker
    {
        if (this._rulesChecker !== null) {
            return this._rulesChecker;
        }
        /** @psalm-var class-string<\Cake\Datasource\RulesChecker> myClass */
        myClass = defined("static::RULES_CLASS") ? static::RULES_CLASS : RulesChecker::class;
        /** @psalm-suppress ArgumentTypeCoercion */
        this._rulesChecker = this.buildRules(new myClass(["repository" => this]));
        this.dispatchEvent("Model.buildRules", ["rules" => this._rulesChecker]);

        return this._rulesChecker;
    }

    /**
     * Returns a RulesChecker object after modifying the one that was supplied.
     *
     * Subclasses should override this method in order to initialize the rules to be applied to
     * entities saved by this instance.
     *
     * @param \Cake\Datasource\RulesChecker $rules The rules object to be modified.
     * @return \Cake\Datasource\RulesChecker
     */
    function buildRules(RulesChecker $rules): RulesChecker
    {
        return $rules;
    }
}
