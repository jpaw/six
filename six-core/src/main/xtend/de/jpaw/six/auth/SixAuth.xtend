package de.jpaw.six.auth

import de.jpaw.bonaparte.pojos.api.auth.JwtInfo
import de.jpaw.bonaparte8.vertx3.auth.BonaparteJwtAuthHandlerImpl
import de.jpaw.dp.Dependent
import de.jpaw.dp.Inject
import de.jpaw.dp.Singleton
import de.jpaw.six.IAuthenticationBackend
import de.jpaw.six.IServiceModule
import io.vertx.core.Handler
import io.vertx.core.Vertx
import io.vertx.core.impl.VertxInternal
import io.vertx.ext.web.Router
import io.vertx.ext.web.RoutingContext
import java.nio.charset.StandardCharsets
import java.util.Base64
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
    
    // hook for per-request basic or X509 authentification
    override authenticate(RoutingContext ctx, String header) {
        if (header.startsWith("Basic ")) {
            try {
                val decoded = new String(Base64.urlDecoder.decode(header.substring(6).trim), StandardCharsets.UTF_8)
                val colonPos = decoded.indexOf(':')
                if (colonPos > 0 && colonPos < decoded.length) {
                    // set User
                    val user = authBackend.authByUserPassword(decoded.substring(0, colonPos), decoded.substring(colonPos+1))
                }
            } catch (Exception e) {
                ctx.response.statusCode = 500
                ctx.response.statusMessage = "http header decoding exception"
                return
            }
        }
        super.authenticate(ctx, header)
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
