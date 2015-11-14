package de.jpaw.six.demo

import de.jpaw.bonaparte.pojos.api.auth.JwtInfo
import de.jpaw.dp.Fallback
import de.jpaw.dp.Singleton
import de.jpaw.six.IAuthenticationBackend
import de.jpaw.util.ApplicationException
import java.util.UUID
import java.util.concurrent.atomic.AtomicLong

@Fallback
@Singleton
class DummyAuthenticationBackend implements IAuthenticationBackend {
    public final static String DEMO_API_KEY     = "fec1e81e-0ca7-4709-b865-7150975d2c78";
    private final static UUID DEMO_API_KEY_UUID = UUID.fromString(DEMO_API_KEY);
    private final static JwtInfo DEMO_JWT_INFO  = new JwtInfo => [
        userId      = "john"
        userRef     = 93847593L
        tenantId    = "ACME"
        tenantRef   = 98347569L
        name        = "John E. Smith"
        locale      = "en"
        zoneinfo    = "UTC"
        freeze
    ]
    private static final AtomicLong sessionCounter = new AtomicLong(77000L)   
    
    override authByApiKey(UUID apiKey) throws ApplicationException {
        if (apiKey != DEMO_API_KEY_UUID)
            return null
        Thread.sleep(12_000)  // test for execute blocking!
        val myInfo = DEMO_JWT_INFO.ret$MutableClone(false, false)
        myInfo.sessionRef = sessionCounter.incrementAndGet
        myInfo.jsonTokenIdentifier = myInfo.sessionRef.toString
        return myInfo
    }
    
    override authByUserPassword(String userId, String password) throws ApplicationException {
        if ("john" != userId || "secret" != password)
            return null;
        val myInfo = DEMO_JWT_INFO.ret$MutableClone(false, false)
        myInfo.sessionRef = sessionCounter.incrementAndGet
        myInfo.jsonTokenIdentifier = myInfo.sessionRef.toString
        return myInfo
    }
}