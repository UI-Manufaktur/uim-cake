module uim.cake.https;

use Laminas\Diactoros\CallbackStream as BaseCallbackStream;

/**
 * Implementation of PSR HTTP streams.
 *
 * This differs from Laminas\Diactoros\Callback stream in that
 * it allows the use of `echo` inside the callback, and gracefully
 * handles the callback not returning a string.
 *
 * Ideally we can amend/update diactoros, but we need to figure
 * that out with the diactoros project. Until then we"ll use this shim
 * to provide backwards compatibility with existing UIM apps.
 *
 * @internal
 */
class CallbackStream : BaseCallbackStream
{
    string getContents() {
        $callback = this.detach();
        myResult = "";
        /** @psalm-suppress TypeDoesNotContainType */
        if ($callback !== null) {
            myResult = $callback();
        }
        if (!is_string(myResult)) {
            return "";
        }

        return myResult;
    }
}
