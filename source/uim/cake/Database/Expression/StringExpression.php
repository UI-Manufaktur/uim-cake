


 *


 * @since         4.2.0
  */
module uim.cake.databases.Expression;

import uim.cake.databases.IExpression;
import uim.cake.databases.ValueBinder;
use Closure;

/**
 * String expression with collation.
 */
class StringExpression : IExpression
{
    /**
     * @var string
     */
    protected $string;

    /**
     * @var string
     */
    protected $collation;

    /**
     * @param string $string String value
     * @param string $collation String collation
     */
    this(string $string, string $collation) {
        this.string = $string;
        this.collation = $collation;
    }

    /**
     * Sets the string collation.
     *
     * @param string $collation String collation
     */
    void setCollation(string $collation): void
    {
        this.collation = $collation;
    }

    /**
     * Returns the string collation.
     */
    string getCollation(): string
    {
        return this.collation;
    }


    function sql(ValueBinder $binder): string
    {
        $placeholder = $binder.placeholder("c");
        $binder.bind($placeholder, this.string, "string");

        return $placeholder . " COLLATE " . this.collation;
    }


    O traverse(this O)(Closure $callback) {
        return this;
    }
}
