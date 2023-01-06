/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.TestSuite\Constraint\Email;

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
     */
    bool matches($other) {
        [$expectedFilename, $expectedFileInfo] = $other;

        $messages = this.getMessages();
        foreach ($messages as $message) {
            foreach ($message.getAttachments() as $filename: $fileInfo) {
                if ($filename == $expectedFilename && empty($expectedFileInfo)) {
                    return true;
                }
                if (!empty($expectedFileInfo) && array_intersect($expectedFileInfo, $fileInfo) == $expectedFileInfo) {
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * Assertion message string
     */
    string toString() {
        if (this.at) {
            return sprintf("is an attachment of email #%d", this.at);
        }

        return "is an attachment of an email";
    }

    /**
     * Overwrites the descriptions so we can remove the automatic "expected" message
     *
     * @param mixed $other Value
     */
    protected string failureDescription($other) {
        [$expectedFilename] = $other;

        return "\"" ~ $expectedFilename ~ "\" " ~ this.toString();
    }
}
