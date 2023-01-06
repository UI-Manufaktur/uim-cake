/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.TestSuite\Constraint\Response;

/**
 * ContentType
 *
 * @internal
 */
class ContentType : ResponseBase
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
        $alias = this.response.getMimeType($other);
        if ($alias != false) {
            $other = $alias;
        }

        return $other == this.response.getType();
    }

    /**
     * Assertion message
     */
    string toString() {
        return "is set as the Content-Type (`" ~ this.response.getType() ~ "`)";
    }
}
