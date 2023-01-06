/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.TestSuite\Constraint\Response;

/**
 * FileSent
 *
 * @internal
 */
class FileSent : ResponseBase
{
    /**
     * @var uim.cake.http.Response
     */
    protected $response;

    /**
     * Checks assertion
     *
     * @param mixed $other Expected type
     */
    bool matches($other) {
        return this.response.getFile() != null;
    }

    /**
     * Assertion message
     */
    string toString() {
        return "file was sent";
    }

    /**
     * Overwrites the descriptions so we can remove the automatic "expected" message
     *
     * @param mixed $other Value
     */
    protected string failureDescription($other) {
        return this.toString();
    }
}
