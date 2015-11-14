package de.jpaw.six.demo

import de.jpaw.bonaparte.core.BonaparteJsonEscaper
import de.jpaw.dp.Dependent
import de.jpaw.dp.Named
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
class DemoModule implements IServiceModule {
    private static final Logger LOGGER = LoggerFactory.getLogger(DemoModule)
    
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