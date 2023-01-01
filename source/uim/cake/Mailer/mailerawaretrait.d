module uim.cake.Mailer;

import uim.cake.core.App;
import uim.cake.Mailer\exceptions.MissingMailerException;

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
     * @param string aName Mailer"s name.
     * @param array<string, mixed>|string|null $config Array of configs, or profile name string.
     * @return uim.cake.Mailer\Mailer
     * @throws uim.cake.Mailer\exceptions.MissingMailerException if undefined mailer class.
     */
    protected function getMailer(string aName, $config = null): Mailer
    {
        $className = App::className($name, "Mailer", "Mailer");
        if ($className == null) {
            throw new MissingMailerException(compact("name"));
        }

        return new $className($config);
    }
}
