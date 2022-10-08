

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://book.cakephp.org/4/en/development/errors.html#error-exception-configuration
 * @since         4.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.console\Exception;

use Throwable;

/**
 * Exception raised with suggestions
 */
class MissingOptionException : ConsoleException
{
    /**
     * The requested thing that was not found.
     *
     * @var string
     */
    protected myRequested = '';

    /**
     * The valid suggestions.
     *
     * @var array<string>
     */
    protected $suggestions = [];

    /**
     * Constructor.
     *
     * @param string myMessage The string message.
     * @param string myRequested The requested value.
     * @param array<string> $suggestions The list of potential values that were valid.
     * @param int|null $code The exception code if relevant.
     * @param \Throwable|null $previous the previous exception.
     */
    this(
        string myMessage,
        string myRequested = '',
        array $suggestions = [],
        ?int $code = null,
        ?Throwable $previous = null
    ) {
        this.suggestions = $suggestions;
        this.requested = myRequested;
        super.this(myMessage, $code, $previous);
    }

    /**
     * Get the message with suggestions
     */
    string getFullMessage()
    {
        $out = this.getMessage();
        $bestGuess = this.findClosestItem(this.requested, this.suggestions);
        if ($bestGuess) {
            $out .= "\nDid you mean: `{$bestGuess}`?";
        }
        $good = [];
        foreach (this.suggestions as $option) {
            if (levenshtein($option, this.requested) < 8) {
                $good[] = '- ' . $option;
            }
        }

        if ($good) {
            $out .= "\n\nOther valid choices:\n\n" . implode("\n", $good);
        }

        return $out;
    }

    /**
     * Find the best match for requested in suggestions
     *
     * @param string $needle Unknown option name trying to be used.
     * @param array<string> $haystack Suggestions to look through.
     * @return string The best match
     */
    protected auto findClosestItem($needle, $haystack): ?string
    {
        $bestGuess = null;
        foreach ($haystack as $item) {
            if (preg_match('/^' . $needle . '/', $item)) {
                return $item;
            }
        }

        $bestScore = 4;
        foreach ($haystack as $item) {
            $score = levenshtein($needle, $item);

            if ($score < $bestScore) {
                $bestScore = $score;
                $bestGuess = $item;
            }
        }

        return $bestGuess;
    }
}
