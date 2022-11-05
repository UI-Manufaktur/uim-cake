

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.databases.expressions;

import uim.baklava.chronos\Date;
import uim.baklava.chronos\MutableDate;
import uim.baklava.databases.IExpression;
import uim.baklava.databases.Query;
import uim.baklava.databases.ValueBinder;
use IDateTime;

/**
 * Trait that holds shared functionality for case related expressions.
 *
 * @property \Cake\Database\TypeMap $_typeMap The type map to use when using an array of conditions for the `WHEN`
 *  value.
 * @internal
 */
trait CaseExpressionTrait
{
    /**
     * Infers the abstract type for the given value.
     *
     * @param mixed myValue The value for which to infer the type.
     * @return string|null The abstract type, or `null` if it could not be inferred.
     */
    protected auto inferType(myValue): ?string
    {
        myType = null;

        if (is_string(myValue)) {
            myType = 'string';
        } elseif (is_int(myValue)) {
            myType = 'integer';
        } elseif (is_float(myValue)) {
            myType = 'float';
        } elseif (is_bool(myValue)) {
            myType = 'boolean';
        } elseif (
            myValue instanceof Date ||
            myValue instanceof MutableDate
        ) {
            myType = 'date';
        } elseif (myValue instanceof IDateTime) {
            myType = 'datetime';
        } elseif (
            is_object(myValue) &&
            method_exists(myValue, '__toString')
        ) {
            myType = 'string';
        } elseif (
            this._typeMap !== null &&
            myValue instanceof IdentifierExpression
        ) {
            myType = this._typeMap.type(myValue.getIdentifier());
        }

        return myType;
    }

    /**
     * Compiles a nullable value to SQL.
     *
     * @param \Cake\Database\ValueBinder $binder The value binder to use.
     * @param \Cake\Database\IExpression|object|scalar|null myValue The value to compile.
     * @param string|null myType The value type.
     * @return string
     */
    protected auto compileNullableValue(ValueBinder $binder, myValue, ?string myType = null): string
    {
        if (
            myType !== null &&
            !(myValue instanceof IExpression)
        ) {
            myValue = this._castToExpression(myValue, myType);
        }

        if (myValue === null) {
            myValue = 'NULL';
        } elseif (myValue instanceof Query) {
            myValue = sprintf('(%s)', myValue.sql($binder));
        } elseif (myValue instanceof IExpression) {
            myValue = myValue.sql($binder);
        } else {
            $placeholder = $binder.placeholder('c');
            $binder.bind($placeholder, myValue, myType);
            myValue = $placeholder;
        }

        return myValue;
    }
}
