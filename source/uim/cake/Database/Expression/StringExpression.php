module uim.cake.database.Expression;

import uim.cake.database.IExpression;
import uim.cake.database.ValueBinder;
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
    this(string $string, string $collation)
    {
        this.string = $string;
        this.collation = $collation;
    }

    /**
     * Sets the string collation.
     *
     * @param string $collation String collation
     * @return void
     */
    auto setCollation(string $collation): void
    {
        this.collation = $collation;
    }

    /**
     * Returns the string collation.
     *
     * @return string
     */
    auto getCollation(): string
    {
        return this.collation;
    }

    /**
     * @inheritDoc
     */
    function sql(ValueBinder $binder): string
    {
        $placeholder = $binder.placeholder('c');
        $binder.bind($placeholder, this.string, 'string');

        return $placeholder . ' COLLATE ' . this.collation;
    }

    /**
     * @inheritDoc
     */
    function traverse(Closure $callback)
    {
        return this;
    }
}
