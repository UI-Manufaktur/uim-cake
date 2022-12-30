module uim.cake.consoles.TestSuite;

use RuntimeException;

/**
 * Exception class used to indicate missing console input.
 */
class MissingConsoleInputException : RuntimeException
{
    /**
     * Update the exception message with the question text
     *
     * @param string $question The question text.
     */
    void setQuestion($question) {
        this.message .= "\nThe question asked was: " . $question;
    }
}

// phpcs:disable
class_alias(MissingConsoleInputException::class, "Cake\TestSuite\Stub\MissingConsoleInputException");
// phpcs:enable
