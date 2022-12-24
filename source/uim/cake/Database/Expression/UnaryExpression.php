

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
use Cake\Database\ValueBinder;
use Closure;

/**
 * An expression object that represents an expression with only a single operand.
 */
class UnaryExpression : IExpression
{
    /**
     * Indicates that the operation is in pre-order
     *
     * @var int
     */
    public const PREFIX = 0;

    /**
     * Indicates that the operation is in post-order
     *
     * @var int
     */
    public const POSTFIX = 1;

    /**
     * The operator this unary expression represents
     *
     * @var string
     */
    protected $_operator;

    /**
     * Holds the value which the unary expression operates
     *
     * @var mixed
     */
    protected $_value;

    /**
     * Where to place the operator
     *
     * @var int
     */
    protected $position;

    /**
     * Constructor
     *
     * @param string $operator The operator to used for the expression
     * @param mixed $value the value to use as the operand for the expression
     * @param int $position either UnaryExpression::PREFIX or UnaryExpression::POSTFIX
     */
    public this(string $operator, $value, $position = self::PREFIX)
    {
        _operator = $operator;
        _value = $value;
        this.position = $position;
    }

    /**
     * @inheritDoc
     */
    function sql(ValueBinder $binder): string
    {
        $operand = _value;
        if ($operand instanceof IExpression) {
            $operand = $operand.sql($binder);
        }

        if (this.position == self::POSTFIX) {
            return '(' . $operand . ') ' . _operator;
        }

        return _operator . ' (' . $operand . ')';
    }

    /**
     * @inheritDoc
     */
    public O traverse(this O)(Closure $callback)
    {
        if (_value instanceof IExpression) {
            $callback(_value);
            _value.traverse($callback);
        }

        return this;
    }

    /**
     * Perform a deep clone of the inner expression.
     *
     * @return void
     */
    function __clone()
    {
        if (_value instanceof IExpression) {
            _value = clone _value;
        }
    }
}
