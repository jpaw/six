package de.jpaw.six.server

import de.jpaw.bonaparte.core.BonaPortable
import de.jpaw.bonaparte8.vertx3.codecs.SingleThreadCachingMessageCoderFactory
import de.jpaw.dp.Default
import de.jpaw.dp.Dependent
import de.jpaw.dp.Inject
import de.jpaw.dp.Jdp
import de.jpaw.six.IServiceModule
import de.jpaw.six.auth.IAuthHandlerFactory
import de.jpaw.xenums.init.ExceptionInitializer
import de.jpaw.xenums.init.ReflectionsPackageCache
import de.jpaw.xenums.init.XenumInitializer
import io.vertx.core.AbstractVerticle
import io.vertx.core.Handler
import io.vertx.core.Vertx
import io.vertx.core.buffer.Buffer
import io.vertx.ext.web.Router
import io.vertx.ext.web.RoutingContext
import io.vertx.ext.web.handler.BodyHandler
import io.vertx.ext.web.handler.StaticHandler
import io.vertx.ext.web.handler.sockjs.BridgeOptions
import io.vertx.ext.web.handler.sockjs.PermittedOptions
import io.vertx.ext.web.handler.sockjs.SockJSHandler
import java.util.Collections
import org.slf4j.Logger
import org.slf4j.LoggerFactory

@Default
@Dependent
public class SixMessageCoderFactory<O extends BonaPortable> extends SingleThreadCachingMessageCoderFactory<BonaPortable> {
}

public class SimpleBodyHandler implements Handler<RoutingContext> {
    val long bodyLimit
    
    public new (Long limit) {
        this.bodyLimit = limit
    }
    public new () {
        this.bodyLimit = -1L
    }
    
    override handle(RoutingContext context) {
        context.request => [
            val handler = new BHandler(context, bodyLimit);
            handler(handler);
            endHandler [ handler.end ]
        ]
    }
    
    private static class BHandler implements Handler<Buffer> {

        val long bodyLimit
        val RoutingContext context;
        val Buffer body = Buffer.buffer();
        var boolean failed;
        var boolean ended;

        private new(RoutingContext it, long limit) {
            this.context = it
            this.bodyLimit = limit
            // request.expectMultipart = false
            request.exceptionHandler [ context.fail(it) ];
        }
        
        override handle(Buffer buff) {
            if (failed) {
                return;
            }
            if (bodyLimit != -1 && (body.length() + buff.length()) > bodyLimit) {
                failed = true;
                context.fail(413);
            } else {
                body.appendBuffer(buff);
            }
        }

        def void end() {
            if (failed || ended) {
                return;
            }
            ended = true;
            context.setBody(body);
            context.next();
        }
    }
}


public class SixServer extends AbstractVerticle {
    private static final Logger LOGGER = LoggerFactory.getLogger(SixServer)
    private static final String EVENTBUS_ADDRESS = "draw";
    private static int port = 8080
    
    // have a per-instance (thread) prealloacted map of composers
    @Inject IAuthHandlerFactory authHandlerFactory
        
    // doc on key store:  http://vertx.io/docs/vertx-auth-jwt/js/
    override void start() {
        super.start
        
        val modules = Jdp.getOneInstancePerQualifier(IServiceModule)
        Collections.sort(modules)
        LOGGER.info("Six Vert.x server started, modules found are: " + modules.map[moduleName].join(', '))
        
        val authHandler = authHandlerFactory.create(vertx) 
        val bridgeOptions = new BridgeOptions()
            .addOutboundPermitted(new PermittedOptions().setAddress(EVENTBUS_ADDRESS))
            .addInboundPermitted(new PermittedOptions().setAddress(EVENTBUS_ADDRESS))
            
        val router = Router.router(vertx) => [
            route("/api/*").handler(BodyHandler.create)     // must be before any possible execBlocking, see https://github.com/vert-x3/vertx-web/issues/198
            route("/api/*").handler(authHandler);
            // post("/api/*").handler(new SimpleBodyHandler(8_000_000L))  // BodyHandler.create)
            
            // register the web paths of the injected modules
            for (m : modules) {
                mountSubRouter(m.mountPoint + m.moduleName, m.createRouter(vertx))
            }
            mountSubRouter("/auth", authHandler.createRouter(vertx))
            
            route("/eventbus/*").handler(SockJSHandler.create(vertx).bridge(bridgeOptions))
//            ]
            route("/static/*").handler(StaticHandler.create => [
                webRoot = "web"
                filesReadOnly = true
                maxAgeSeconds = 12 * 60 * 60  // 12 hours (1 working day)
            ])
            get("/favicon.ico").handler [
                LOGGER.info("favico requested")
                response.sendFile("web/favicon.ico")
            ]
            route.handler [           // no matching path or method
                LOGGER.info("Request method {} for path {} not supported", request.method, request.path)
                response.statusCode = 404
            ]
        ]
        vertx.createHttpServer => [
//            websocketHandler [
//                if (path == "/websockettestpath")
//                    println("Connected websocket")
//                else
//                    reject
//            ]
            requestHandler [ router.accept(it) ]
            listen(port)
        ]
    }

    def static void initializeJdp() {
        val scannedPackages = ReflectionsPackageCache.getAll("de.jpaw")
        
        ExceptionInitializer.initializeExceptionClasses(scannedPackages);
        XenumInitializer.initializeXenums(scannedPackages);
        
        Jdp.init(scannedPackages);
    }

    def static void main(String[] args) throws Exception {
        LOGGER.info('''Six server starting...''')
        initializeJdp
        try {
            val portStr = System.getenv("PORT")
            if (portStr !== null) {
                println('''Found environment spec for PORT: «portStr», assuming we run on AWS Elastic Beanstalk''')
                port = Integer.parseInt(portStr)
            } else {
                println('''No PORT environment setting found, assuming we run locally''')
            }
        } catch (Exception e) {
            println('''Exception «e.message», JPA probably not working''')
        }
        Vertx.vertx.deployVerticle(new SixServer)
        LOGGER.info('''listening on port «port»...''')

        new Thread([Thread.sleep(100000)]).start // wait in some other thread
    }
}     
