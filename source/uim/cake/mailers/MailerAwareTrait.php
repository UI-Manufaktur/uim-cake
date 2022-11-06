module uim.cakeiler;

import uim.cakere.App;
import uim.cakeiler\Exception\MissingMailerException;

/**
 * Provides functionality for loading mailer classes
 * onto properties of the host object.
 *
 * Example users of this trait are Cake\Controller\Controller and
 * Cake\Console\Command.
 */
trait MailerAwareTrait
{
    /**
     * Returns a mailer instance.
     *
     * @param string myName Mailer's name.
     * @param array<string, mixed>|string|null myConfig Array of configs, or profile name string.
     * @return \Cake\Mailer\Mailer
     * @throws \Cake\Mailer\Exception\MissingMailerException if undefined mailer class.
     */
    protected auto getMailer(string myName, myConfig = null): Mailer
    {
        myClassName = App::className(myName, 'Mailer', 'Mailer');
        if (myClassName === null) {
            throw new MissingMailerException(compact('name'));
        }

        return new myClassName(myConfig);
    }
}
