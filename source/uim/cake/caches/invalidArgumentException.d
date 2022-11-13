module uim.cake.caches;

import uim.cakere.exceptions\CakeException;
use Psr\SimpleCache\InvalidArgumentException as InvalidArgumentInterface;

// Exception raised when cache keys are invalid.
class InvalidArgumentException : CakeException : InvalidArgumentInterface
{
}
