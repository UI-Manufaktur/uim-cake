

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
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
namespace Cake\Database\Expression;

use Cake\Database\IExpression;
use Cake\Database\Type\ExpressionTypeCasterTrait;
use Cake\Database\ValueBinder;
use Closure;

/**
 * An expression object that represents a SQL BETWEEN snippet
 */
class BetweenExpression : IExpression, FieldInterface
{
    use ExpressionTypeCasterTrait;
    use FieldTrait;

    /**
     * The first value in the expression
     *
     * @var mixed
     */
    protected $_from;

    /**
     * The second value in the expression
     *
     * @var mixed
     */
    protected $_to;

    /**
     * The data type for the from and to arguments
     *
     * @var mixed
     */
    protected $_type;

    /**
     * Constructor
     *
     * @param \Cake\Database\IExpression|string $field The field name to compare for values inbetween the range.
     * @param mixed $from The initial value of the range.
     * @param mixed $to The ending value in the comparison range.
     * @param string|null $type The data type name to bind the values with.
     */
    public this($field, $from, $to, $type = null)
    {
        if ($type != null) {
            $from = _castToExpression($from, $type);
            $to = _castToExpression($to, $type);
        }

        _field = $field;
        _from = $from;
        _to = $to;
        _type = $type;
    }

    /**
     * @inheritDoc
     */
    function sql(ValueBinder $binder): string
    {
        $parts = [
            'from': _from,
            'to': _to,
        ];

        /** @var \Cake\Database\IExpression|string $field */
        $field = _field;
        if ($field instanceof IExpression) {
            $field = $field.sql($binder);
        }

        foreach ($parts as $name: $part) {
            if ($part instanceof IExpression) {
                $parts[$name] = $part.sql($binder);
                continue;
            }
            $parts[$name] = _bindValue($part, $binder, _type);
        }

        return sprintf('%s BETWEEN %s AND %s', $field, $parts['from'], $parts['to']);
    }

    /**
     * @inheritDoc
     */
    public O traverse(this O)(Closure $callback)
    {
        foreach ([_field, _from, _to] as $part) {
            if ($part instanceof IExpression) {
                $callback($part);
            }
        }

        return this;
    }

    /**
     * Registers a value in the placeholder generator and returns the generated placeholder
     *
     * @param mixed $value The value to bind
     * @param \Cake\Database\ValueBinder $binder The value binder to use
     * @param string $type The type of $value
     * @return string generated placeholder
     */
    protected function _bindValue($value, $binder, $type): string
    {
        $placeholder = $binder.placeholder('c');
        $binder.bind($placeholder, $value, $type);

        return $placeholder;
    }

    /**
     * Do a deep clone of this expression.
     *
     * @return void
     */
    function __clone()
    {
        foreach (['_field', '_from', '_to'] as $part) {
            if (this.{$part} instanceof IExpression) {
                this.{$part} = clone this.{$part};
            }
        }
    }
}
