module uim.cake.TestSuite\Stub;

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
     * @return void
     */
    auto setQuestion($question) {
        this.message .= "\nThe question asked was: " . $question;
    }
}
