package de.jpaw.six.demo

import de.jpaw.bonaparte.api.auth.IRequestProcessor
import de.jpaw.bonaparte.core.BonaPortable
import de.jpaw.bonaparte.core.BonaparteJsonEscaper
import de.jpaw.bonaparte.core.StaticMeta
import de.jpaw.bonaparte.pojos.api.auth.JwtInfo
import de.jpaw.dp.Dependent
import de.jpaw.dp.Fallback
import de.jpaw.dp.Named
import de.jpaw.dp.Singleton
import de.jpaw.six.IServiceModule
import io.vertx.core.Vertx
import io.vertx.ext.web.Router
import java.util.Currency
import org.slf4j.Logger
import org.slf4j.LoggerFactory

import static io.vertx.core.http.HttpHeaders.*

/** This is a pseudo module in the sense that rather than contributing a specific set of methods,
 * it provides a dispatcher.
 */
 @Named("demo")
 @Dependent
class SixDemoModule implements IServiceModule {
    private static final Logger LOGGER = LoggerFactory.getLogger(SixDemoModule)
    
    override getExceptionOffset() {
        return 230000
    }
    
    override getModuleName() {
        return "demo"
    }
    
    override createRouter(Vertx vertx) {
        LOGGER.info("Registering module {}", moduleName)
        
        return Router.router(vertx) => [
            get("/hello").handler [
                LOGGER.info("Saying hello")
                response.putHeader(CONTENT_TYPE, "text/plain");
                response.end('''Hello world''')
            ]
            get("/currencies").handler [
                LOGGER.info("Sending currencies")
                response.putHeader("content-type", "application/json").end(BonaparteJsonEscaper.asJson(Currency.availableCurrencies.map[currencyCode].toList))
            ]
        ]
    }
}

@Fallback
@Singleton
class SixDemoProcessor implements IRequestProcessor<BonaPortable, BonaPortable> {
    private static final Logger LOGGER = LoggerFactory.getLogger(SixDemoProcessor)
    
    override execute(BonaPortable rq, JwtInfo info, String encodedJwt) {
        LOGGER.info('''Processing request «rq»''')
        return rq  // demo: simple ECHO
    }
    
    override getRequestRef() {
        return StaticMeta.OUTER_BONAPORTABLE
    }
    
    override getResponseRef() {
        return StaticMeta.OUTER_BONAPORTABLE
    }
    
    override getReturnCode(BonaPortable rs) {
        return 0
    }
    
    override getErrorDetails(BonaPortable rs) {
        return null;
    }
}