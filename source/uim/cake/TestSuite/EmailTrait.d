

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.7.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.TestSuite;

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
     * @return void
     */
    auto setupTransports(): void
    {
        TestEmailTransport::replaceAllTransports();
    }

    /**
     * Resets transport state
     *
     * @after
     * @return void
     */
    function cleanupEmailTrait(): void
    {
        TestEmailTransport::clearMessages();
    }

    /**
     * Asserts an expected number of emails were sent
     *
     * @param int myCount Email count
     * @param string myMessage Message
     * @return void
     */
    function assertMailCount(int myCount, string myMessage = ''): void
    {
        this.assertThat(myCount, new MailCount(), myMessage);
    }

    /**
     * Asserts that no emails were sent
     *
     * @param string myMessage Message
     * @return void
     */
    function assertNoMailSent(string myMessage = ''): void
    {
        this.assertThat(null, new NoMailSent(), myMessage);
    }

    /**
     * Asserts an email at a specific index was sent to an address
     *
     * @param int $at Email index
     * @param string $address Email address
     * @param string myMessage Message
     * @return void
     */
    function assertMailSentToAt(int $at, string $address, string myMessage = ''): void
    {
        this.assertThat($address, new MailSentTo($at), myMessage);
    }

    /**
     * Asserts an email at a specific index was sent from an address
     *
     * @param int $at Email index
     * @param string $address Email address
     * @param string myMessage Message
     * @return void
     */
    function assertMailSentFromAt(int $at, string $address, string myMessage = ''): void
    {
        this.assertThat($address, new MailSentFrom($at), myMessage);
    }

    /**
     * Asserts an email at a specific index contains expected contents
     *
     * @param int $at Email index
     * @param string myContentss Contents
     * @param string myMessage Message
     * @return void
     */
    function assertMailContainsAt(int $at, string myContentss, string myMessage = ''): void
    {
        this.assertThat(myContentss, new MailContains($at), myMessage);
    }

    /**
     * Asserts an email at a specific index contains expected html contents
     *
     * @param int $at Email index
     * @param string myContentss Contents
     * @param string myMessage Message
     * @return void
     */
    function assertMailContainsHtmlAt(int $at, string myContentss, string myMessage = ''): void
    {
        this.assertThat(myContentss, new MailContainsHtml($at), myMessage);
    }

    /**
     * Asserts an email at a specific index contains expected text contents
     *
     * @param int $at Email index
     * @param string myContentss Contents
     * @param string myMessage Message
     * @return void
     */
    function assertMailContainsTextAt(int $at, string myContentss, string myMessage = ''): void
    {
        this.assertThat(myContentss, new MailContainsText($at), myMessage);
    }

    /**
     * Asserts an email at a specific index contains the expected value within an Email getter
     *
     * @param int $at Email index
     * @param string $expected Contents
     * @param string $parameter Email getter parameter (e.g. "cc", "bcc")
     * @param string myMessage Message
     * @return void
     */
    function assertMailSentWithAt(int $at, string $expected, string $parameter, string myMessage = ''): void
    {
        this.assertThat($expected, new MailSentWith($at, $parameter), myMessage);
    }

    /**
     * Asserts an email was sent to an address
     *
     * @param string $address Email address
     * @param string myMessage Message
     * @return void
     */
    function assertMailSentTo(string $address, string myMessage = ''): void
    {
        this.assertThat($address, new MailSentTo(), myMessage);
    }

    /**
     * Asserts an email was sent from an address
     *
     * @param string $address Email address
     * @param string myMessage Message
     * @return void
     */
    function assertMailSentFrom(string $address, string myMessage = ''): void
    {
        this.assertThat($address, new MailSentFrom(), myMessage);
    }

    /**
     * Asserts an email contains expected contents
     *
     * @param string myContentss Contents
     * @param string myMessage Message
     * @return void
     */
    function assertMailContains(string myContentss, string myMessage = ''): void
    {
        this.assertThat(myContentss, new MailContains(), myMessage);
    }

    /**
     * Asserts an email contains expected attachment
     *
     * @param string $filename Filename
     * @param array $file Additional file properties
     * @param string myMessage Message
     * @return void
     */
    function assertMailContainsAttachment(string $filename, array $file = [], string myMessage = ''): void
    {
        this.assertThat([$filename, $file], new MailContainsAttachment(), myMessage);
    }

    /**
     * Asserts an email contains expected html contents
     *
     * @param string myContentss Contents
     * @param string myMessage Message
     * @return void
     */
    function assertMailContainsHtml(string myContentss, string myMessage = ''): void
    {
        this.assertThat(myContentss, new MailContainsHtml(), myMessage);
    }

    /**
     * Asserts an email contains an expected text content
     *
     * @param string $expected Expected text.
     * @param string myMessage Message to display if assertion fails.
     * @return void
     */
    function assertMailContainsText(string $expected, string myMessage = ''): void
    {
        this.assertThat($expected, new MailContainsText(), myMessage);
    }

    /**
     * Asserts an email contains the expected value within an Email getter
     *
     * @param string $expected Contents
     * @param string $parameter Email getter parameter (e.g. "cc", "subject")
     * @param string myMessage Message
     * @return void
     */
    function assertMailSentWith(string $expected, string $parameter, string myMessage = ''): void
    {
        this.assertThat($expected, new MailSentWith(null, $parameter), myMessage);
    }

    /**
     * Asserts an email subject contains expected contents
     *
     * @param string myContentss Contents
     * @param string myMessage Message
     * @return void
     */
    function assertMailSubjectContains(string myContentss, string myMessage = ''): void
    {
        this.assertThat(myContentss, new MailSubjectContains(), myMessage);
    }

    /**
     * Asserts an email at a specific index contains expected html contents
     *
     * @param int $at Email index
     * @param string myContentss Contents
     * @param string myMessage Message
     * @return void
     */
    function assertMailSubjectContainsAt(int $at, string myContentss, string myMessage = ''): void
    {
        this.assertThat(myContentss, new MailSubjectContains($at), myMessage);
    }
}
