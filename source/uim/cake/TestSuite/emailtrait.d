module uim.cake.TestSuite;

import uim.cake.TestSuite\Constraint\Email\MailContains;
import uim.cake.TestSuite\Constraint\Email\MailContainsAttachment;
import uim.cake.TestSuite\Constraint\Email\MailContainsHtml;
import uim.cake.TestSuite\Constraint\Email\MailContainsText;
import uim.cake.TestSuite\Constraint\Email\MailCount;
import uim.cake.TestSuite\Constraint\Email\MailSentFrom;
import uim.cake.TestSuite\Constraint\Email\MailSentTo;
import uim.cake.TestSuite\Constraint\Email\MailSentWith;
import uim.cake.TestSuite\Constraint\Email\MailSubjectContains;
import uim.cake.TestSuite\Constraint\Email\NoMailSent;

/**
 * Make assertions on emails sent through the Cake\TestSuite\TestEmailTransport
 *
 * After adding the trait to your test case, all mail transports will be replaced
 * with TestEmailTransport which is used for making assertions and will *not* actually
 * send emails.
 */
trait EmailTrait
{
    /**
     * Replaces all transports with the test transport during test setup
     *
     * @before
     */
    void setupTransports() {
        TestEmailTransport::replaceAllTransports();
    }

    /**
     * Resets transport state
     *
     * @after
     */
    void cleanupEmailTrait() {
        TestEmailTransport::clearMessages();
    }

    /**
     * Asserts an expected number of emails were sent
     *
     * @param int $count Email count
     * @param string $message Message
     */
    void assertMailCount(int $count, string $message = "") {
        this.assertThat($count, new MailCount(), $message);
    }

    /**
     * Asserts that no emails were sent
     *
     * @param string $message Message
     */
    void assertNoMailSent(string $message = "") {
        this.assertThat(null, new NoMailSent(), $message);
    }

    /**
     * Asserts an email at a specific index was sent to an address
     *
     * @param int $at Email index
     * @param string $address Email address
     * @param string $message Message
     */
    void assertMailSentToAt(int $at, string $address, string $message = "") {
        this.assertThat($address, new MailSentTo($at), $message);
    }

    /**
     * Asserts an email at a specific index was sent from an address
     *
     * @param int $at Email index
     * @param string $address Email address
     * @param string $message Message
     */
    void assertMailSentFromAt(int $at, string $address, string $message = "") {
        this.assertThat($address, new MailSentFrom($at), $message);
    }

    /**
     * Asserts an email at a specific index contains expected contents
     *
     * @param int $at Email index
     * @param string $contents Contents
     * @param string $message Message
     */
    void assertMailContainsAt(int $at, string $contents, string $message = "") {
        this.assertThat($contents, new MailContains($at), $message);
    }

    /**
     * Asserts an email at a specific index contains expected html contents
     *
     * @param int $at Email index
     * @param string $contents Contents
     * @param string $message Message
     */
    void assertMailContainsHtmlAt(int $at, string $contents, string $message = "") {
        this.assertThat($contents, new MailContainsHtml($at), $message);
    }

    /**
     * Asserts an email at a specific index contains expected text contents
     *
     * @param int $at Email index
     * @param string $contents Contents
     * @param string $message Message
     */
    void assertMailContainsTextAt(int $at, string $contents, string $message = "") {
        this.assertThat($contents, new MailContainsText($at), $message);
    }

    /**
     * Asserts an email at a specific index contains the expected value within an Email getter
     *
     * @param int $at Email index
     * @param string $expected Contents
     * @param string $parameter Email getter parameter (e.g~ "cc", "bcc")
     * @param string $message Message
     */
    void assertMailSentWithAt(int $at, string $expected, string $parameter, string $message = "") {
        this.assertThat($expected, new MailSentWith($at, $parameter), $message);
    }

    /**
     * Asserts an email was sent to an address
     *
     * @param string $address Email address
     * @param string $message Message
     */
    void assertMailSentTo(string $address, string $message = "") {
        this.assertThat($address, new MailSentTo(), $message);
    }

    /**
     * Asserts an email was sent from an address
     *
     * @param array<string>|string $address Email address
     * @param string $message Message
     */
    void assertMailSentFrom($address, string $message = "") {
        this.assertThat($address, new MailSentFrom(), $message);
    }

    /**
     * Asserts an email contains expected contents
     *
     * @param string $contents Contents
     * @param string $message Message
     */
    void assertMailContains(string $contents, string $message = "") {
        this.assertThat($contents, new MailContains(), $message);
    }

    /**
     * Asserts an email contains expected attachment
     *
     * @param string $filename Filename
     * @param array $file Additional file properties
     * @param string $message Message
     */
    void assertMailContainsAttachment(string $filename, array $file = [], string $message = "") {
        this.assertThat([$filename, $file], new MailContainsAttachment(), $message);
    }

    /**
     * Asserts an email contains expected html contents
     *
     * @param string $contents Contents
     * @param string $message Message
     */
    void assertMailContainsHtml(string $contents, string $message = "") {
        this.assertThat($contents, new MailContainsHtml(), $message);
    }

    /**
     * Asserts an email contains an expected text content
     *
     * @param string $expected Expected text.
     * @param string $message Message to display if assertion fails.
     */
    void assertMailContainsText(string $expected, string $message = "") {
        this.assertThat($expected, new MailContainsText(), $message);
    }

    /**
     * Asserts an email contains the expected value within an Email getter
     *
     * @param string $expected Contents
     * @param string $parameter Email getter parameter (e.g~ "cc", "subject")
     * @param string $message Message
     */
    void assertMailSentWith(string $expected, string $parameter, string $message = "") {
        this.assertThat($expected, new MailSentWith(null, $parameter), $message);
    }

    /**
     * Asserts an email subject contains expected contents
     *
     * @param string $contents Contents
     * @param string $message Message
     */
    void assertMailSubjectContains(string $contents, string $message = "") {
        this.assertThat($contents, new MailSubjectContains(), $message);
    }

    /**
     * Asserts an email at a specific index contains expected html contents
     *
     * @param int $at Email index
     * @param string $contents Contents
     * @param string $message Message
     */
    void assertMailSubjectContainsAt(int $at, string $contents, string $message = "") {
        this.assertThat($contents, new MailSubjectContains($at), $message);
    }
}
