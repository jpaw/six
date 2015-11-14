package de.jpaw.six;

import de.jpaw.bonaparte.pojos.api.auth.JwtInfo;
import de.jpaw.util.ApplicationException;

public interface IAuthenticationBackend {
    JwtInfo authByApiKey(String apiKey) throws ApplicationException ;
    JwtInfo authByUserPassword(String userId, String password) throws ApplicationException;
}
