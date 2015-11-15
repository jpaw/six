package de.jpaw.six.auth

import de.jpaw.bonaparte.api.auth.IAuthenticationBackend
import de.jpaw.bonaparte.pojos.api.auth.JwtInfo
import de.jpaw.bonaparte8.vertx3.auth.BonaparteJwtAuthHandlerImpl
import de.jpaw.bonaparte8.vertx3.auth.BonaparteVertxUser
import de.jpaw.dp.Dependent
import de.jpaw.dp.Inject
import de.jpaw.dp.Singleton
import de.jpaw.six.IServiceModule
import io.vertx.core.AsyncResultHandler
import io.vertx.core.Handler
import io.vertx.core.Vertx
import io.vertx.core.impl.VertxInternal
import io.vertx.ext.web.Router
import io.vertx.ext.web.RoutingContext
import java.nio.charset.StandardCharsets
import java.util.Base64
import java.util.UUID
import org.slf4j.Logger
import org.slf4j.LoggerFactory

import static io.vertx.core.http.HttpHeaders.*

interface IAuthHandler extends Handler<RoutingContext> {
    def Router createRouter(Vertx vertx)
}

interface IAuthHandlerFactory {
    def IAuthHandler create(Vertx vertx)
}

// no Named in order not to see it in the module list!
@Dependent
class SixAuthHandler extends BonaparteJwtAuthHandlerImpl implements IAuthHandler, IServiceModule {
    private static final Logger LOGGER = LoggerFactory.getLogger(SixAuthHandler)
    private static final Long DURATION_OF_TEMPORARY_TOKEN = Long.valueOf(60)

    @Inject IAuthenticationBackend authBackend;
        
    public new (VertxInternal vertx) {
        super(vertx.resolveFile("/tmp/mykeystore.jceks"), "xyzzy5")
    }
    
    override getExceptionOffset() {
        return 1_000
    }
    
    override getModuleName() {
        return "auth"
    }
    
    override getMountPoint() {
        return "/"
    }
    
    // hook for per-request basic or X509 authentification.
    // this is called while we actually wanted an existing token, but did not get one.
    // if we find another usable auth method, generate a temporary 1 minute token
    override authenticate(RoutingContext it, String header) {
        try {
            val ctx = it
            val AsyncResultHandler<JwtInfo> resultHandler = [
                if (succeeded && result !== null) {
                    val jwtToken = sign(result, DURATION_OF_TEMPORARY_TOKEN, null)
                    ctx.user = new BonaparteVertxUser(jwtToken, result)
                    ctx.next
                } else {
                    ctx.error(403, "Authorization parameters not accepted")
                }]
            if (header.startsWith("Basic ")) {
                val decoded = new String(Base64.urlDecoder.decode(header.substring(6).trim), StandardCharsets.UTF_8)
                val colonPos = decoded.indexOf(':')
                if (colonPos > 0 && colonPos < decoded.length) {
                    // set User. Do it in a separate blocking thread because most likely the implementation uses database I/O
                    vertx.executeBlocking([
                        complete(authBackend.authByUserPassword(decoded.substring(0, colonPos), decoded.substring(colonPos+1)))
                    ], [
                        if (succeeded && result !== null) {
                            val jwtToken = sign(result, DURATION_OF_TEMPORARY_TOKEN, null)
                            ctx.user = new BonaparteVertxUser(jwtToken, result)
                            ctx.next
                        } else {
                            ctx.error(403, "Basic Authorization parameters not accepted")
                        }
                    ])
                    return
                }
                error(403, "Basic Authorization parameters not accepted")
                return
            }
            if (header.startsWith("API-Key ")) {
//                val info = authBackend.authByApiKey(UUID.fromString(header.substring(8).trim))
//                if (info !== null) {
//                    val jwtToken = sign(info, DURATION_OF_TEMPORARY_TOKEN, null)
//                    user = new BonaparteVertxUser(jwtToken, info)
//                    next
//                    return
//                }
                vertx.executeBlocking([ complete(authBackend.authByApiKey(UUID.fromString(header.substring(8).trim))) ], resultHandler)
                return
            }
        } catch (Exception e) {
            error(500, "http Authorization header processing exception")
            return
        }
        super.authenticate(it, header)
    }
    
    // setup sign-in
    override createRouter(Vertx vertx) {
        LOGGER.info("Registering module auth")
        return Router.router(vertx) => [
            get("/login").handler [                                             // create a new JWT token
                LOGGER.info("Logging in for locale {}", preferredLocale)
                response.putHeader(CONTENT_TYPE, "text/plain");
                response.end(sign(new JwtInfo => [
                        tenantId    = "ACME"
                        userId      =  "john"
                        userRef     = 4711L
                    ], 600L, null));
            ]
            
        ]
    }
}

@Singleton
class SixAuthHandlerFactory implements IAuthHandlerFactory {
    override create(Vertx vertx) {
        return new SixAuthHandler(vertx as VertxInternal)
    }
}
