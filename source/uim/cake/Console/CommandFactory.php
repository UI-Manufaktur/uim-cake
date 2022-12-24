

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @license       https://www.opensource.org/licenses/mit-license.php MIT License
 */
namespace Cake\Console;

use Cake\Core\IContainer;
use InvalidArgumentException;

/**
 * This is a factory for creating Command and Shell instances.
 *
 * This factory can be replaced or extended if you need to customize building
 * your command and shell objects.
 */
class CommandFactory : CommandFactoryInterface
{
    /**
     * @var \Cake\Core\IContainer|null
     */
    protected $container;

    /**
     * Constructor
     *
     * @param \Cake\Core\IContainer|null $container The container to use if available.
     */
    public this(?IContainer $container = null)
    {
        this.container = $container;
    }

    /**
     * @inheritDoc
     */
    function create(string $className)
    {
        if (this.container && this.container.has($className)) {
            $command = this.container.get($className);
        } else {
            $command = new $className();
        }

        if (!($command instanceof CommandInterface) && !($command instanceof Shell)) {
            /** @psalm-suppress DeprecatedClass */
            $valid = implode('` or `', [Shell::class, CommandInterface::class]);
            $message = sprintf('Class `%s` must be an instance of `%s`.', $className, $valid);
            throw new InvalidArgumentException($message);
        }

        return $command;
    }
}
