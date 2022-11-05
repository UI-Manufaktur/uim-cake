module uim.baklava.TestSuite\Constraint\Email;

/**
 * MailContainsAttachment
 *
 * @internal
 */
class MailContainsAttachment : MailContains
{
    /**
     * Checks constraint
     *
     * @param mixed $other Constraint check
     * @return bool
     */
    function matches($other): bool
    {
        [$expectedFilename, $expectedFileInfo] = $other;

        myMessages = this.getMessages();
        foreach (myMessages as myMessage) {
            foreach (myMessage.getAttachments() as myfilename => myfileInfo) {
                if (myfilename === $expectedFilename && empty($expectedFileInfo)) {
                    return true;
                }
                if (!empty($expectedFileInfo) && array_intersect($expectedFileInfo, myfileInfo) === $expectedFileInfo) {
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * Assertion message string
     *
     * @return string
     */
    function toString(): string
    {
        if (this.at) {
            return sprintf('is an attachment of email #%d', this.at);
        }

        return 'is an attachment of an email';
    }

    /**
     * Overwrites the descriptions so we can remove the automatic "expected" message
     *
     * @param mixed $other Value
     * @return string
     */
    protected auto failureDescription($other): string
    {
        [$expectedFilename] = $other;

        return '\'' . $expectedFilename . '\' ' . this.toString();
    }
}
