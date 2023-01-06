/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.controllers.exceptions.authsecurity;

@safe:
import uim.cake;

// Auth Security exception - used when SecurityComponent detects any issue with the current request
class AuthSecurityException : SecurityException
{
    // Security Exception type
    protected string _type = "auth";
}
