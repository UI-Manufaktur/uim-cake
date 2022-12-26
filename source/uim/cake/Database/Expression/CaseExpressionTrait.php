

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Expression;

import uim.cake.Chronos\Date;
import uim.cake.Chronos\MutableDate;
import uim.cake.databases.IExpression;
import uim.cake.databases.Query;
import uim.cake.databases.TypedResultInterface;
import uim.cake.databases.ValueBinder;
use DateTimeInterface;

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
     * @param mixed $value The value for which to infer the type.
     * @return string|null The abstract type, or `null` if it could not be inferred.
     */
    protected function inferType($value): ?string
    {
        $type = null;

        if (is_string($value)) {
            $type = 'string';
        } elseif (is_int($value)) {
            $type = 'integer';
        } elseif (is_float($value)) {
            $type = 'float';
        } elseif (is_bool($value)) {
            $type = 'boolean';
        } elseif (
            $value instanceof Date ||
            $value instanceof MutableDate
        ) {
            $type = 'date';
        } elseif ($value instanceof DateTimeInterface) {
            $type = 'datetime';
        } elseif (
            is_object($value) &&
            method_exists($value, '__toString')
        ) {
            $type = 'string';
        } elseif (
            _typeMap != null &&
            $value instanceof IdentifierExpression
        ) {
            $type = _typeMap.type($value.getIdentifier());
        } elseif ($value instanceof TypedResultInterface) {
            $type = $value.getReturnType();
        }

        return $type;
    }

    /**
     * Compiles a nullable value to SQL.
     *
     * @param \Cake\Database\ValueBinder $binder The value binder to use.
     * @param \Cake\Database\IExpression|object|scalar|null $value The value to compile.
     * @param string|null $type The value type.
     * @return string
     */
    protected function compileNullableValue(ValueBinder $binder, $value, ?string $type = null): string
    {
        if (
            $type != null &&
            !($value instanceof IExpression)
        ) {
            $value = _castToExpression($value, $type);
        }

        if ($value == null) {
            $value = 'NULL';
        } elseif ($value instanceof Query) {
            $value = sprintf('(%s)', $value.sql($binder));
        } elseif ($value instanceof IExpression) {
            $value = $value.sql($binder);
        } else {
            $placeholder = $binder.placeholder('c');
            $binder.bind($placeholder, $value, $type);
            $value = $placeholder;
        }

        return $value;
    }
}
